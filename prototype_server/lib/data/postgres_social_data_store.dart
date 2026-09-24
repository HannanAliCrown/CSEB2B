import 'package:postgres/postgres.dart';

import '../db/postgres_client.dart';
import 'postgres_partner_data_store.dart' show normaliseMobile;
import 'social_data_store.dart';
import 'social_models.dart';

/// The [SocialDataStore] backed by PostgreSQL.
///
/// Every read is scoped to one partner, because "how many hearts" and "did I
/// heart it" are different questions and only the second needs to know who is
/// asking.
class PostgresSocialDataStore implements SocialDataStore {
  PostgresSocialDataStore(this._client);

  final PostgresClient _client;

  // --- Space ---

  /// The audiences a role can see. 'trade' groups wholesalers and
  /// distributors, which is how the app groups them too.
  static List<String> _audiencesFor(String userType) => switch (userType) {
    'installer' => ['all', 'installer'],
    'retailer' => ['all', 'retailer'],
    'wholesaler' || 'distributor' => ['all', 'trade'],
    _ => ['all'],
  };

  Future<({String id, String userType})?> _account(String mobileNumber) async {
    final result = await _client.pool.execute(
      Sql.named(
        'SELECT id, user_type FROM accounts WHERE mobile_number = @number',
      ),
      parameters: {'number': normaliseMobile(mobileNumber)},
    );
    if (result.isEmpty) return null;
    final row = result.first.toColumnMap();
    return (id: '${row['id']}', userType: row['user_type'] as String);
  }

  @override
  Future<List<SpacePostRow>> spaceFeed(String mobileNumber) async {
    final account = await _account(mobileNumber);
    if (account == null) return const [];

    final posts = await _client.pool.execute(
      Sql.named('''
        SELECT p.id, p.title, p.body, p.image_url, p.audience, p.posted_at,
               (SELECT count(*) FROM space_post_hearts h WHERE h.post_id = p.id)::int AS hearts,
               EXISTS (SELECT 1 FROM space_post_hearts h
                        WHERE h.post_id = p.id AND h.account_id = @accountId) AS hearted_by_me
          FROM space_posts p
         WHERE p.published
           AND p.audience = ANY(@audiences)
         ORDER BY p.posted_at DESC
      '''),
      parameters: {
        'accountId': account.id,
        'audiences': account.userType.isEmpty
            ? ['all']
            : _audiencesFor(account.userType),
      },
    );

    return [
      for (final row in posts)
        await _postFrom(row.toColumnMap(), withComments: true),
    ];
  }

  @override
  Future<SpacePostRow?> spacePost({
    required String postId,
    required String mobileNumber,
  }) async {
    final account = await _account(mobileNumber);
    if (account == null) return null;

    final result = await _client.pool.execute(
      Sql.named('''
        SELECT p.id, p.title, p.body, p.image_url, p.audience, p.posted_at,
               (SELECT count(*) FROM space_post_hearts h WHERE h.post_id = p.id)::int AS hearts,
               EXISTS (SELECT 1 FROM space_post_hearts h
                        WHERE h.post_id = p.id AND h.account_id = @accountId) AS hearted_by_me
          FROM space_posts p
         WHERE p.id = @postId AND p.published
      '''),
      parameters: {'postId': postId, 'accountId': account.id},
    );
    if (result.isEmpty) return null;
    return _postFrom(result.first.toColumnMap(), withComments: true);
  }

  Future<SpacePostRow> _postFrom(
    Map<String, dynamic> row, {
    required bool withComments,
  }) async {
    final id = '${row['id']}';
    return SpacePostRow(
      id: id,
      title: row['title'] as String,
      body: row['body'] as String,
      imageUrl: row['image_url'] as String?,
      postedAt: row['posted_at'] as DateTime,
      audience: row['audience'] as String,
      hearts: (row['hearts'] as num).toInt(),
      heartedByMe: row['hearted_by_me'] as bool,
      comments: withComments ? await _commentsFor(id) : const [],
    );
  }

  /// Every comment on a post with its replies nested underneath, in one
  /// query — a reply is the same row with a parent.
  Future<List<SpaceCommentRow>> _commentsFor(String postId) async {
    final result = await _client.pool.execute(
      Sql.named(
        'SELECT id, parent_comment_id, author_name, body, official, posted_at '
        'FROM space_comments WHERE post_id = @postId '
        'ORDER BY posted_at',
      ),
      parameters: {'postId': postId},
    );

    final tops = <String, List<SpaceCommentRow>>{};
    final replies = <String, List<SpaceCommentRow>>{};

    for (final row in result) {
      final map = row.toColumnMap();
      final parent = map['parent_comment_id'];
      final comment = SpaceCommentRow(
        id: '${map['id']}',
        author: map['author_name'] as String,
        body: map['body'] as String,
        postedAt: map['posted_at'] as DateTime,
        official: map['official'] as bool,
      );
      if (parent == null) {
        tops[comment.id] = [comment];
      } else {
        (replies['$parent'] ??= []).add(comment);
      }
    }

    return [
      for (final entry in tops.entries)
        SpaceCommentRow(
          id: entry.value.first.id,
          author: entry.value.first.author,
          body: entry.value.first.body,
          postedAt: entry.value.first.postedAt,
          official: entry.value.first.official,
          replies: replies[entry.key] ?? const [],
        ),
    ];
  }

