/// Data-layer models for Space and Chat, mirroring
/// db/migrations/003_space_and_chat.sql.
library;

/// A comment, or a reply under one. The two are the same row in the database
/// and differ only by whether they have a parent.
class SpaceCommentRow {
  const SpaceCommentRow({
    required this.id,
    required this.author,
    required this.body,
    required this.postedAt,
    required this.official,
    this.replies = const [],
  });

  final String id;
  final String author;
  final String body;
  final DateTime postedAt;

  /// True when Crown Solar itself wrote it.
  final bool official;

  final List<SpaceCommentRow> replies;

  Map<String, Object?> toJson() => {
    'id': id,
    'author': author,
    'body': body,
    'postedAt': postedAt.toIso8601String(),
    'official': official,
    'replies': [for (final reply in replies) reply.toJson()],
  };
}

/// One post, as one partner sees it.
///
/// `hearts` and `heartedByMe` are counted from the heart rows rather than
/// stored, so they cannot drift from who actually hearted it.
class SpacePostRow {
  const SpacePostRow({
    required this.id,
    required this.title,
    required this.body,
    required this.postedAt,
    required this.audience,
    required this.hearts,
    required this.heartedByMe,
    this.imageUrl,
    this.comments = const [],
  });

  final String id;
  final String title;
  final String body;
  final DateTime postedAt;

  /// 'all' | 'installer' | 'retailer' | 'trade'.
  final String audience;

  final int hearts;
  final bool heartedByMe;
  final String? imageUrl;
  final List<SpaceCommentRow> comments;

  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'body': body,
    'imageUrl': imageUrl,
    'postedAt': postedAt.toIso8601String(),
    'audience': audience,
    'hearts': hearts,
    'heartedByMe': heartedByMe,
    'comments': [for (final comment in comments) comment.toJson()],
  };
}

/// Who a conversation is with.
///
/// A department's title and purpose are not here: the app owns that copy, and
/// duplicating it in the database would give it two places to disagree. The
/// address is enough for the app to look it up.
class ChatPartyRow {
  const ChatPartyRow({
    required this.address,
    required this.isDepartment,
    this.name,
    this.role,
    this.market,
  });

  /// Ten national digits, or `dept:<name>`.
  final String address;
  final bool isDepartment;

  final String? name;
  final String? role;
  final String? market;

  Map<String, Object?> toJson() => {
    'address': address,
    'isDepartment': isDepartment,
    'name': name,
    'role': role,
    'market': market,
  };
}

class ChatMessageRow {
  const ChatMessageRow({
    required this.id,
    required this.body,
    required this.sentAt,
    required this.senderAddress,
    required this.status,
  });

  final String id;
  final String body;
  final DateTime sentAt;

  /// Who said it. The app compares this with its own address to decide which
  /// side of the thread a bubble sits on.
  final String senderAddress;

  /// 'sending' | 'sent' | 'delivered' | 'read'.
  final String status;

  Map<String, Object?> toJson() => {
    'id': id,
    'body': body,
    'sentAt': sentAt.toIso8601String(),
    'senderAddress': senderAddress,
    'status': status,
  };
}

class ChatThreadRow {
  const ChatThreadRow({
    required this.id,
    required this.party,
    required this.messages,
    required this.unread,
  });

  final String id;
  final ChatPartyRow party;
  final List<ChatMessageRow> messages;

  /// Messages the partner has not opened yet: those after their read mark
  /// that they did not send themselves.
  final int unread;

  Map<String, Object?> toJson() => {
    'id': id,
    'party': party.toJson(),
    'unread': unread,
    'messages': [for (final message in messages) message.toJson()],
  };
}
