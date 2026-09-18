import 'package:shelf/shelf.dart';
import 'package:prototype_server/router.dart';
import 'package:test/test.dart';

import '../support/fake_auth_data_store.dart';
import '../support/request_helpers.dart';

void main() {
  group('rebinding authorization (FR-018, FR-019, FR-024, FR-025)', () {
    late FakeAuthDataStore store;

    setUp(() => store = FakeAuthDataStore());

    test(
      'first check creates a Pending authorization and does not touch bindings',
      () async {
        final account = store.addAccount(
          mobileNumber: '+923000000030',
          userType: 'installer',
        );
        final router = buildRouter(store);

        final result = await getJson(
          router,
          '/rebinding-authorizations?accountId=${account.id}&deviceId=device-1',
        );

        expect(result['statusCode'], 200);
        expect(result['body']['status'], 'pending');
        expect(store.activeBindingFor(account.id), isNull);
      },
    );

    test('a resolved Pending/Not Authorized status is returned unchanged on repeat checks', () async {
      final account = store.addAccount(
        mobileNumber: '+923000000031',
        userType: 'retailer',
      );
      final router = buildRouter(store);
      await getJson(
        router,
        '/rebinding-authorizations?accountId=${account.id}&deviceId=device-2',
      );

      final result = await getJson(
        router,
        '/rebinding-authorizations?accountId=${account.id}&deviceId=device-2',
      );

      expect(result['body']['status'], 'pending');
    });

    test('no endpoint on this server accepts a caller-supplied status (FR-025, FR-026)', () async {
      final router = buildRouter(store);
      // There is no POST/PUT handler for /rebinding-authorizations at all —
      // only GET exists. Anything else 404s via shelf_router's default
      // (a plain-text body, not JSON — so this test checks the status code
      // directly rather than reusing the JSON-decoding postJson helper).
      final request = Request(
        'POST',
        Uri.parse('http://localhost/rebinding-authorizations'),
      );
      final response = await router.call(request);
      expect(response.statusCode, 404);
    });
  });
}
