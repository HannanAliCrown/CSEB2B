import 'social_models.dart';

/// The persistence boundary for Space and Chat.
///
/// Note what is absent: nothing here creates a Space post. Posts are written
/// by a separate Crown Solar application; the partner app reads them and adds
/// only its own hearts and comments.
abstract interface class SocialDataStore {
  // --- Space ---

  /// The posts this partner's role is meant to see, newest first, each with
  /// its hearts, whether this partner hearted it, and its comments.
  Future<List<SpacePostRow>> spaceFeed(String mobileNumber);

  /// One post as this partner sees it, or null when it is gone or not
  /// published.
  Future<SpacePostRow?> spacePost({
    required String postId,
    required String mobileNumber,
  });

  /// Adds this partner's heart, or takes it away. Returns the post as it now
  /// stands.
  Future<SpacePostRow?> toggleHeart({
    required String postId,
    required String mobileNumber,
  });

  /// A new top-level comment. Null when the post is gone.
  Future<SpaceCommentRow?> addComment({
    required String postId,
    required String mobileNumber,
    required String body,
  });

  /// A reply under an existing comment. Null when that comment is gone, and
  /// refused by the database if it would make a third level.
  Future<SpaceCommentRow?> addReply({
    required String commentId,
    required String mobileNumber,
    required String body,
  });

  // --- Chat ---

  /// This partner's conversations, newest first.
  Future<List<ChatThreadRow>> chatThreads(String mobileNumber);

  /// The conversation with this party, started if there is none.
  Future<ChatThreadRow?> openThread({
    required String mobileNumber,
    required String partyAddress,
  });

  /// Who an address belongs to, or null when nobody. A 'dept:' address always
  /// resolves; a number resolves only to a registered partner.
  Future<ChatPartyRow?> resolveParty(String address);

  /// Sends a message and returns the conversation as it now stands.
  Future<ChatThreadRow?> sendMessage({
    required String mobileNumber,
    required String partyAddress,
    required String body,
  });

  /// Moves this partner's read mark to now, clearing the unread badge.
  Future<void> markThreadRead({
    required String mobileNumber,
    required String partyAddress,
  });
}
