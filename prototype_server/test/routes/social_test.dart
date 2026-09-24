import 'package:shelf/shelf.dart';

import 'package:prototype_server/router.dart';
import 'package:test/test.dart';

import '../support/fake_auth_data_store.dart';
import '../support/fake_social_data_store.dart';
import '../support/request_helpers.dart';

void main() {
  late FakeSocialDataStore social;
  late FakeAuthDataStore auth;

  const adnan = '3004821190';
  const bilal = '3217745002';

  setUp(() {
    social = FakeSocialDataStore();
    auth = FakeAuthDataStore();
    social.addAccount(
      mobileNumber: adnan,
      role: 'installer',
      name: 'Adnan Solar Works',
    );
    social.addAccount(
      mobileNumber: bilal,
      role: 'retailer',
      name: 'Bilal Traders',
    );
  });

  dynamic router() => buildRouter(auth, social: social);

  group('the Space feed', () {
    test('a post aimed at another role never reaches the phone', () async {
      social.addPost(title: 'For everyone');
      social.addPost(title: 'For installers', audience: 'installer');
      social.addPost(title: 'For retailers', audience: 'retailer');

      final body =
          (await getJson(router(), '/space/feed?mobileNumber=$adnan'))['body']
              as Map;
      final titles = (body['posts'] as List)
          .map((p) => (p as Map)['title'])
          .toList();

      expect(titles, ['For everyone', 'For installers']);
    });

    test('a trade post reaches wholesalers and distributors', () async {
      social.addAccount(
        mobileNumber: '3014429911',
        role: 'wholesaler',
        name: 'Hamza Solar House',
      );
      social.addPost(title: 'Quarterly targets', audience: 'trade');

      final body =
          (await getJson(
                router(),
                '/space/feed?mobileNumber=3014429911',
              ))['body']
              as Map;

      expect((body['posts'] as List), hasLength(1));
    });

    test('there is no way to publish a post from this app', () async {
      // Not a JSON error — the route does not exist at all, which is the
      // point: posts come from the publishing application, never from here.
      final response = await router().call(
        Request(
          'POST',
          Uri.parse('http://localhost/space/posts'),
          body: '{"title":"Written by a partner"}',
          headers: const {'content-type': 'application/json'},
        ),
      );

      expect(response.statusCode, 404);
    });
  });

  group('hearts', () {
    test('a heart goes on, and off again, counted once', () async {
      final id = social.addPost(title: 'Dealer meet-up');

      final on =
          (await postJson(router(), '/space/posts/$id/heart', {
                'mobileNumber': adnan,
              }))['body']
              as Map;
      expect(on['hearts'], 1);
      expect(on['heartedByMe'], isTrue);

      final off =
          (await postJson(router(), '/space/posts/$id/heart', {
                'mobileNumber': adnan,
              }))['body']
              as Map;
      expect(off['hearts'], 0);
      expect(off['heartedByMe'], isFalse);
    });

    test('two partners are two hearts, and each sees only their own', () async {
      final id = social.addPost(title: 'Dealer meet-up');

      await postJson(router(), '/space/posts/$id/heart', {
        'mobileNumber': adnan,
      });
      final forBilal =
          (await postJson(router(), '/space/posts/$id/heart', {
                'mobileNumber': bilal,
              }))['body']
              as Map;

      expect(forBilal['hearts'], 2);

      final adnanView =
          (await getJson(
                router(),
                '/space/posts/$id?mobileNumber=$adnan',
              ))['body']
              as Map;
      expect(adnanView['hearts'], 2);
      expect(adnanView['heartedByMe'], isTrue);
    });
  });

  group('comments', () {
    test('a comment carries the business that wrote it', () async {
      final id = social.addPost(title: 'Dealer meet-up');

      final body =
          (await postJson(router(), '/space/posts/$id/comments', {
                'mobileNumber': bilal,
                'body': 'Parking available hai?',
              }))['body']
              as Map;

      expect(body['author'], 'Bilal Traders');
      expect(body['official'], isFalse);
    });

    test('a reply nests under its comment rather than beside it', () async {
      final id = social.addPost(title: 'Dealer meet-up');
      final comment =
          (await postJson(router(), '/space/posts/$id/comments', {
                'mobileNumber': bilal,
                'body': 'Parking available hai?',
              }))['body']
              as Map;

      await postJson(router(), '/space/comments/${comment['id']}/replies', {
        'mobileNumber': adnan,
        'body': 'Haan, peeche hai.',
      });

      final post =
          (await getJson(
                router(),
                '/space/posts/$id?mobileNumber=$adnan',
              ))['body']
              as Map;
      final comments = post['comments'] as List;

      expect(comments, hasLength(1), reason: 'a reply is not a comment');
      expect((comments.single as Map)['replies'], hasLength(1));
    });

    test('a reply to a reply is refused', () async {
      final id = social.addPost(title: 'Dealer meet-up');
      final comment =
          (await postJson(router(), '/space/posts/$id/comments', {
                'mobileNumber': bilal,
                'body': 'Parking available hai?',
              }))['body']
              as Map;
      final reply =
          (await postJson(
                router(),
                '/space/comments/${comment['id']}/replies',
                {'mobileNumber': adnan, 'body': 'Haan.'},
              ))['body']
              as Map;

      final third = await postJson(
        router(),
        '/space/comments/${reply['id']}/replies',
        {'mobileNumber': bilal, 'body': 'Shukriya'},
      );

      expect(third['statusCode'], 409);
      expect(
        (third['body'] as Map)['error'],
        'replies_are_one_level_deep',
        reason: 'the app shows two levels; a third would have nowhere to go',
      );
    });

    test('an empty comment is refused', () async {
      final id = social.addPost(title: 'Dealer meet-up');

      final result = await postJson(router(), '/space/posts/$id/comments', {
        'mobileNumber': adnan,
        'body': '   ',
      });

      expect(result['statusCode'], 400);
    });
  });

  group('chat', () {
    test('a message sent by one partner arrives for the other', () async {
      await postJson(router(), '/chat/messages', {
        'mobileNumber': adnan,
        'partyAddress': bilal,
        'body': 'Bhai, rate kya hai?',
      });

      final forBilal =
          (await getJson(router(), '/chat/threads?mobileNumber=$bilal'))['body']
              as Map;
      final thread = (forBilal['threads'] as List).single as Map;

      expect((thread['party'] as Map)['name'], 'Adnan Solar Works');
      expect(
        ((thread['messages'] as List).single as Map)['body'],
        'Bhai, rate kya hai?',
      );
      expect(thread['unread'], 1, reason: 'the receiver has not opened it yet');
    });

    test('the sender has nothing unread in their own conversation', () async {
      await postJson(router(), '/chat/messages', {
        'mobileNumber': adnan,
        'partyAddress': bilal,
        'body': 'Bhai, rate kya hai?',
      });

      final forAdnan =
          (await getJson(router(), '/chat/threads?mobileNumber=$adnan'))['body']
              as Map;

      expect(((forAdnan['threads'] as List).single as Map)['unread'], 0);
    });

    test('opening a conversation clears the badge', () async {
      await postJson(router(), '/chat/messages', {
        'mobileNumber': adnan,
        'partyAddress': bilal,
        'body': 'Bhai, rate kya hai?',
      });

      await postJson(router(), '/chat/threads/read', {
        'mobileNumber': bilal,
        'partyAddress': adnan,
      });

      final forBilal =
          (await getJson(router(), '/chat/threads?mobileNumber=$bilal'))['body']
              as Map;

      expect(((forBilal['threads'] as List).single as Map)['unread'], 0);
    });

    test('opening the same conversation twice is one conversation', () async {
      await postJson(router(), '/chat/threads/open', {
        'mobileNumber': adnan,
        'partyAddress': bilal,
      });
      await postJson(router(), '/chat/threads/open', {
        'mobileNumber': bilal,
        'partyAddress': adnan,
      });

      final forAdnan =
          (await getJson(router(), '/chat/threads?mobileNumber=$adnan'))['body']
              as Map;

      expect(
        forAdnan['threads'],
        hasLength(1),
        reason: 'a pair shares one thread, whichever side opened it',
      );
    });

    test('a department always resolves; a stranger does not', () async {
      final department = await getJson(
        router(),
        '/chat/party?address=dept:crm',
      );
      expect(department['statusCode'], 200);
      expect((department['body'] as Map)['isDepartment'], isTrue);

      final stranger = await getJson(
        router(),
        '/chat/party?address=3009990000',
      );
      expect(stranger['statusCode'], 404);
    });

    test(
      'an officer resolves by name and role; an unknown one does not',
      () async {
        social.addStaffParty(
          address: 'staff:mo-1',
          role: 'mo',
          name: 'Imran Aslam',
        );

        final officer = await getJson(
          router(),
          '/chat/party?address=staff:mo-1',
        );
        expect(officer['statusCode'], 200);
        final body = officer['body'] as Map;
        expect(body['isDepartment'], isFalse);
        expect(body['name'], 'Imran Aslam');
        expect(body['role'], 'mo');

        final unknown = await getJson(router(), '/chat/party?address=staff:x');
        expect(unknown['statusCode'], 404);
      },
    );

    test('a partner cannot start a conversation with themselves', () async {
      final result = await postJson(router(), '/chat/threads/open', {
        'mobileNumber': adnan,
        'partyAddress': adnan,
      });

      expect(result['statusCode'], 404);
    });
  });
}
