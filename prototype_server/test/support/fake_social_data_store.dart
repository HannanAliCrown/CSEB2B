import 'package:prototype_server/data/social_data_store.dart';
import 'package:prototype_server/data/social_models.dart';
import 'package:prototype_server/data/postgres_partner_data_store.dart'
    show normaliseMobile;

/// An in-memory [SocialDataStore], enforcing the same rules the SQL does:
/// one heart per partner per post, replies only one level deep, and one
/// conversation shared between two parties rather than a copy each.
class FakeSocialDataStore implements SocialDataStore {
  final Map<String, ({String role, String name})> _accounts = {};
  final List<_Post> _posts = [];
  final List<_Thread> _threads = [];

  var _nextId = 1;

  // --- Test setup ---

  void addAccount({
    required String mobileNumber,
    required String role,
    required String name,
  }) => _accounts[normaliseMobile(mobileNumber)] = (role: role, name: name);

  String addPost({required String title, String audience = 'all'}) {
    final post = _Post(id: 'p${_nextId++}', title: title, audience: audience);
    _posts.add(post);
    return post.id;
  }

  // --- Space ---

  static bool _reaches(String audience, String role) =>
      audience == 'all' ||
      audience == role ||
      (audience == 'trade' && (role == 'wholesaler' || role == 'distributor'));

  @override
  Future<List<SpacePostRow>> spaceFeed(String mobileNumber) async {
    final me = normaliseMobile(mobileNumber);
    final account = _accounts[me];
    if (account == null) return const [];

    return [
      for (final post in _posts)
        if (_reaches(post.audience, account.role)) _postRowFor(post, me),
    ];
  }

  @override
  Future<SpacePostRow?> spacePost({
    required String postId,
    required String mobileNumber,
  }) async {
    final me = normaliseMobile(mobileNumber);
    if (!_accounts.containsKey(me)) return null;
    for (final post in _posts) {
      if (post.id == postId) return _postRowFor(post, me);
    }
    return null;
  }

  SpacePostRow _postRowFor(_Post post, String me) => SpacePostRow(
    id: post.id,
    title: post.title,
    body: 'body',
    postedAt: post.postedAt,
    audience: post.audience,
    hearts: post.hearts.length,
    heartedByMe: post.hearts.contains(me),
    comments: [
      for (final comment in post.comments)
        if (comment.parentId == null)
          SpaceCommentRow(
            id: comment.id,
            author: comment.author,
            body: comment.body,
            postedAt: comment.postedAt,
            official: comment.official,
            replies: [
              for (final reply in post.comments)
                if (reply.parentId == comment.id)
                  SpaceCommentRow(
                    id: reply.id,
                    author: reply.author,
                    body: reply.body,
                    postedAt: reply.postedAt,
                    official: reply.official,
                  ),
            ],
          ),
    ],
  );

  @override
  Future<SpacePostRow?> toggleHeart({
    required String postId,
    required String mobileNumber,
  }) async {
    final me = normaliseMobile(mobileNumber);
    if (!_accounts.containsKey(me)) return null;

    for (final post in _posts) {
      if (post.id != postId) continue;
      // A set, so hearting twice is still one heart.
      post.hearts.contains(me) ? post.hearts.remove(me) : post.hearts.add(me);
      return _postRowFor(post, me);
    }
    return null;
  }

  @override
  Future<SpaceCommentRow?> addComment({
    required String postId,
    required String mobileNumber,
    required String body,
  }) async {
    final me = normaliseMobile(mobileNumber);
    final account = _accounts[me];
    if (account == null) return null;

    for (final post in _posts) {
      if (post.id != postId) continue;
      final comment = _Comment(
        id: 'c${_nextId++}',
        author: account.name,
        body: body,
      );
      post.comments.add(comment);
      return SpaceCommentRow(
        id: comment.id,
        author: comment.author,
        body: comment.body,
        postedAt: comment.postedAt,
        official: false,
      );
    }
    return null;
  }

  @override
  Future<SpaceCommentRow?> addReply({
    required String commentId,
    required String mobileNumber,
    required String body,
  }) async {
    final me = normaliseMobile(mobileNumber);
    final account = _accounts[me];
    if (account == null) return null;

    for (final post in _posts) {
      for (final parent in [...post.comments]) {
        if (parent.id != commentId) continue;
        // The database refuses a third level; so does this.
        if (parent.parentId != null) {
          throw StateError('a reply cannot be made to a reply');
        }
        final reply = _Comment(
          id: 'r${_nextId++}',
          author: account.name,
          body: body,
          parentId: parent.id,
        );
        post.comments.add(reply);
        return SpaceCommentRow(
          id: reply.id,
          author: reply.author,
          body: reply.body,
          postedAt: reply.postedAt,
          official: false,
        );
      }
    }
    return null;
  }

