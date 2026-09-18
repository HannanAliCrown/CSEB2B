import 'package:prototype_server/data/models.dart';
import 'package:prototype_server/router.dart';
import 'package:test/test.dart';

import '../support/fake_auth_data_store.dart';
import '../support/request_helpers.dart';

void main() {
  group('login-context OTP (FR-005, FR-016, FR-017, FR-020, FR-021)', () {
    late FakeAuthDataStore store;

    setUp(() => store = FakeAuthDataStore());

    test(
      'a login-context challenge is distinct from any registration challenge',
      () async {
        final account = store.addAccount(
          mobileNumber: '+923000000020',
          userType: 'installer',
        );
        final router = buildRouter(store);

        final registrationOtp = await postJson(router, '/registration/otp', {
          'mobileNumber': account.mobileNumber,
          'deviceId': 'device-1',
        });
        final loginOtp = await postJson(router, '/login/otp', {
          'accountId': account.id,
          'deviceId': registrationOtp['body']['deviceId'],
        });

        expect(
          registrationOtp['body']['challengeId'],
          isNot(loginOtp['body']['challengeId']),
        );
      },
    );

    test('verifying the login-context OTP does not itself create any device '
        'binding or rebinding-authorization row (FR-014)', () async {
      final account = store.addAccount(
        mobileNumber: '+923000000021',
        userType: 'retailer',
      );
      final router = buildRouter(store);
      final otp = await postJson(router, '/login/otp', {
        'accountId': account.id,
        'deviceId': 'device-2',
      });

      final verify = await postJson(router, '/login/otp/verify', {
        'accountId': account.id,
        'deviceId': 'device-2',
        'code': otp['body']['code'],
      });

      expect(verify['statusCode'], 200);
      expect(verify['body']['verified'], true);
      expect(store.activeBindingFor(account.id), isNull);
      expect(store.authorizations, isEmpty);
    });

    test(
      'an incorrect login-context OTP fails without changing any state',
      () async {
        final account = store.addAccount(
          mobileNumber: '+923000000022',
          userType: 'wholesaler',
        );
        final router = buildRouter(store);
        await postJson(router, '/login/otp', {
          'accountId': account.id,
          'deviceId': 'device-3',
        });

        final verify = await postJson(router, '/login/otp/verify', {
          'accountId': account.id,
          'deviceId': 'device-3',
          'code': 'wrong',
        });

        expect(verify['statusCode'], 400);
        expect(verify['body']['error'], 'invalid_code');
      },
    );

    test(
      'second-device tier (zero prior moves): OTP is issued unconditionally, '
      'never consulting rebinding_authorizations at all (FR-016)',
      () async {
        final account = store.addAccount(
          mobileNumber: '+923000000023',
          userType: 'installer',
        );
        expect(
          await store.getDeviceMoveTier(account.id),
          DeviceMoveTier.secondDevice,
        );
        final router = buildRouter(store);

        final result = await postJson(router, '/login/otp', {
          'accountId': account.id,
          'deviceId': 'device-4',
        });

        expect(result['statusCode'], 200);
        expect(result['body']['challengeId'], isNotNull);
        expect(
          store.authorizations,
          isEmpty,
          reason:
              'second-device tier must never create/read an '
              'authorization row',
        );
      },
    );

    Future<Account> accountWithOneCompletedMove(
      FakeAuthDataStore store,
      String mobileNumber,
      String userType,
    ) async {
      final account = store.addAccount(
        mobileNumber: mobileNumber,
        userType: userType,
      );
      final device1 = await store.findOrCreateDevice(
        'reg-device-$mobileNumber',
      );
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
      final device2 = await store.findOrCreateDevice(
        'move2-device-$mobileNumber',
      );
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
      return account;
    }

    test('third-or-later tier (one+ prior moves): OTP is refused (403) while '
        'authorization is Pending — never issued (FR-017)', () async {
      final account = await accountWithOneCompletedMove(
        store,
        '+923000000024',
        'retailer',
      );
      expect(
        await store.getDeviceMoveTier(account.id),
        DeviceMoveTier.thirdOrLater,
      );
      final router = buildRouter(store);

      final result = await postJson(router, '/login/otp', {
        'accountId': account.id,
        'deviceId': 'device-5',
      });

      expect(result['statusCode'], 403);
      expect(result['body']['error'], 'not_authorized');
      expect(result['body']['authorizationStatus'], 'pending');
    });

    test('third-or-later tier: OTP is refused (403) while authorization is '
        'Not Authorized — never issued (FR-017)', () async {
      final account = await accountWithOneCompletedMove(
        store,
        '+923000000025',
        'wholesaler',
      );
      await store.getOrCreateRebindingAuthorization(
        accountId: account.id,
        deviceId: (await store.findOrCreateDevice('device-6')).id,
      );
      store.setAuthorizationStatus(
        account.id,
        (await store.findOrCreateDevice('device-6')).id,
        RebindingAuthorizationStatus.notAuthorized,
      );
      final router = buildRouter(store);

      final result = await postJson(router, '/login/otp', {
        'accountId': account.id,
        'deviceId': (await store.findOrCreateDevice('device-6')).id,
      });

      expect(result['statusCode'], 403);
      expect(result['body']['authorizationStatus'], 'not_authorized');
    });

    test('third-or-later tier: OTP IS issued once authorization is Authorized '
        '(FR-018)', () async {
      final account = await accountWithOneCompletedMove(
        store,
        '+923000000026',
        'distributor',
      );
      final device = await store.findOrCreateDevice('device-7');
      await store.getOrCreateRebindingAuthorization(
        accountId: account.id,
        deviceId: device.id,
      );
      store.setAuthorizationStatus(
        account.id,
        device.id,
        RebindingAuthorizationStatus.authorized,
      );
      final router = buildRouter(store);

      final result = await postJson(router, '/login/otp', {
        'accountId': account.id,
        'deviceId': device.id,
      });

      expect(result['statusCode'], 200);
      expect(result['body']['challengeId'], isNotNull);
    });
  });
}