  @override
  Future<SpacePostRow?> toggleHeart({
    required String postId,
    required String mobileNumber,
  }) async {
    final account = await _account(mobileNumber);
    if (account == null) return null;

    // Delete first: if a row went, the heart was on and is now off. The
    // primary key makes both directions safe to repeat.
    final removed = await _client.pool.execute(
      Sql.named(
        'DELETE FROM space_post_hearts '
        'WHERE post_id = @postId AND account_id = @accountId RETURNING post_id',
      ),
      parameters: {'postId': postId, 'accountId': account.id},
    );
    if (removed.isEmpty) {
      await _client.pool.execute(
        Sql.named(
          'INSERT INTO space_post_hearts (post_id, account_id) '
          'VALUES (@postId, @accountId) ON CONFLICT DO NOTHING',
        ),
        parameters: {'postId': postId, 'accountId': account.id},
      );
    }

    return spacePost(postId: postId, mobileNumber: mobileNumber);
  }

  @override
  Future<SpaceCommentRow?> addComment({
    required String postId,
    required String mobileNumber,
    required String body,
  }) async {
    final result = await _client.pool.execute(
      Sql.named('''
        INSERT INTO space_comments (post_id, account_id, author_name, body)
        SELECT p.id, a.id, a.display_name, @body
          FROM space_posts p, accounts a
         WHERE p.id = @postId AND p.published AND a.mobile_number = @number
        RETURNING id, author_name, body, official, posted_at
      '''),
      parameters: {
        'postId': postId,
        'number': normaliseMobile(mobileNumber),
        'body': body,
      },
    );
    if (result.isEmpty) return null;
    return _commentFrom(result.first.toColumnMap());
  }

  @override
  Future<SpaceCommentRow?> addReply({
    required String commentId,
    required String mobileNumber,
    required String body,
  }) async {
    // The post comes from the comment being answered, so a reply can never
    // land on a different post than its parent.
    final result = await _client.pool.execute(
      Sql.named('''
        INSERT INTO space_comments (post_id, parent_comment_id, account_id, author_name, body)
        SELECT c.post_id, c.id, a.id, a.display_name, @body
          FROM space_comments c, accounts a
         WHERE c.id = @commentId AND a.mobile_number = @number
        RETURNING id, author_name, body, official, posted_at
      '''),
      parameters: {
        'commentId': commentId,
        'number': normaliseMobile(mobileNumber),
        'body': body,
      },
    );
    if (result.isEmpty) return null;
    return _commentFrom(result.first.toColumnMap());
  }

  SpaceCommentRow _commentFrom(Map<String, dynamic> row) => SpaceCommentRow(
    id: '${row['id']}',
    author: row['author_name'] as String,
    body: row['body'] as String,
    postedAt: row['posted_at'] as DateTime,
    official: row['official'] as bool,
  );

  // --- Chat ---

  @override
  Future<ChatPartyRow?> resolveParty(String address) async {
    if (address.startsWith('dept:')) {
      return ChatPartyRow(address: address, isDepartment: true);
    }

    if (address.startsWith('staff:')) {
      // A Crown Solar Teams officer, named by the row Teams keeps here.
      final staff = await _client.pool.execute(
        Sql.named(
          'SELECT display_name, role FROM chat_staff_parties '
          'WHERE address = @address',
        ),
        parameters: {'address': address},
      );
      if (staff.isEmpty) return null;
      final row = staff.first.toColumnMap();
      return ChatPartyRow(
        address: address,
        isDepartment: false,
        name: row['display_name'] as String,
        role: row['role'] as String,
      );
    }

    final number = normaliseMobile(address);
    final result = await _client.pool.execute(
      Sql.named(
        'SELECT a.mobile_number, a.display_name, a.user_type, m.name AS market '
        'FROM accounts a LEFT JOIN markets m ON m.id = a.market_id '
        'WHERE a.mobile_number = @number',
      ),
      parameters: {'number': number},
    );
    if (result.isEmpty) return null;

    final row = result.first.toColumnMap();
    return ChatPartyRow(
      address: row['mobile_number'] as String,
      isDepartment: false,
      name: row['display_name'] as String?,
      role: row['user_type'] as String?,
      market: row['market'] as String?,
    );
  }

