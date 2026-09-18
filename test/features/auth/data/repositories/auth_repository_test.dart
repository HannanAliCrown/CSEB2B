import 'package:flutter_test/flutter_test.dart';

import 'package:cse_b2b/features/auth/data/repositories/auth_repository.dart';
import 'package:cse_b2b/features/auth/data/services/auth_service.dart';

import '../../support/fake_auth_service.dart';
import '../../support/fake_stores.dart';

void main() {
  group('AuthRepository', () {
    late FakeAuthService authService;
    late FakeSessionStore sessionStore;
    late AuthRepository repository;

    setUp(() {
      authService = FakeAuthService();
      sessionStore = FakeSessionStore();
      repository = AuthRepository(
        authService: authService,
        deviceIdentityStore: FakeDeviceIdentityStore('device-abc'),
        sessionStore: sessionStore,
      );
    });

    test(
      'requestRegistrationOtp passes the current device id through',
      () async {
        await repository.requestRegistrationOtp('+920000000001');
        expect(authService.calls, contains('requestRegistrationOtp'));
      },
    );

    test('confirmTakeover passes the current device id through and writes '
        'nothing locally (FR-014)', () async {
      final result = await repository.confirmTakeover('+920000000001');
      expect(authService.calls, contains('confirmTakeover'));
      expect(result.acknowledged, isTrue);
      expect(sessionStore.stored, isNull);
    });

    test('persistSessionIfRequested writes a session only when keepSignedIn is true', () async {
      await repository.persistSessionIfRequested(
        accountId: 'account-1',
        keepSignedIn: false,
      );
      expect(sessionStore.stored, isNull);

      await repository.persistSessionIfRequested(
        accountId: 'account-1',
        keepSignedIn: true,
      );
      expect(sessionStore.stored, isNotNull);
      expect(sessionStore.stored!.accountId, 'account-1');
      expect(sessionStore.stored!.deviceInstallationUuid, 'device-abc');
    });

    test(
      'restoreSession returns noSession when nothing is persisted',
      () async {
        final result = await repository.restoreSession();
        expect(result.outcome, SessionRestoreOutcome.noSession);
      },
    );

    test(
      'restoreSession restores only when the device is still active (FR-030)',
      () async {
        await repository.persistSessionIfRequested(
          accountId: 'account-1',
          keepSignedIn: true,
        );
        authService.deviceStatusResult = const DeviceStatusResult(
          DeviceBindingStatus.active,
        );

        final result = await repository.restoreSession();

        expect(result.outcome, SessionRestoreOutcome.restored);
        expect(result.accountId, 'account-1');
      },
    );

    test('restoreSession never restores a revoked device, and clears the stale '
        'local session (FR-030)', () async {
      await repository.persistSessionIfRequested(
        accountId: 'account-1',
        keepSignedIn: true,
      );
      authService.deviceStatusResult = const DeviceStatusResult(
        DeviceBindingStatus.revoked,
      );

      final result = await repository.restoreSession();

      expect(result.outcome, SessionRestoreOutcome.deviceNoLongerActive);
      expect(sessionStore.stored, isNull);
    });

    test('logout clears the local session without calling AuthService (FR-032, FR-033)', () async {
      await repository.persistSessionIfRequested(
        accountId: 'account-1',
        keepSignedIn: true,
      );

      await repository.logout();

      expect(sessionStore.stored, isNull);
      expect(authService.calls, isEmpty);
    });
  });
}
