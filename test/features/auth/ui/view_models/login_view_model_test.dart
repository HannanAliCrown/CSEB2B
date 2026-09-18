import 'package:flutter_test/flutter_test.dart';

import 'package:cse_b2b/features/auth/data/repositories/auth_repository.dart';
import 'package:cse_b2b/features/auth/data/services/auth_service.dart';
import 'package:cse_b2b/features/auth/ui/view_models/login_view_model.dart';

import '../../support/fake_auth_service.dart';
import '../../support/fake_stores.dart';

AuthRepository _repository(FakeAuthService service) => AuthRepository(
  authService: service,
  deviceIdentityStore: FakeDeviceIdentityStore(),
  sessionStore: FakeSessionStore(),
);

void main() {
  group('LoginViewModel', () {
    test(
      'a trusted device reaches success with no OTP requested (FR-011)',
      () async {
        final service = FakeAuthService()
          ..loginResult = const LoginResult.success(
            status: LoginStatus.trusted,
            accountId: 'account-1',
            deviceId: 'device-1',
          );
        final viewModel = LoginViewModel(repository: _repository(service));

        await viewModel.submitMobileNumber('+920000000001');

        expect(viewModel.step, LoginStep.trustedSuccess);
        expect(service.calls, isNot(contains('requestLoginOtp')));
      },
    );

    test('an unrecognized mobile number reports accountNotFound', () async {
      final service = FakeAuthService()
        ..loginResult = const LoginResult.accountNotFound();
      final viewModel = LoginViewModel(repository: _repository(service));

      await viewModel.submitMobileNumber('+929999999999');

      expect(viewModel.step, LoginStep.accountNotFound);
    });

    group('second-device tier (FR-016): OTP alone, no authorization check', () {
      test('a New/Untrusted device at this tier goes straight to OTP entry — '
          'checkRebindingAuthorization is never called', () async {
        final service = FakeAuthService()
          ..loginResult = const LoginResult.success(
            status: LoginStatus.newUntrusted,
            accountId: 'account-1',
            deviceId: 'device-2',
            tier: DeviceMoveTier.secondDevice,
          );
        final viewModel = LoginViewModel(repository: _repository(service));

        await viewModel.submitMobileNumber('+920000000001');

        expect(viewModel.step, LoginStep.enterOtp);
        expect(service.calls, contains('requestLoginOtp'));
        expect(service.calls, isNot(contains('checkRebindingAuthorization')));
      });

      test('a verified OTP completes the rebinding directly — no authorization '
          'call at any point in this tier', () async {
        final service = FakeAuthService()
          ..loginResult = const LoginResult.success(
            status: LoginStatus.newUntrusted,
            accountId: 'account-1',
            deviceId: 'device-2',
            tier: DeviceMoveTier.secondDevice,
          );
        final viewModel = LoginViewModel(repository: _repository(service));
        await viewModel.submitMobileNumber('+920000000001');

        await viewModel.submitOtp('222222');

        expect(viewModel.step, LoginStep.rebindingSuccess);
        expect(service.calls, contains('completeRebinding'));
        expect(service.calls, isNot(contains('checkRebindingAuthorization')));
      });
    });

    group(
      'third-or-later tier (FR-017, FR-018): authorization checked BEFORE OTP',
      () {
        test('a New/Untrusted device at this tier checks authorization first — '
            'no OTP is requested yet', () async {
          final service = FakeAuthService()
            ..loginResult = const LoginResult.success(
              status: LoginStatus.newUntrusted,
              accountId: 'account-1',
              deviceId: 'device-3',
              tier: DeviceMoveTier.thirdOrLater,
            )
            ..rebindingAuthorizationResult = const RebindingAuthorizationResult(
              RebindingAuthorizationStatus.pending,
            );
          final viewModel = LoginViewModel(repository: _repository(service));

          await viewModel.submitMobileNumber('+920000000002');

          expect(viewModel.step, LoginStep.authorizationPending);
          expect(service.calls, contains('checkRebindingAuthorization'));
          expect(service.calls, isNot(contains('requestLoginOtp')));
        });

        test('Not Authorized never requests an OTP either', () async {
          final service = FakeAuthService()
            ..loginResult = const LoginResult.success(
              status: LoginStatus.newUntrusted,
              accountId: 'account-1',
              deviceId: 'device-3',
              tier: DeviceMoveTier.thirdOrLater,
            )
            ..rebindingAuthorizationResult = const RebindingAuthorizationResult(
              RebindingAuthorizationStatus.notAuthorized,
            );
          final viewModel = LoginViewModel(repository: _repository(service));

          await viewModel.submitMobileNumber('+920000000003');

          expect(viewModel.step, LoginStep.authorizationNotAuthorized);
          expect(service.calls, isNot(contains('requestLoginOtp')));
        });

        test('Authorized requests the OTP, and a verified code completes the '
            'rebinding', () async {
          final service = FakeAuthService()
            ..loginResult = const LoginResult.success(
              status: LoginStatus.newUntrusted,
              accountId: 'account-1',
              deviceId: 'device-3',
              tier: DeviceMoveTier.thirdOrLater,
            )
            ..rebindingAuthorizationResult = const RebindingAuthorizationResult(
              RebindingAuthorizationStatus.authorized,
            );
          final viewModel = LoginViewModel(repository: _repository(service));
          await viewModel.submitMobileNumber('+920000000004');
          expect(viewModel.step, LoginStep.enterOtp);
          expect(service.calls, contains('requestLoginOtp'));

          await viewModel.submitOtp('222222');

          expect(viewModel.step, LoginStep.rebindingSuccess);
          expect(service.calls, contains('completeRebinding'));
        });

        test(
          'checkAuthorizationAndRebindIfPossible is the retry entry point '
          'for the authorizationPending state, and re-checks fresh each time',
          () async {
            final service = FakeAuthService()
              ..loginResult = const LoginResult.success(
                status: LoginStatus.newUntrusted,
                accountId: 'account-1',
                deviceId: 'device-3',
                tier: DeviceMoveTier.thirdOrLater,
              )
              ..rebindingAuthorizationResult =
                  const RebindingAuthorizationResult(
                    RebindingAuthorizationStatus.pending,
                  );
            final viewModel = LoginViewModel(repository: _repository(service));
            await viewModel.submitMobileNumber('+920000000005');
            expect(viewModel.step, LoginStep.authorizationPending);

            service.rebindingAuthorizationResult =
                const RebindingAuthorizationResult(
                  RebindingAuthorizationStatus.authorized,
                );
            await viewModel.checkAuthorizationAndRebindIfPossible();

            expect(viewModel.step, LoginStep.enterOtp);
          },
        );
      },
    );

    group(
      'device conflict (FR-013, FR-014): confirmed/declined BEFORE OTP',
      () {
        test('a conflict is shown before any OTP is requested or authorization '
            'is checked, at either tier', () async {
          final service = FakeAuthService()
            ..loginResult = const LoginResult.success(
              status: LoginStatus.newUntrusted,
              accountId: 'account-1',
              deviceId: 'device-4',
              tier: DeviceMoveTier.secondDevice,
              conflict: ConflictInfo(otherAccountId: 'account-2'),
            );
          final viewModel = LoginViewModel(repository: _repository(service));

          await viewModel.submitMobileNumber('+920000000006');

          expect(viewModel.step, LoginStep.deviceConflictConfirmation);
          expect(viewModel.pendingConflict?.otherAccountId, 'account-2');
          expect(service.calls, isNot(contains('requestLoginOtp')));
          expect(service.calls, isNot(contains('checkRebindingAuthorization')));
        });

        test(
          'declining performs no writes at all — no confirmTakeover, no OTP, '
          'no authorization check',
          () async {
            final service = FakeAuthService()
              ..loginResult = const LoginResult.success(
                status: LoginStatus.newUntrusted,
                accountId: 'account-1',
                deviceId: 'device-4',
                tier: DeviceMoveTier.secondDevice,
                conflict: ConflictInfo(otherAccountId: 'account-2'),
              );
            final viewModel = LoginViewModel(repository: _repository(service));
            await viewModel.submitMobileNumber('+920000000007');

            viewModel.declineDeviceConflict();

            expect(viewModel.step, LoginStep.enterMobileNumber);
            expect(viewModel.pendingConflict, isNull);
            expect(service.calls, isNot(contains('confirmTakeover')));
            expect(service.calls, isNot(contains('requestLoginOtp')));
          },
        );

        test(
          'confirming a conflict at the second-device tier proceeds straight '
          'to OTP entry',
          () async {
            final service = FakeAuthService()
              ..loginResult = const LoginResult.success(
                status: LoginStatus.newUntrusted,
                accountId: 'account-1',
                deviceId: 'device-4',
                tier: DeviceMoveTier.secondDevice,
                conflict: ConflictInfo(otherAccountId: 'account-2'),
              );
            final viewModel = LoginViewModel(repository: _repository(service));
            await viewModel.submitMobileNumber('+920000000008');

            await viewModel.confirmDeviceConflict();

            expect(service.calls, contains('confirmTakeover'));
            expect(viewModel.step, LoginStep.enterOtp);
            expect(viewModel.pendingConflict, isNull);
          },
        );

        test('confirming a conflict at the third-or-later tier checks '
            'authorization before requesting any OTP', () async {
          final service = FakeAuthService()
            ..loginResult = const LoginResult.success(
              status: LoginStatus.newUntrusted,
              accountId: 'account-1',
              deviceId: 'device-4',
              tier: DeviceMoveTier.thirdOrLater,
              conflict: ConflictInfo(otherAccountId: 'account-2'),
            )
            ..rebindingAuthorizationResult = const RebindingAuthorizationResult(
              RebindingAuthorizationStatus.pending,
            );
          final viewModel = LoginViewModel(repository: _repository(service));
          await viewModel.submitMobileNumber('+920000000009');

          await viewModel.confirmDeviceConflict();

          expect(service.calls, contains('confirmTakeover'));
          expect(service.calls, contains('checkRebindingAuthorization'));
          expect(service.calls, isNot(contains('requestLoginOtp')));
          expect(viewModel.step, LoginStep.authorizationPending);
        });
      },
    );
  });
}
