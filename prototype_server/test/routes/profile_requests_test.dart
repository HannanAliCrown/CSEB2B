import 'package:prototype_server/data/partner_models.dart';
import 'package:prototype_server/router.dart';
import 'package:test/test.dart';

import '../support/fake_auth_data_store.dart';
import '../support/fake_partner_data_store.dart';
import '../support/request_helpers.dart';

void main() {
  late FakePartnerDataStore partners;
  late FakeAuthDataStore auth;

  /// The retailer an applicant names as their buying source.
  const alNoor = '3007781204';

  /// A wholesaler who has nothing to do with that application.
  const hamza = '3008890011';

  const applicant = '3331234567';

  setUp(() {
    partners = FakePartnerDataStore();
    auth = FakeAuthDataStore();
    partners
      ..addAccount(
        mobileNumber: alNoor,
        userType: 'retailer',
        displayName: 'Al-Noor Electric Store',
      )
      ..addAccount(
        mobileNumber: hamza,
        userType: 'wholesaler',
        displayName: 'Hamza Solar House',
      );
  });

  dynamic router() => buildRouter(auth, partners: partners);

  /// An installer applying, naming [source] as where they buy.
  Future<String> apply({
    String mobileNumber = applicant,
    String source = alNoor,
  }) async {
    final result = await partners.submitApplication(
      ApplicationInput(
        mobileNumber: mobileNumber,
        role: 'installer',
        fullName: 'Kamran Abbas',
        businessName: 'Kamran Solar Services',
        businessAddress: 'Shop 14, Bilal Market, Shahdara',
        cnicNumber: '3520212345${mobileNumber.substring(6)}',
        marketName: 'Ravi Road, Lahore',
        buyingSources: [BuyingSourceInput(position: 0, mobileNumber: source)],
      ),
    );
    return result.application!.id;
  }

  /// A complete decision: an approval names what the applicant is expected
  /// to buy, a rejection names why. Both are required.
  Future<Map<String, dynamic>> decide({
    required String applicationId,
    String mobileNumber = alNoor,
    bool approved = true,
    String? expectedPurchaseBandId = 'band2',
    String? note = 'Not a customer of ours.',
  }) => postJson(router(), '/profile-requests/decision', {
    'mobileNumber': mobileNumber,
    'applicationId': applicationId,
    'approved': approved,
    'expectedPurchaseBandId': ?expectedPurchaseBandId,
    'note': ?note,
  });

  group('the inbox', () {
    test('lists the registrations naming this partner', () async {
      await apply();

      final body =
          (await getJson(
                router(),
                '/profile-requests?mobileNumber=$alNoor',
              ))['body']
              as Map;
      final request = (body['requests'] as List).single as Map;

      expect(body['outstanding'], 1);
      expect(request['businessName'], 'Kamran Solar Services');
      expect(request['contactName'], 'Kamran Abbas');
      expect(request['role'], 'installer');
    });

    test("shows nothing from someone else's application", () async {
      await apply();

      final body =
          (await getJson(
                router(),
                '/profile-requests?mobileNumber=$hamza',
              ))['body']
              as Map;

      expect((body['requests'] as List), isEmpty);
      expect(body['outstanding'], 0);
    });

    test('an unknown number has no inbox', () async {
      final result = await getJson(
        router(),
        '/profile-requests?mobileNumber=3001112222',
      );
      expect(result['statusCode'], 404);
    });
  });

  group('deciding', () {
    test('a decided request leaves the inbox', () async {
      final id = await apply();
      expect((await decide(applicationId: id))['statusCode'], 200);

      final body =
          (await getJson(
                router(),
                '/profile-requests?mobileNumber=$alNoor',
              ))['body']
              as Map;
      expect(
        (body['requests'] as List),
        isEmpty,
        reason: 'this is an inbox, not a history',
      );
    });

    test('nobody can decide a request that is not theirs', () async {
      final id = await apply();

      final result = await decide(applicationId: id, mobileNumber: hamza);

      expect(
        result['statusCode'],
        404,
        reason: '403 would confirm the application exists',
      );
      final stillWaiting =
          (await getJson(
                router(),
                '/profile-requests?mobileNumber=$alNoor',
              ))['body']
              as Map;
      expect((stillWaiting['requests'] as List).length, 1);
    });

    test('deciding twice changes nothing the second time', () async {
      final id = await apply();
      await decide(applicationId: id);

      final again = await decide(applicationId: id, approved: false);
      expect(again['statusCode'], 404);
    });

    test('approving opens nobody\'s account by itself', () async {
      final id = await apply();
      await decide(applicationId: id);

      final application = await partners.latestApplicationForNumber(applicant);
      expect(
        application!.status,
        'submitted',
        reason: 'the marketing officer and CRM still have to decide',
      );
    });

    test('a rejection by the buying source ends the application', () async {
      final id = await apply();
      await decide(applicationId: id, approved: false);

      final application = await partners.latestApplicationForNumber(applicant);
      expect(application!.status, 'rejected');
    });

    test('an unknown number decides nothing', () async {
      final id = await apply();
      final result = await decide(
        applicationId: id,
        mobileNumber: '3001112222',
      );
      expect(result['statusCode'], 404);
      expect((result['body'] as Map)['error'], 'unknown_account');
    });
  });

  group('what a verdict has to carry', () {
    test('approving needs the expected purchasing', () async {
      final id = await apply();

      final result = await decide(
        applicationId: id,
        expectedPurchaseBandId: null,
      );

      expect(result['statusCode'], 400);
      expect((result['body'] as Map)['error'], 'expected_purchase_required');

      final stillWaiting =
          (await getJson(
                router(),
                '/profile-requests?mobileNumber=$alNoor',
              ))['body']
              as Map;
      expect(
        (stillWaiting['requests'] as List).length,
        1,
        reason: 'a refused verdict must not half-decide the request',
      );
    });

    test('rejecting needs a reason', () async {
      final id = await apply();

      final blank = await decide(
        applicationId: id,
        approved: false,
        note: '   ',
      );
      final missing = await decide(
        applicationId: id,
        approved: false,
        note: null,
      );

      expect((blank['body'] as Map)['error'], 'reason_required');
      expect((missing['body'] as Map)['error'], 'reason_required');

      final application = await partners.latestApplicationForNumber(applicant);
      expect(
        application!.status,
        'submitted',
        reason: 'nobody is rejected without being told why',
      );
    });

    test('the bands come from the data layer, not the screen', () async {
      final body =
          (await getJson(
                router(),
                '/profile-requests/expected-purchase',
              ))['body']
              as Map;

      expect((body['bands'] as List), isNotEmpty);
      expect(((body['bands'] as List).first as Map)['label'], isNotEmpty);
    });
  });
}