  // --- Chat ---

  @override
  Future<ChatPartyRow?> resolveParty(String address) async {
    if (address.startsWith('dept:')) {
      return ChatPartyRow(address: address, isDepartment: true);
    }
    final number = normaliseMobile(address);
    final account = _accounts[number];
    if (account == null) return null;
    return ChatPartyRow(
      address: number,
      isDepartment: false,
      name: account.name,
      role: account.role,
    );
  }

  _Thread? _threadBetween(String a, String b) {
    for (final thread in _threads) {
      if (thread.parties.contains(a) && thread.parties.contains(b)) {
        return thread;
      }
    }
    return null;
  }

  @override
  Future<List<ChatThreadRow>> chatThreads(String mobileNumber) async {
    final me = normaliseMobile(mobileNumber);
    final mine =
        [
          for (final thread in _threads)
            if (thread.parties.contains(me)) thread,
        ]..sort((a, b) {
          final left = a.messages.isEmpty ? null : a.messages.last.sentAt;
          final right = b.messages.isEmpty ? null : b.messages.last.sentAt;
          if (left == null || right == null) return 0;
          return right.compareTo(left);
        });

    final rows = <ChatThreadRow>[];
    for (final thread in mine) {
      final row = await _threadRowFor(thread, me);
      if (row != null) rows.add(row);
    }
    return rows;
  }

  Future<ChatThreadRow?> _threadRowFor(_Thread thread, String me) async {
    final other = thread.parties.firstWhere((p) => p != me);
    final party = await resolveParty(other);
    if (party == null) return null;

    final mark = thread.reads[me];
    return ChatThreadRow(
      id: thread.id,
      party: party,
      unread: thread.messages
          .where(
            (m) => m.sender != me && (mark == null || m.sentAt.isAfter(mark)),
          )
          .length,
      messages: [
        for (final message in thread.messages)
          ChatMessageRow(
            id: message.id,
            body: message.body,
            sentAt: message.sentAt,
            senderAddress: message.sender,
            status: 'sent',
          ),
      ],
    );
  }

  @override
  Future<ChatThreadRow?> openThread({
    required String mobileNumber,
    required String partyAddress,
  }) async {
    final me = normaliseMobile(mobileNumber);
    final party = await resolveParty(partyAddress);
    if (party == null || party.address == me) return null;

    final thread =
        _threadBetween(me, party.address) ??
        (() {
          final fresh = _Thread(
            id: 't${_nextId++}',
            parties: {me, party.address},
          );
          _threads.add(fresh);
          return fresh;
        })();

    return _threadRowFor(thread, me);
  }

  @override
  Future<ChatThreadRow?> sendMessage({
    required String mobileNumber,
    required String partyAddress,
    required String body,
  }) async {
    final me = normaliseMobile(mobileNumber);
    final opened = await openThread(
      mobileNumber: mobileNumber,
      partyAddress: partyAddress,
    );
    if (opened == null) return null;

    final thread = _threads.firstWhere((t) => t.id == opened.id);
    thread.messages.add(_Message(id: 'm${_nextId++}', sender: me, body: body));
    return _threadRowFor(thread, me);
  }

  @override
  Future<void> markThreadRead({
    required String mobileNumber,
    required String partyAddress,
  }) async {
    final me = normaliseMobile(mobileNumber);
    final opened = await openThread(
      mobileNumber: mobileNumber,
      partyAddress: partyAddress,
    );
    if (opened == null) return;
    _threads.firstWhere((t) => t.id == opened.id).reads[me] = DateTime.now();
  }
}

class _Post {
  _Post({required this.id, required this.title, required this.audience});

  final String id;
  final String title;
  final String audience;
  final DateTime postedAt = DateTime.now();
  final Set<String> hearts = {};
  final List<_Comment> comments = [];
}

class _Comment {
  _Comment({
    required this.id,
    required this.author,
    required this.body,
    this.parentId,
  });

  final String id;
  final String author;
  final String body;
  final String? parentId;

  /// Crown Solar's own comments come from the publishing application, so
  /// nothing written through these routes is ever official.
  final bool official = false;
  final DateTime postedAt = DateTime.now();
}

class _Thread {
  _Thread({required this.id, required this.parties});

  final String id;
  final Set<String> parties;
  final List<_Message> messages = [];
  final Map<String, DateTime> reads = {};
}

class _Message {
  _Message({required this.id, required this.sender, required this.body});

  final String id;
  final String sender;
  final String body;
  final DateTime sentAt = DateTime.now();
}
