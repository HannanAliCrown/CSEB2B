import 'package:prototype_server/data/models.dart';
import 'package:prototype_server/router.dart';
import 'package:test/test.dart';

import '../support/fake_auth_data_store.dart';
import '../support/request_helpers.dart';

void main() {
  group('login (FR-007, FR-011, FR-012, FR-013, FR-014, FR-015, FR-026)', () {
    late FakeAuthDataStore store;

    setUp(() => store = FakeAuthDataStore());

    test('the Active device signs in trusted, with no OTP', () async {
      final account = store.addAccount(
        mobileNumber: '+923000000010',
        userType: 'installer',
      );
      final device = await store.findOrCreateDevice('device-active');
      await store.createOtpChallenge(
        accountId: account.id,
        deviceId: device.id,
        context: OtpContext.registration,
      );
      // Simulate a completed registration directly against the fake.
      final challenge = store.otpChallenges.last;
      await store.verifyRegistrationOtpAndBind(
        accountId: account.id,
        deviceId: device.id,
        submittedCode: challenge.code,
      );

      final router = buildRouter(store);
      final result = await postJson(router, '/login', {
        'mobileNumber': account.mobileNumber,
        'deviceId': device.installationUuid,
      });

      expect(result['statusCode'], 200);
      expect(result['body']['outcome'], 'trusted');
    });

    test('a different device is classified new_untrusted, never granted access on the mobile number alone', () async {
      final account = store.addAccount(
        mobileNumber: '+923000000011',
        userType: 'retailer',
      );
      final router = buildRouter(store);

      final result = await postJson(router, '/login', {
        'mobileNumber': account.mobileNumber,
        'deviceId': 'device-never-seen',
      });

      expect(result['statusCode'], 200);
      expect(result['body']['outcome'], 'new_untrusted');
    });

    test('a New/Untrusted device for an account with zero prior moves reports '
        'tier=second_device and no conflict (FR-015)', () async {
      final account = store.addAccount(
        mobileNumber: '+923000000014',
        userType: 'installer',
      );
      final router = buildRouter(store);

      final result = await postJson(router, '/login', {
        'mobileNumber': account.mobileNumber,
        'deviceId': 'device-never-seen-2',
      });

      expect(result['body']['outcome'], 'new_untrusted');
      expect(result['body']['tier'], 'second_device');
      expect(result['body']['conflict'], isNull);
    });

    test(
      'an account that has already completed one device move reports '
      'tier=third_or_later on its next New/Untrusted attempt (FR-015)',
      () async {
        final account = store.addAccount(
          mobileNumber: '+923000000015',
          userType: 'retailer',
        );
        // Complete one second-device-tier move: device-1 -> device-2.
        final device1 = await store.findOrCreateDevice('device-1');
        final regOtp = await store.createOtpChallenge(
          accountId: account.id,
          deviceId: device1.id,
          context: OtpContext.registration,
        );
        await store.verifyRegistrationOtpAndBind(
          accountId: account.id,
          deviceId: device1.id,
          submittedCode: regOtp.code,
        );
        final device2 = await store.findOrCreateDevice('device-2');
        final loginOtp = await store.createOtpChallenge(
          accountId: account.id,
          deviceId: device2.id,
          context: OtpContext.newDeviceLogin,
        );
        await store.verifyLoginOtp(
          accountId: account.id,
          deviceId: device2.id,
          submittedCode: loginOtp.code,
        );
        await store.completeRebinding(
          accountId: account.id,
          deviceId: device2.id,
        );

        final router = buildRouter(store);
        final result = await postJson(router, '/login', {
          'mobileNumber': account.mobileNumber,
          'deviceId': 'device-3',
        });

        expect(result['body']['outcome'], 'new_untrusted');
        expect(result['body']['tier'], 'third_or_later');
      },
    );

    test('a device currently Active for a DIFFERENT account reports a conflict '
        '(FR-013), independent of the requesting account\'s tier', () async {
      final accountA = store.addAccount(
        mobileNumber: '+923000000016',
        userType: 'installer',
      );
      final accountB = store.addAccount(
        mobileNumber: '+923000000017',
        userType: 'retailer',
      );
      final deviceB = await store.findOrCreateDevice('device-b-conflict');
      final regOtp = await store.createOtpChallenge(
        accountId: accountB.id,
        deviceId: deviceB.id,
        context: OtpContext.registration,
      );
      await store.verifyRegistrationOtpAndBind(
        accountId: accountB.id,
        deviceId: deviceB.id,
        submittedCode: regOtp.code,
      );

      final router = buildRouter(store);
      final result = await postJson(router, '/login', {
        'mobileNumber': accountA.mobileNumber,
        'deviceId': deviceB.installationUuid,
      });

      expect(result['body']['outcome'], 'new_untrusted');
      expect(result['body']['conflict']['otherAccountId'], accountB.id);
    });

    test('confirm-takeover acknowledges the conflict and writes nothing at all '
        '(FR-014)', () async {
      final accountA = store.addAccount(
        mobileNumber: '+923000000018',
        userType: 'wholesaler',
      );
      final router = buildRouter(store);
      final bindingsBefore = store.bindings.length;
      final authsBefore = store.authorizations.length;

      final result = await postJson(router, '/login/confirm-takeover', {
        'mobileNumber': accountA.mobileNumber,
        'deviceId': 'device-declined-or-confirmed',
      });

      expect(result['statusCode'], 200);
      expect(result['body']['acknowledged'], true);
      expect(store.bindings.length, bindingsBefore);
      expect(store.authorizations.length, authsBefore);
    });

    test('a Revoked device is classified new_untrusted, never trusted again automatically (FR-023)', () async {
      final accountA = store.addAccount(
        mobileNumber: '+923000000012',
        userType: 'wholesaler',
      );
      final accountB = store.addAccount(
        mobileNumber: '+923000000013',
        userType: 'distributor',
      );
      final device = await store.findOrCreateDevice('device-shared');

      // Bind Device to Account A, then revoke it via a rebinding to Account B.
      final regChallenge = await store.createOtpChallenge(
        accountId: accountA.id,
        deviceId: device.id,
        context: OtpContext.registration,
      );
      await store.verifyRegistrationOtpAndBind(
        accountId: accountA.id,
        deviceId: device.id,
        submittedCode: regChallenge.code,
      );
      final loginOtp = await store.createOtpChallenge(
        accountId: accountB.id,
        deviceId: device.id,
        context: OtpContext.newDeviceLogin,
      );
      await store.verifyLoginOtp(
        accountId: accountB.id,
        deviceId: device.id,
        submittedCode: loginOtp.code,
      );
      final auth = await store.getOrCreateRebindingAuthorization(
        accountId: accountB.id,
        deviceId: device.id,
      );
      store.setAuthorizationStatus(
        accountB.id,
        device.id,
        RebindingAuthorizationStatus.authorized,
      );
      await store.completeRebinding(
        accountId: accountB.id,
        deviceId: device.id,
      );
      // ignore: unnecessary_statements
      auth;

      final router = buildRouter(store);
      final result = await postJson(router, '/login', {
        'mobileNumber': accountA.mobileNumber,
        'deviceId': device.installationUuid,
      });

      expect(result['statusCode'], 200);
      expect(result['body']['outcome'], 'new_untrusted');
    });

    test('an unrecognized mobile number returns account_not_found', () async {
      final router = buildRouter(store);
      final result = await postJson(router, '/login', {
        'mobileNumber': '+920000000099',
        'deviceId': 'device-x',
      });
      expect(result['statusCode'], 404);
    });
  });
}
