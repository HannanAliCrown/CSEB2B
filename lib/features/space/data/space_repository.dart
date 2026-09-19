// Constructor parameters are named for their public API rather than the
// private fields they populate, so the initializing-formal shorthand the
// linter suggests is not available here.
// ignore_for_file: prefer_initializing_formals

import 'package:flutter/foundation.dart';

import '../../session/data/signed_in_user.dart';

/// Who a post is aimed at. Crown Solar broadcasts to everyone or to one role.
enum PostAudience { everyone, installers, retailers, trade }

extension PostAudienceX on PostAudience {
  String get label => switch (this) {
    PostAudience.everyone => 'All partners',
    PostAudience.installers => 'Installers',
    PostAudience.retailers => 'Retailers',
    PostAudience.trade => 'Wholesale and distribution',
  };

  /// Whether a partner in this role should see the post at all.
  bool reaches(PartnerRole role) => switch (this) {
    PostAudience.everyone => true,
    PostAudience.installers => role == PartnerRole.installer,
    PostAudience.retailers => role == PartnerRole.retailer,
    PostAudience.trade =>
      role == PartnerRole.wholesaler || role == PartnerRole.distributor,
  };
}

/// A reply under a comment.
class PostReply {
  const PostReply({
    required this.id,
    required this.author,
    required this.body,
    required this.postedAt,
    this.official = false,
  });

  final String id;
  final String author;
  final String body;
  final DateTime postedAt;

  /// True when Crown Solar itself wrote it.
  final bool official;
}

/// A comment, and anything said under it.
class PostComment {
  PostComment({
    required this.id,
    required this.author,
    required this.body,
    required this.postedAt,
    this.official = false,
    List<PostReply>? replies,
  }) : replies = replies ?? [];

  final String id;
  final String author;
  final String body;
  final DateTime postedAt;
  final bool official;
  final List<PostReply> replies;
}

/// One broadcast from Crown Solar.
class SpacePost {
  SpacePost({
    required this.id,
    required this.title,
    required this.body,
    required this.postedAt,
    required this.audience,
    required this.imageAsset,
    this.hearts = 0,
    this.heartedByMe = false,
    List<PostComment>? comments,
  }) : comments = comments ?? [];

  final String id;
  final String title;
  final String body;
  final DateTime postedAt;
  final PostAudience audience;

  /// The picture that goes with the post, if it has one.
  final String? imageAsset;

  int hearts;
  bool heartedByMe;
  final List<PostComment> comments;

  /// Comments plus every reply under them — what "6 comments" counts.
  int get commentCount =>
      comments.length +
      comments.fold(0, (sum, comment) => sum + comment.replies.length);

  /// What is put on the clipboard or handed to the share sheet.
  String get shareText => '$title\n\n$body\n\n— Crown Solar Energy';
}

/// Space's data boundary: a broadcast feed the partner can react to.
abstract interface class SpaceRepository {
  /// Fires whenever a post changes, so open screens can refresh.
  Listenable get changes;

  /// The posts this partner's role is meant to see, newest first.
  Future<List<SpacePost>> feed(SignedInUser user);

  Future<SpacePost?> post(String id);

  /// Turns the heart on or off and returns the new state.
  Future<SpacePost> toggleHeart(String postId);

  Future<PostComment> comment({
    required String postId,
    required SignedInUser user,
    required String body,
  });

  Future<PostReply> reply({
    required String postId,
    required String commentId,
    required SignedInUser user,
    required String body,
  });
}

class MockSpaceRepository implements SpaceRepository {
  MockSpaceRepository();

  static const _latency = Duration(milliseconds: 200);

  final _changes = _Broadcast();
  var _nextId = 1;

  late final List<SpacePost> _posts = _seed();

  @override
  Listenable get changes => _changes;

  @override
  Future<List<SpacePost>> feed(SignedInUser user) async {
    await Future<void>.delayed(_latency);
    final visible =
        _posts.where((post) => post.audience.reaches(user.role)).toList()
          ..sort((a, b) => b.postedAt.compareTo(a.postedAt));
    return visible;
  }

  @override
  Future<SpacePost?> post(String id) async {
    for (final post in _posts) {
      if (post.id == id) return post;
    }
    return null;
  }

  @override
  Future<SpacePost> toggleHeart(String postId) async {
    final post = _posts.firstWhere((p) => p.id == postId);
    post.heartedByMe = !post.heartedByMe;
    post.hearts += post.heartedByMe ? 1 : -1;
    _changes.announce();
    return post;
  }

