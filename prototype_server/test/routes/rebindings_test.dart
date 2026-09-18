import 'package:prototype_server/data/models.dart';
import 'package:prototype_server/router.dart';
import 'package:test/test.dart';

import '../support/fake_auth_data_store.dart';
import '../support/request_helpers.dart';

Future<String> _registerDevice(
  FakeAuthDataStore store,
  String accountId,
  String installationUuid,
) async {
  final device = await store.findOrCreateDevice(installationUuid);
  final challenge = await store.createOtpChallenge(
    accountId: accountId,
    deviceId: device.id,
    context: OtpContext.registration,
  );
  await store.verifyRegistrationOtpAndBind(
    accountId: accountId,
    deviceId: device.id,
    submittedCode: challenge.code,
  );
  return device.id;
}

void main() {
  group('rebinding (FR-016, FR-017, FR-018, FR-023, FR-024, FR-025, FR-041, FR-042)', () {
    late FakeAuthDataStore store;

    setUp(() => store = FakeAuthDataStore());

    test(
      'completeRebinding refuses when the login-context OTP was never verified',
      () async {
        final account = store.addAccount(
          mobileNumber: '+923000000040',
          userType: 'installer',
        );
        await getJsonRebindingAuthorization(store, account.id, 'device-new');
        store.setAuthorizationStatus(
          account.id,
          (await store.findOrCreateDevice('device-new')).id,
          RebindingAuthorizationStatus.authorized,
        );

        final router = buildRouter(store);
        final result = await postJson(router, '/rebindings', {
          'accountId': account.id,
          'deviceId': (await store.findOrCreateDevice('device-new')).id,
        });

        expect(result['statusCode'], 400);
        expect(result['body']['error'], 'otp_not_verified');
      },
    );

    test('second-device tier (zero prior moves): a verified OTP alone '
        'activates the device, even with authorization left Pending — that '
        'table is never consulted at this tier (FR-016)', () async {
      final account = store.addAccount(
        mobileNumber: '+923000000041',
        userType: 'retailer',
      );
      final device = await store.findOrCreateDevice('device-new-2');
      final otp = await store.createOtpChallenge(
        accountId: account.id,
        deviceId: device.id,
        context: OtpContext.newDeviceLogin,
      );
      await store.verifyLoginOtp(
        accountId: account.id,
        deviceId: device.id,
        submittedCode: otp.code,
      );
      // Deliberately left Pending/unresolved — must not matter here.
      await store.getOrCreateRebindingAuthorization(
        accountId: account.id,
        deviceId: device.id,
      );

      final router = buildRouter(store);
      final result = await postJson(router, '/rebindings', {
        'accountId': account.id,
        'deviceId': device.id,
      });

      expect(result['statusCode'], 200);
      expect(store.activeBindingFor(account.id)!.deviceId, device.id);
    });

    test('third-or-later tier (one+ prior moves): completeRebinding refuses '
        'when authorization is not Authorized (FR-017)', () async {
      final account = store.addAccount(
        mobileNumber: '+923000000045',
        userType: 'retailer',
      );
      // Complete one second-device-tier move first, so the account's next
      // move is third-or-later tier (moveCount becomes 1).
      await _registerDevice(store, account.id, 'device-move1-old');
      final movedDevice = await store.findOrCreateDevice('device-move1-new');
      final firstMoveOtp = await store.createOtpChallenge(
        accountId: account.id,
        deviceId: movedDevice.id,
        context: OtpContext.newDeviceLogin,
      );
      await store.verifyLoginOtp(
        accountId: account.id,
        deviceId: movedDevice.id,
        submittedCode: firstMoveOtp.code,
      );
      await store.completeRebinding(
        accountId: account.id,
        deviceId: movedDevice.id,
      );
      expect(
        await store.getDeviceMoveTier(account.id),
        DeviceMoveTier.thirdOrLater,
      );

      // Now attempt a SECOND move (device 3): verified OTP, but
      // authorization left Pending — must be refused.
      final thirdDevice = await store.findOrCreateDevice('device-move2-new');
      final secondMoveOtp = await store.createOtpChallenge(
        accountId: account.id,
        deviceId: thirdDevice.id,
        context: OtpContext.newDeviceLogin,
      );
      await store.verifyLoginOtp(
        accountId: account.id,
        deviceId: thirdDevice.id,
        submittedCode: secondMoveOtp.code,
      );
      await store.getOrCreateRebindingAuthorization(
        accountId: account.id,
        deviceId: thirdDevice.id,
      );
      // Left Pending — never resolved to authorized.

      final router = buildRouter(store);
      final result = await postJson(router, '/rebindings', {
        'accountId': account.id,
        'deviceId': thirdDevice.id,
      });

      expect(result['statusCode'], 403);
      expect(result['body']['error'], 'not_authorized');
      // The account's Active device must still be the one from the first
      // move — completely unaffected by the refused second move.
      expect(store.activeBindingFor(account.id)!.deviceId, movedDevice.id);
    });

    test('third-or-later tier: completeRebinding succeeds once authorization '
        'is Authorized (FR-018)', () async {
      final account = store.addAccount(
        mobileNumber: '+923000000046',
        userType: 'wholesaler',
      );
      await _registerDevice(store, account.id, 'device-move1-old-b');
      final movedDevice = await store.findOrCreateDevice('device-move1-new-b');
      final firstMoveOtp = await store.createOtpChallenge(
        accountId: account.id,
        deviceId: movedDevice.id,
        context: OtpContext.newDeviceLogin,
      );
      await store.verifyLoginOtp(
        accountId: account.id,
        deviceId: movedDevice.id,
        submittedCode: firstMoveOtp.code,
      );
      await store.completeRebinding(
        accountId: account.id,
        deviceId: movedDevice.id,
      );

      final thirdDevice = await store.findOrCreateDevice('device-move2-new-b');
      final secondMoveOtp = await store.createOtpChallenge(
        accountId: account.id,
        deviceId: thirdDevice.id,
        context: OtpContext.newDeviceLogin,
      );
      await store.verifyLoginOtp(
        accountId: account.id,
        deviceId: thirdDevice.id,
        submittedCode: secondMoveOtp.code,
      );
      await store.getOrCreateRebindingAuthorization(
        accountId: account.id,
        deviceId: thirdDevice.id,
      );
      store.setAuthorizationStatus(
        account.id,
        thirdDevice.id,
        RebindingAuthorizationStatus.authorized,
      );

      final router = buildRouter(store);
      final result = await postJson(router, '/rebindings', {
        'accountId': account.id,
        'deviceId': thirdDevice.id,
      });

      expect(result['statusCode'], 200);
      expect(store.activeBindingFor(account.id)!.deviceId, thirdDevice.id);
      final oldBinding = store.bindings.firstWhere(
        (b) => b.deviceId == movedDevice.id,
      );
      expect(oldBinding.status, BindingStatus.revoked);
    });

    test('a completed move atomically activates the new device and revokes '
        'the previous Active device (FR-016, FR-023, FR-041)', () async {
      final account = store.addAccount(
        mobileNumber: '+923000000042',
        userType: 'wholesaler',
      );
      final oldDeviceId = await _registerDevice(
        store,
        account.id,
        'device-old',
      );
      final newDevice = await store.findOrCreateDevice('device-new-3');
      final otp = await store.createOtpChallenge(
        accountId: account.id,
        deviceId: newDevice.id,
        context: OtpContext.newDeviceLogin,
      );
      await store.verifyLoginOtp(
        accountId: account.id,
        deviceId: newDevice.id,
        submittedCode: otp.code,
      );
      await store.getOrCreateRebindingAuthorization(
        accountId: account.id,
        deviceId: newDevice.id,
      );
      store.setAuthorizationStatus(
        account.id,
        newDevice.id,
        RebindingAuthorizationStatus.authorized,
      );

      final router = buildRouter(store);
      final result = await postJson(router, '/rebindings', {
        'accountId': account.id,
        'deviceId': newDevice.id,
      });

      expect(result['statusCode'], 200);
      final activeBinding = store.activeBindingFor(account.id);
      expect(activeBinding!.deviceId, newDevice.id);

      final oldBinding = store.bindings.firstWhere(
        (b) => b.deviceId == oldDeviceId,
      );
      expect(oldBinding.status, BindingStatus.revoked);
    });

    test(
      'device conflict: rebinding onto a device Active for a DIFFERENT '
      'account atomically transfers it — never Active for both (FR-024)',
      () async {
        final accountA = store.addAccount(
          mobileNumber: '+923000000043',
          userType: 'installer',
        );
        final accountB = store.addAccount(
          mobileNumber: '+923000000044',
          userType: 'retailer',
        );
        final deviceAId = await _registerDevice(store, accountA.id, 'device-a');
        final deviceBId = await _registerDevice(store, accountB.id, 'device-b');

        final deviceB = store.devices.firstWhere((d) => d.id == deviceBId);
        final otp = await store.createOtpChallenge(
          accountId: accountA.id,
          deviceId: deviceB.id,
          context: OtpContext.newDeviceLogin,
        );
        await store.verifyLoginOtp(
          accountId: accountA.id,
          deviceId: deviceB.id,
          submittedCode: otp.code,
        );
        await store.getOrCreateRebindingAuthorization(
          accountId: accountA.id,
          deviceId: deviceB.id,
        );
        store.setAuthorizationStatus(
          accountA.id,
          deviceB.id,
          RebindingAuthorizationStatus.authorized,
        );

        final router = buildRouter(store);
        final result = await postJson(router, '/rebindings', {
          'accountId': accountA.id,
          'deviceId': deviceB.id,
        });

        expect(result['statusCode'], 200);

        final aActive = store.activeBindingFor(accountA.id);
        expect(
          aActive!.deviceId,
          deviceB.id,
          reason: 'Account A → Device B Active',
        );

        final aOldBinding = store.bindings.firstWhere(
          (b) => b.deviceId == deviceAId,
        );
        expect(
          aOldBinding.status,
          BindingStatus.revoked,
          reason: 'Account A → Device A Revoked',
        );

        final bActive = store.activeBindingFor(accountB.id);
        expect(
          bActive,
          isNull,
          reason: 'Account B → Device B Revoked (no longer Active for B)',
        );

        // Never Active for both at once.
        final activeBForDeviceB = store.bindings.where(
          (b) => b.deviceId == deviceB.id && b.status == BindingStatus.active,
        );
        expect(activeBForDeviceB.length, 1);
      },
    );

    test('device conflict at the third-or-later tier: authorization is still '
        'required, and the atomic 3-row transfer still holds (FR-017, '
        'FR-018, FR-024)', () async {
      final accountA = store.addAccount(
        mobileNumber: '+923000000047',
        userType: 'installer',
      );
      final accountB = store.addAccount(
        mobileNumber: '+923000000048',
        userType: 'retailer',
      );
      // Account A completes one prior move, so its next move is
      // third-or-later tier.
      await _registerDevice(store, accountA.id, 'device-a1');
      final aSecondDevice = await store.findOrCreateDevice('device-a2');
      final aMoveOtp = await store.createOtpChallenge(
        accountId: accountA.id,
        deviceId: aSecondDevice.id,
        context: OtpContext.newDeviceLogin,
      );
      await store.verifyLoginOtp(
        accountId: accountA.id,
        deviceId: aSecondDevice.id,
        submittedCode: aMoveOtp.code,
      );
      await store.completeRebinding(
        accountId: accountA.id,
        deviceId: aSecondDevice.id,
      );
      expect(
        await store.getDeviceMoveTier(accountA.id),
        DeviceMoveTier.thirdOrLater,
      );

      final deviceBId = await _registerDevice(
        store,
        accountB.id,
        'device-b-conflict-2',
      );
      final deviceB = store.devices.firstWhere((d) => d.id == deviceBId);

      // Attempt to move onto Device B without authorization: refused.
      final conflictOtpUnauthorized = await store.createOtpChallenge(
        accountId: accountA.id,
        deviceId: deviceB.id,
        context: OtpContext.newDeviceLogin,
      );
      await store.verifyLoginOtp(
        accountId: accountA.id,
        deviceId: deviceB.id,
        submittedCode: conflictOtpUnauthorized.code,
      );
      await store.getOrCreateRebindingAuthorization(
        accountId: accountA.id,
        deviceId: deviceB.id,
      );
      final router = buildRouter(store);
      final refused = await postJson(router, '/rebindings', {
        'accountId': accountA.id,
        'deviceId': deviceB.id,
      });
      expect(refused['statusCode'], 403);
      expect(
        store.activeBindingFor(accountB.id)!.deviceId,
        deviceB.id,
        reason: 'refused attempt must leave Account B untouched',
      );

      // Now authorize it: the transfer must complete atomically.
      store.setAuthorizationStatus(
        accountA.id,
        deviceB.id,
        RebindingAuthorizationStatus.authorized,
      );
      final result = await postJson(router, '/rebindings', {
        'accountId': accountA.id,
        'deviceId': deviceB.id,
      });

      expect(result['statusCode'], 200);
      expect(store.activeBindingFor(accountA.id)!.deviceId, deviceB.id);
      expect(store.activeBindingFor(accountB.id), isNull);
      final activeForDeviceB = store.bindings.where(
        (b) => b.deviceId == deviceB.id && b.status == BindingStatus.active,
      );
      expect(activeForDeviceB.length, 1);
    });

    test(
      'the same conflict-resolution logic applies identically across every '
      'pairing of the four user types, with no special-casing (FR-025)',
      () async {
        final userTypePairs = [
          ('installer', 'retailer'),
          ('wholesaler', 'distributor'),
          ('installer', 'distributor'),
          ('retailer', 'wholesaler'),
        ];

        for (final (typeA, typeB) in userTypePairs) {
          final freshStore = FakeAuthDataStore();
          final accountA = freshStore.addAccount(
            mobileNumber: '+9231${typeA.hashCode % 900000}',
            userType: typeA,
          );
          final accountB = freshStore.addAccount(
            mobileNumber: '+9232${typeB.hashCode % 900000}',
            userType: typeB,
          );
          await _registerDevice(
            freshStore,
            accountA.id,
            'device-a-$typeA-$typeB',
          );
          final deviceBId = await _registerDevice(
            freshStore,
            accountB.id,
            'device-b-$typeA-$typeB',
          );

          final otp = await freshStore.createOtpChallenge(
            accountId: accountA.id,
            deviceId: deviceBId,
            context: OtpContext.newDeviceLogin,
          );
          await freshStore.verifyLoginOtp(
            accountId: accountA.id,
            deviceId: deviceBId,
            submittedCode: otp.code,
          );
          await freshStore.getOrCreateRebindingAuthorization(
            accountId: accountA.id,
            deviceId: deviceBId,
          );
          freshStore.setAuthorizationStatus(
            accountA.id,
            deviceBId,
            RebindingAuthorizationStatus.authorized,
          );

          final router = buildRouter(freshStore);
          final result = await postJson(router, '/rebindings', {
            'accountId': accountA.id,
            'deviceId': deviceBId,
          });

          expect(
            result['statusCode'],
            200,
            reason: 'conflict transfer failed for $typeA -> $typeB',
          );
          expect(freshStore.activeBindingFor(accountA.id)!.deviceId, deviceBId);
          expect(freshStore.activeBindingFor(accountB.id), isNull);
        }
      },
    );
  });
}

Future<void> getJsonRebindingAuthorization(
  FakeAuthDataStore store,
  String accountId,
  String installationUuid,
) async {
  final device = await store.findOrCreateDevice(installationUuid);
  await store.getOrCreateRebindingAuthorization(
    accountId: accountId,
    deviceId: device.id,
  );
}
