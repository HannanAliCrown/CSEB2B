import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:prototype_server/router.dart';
import 'package:test/test.dart';

import '../support/fake_auth_data_store.dart';
import '../support/fake_profile_data_store.dart';
import '../support/request_helpers.dart';

void main() {
  late FakeProfileDataStore profile;
  late FakeAuthDataStore auth;

  const adnan = '3004821190';

  setUp(() {
    profile = FakeProfileDataStore();
    auth = FakeAuthDataStore();
    profile.addAccount(mobileNumber: adnan);
  });

  dynamic router() => buildRouter(auth, profile: profile);

  /// `putJson`, which the shared helpers do not have.
  Future<Map<String, dynamic>> putJson(
    dynamic router,
    String path,
    Map<String, Object?> body,
  ) async {
    final response = await router.call(
      Request(
        'PUT',
        Uri.parse('http://localhost$path'),
        body: jsonEncode(body),
        headers: const {'content-type': 'application/json'},
      ),
    );
    return {
      'statusCode': response.statusCode,
      'body': jsonDecode(await response.readAsString()),
    };
  }

  group('language and theme', () {
    test('a fresh account has chosen nothing', () async {
      final body =
          (await getJson(
                router(),
                '/profile/settings?mobileNumber=$adnan',
              ))['body']
              as Map;

      expect(body['languageCode'], isNull);
      expect(body['theme'], isNull);
      expect(body['pinSet'], isFalse);
    });

    test('setting one thing does not clear another', () async {
      await putJson(router(), '/profile/settings', {
        'mobileNumber': adnan,
        'languageCode': 'ur',
        'languageRemembered': true,
      });

      final body =
          (await putJson(router(), '/profile/settings', {
                'mobileNumber': adnan,
                'theme': 'dark',
              }))['body']
              as Map;

      expect(body['theme'], 'dark');
      expect(
        body['languageCode'],
        'ur',
        reason: 'the theme screen must not wipe the language screen\'s choice',
      );
      expect(body['languageRemembered'], isTrue);
    });

    test('an unknown number has no settings to change', () async {
      final result = await putJson(router(), '/profile/settings', {
        'mobileNumber': '3009990000',
        'theme': 'dark',
      });
      expect(result['statusCode'], 404);
    });
  });

  group('the app PIN', () {
    test('must be four digits', () async {
      for (final bad in ['123', '12345', 'abcd', '']) {
        final result = await postJson(router(), '/profile/pin', {
          'mobileNumber': adnan,
          'pin': bad,
        });
        expect(result['statusCode'], 400, reason: bad);
      }
      expect(profile.pinFor(adnan), isNull);
    });

    test('is set, and turns itself on', () async {
      final body =
          (await postJson(router(), '/profile/pin', {
                'mobileNumber': adnan,
                'pin': '1234',
              }))['body']
              as Map;

      expect(body['pinSet'], isTrue);
      expect(body['pinEnabled'], isTrue);
    });

    test('cannot be changed without the current one', () async {
      await postJson(router(), '/profile/pin', {
        'mobileNumber': adnan,
        'pin': '1234',
      });

      final noCurrent = await postJson(router(), '/profile/pin', {
        'mobileNumber': adnan,
        'pin': '5678',
      });
      final wrongCurrent = await postJson(router(), '/profile/pin', {
        'mobileNumber': adnan,
        'pin': '5678',
        'currentPin': '0000',
      });

      expect(noCurrent['statusCode'], 403);
      expect(wrongCurrent['statusCode'], 403);
      expect(
        profile.pinFor(adnan),
        '1234',
        reason: 'a borrowed phone must not be able to lock its owner out',
      );
    });

    test('changes when the current one is right', () async {
      await postJson(router(), '/profile/pin', {
        'mobileNumber': adnan,
        'pin': '1234',
      });

      final result = await postJson(router(), '/profile/pin', {
        'mobileNumber': adnan,
        'pin': '5678',
        'currentPin': '1234',
      });

      expect(result['statusCode'], 200);
      expect(profile.pinFor(adnan), '5678');
    });

    test('verifying answers yes or no, never an error', () async {
      await postJson(router(), '/profile/pin', {
        'mobileNumber': adnan,
        'pin': '1234',
      });

      final right = await postJson(router(), '/profile/pin/verify', {
        'mobileNumber': adnan,
        'pin': '1234',
      });
      final wrong = await postJson(router(), '/profile/pin/verify', {
        'mobileNumber': adnan,
        'pin': '9999',
      });

      expect(right['statusCode'], 200);
      expect((right['body'] as Map)['verified'], isTrue);
      expect(
        wrong['statusCode'],
        200,
        reason: 'a wrong PIN is an answer, not a failure',
      );
      expect((wrong['body'] as Map)['verified'], isFalse);
    });

    test('turning it off needs the PIN, and keeps it for later', () async {
      await postJson(router(), '/profile/pin', {
        'mobileNumber': adnan,
        'pin': '1234',
      });

      final wrong = await postJson(router(), '/profile/pin/disable', {
        'mobileNumber': adnan,
        'pin': '0000',
      });
      expect(wrong['statusCode'], 403);

      final body =
          (await postJson(router(), '/profile/pin/disable', {
                'mobileNumber': adnan,
                'pin': '1234',
              }))['body']
              as Map;

      expect(body['pinEnabled'], isFalse);
      expect(
        body['pinSet'],
        isTrue,
        reason: 'turning it back on should not force a new PIN',
      );
    });

    test('no response ever carries the PIN back', () async {
      final set = await postJson(router(), '/profile/pin', {
        'mobileNumber': adnan,
        'pin': '1234',
      });
      final settings = await getJson(
        router(),
        '/profile/settings?mobileNumber=$adnan',
      );

      for (final result in [set, settings]) {
        expect(jsonEncode(result['body']), isNot(contains('1234')));
      }
    });
  });

  group('support numbers', () {
    test('come back in order, filtered by role', () async {
      profile.addContact(label: 'Helpline', phoneNumber: '042 111 276 963');
      profile.addContact(
        label: 'Shop Branding',
        phoneNumber: '042 111 276 966',
        audience: 'retailer',
      );

      final body =
          (await getJson(
                router(),
                '/support/contacts?mobileNumber=$adnan',
              ))['body']
              as Map;
      final labels = (body['contacts'] as List)
          .map((c) => (c as Map)['label'])
          .toList();

      expect(labels, ['Helpline']);
    });
  });

  group('about', () {
    test('returns the copy and no version', () async {
      profile.addInfo('company', 'Crown Solar Energy (Pvt) Ltd');

      final body = (await getJson(router(), '/app/about'))['body'] as Map;
      final info = body['info'] as Map;

      expect(info['company'], 'Crown Solar Energy (Pvt) Ltd');
      expect(
        info.containsKey('version'),
        isFalse,
        reason: 'the installed binary knows its own version',
      );
    });
  });
}