  @override
  Future<PostComment> comment({
    required String postId,
    required SignedInUser user,
    required String body,
  }) async {
    await Future<void>.delayed(_latency);
    final post = _posts.firstWhere((p) => p.id == postId);
    final comment = PostComment(
      id: 'C${_nextId++}',
      author: user.businessName,
      body: body,
      postedAt: DateTime.now(),
    );
    post.comments.add(comment);
    _changes.announce();
    return comment;
  }

  @override
  Future<PostReply> reply({
    required String postId,
    required String commentId,
    required SignedInUser user,
    required String body,
  }) async {
    await Future<void>.delayed(_latency);
    final post = _posts.firstWhere((p) => p.id == postId);
    final comment = post.comments.firstWhere((c) => c.id == commentId);
    final reply = PostReply(
      id: 'R${_nextId++}',
      author: user.businessName,
      body: body,
      postedAt: DateTime.now(),
    );
    comment.replies.add(reply);
    _changes.announce();
    return reply;
  }

  /// The opening feed, so Space is never empty on first sight.
  List<SpacePost> _seed() {
    final now = DateTime.now();

    return [
      SpacePost(
        id: 'P1',
        title: 'Dealer meet-up in Lahore on 20 September',
        body:
            'Doors open at 10 am at Pearl Continental. Bring your profile QR '
            'for attendance. Lunch and the new product briefing are included.',
        postedAt: now.subtract(const Duration(hours: 4)),
        audience: PostAudience.everyone,
        imageAsset: 'assets/images/crown_solar_logo.png',
        hearts: 48,
        comments: [
          PostComment(
            id: 'C${_nextId++}',
            author: 'Shahdara Solar Services',
            body: 'Kya installers bhi aa sakte hain?',
            postedAt: now.subtract(const Duration(hours: 1)),
            replies: [
              PostReply(
                id: 'R${_nextId++}',
                author: 'Crown Solar · CRM',
                body: 'Yes, installers are welcome. Bring your profile QR.',
                postedAt: now.subtract(const Duration(minutes: 45)),
                official: true,
              ),
            ],
          ),
          PostComment(
            id: 'C${_nextId++}',
            author: 'Bilal Traders',
            body: 'Parking available hai?',
            postedAt: now.subtract(const Duration(minutes: 20)),
          ),
        ],
      ),
      SpacePost(
        id: 'P2',
        title: 'New 8kW hybrid inverter is now shipping',
        body:
            'The CS-8K hybrid ships from the Lahore plant this week. It '
            'carries a five-year warranty and works with the existing '
            'mounting kit.',
        postedAt: now.subtract(const Duration(days: 1)),
        audience: PostAudience.everyone,
        // The reverse logo is white, so it would be invisible on the light
        // card. Only the standard mark is readable there.
        imageAsset: 'assets/images/crown_solar_logo.png',
        hearts: 122,
        comments: [
          PostComment(
            id: 'C${_nextId++}',
            author: 'Hamza Solar House',
            body: 'Stock kab tak aayega Badami Bagh mein?',
            postedAt: now.subtract(const Duration(hours: 20)),
          ),
        ],
      ),
      SpacePost(
        id: 'P3',
        title: 'Installer certification, free this month',
        body:
            'Two-day certification at the Lahore training centre. Certified '
            'installers appear first when a customer searches their area.',
        postedAt: now.subtract(const Duration(days: 2)),
        audience: PostAudience.installers,
        imageAsset: null,
        hearts: 31,
      ),
      SpacePost(
        id: 'P4',
        title: 'Frontlit shop boards: requests open until 30 September',
        body:
            'Retailers can request a new frontlit board through Shop '
            'Branding. The supplier calls within three working days.',
        postedAt: now.subtract(const Duration(days: 3)),
        audience: PostAudience.retailers,
        imageAsset: null,
        hearts: 64,
      ),
      SpacePost(
        id: 'P5',
        title: 'Quarterly targets close on 30 September',
        body:
            'Hit 80% of your quarterly target to unlock the annual bonus '
            'band. Your progress is on the Points screen.',
        postedAt: now.subtract(const Duration(days: 4)),
        audience: PostAudience.trade,
        imageAsset: null,
        hearts: 18,
      ),
    ];
  }
}

/// A [ChangeNotifier] its owner can fire, so the repository can announce a
/// change without exposing the whole notifier API.
class _Broadcast extends ChangeNotifier {
  void announce() => notifyListeners();
}
