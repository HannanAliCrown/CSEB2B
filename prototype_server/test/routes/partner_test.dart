import 'package:prototype_server/router.dart';
import 'package:test/test.dart';

import '../support/fake_auth_data_store.dart';
import '../support/fake_partner_data_store.dart';
import '../support/request_helpers.dart';

void main() {
  late FakePartnerDataStore partners;
  late FakeAuthDataStore auth;

  setUp(() {
    partners = FakePartnerDataStore();
    auth = FakeAuthDataStore();
  });

  dynamic router() => buildRouter(auth, partners: partners);

  Map<String, Object?> application({
    String mobileNumber = '3009998887',
    String cnic = '35202-1111111-1',
    List<Map<String, Object?>> buyingSources = const [],
  }) => {
    'mobileNumber': mobileNumber,
    'role': 'installer',
    'fullName': 'Test Applicant',
    'businessName': 'Test Solar Works',
    'businessAddress': 'Shop 1, Ravi Road',
    'cnicNumber': cnic,
    'marketName': 'Ravi Road, Lahore',
    'buyingSources': buyingSources,
  };

  group('first launch', () {
    test('records what the phone settled', () async {
      final result = await postJson(router(), '/devices/launch', {
        'installationUuid': 'device-1',
        'languageCode': 'ur',
        'notificationPermission': 'granted',
        'latitude': 31.5,
        'longitude': 74.3,
      });

      expect(result['statusCode'], 200);
      expect(partners.lastLaunch?.installationUuid, 'device-1');
      expect(partners.lastLaunch?.languageCode, 'ur');
      expect(partners.lastLaunch?.latitude, 31.5);
    });

    test('refuses a report that does not say which phone', () async {
      final result = await postJson(router(), '/devices/launch', {
        'languageCode': 'en',
      });
      expect(result['statusCode'], 400);
    });
  });

  group('reference data', () {
    test('markets come back alphabetically', () async {
      partners.addMarket('Shahdara, Lahore');
      partners.addMarket('Hall Road, Lahore');

      final result = await getJson(router(), '/markets');
      final markets = (result['body'] as Map)['markets'] as List;

      expect(markets.map((m) => (m as Map)['name']), [
        'Hall Road, Lahore',
        'Shahdara, Lahore',
      ]);
    });
  });

  group('lookups', () {
    test('a taken number comes back with who holds it', () async {
      partners.addAccount(
        mobileNumber: '03004821190',
        userType: 'installer',
        displayName: 'Adnan Solar Works',
      );

      final result = await getJson(
        router(),
        '/accounts/lookup?mobileNumber=%2B92%203004821190',
      );
      final body = result['body'] as Map;

      expect(body['exists'], isTrue);
      expect(body['displayName'], 'Adnan Solar Works');
    });

    test('a free number says so', () async {
      final result = await getJson(
        router(),
        '/accounts/lookup?mobileNumber=3001112223',
      );
      expect((result['body'] as Map)['exists'], isFalse);
    });

    test('a taken CNIC says only that it is taken', () async {
      partners.addAccount(
        mobileNumber: '3004821190',
        userType: 'installer',
        displayName: 'Adnan Solar Works',
        cnicNumber: '35202-7719480-3',
      );

      final result = await getJson(
        router(),
        '/accounts/cnic-holder?cnicNumber=35202-7719480-3',
      );
      final body = result['body'] as Map;

      expect(body['taken'], isTrue);
      expect(
        body.values.join(),
        isNot(contains('Adnan')),
        reason: 'who holds a CNIC is not the applicant\'s business',
      );
    });

    test('a retailer is a usable buying source', () async {
      partners.addAccount(
        mobileNumber: '3007781204',
        userType: 'retailer',
        displayName: 'Al-Noor Electric Store',
        marketName: 'Ravi Road, Lahore',
      );

      final body =
          (await getJson(
                router(),
                '/buying-sources/lookup?mobileNumber=3007781204',
              ))['body']
              as Map;

      expect(body['found'], isTrue);
      expect(body['eligible'], isTrue);
      expect(body['market'], 'Ravi Road, Lahore');
    });

    test('an installer is found but cannot be bought from', () async {
      partners.addAccount(
        mobileNumber: '3004821190',
        userType: 'installer',
        displayName: 'Adnan Solar Works',
      );

      final body =
          (await getJson(
                router(),
                '/buying-sources/lookup?mobileNumber=3004821190',
              ))['body']
              as Map;

      expect(body['found'], isTrue);
      expect(body['eligible'], isFalse);
      expect(body['name'], 'Adnan Solar Works');
    });

    test('an unknown number is not a buying source', () async {
      final body =
          (await getJson(
                router(),
                '/buying-sources/lookup?mobileNumber=3009990000',
              ))['body']
              as Map;

      expect(body['found'], isFalse);
    });
  });

  group('registration OTP', () {
    test('a code is issued against a number with no account', () async {
      final body =
          (await postJson(router(), '/registration/wizard/otp', {
                'mobileNumber': '3009998887',
              }))['body']
              as Map;

      expect(body['code'], partners.issuedOtpFor('3009998887'));
    });

    test('the right code verifies and the wrong one does not', () async {
      await postJson(router(), '/registration/wizard/otp', {
        'mobileNumber': '3009998887',
      });

      final wrong = await postJson(
        router(),
        '/registration/wizard/otp/verify',
        {'mobileNumber': '3009998887', 'code': '000000'},
      );
      expect(wrong['statusCode'], 400);

      final right = await postJson(
        router(),
        '/registration/wizard/otp/verify',
        {'mobileNumber': '3009998887', 'code': '123456'},
      );
      expect(right['statusCode'], 200);
      expect((right['body'] as Map)['outcome'], 'verified');
    });
  });

  group('submitting an application', () {
    test('lands with all three approvals outstanding', () async {
      final result = await postJson(
        router(),
        '/registration/applications',
        application(),
      );
      final body = result['body'] as Map;

      expect(result['statusCode'], 201);
      expect(body['status'], 'submitted');
      expect(body['reference'], isNotEmpty);
      expect(
        (body['approvals'] as List).map((a) => (a as Map)['state']),
        everyElement('outstanding'),
        reason: 'submitting starts the chain; it never grants it',
      );
    });

    test('names the first buying source as the one who verifies', () async {
      partners.addAccount(
        mobileNumber: '3007781204',
        userType: 'retailer',
        displayName: 'Al-Noor Electric Store',
      );
      partners.addAccount(
        mobileNumber: '3014429911',
        userType: 'wholesaler',
        displayName: 'Hamza Solar House',
      );

      final body =
          (await postJson(
                router(),
                '/registration/applications',
                application(
                  buyingSources: const [
                    {'position': 0, 'mobileNumber': '3007781204'},
                    {'position': 1, 'mobileNumber': '3014429911'},
                  ],
                ),
              ))['body']
              as Map;

      expect(body['verifyingSourceName'], 'Al-Noor Electric Store');
    });

    test('a number that already has an account is refused', () async {
      partners.addAccount(
        mobileNumber: '3009998887',
        userType: 'retailer',
        displayName: 'Bilal Traders',
      );

      final result = await postJson(
        router(),
        '/registration/applications',
        application(),
      );

      expect(result['statusCode'], 409);
      expect((result['body'] as Map)['error'], 'number_taken');
    });

    test('a CNIC that already registered is refused, without naming', () async {
      partners.addAccount(
        mobileNumber: '3004821190',
        userType: 'installer',
        displayName: 'Adnan Solar Works',
        cnicNumber: '35202-1111111-1',
      );

      final result = await postJson(
        router(),
        '/registration/applications',
        application(),
      );
      final body = result['body'] as Map;

      expect(result['statusCode'], 409);
      expect(body['error'], 'cnic_taken');
      expect(body['heldBy'], isNull);
    });

    test('a second application on an open one is refused', () async {
      await postJson(router(), '/registration/applications', application());

      final second = await postJson(
        router(),
        '/registration/applications',
        application(cnic: '35202-2222222-2'),
      );

      expect(second['statusCode'], 409);
      expect((second['body'] as Map)['error'], 'application_open');
    });

    test('the latest application can be read back by number', () async {
      await postJson(router(), '/registration/applications', application());

      final result = await getJson(
        router(),
        '/registration/applications/latest?mobileNumber=03009998887',
      );

      expect(result['statusCode'], 200);
      expect((result['body'] as Map)['mobileNumber'], '3009998887');
    });

    test('no application on a number is a 404, not an empty one', () async {
      final result = await getJson(
        router(),
        '/registration/applications/latest?mobileNumber=3001112223',
      );
      expect(result['statusCode'], 404);
    });
  });

  group('home', () {
    setUp(() {
      partners.addAccount(
        mobileNumber: '3004821190',
        userType: 'installer',
        displayName: 'Adnan Solar Works',
      );
      partners.setWallet('3004821190', available: 1600000, held: 150000);
    });

    test('the wallet figure comes back in paisa', () async {
      final body =
          (await getJson(
                router(),
                '/dashboard?mobileNumber=3004821190',
              ))['body']
              as Map;

      expect(body['availablePaisa'], 1600000);
      expect(body['heldPaisa'], 150000);
    });

    test('a slide aimed at another role never reaches the phone', () async {
      partners.addSlide(audience: 'installer', headline: 'For installers');
      partners.addSlide(audience: 'retailer', headline: 'For retailers');
      partners.addSlide(audience: 'all', headline: 'For everyone');

      final body =
          (await getJson(
                router(),
                '/dashboard?mobileNumber=3004821190',
              ))['body']
              as Map;
      final headlines = (body['slides'] as List)
          .map((s) => (s as Map)['headline'])
          .toList();

      expect(headlines, ['For installers', 'For everyone']);
    });

    test('a slide carries its picture', () async {
      partners.addSlide(
        audience: 'all',
        imageUrl: 'https://crownsolar.example/eid.png',
        eyebrow: 'EID SCHEME',
        headline: 'Double prizes',
      );

      final slide =
          ((await getJson(
                    router(),
                    '/dashboard?mobileNumber=3004821190',
                  ))['body']
                  as Map)['slides']
              as List;

      expect(
        (slide.single as Map)['imageUrl'],
        'https://crownsolar.example/eid.png',
      );
    });

    test('a ticker message carries its two colours', () async {
      partners.addTicker(
        message: 'Eid scheme live',
        textColour: '#FFFFFF',
        backgroundColour: '#04037E',
      );
      partners.addTicker(message: 'Plain one');

      final ticker =
          ((await getJson(
                    router(),
                    '/dashboard?mobileNumber=3004821190',
                  ))['body']
                  as Map)['ticker']
              as List;

      expect((ticker.first as Map)['textColour'], '#FFFFFF');
      expect((ticker.first as Map)['backgroundColour'], '#04037E');
      expect(
        (ticker.last as Map)['textColour'],
        isNull,
        reason: 'no colour means the app\'s own, not a default written here',
      );
    });

    test('a number with no account has no dashboard', () async {
      final result = await getJson(
        router(),
        '/dashboard?mobileNumber=3001112223',
      );
      expect(result['statusCode'], 404);
    });
  });

  group('signing in', () {
    test('an open account signs in approved', () async {
      partners.addAccount(
        mobileNumber: '3004821190',
        userType: 'installer',
        displayName: 'Adnan Solar Works',
        contactName: 'Muhammad Adnan Shahid',
        marketName: 'Ravi Road, Lahore',
      );

      final body =
          (await getJson(
                router(),
                '/session/lookup?mobileNumber=03004821190',
              ))['body']
              as Map;

      expect(body['approved'], isTrue);
      expect(body['businessName'], 'Adnan Solar Works');
      expect(body['role'], 'installer');
      expect(body['market'], 'Ravi Road, Lahore');
    });

    test('an application still waiting signs in unapproved', () async {
      await postJson(router(), '/registration/applications', application());

      final body =
          (await getJson(
                router(),
                '/session/lookup?mobileNumber=3009998887',
              ))['body']
              as Map;

      expect(
        body['approved'],
        isFalse,
        reason: 'they sign in to watch the approvals, not to use the app',
      );
      expect(body['businessName'], 'Test Solar Works');
      expect(body['role'], 'installer');
    });

    test('a number that is nobody is refused', () async {
      final result = await getJson(
        router(),
        '/session/lookup?mobileNumber=3001112223',
      );
      expect(result['statusCode'], 404);
    });
  });
}