  @override
  Future<List<ChatThreadRow>> chatThreads(String mobileNumber) async {
    final mine = normaliseMobile(mobileNumber);

    final result = await _client.pool.execute(
      Sql.named('''
        SELECT t.id,
               CASE WHEN t.party_low = @mine THEN t.party_high ELSE t.party_low END AS other,
               t.last_message_at
          FROM chat_threads t
         WHERE t.party_low = @mine OR t.party_high = @mine
         ORDER BY t.last_message_at DESC NULLS LAST
      '''),
      parameters: {'mine': mine},
    );

    final threads = <ChatThreadRow>[];
    for (final row in result) {
      final map = row.toColumnMap();
      final thread = await _threadFrom(
        id: '${map['id']}',
        otherAddress: map['other'] as String,
        mine: mine,
      );
      if (thread != null) threads.add(thread);
    }
    return threads;
  }

  Future<ChatThreadRow?> _threadFrom({
    required String id,
    required String otherAddress,
    required String mine,
  }) async {
    final party = await resolveParty(otherAddress);
    if (party == null) return null;

    final messages = await _client.pool.execute(
      Sql.named(
        'SELECT id, sender_address, body, status, sent_at '
        'FROM chat_messages WHERE thread_id = @id ORDER BY sent_at',
      ),
      parameters: {'id': id},
    );

    // Unread is derived: anything after my read mark that I did not send.
    final unread = await _client.pool.execute(
      Sql.named('''
        SELECT count(*)::int AS unread
          FROM chat_messages m
          LEFT JOIN chat_thread_reads r
            ON r.thread_id = m.thread_id AND r.participant_address = @mine
         WHERE m.thread_id = @id
           AND m.sender_address <> @mine
           AND (r.last_read_at IS NULL OR m.sent_at > r.last_read_at)
      '''),
      parameters: {'id': id, 'mine': mine},
    );

    return ChatThreadRow(
      id: id,
      party: party,
      unread: (unread.first.toColumnMap()['unread'] as num).toInt(),
      messages: [
        for (final row in messages)
          ChatMessageRow(
            id: '${row.toColumnMap()['id']}',
            body: row.toColumnMap()['body'] as String,
            sentAt: row.toColumnMap()['sent_at'] as DateTime,
            senderAddress: row.toColumnMap()['sender_address'] as String,
            status: row.toColumnMap()['status'] as String,
          ),
      ],
    );
  }

  @override
  Future<ChatThreadRow?> openThread({
    required String mobileNumber,
    required String partyAddress,
  }) async {
    final mine = normaliseMobile(mobileNumber);
    final party = await resolveParty(partyAddress);
    if (party == null || party.address == mine) return null;

    final low = mine.compareTo(party.address) < 0 ? mine : party.address;
    final high = mine.compareTo(party.address) < 0 ? party.address : mine;

    final result = await _client.pool.execute(
      Sql.named('''
        INSERT INTO chat_threads (party_low, party_high)
        VALUES (@low, @high)
        ON CONFLICT (party_low, party_high) DO UPDATE SET party_low = EXCLUDED.party_low
        RETURNING id
      '''),
      parameters: {'low': low, 'high': high},
    );

    return _threadFrom(
      id: '${result.first.toColumnMap()['id']}',
      otherAddress: party.address,
      mine: mine,
    );
  }

  @override
  Future<ChatThreadRow?> sendMessage({
    required String mobileNumber,
    required String partyAddress,
    required String body,
  }) async {
    final thread = await openThread(
      mobileNumber: mobileNumber,
      partyAddress: partyAddress,
    );
    if (thread == null) return null;

    await _client.pool.execute(
      Sql.named(
        'INSERT INTO chat_messages (thread_id, sender_address, body, status) '
        "VALUES (@threadId, @sender, @body, 'sent')",
      ),
      parameters: {
        'threadId': thread.id,
        'sender': normaliseMobile(mobileNumber),
        'body': body,
      },
    );

    return openThread(mobileNumber: mobileNumber, partyAddress: partyAddress);
  }

  @override
  Future<void> markThreadRead({
    required String mobileNumber,
    required String partyAddress,
  }) async {
    final thread = await openThread(
      mobileNumber: mobileNumber,
      partyAddress: partyAddress,
    );
    if (thread == null) return;

    await _client.pool.execute(
      Sql.named('''
        INSERT INTO chat_thread_reads (thread_id, participant_address, last_read_at)
        VALUES (@threadId, @mine, now())
        ON CONFLICT (thread_id, participant_address)
        DO UPDATE SET last_read_at = now()
      '''),
      parameters: {
        'threadId': thread.id,
        'mine': normaliseMobile(mobileNumber),
      },
    );
  }
}
