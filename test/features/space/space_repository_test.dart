import 'package:flutter_test/flutter_test.dart';

import 'package:cse_b2b/core/mock/partner_directory.dart';
import 'package:cse_b2b/features/session/data/signed_in_user.dart';
import 'package:cse_b2b/features/space/data/space_repository.dart';

SignedInUser _userWithRole(PartnerRole role) {
  final account = PartnerDirectory.accounts.firstWhere(
    (a) => PartnerRoleX.parse(a.role) == role,
  );
  return SignedInUser.fromAccount(account);
}

void main() {
  group('the feed', () {
    test('reaches an installer with the posts meant for them', () async {
      final posts = await MockSpaceRepository().feed(
        _userWithRole(PartnerRole.installer),
      );

      final audiences = posts.map((p) => p.audience).toSet();
      expect(audiences, contains(PostAudience.everyone));
      expect(audiences, contains(PostAudience.installers));
      expect(audiences, isNot(contains(PostAudience.retailers)));
      expect(audiences, isNot(contains(PostAudience.trade)));
    });

    test('keeps a retailers-only post away from installers', () async {
      final space = MockSpaceRepository();

      final retailer = await space.feed(_userWithRole(PartnerRole.retailer));
      final installer = await space.feed(_userWithRole(PartnerRole.installer));

      expect(retailer.any((p) => p.id == 'P4'), isTrue);
      expect(installer.any((p) => p.id == 'P4'), isFalse);
    });

    test('reaches both trade roles with a trade post', () async {
      final space = MockSpaceRepository();

      for (final role in [PartnerRole.wholesaler, PartnerRole.distributor]) {
        final posts = await space.feed(_userWithRole(role));
        expect(posts.any((p) => p.id == 'P5'), isTrue, reason: '$role');
      }
    });

    test('is ordered newest first', () async {
      final posts = await MockSpaceRepository().feed(
        _userWithRole(PartnerRole.installer),
      );

      for (var i = 1; i < posts.length; i++) {
        expect(
          posts[i - 1].postedAt.isBefore(posts[i].postedAt),
          isFalse,
          reason: 'newest first',
        );
      }
    });
  });

  group('reacting', () {
    test('a heart goes on and off again, counted once', () async {
      final space = MockSpaceRepository();
      final before = (await space.post('P1'))!;
      final count = before.hearts;
      expect(before.heartedByMe, isFalse);

      final hearted = await space.toggleHeart('P1');
      expect(hearted.heartedByMe, isTrue);
      expect(hearted.hearts, count + 1);

      final cleared = await space.toggleHeart('P1');
      expect(cleared.heartedByMe, isFalse);
      expect(cleared.hearts, count);
    });

    test('a comment is kept under the post and announced', () async {
      final space = MockSpaceRepository();
      var announced = 0;
      space.changes.addListener(() => announced++);

      final user = _userWithRole(PartnerRole.installer);
      await space.comment(postId: 'P2', user: user, body: 'Rate list bhejein');

      final post = (await space.post('P2'))!;
      expect(post.comments.last.body, 'Rate list bhejein');
      expect(post.comments.last.author, user.businessName);
      expect(post.comments.last.official, isFalse);
      expect(announced, 1);
    });

    test('a reply sits under its comment, not beside it', () async {
      final space = MockSpaceRepository();
      final post = (await space.post('P1'))!;
      final comment = post.comments.first;
      final commentsBefore = post.comments.length;

      await space.reply(
        postId: 'P1',
        commentId: comment.id,
        user: _userWithRole(PartnerRole.installer),
        body: 'Main bhi aa raha hoon',
      );

      expect(post.comments, hasLength(commentsBefore));
      expect(comment.replies.last.body, 'Main bhi aa raha hoon');
    });

    test('the comment count includes replies', () async {
      final space = MockSpaceRepository();
      final post = (await space.post('P1'))!;
      final before = post.commentCount;

      await space.reply(
        postId: 'P1',
        commentId: post.comments.first.id,
        user: _userWithRole(PartnerRole.installer),
        body: 'Ok',
      );
      await space.comment(
        postId: 'P1',
        user: _userWithRole(PartnerRole.installer),
        body: 'Thanks',
      );

      expect(post.commentCount, before + 2);
    });

    test('a shared post carries its title, body and who posted it', () async {
      final post = (await MockSpaceRepository().post('P1'))!;

      expect(post.shareText, contains(post.title));
      expect(post.shareText, contains(post.body));
      expect(post.shareText, contains('Crown Solar Energy'));
    });
  });
}
