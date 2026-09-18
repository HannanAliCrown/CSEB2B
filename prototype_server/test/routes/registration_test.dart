import 'package:prototype_server/router.dart';
import 'package:test/test.dart';

import '../support/fake_auth_data_store.dart';
import '../support/request_helpers.dart';

void main() {
  group('registration (FR-001–FR-005, FR-040)', () {
    late FakeAuthDataStore store;

    setUp(() => store = FakeAuthDataStore());

    test('requesting an OTP for an unregistered account returns 404', () async {
      final router = buildRouter(store);
      final result = await postJson(router, '/registration/otp', {
        'mobileNumber': '+920000000000',
        'deviceId': 'device-x',
      });
      expect(result['statusCode'], 404);
    });

    test('OTP verified + binding persists together (atomic) — activates the device', () async {
      final account = store.addAccount(
        mobileNumber: '+923000000001',
        userType: 'installer',
      );
      final router = buildRouter(store);

      final otpResponse = await postJson(router, '/registration/otp', {
        'mobileNumber': account.mobileNumber,
        'deviceId': 'device-a',
      });
      expect(otpResponse['statusCode'], 200);
      final code = otpResponse['body']['code'] as String;
      final deviceId = otpResponse['body']['deviceId'] as String;

      final verifyResponse = await postJson(
        router,
        '/registration/otp/verify',
        {'accountId': account.id, 'deviceId': deviceId, 'code': code},
      );
      expect(verifyResponse['statusCode'], 200);
      expect(verifyResponse['body']['status'], 'active');

      final binding = store.activeBindingFor(account.id);
      expect(binding, isNotNull);
      expect(binding!.deviceId, deviceId);
    });

    test('an incorrect OTP leaves verified=false and creates no binding — '
        'this is the FR-017 resolution: failed attempts are not separately audited', () async {
      final account = store.addAccount(
        mobileNumber: '+923000000002',
        userType: 'retailer',
      );
      final router = buildRouter(store);
      final otpResponse = await postJson(router, '/registration/otp', {
        'mobileNumber': account.mobileNumber,
        'deviceId': 'device-b',
      });
      final deviceId = otpResponse['body']['deviceId'] as String;

      final verifyResponse = await postJson(
        router,
        '/registration/otp/verify',
        {'accountId': account.id, 'deviceId': deviceId, 'code': 'wrong-code'},
      );

      expect(verifyResponse['statusCode'], 400);
      expect(verifyResponse['body']['error'], 'invalid_code');
      expect(store.activeBindingFor(account.id), isNull);

      // Retry with the correct code still succeeds — no lockout invented.
      final code = otpResponse['body']['code'] as String;
      final retryResponse = await postJson(router, '/registration/otp/verify', {
        'accountId': account.id,
        'deviceId': deviceId,
        'code': code,
      });
      expect(retryResponse['statusCode'], 200);
    });

    test('registration succeeds identically for all four user types (FR-004, FR-022)', () async {
      for (final userType in [
        'installer',
        'retailer',
        'wholesaler',
        'distributor',
      ]) {
        final account = store.addAccount(
          mobileNumber: '+9230000000${userType.hashCode % 90 + 10}',
          userType: userType,
        );
        final router = buildRouter(store);
        final otpResponse = await postJson(router, '/registration/otp', {
          'mobileNumber': account.mobileNumber,
          'deviceId': 'device-${account.id}',
        });
        final code = otpResponse['body']['code'] as String;
        final deviceId = otpResponse['body']['deviceId'] as String;

        final verifyResponse = await postJson(
          router,
          '/registration/otp/verify',
          {'accountId': account.id, 'deviceId': deviceId, 'code': code},
        );
        expect(
          verifyResponse['statusCode'],
          200,
          reason: 'failed for $userType',
        );
      }
    });

    test('an account that already has an Active device is refused a new registration OTP', () async {
      final account = store.addAccount(
        mobileNumber: '+923000000003',
        userType: 'wholesaler',
      );
      final router = buildRouter(store);
      final first = await postJson(router, '/registration/otp', {
        'mobileNumber': account.mobileNumber,
        'deviceId': 'device-c',
      });
      await postJson(router, '/registration/otp/verify', {
        'accountId': account.id,
        'deviceId': first['body']['deviceId'],
        'code': first['body']['code'],
      });

      final second = await postJson(router, '/registration/otp', {
        'mobileNumber': account.mobileNumber,
        'deviceId': 'device-d',
      });
      expect(second['statusCode'], 409);
    });
  });
}
