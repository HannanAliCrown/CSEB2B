import 'package:flutter_test/flutter_test.dart';

import 'package:cse_b2b/features/auth/data/repositories/auth_repository.dart';
import 'package:cse_b2b/features/auth/data/services/auth_service.dart';
import 'package:cse_b2b/features/auth/ui/view_models/registration_view_model.dart';

import '../../support/fake_auth_service.dart';
import '../../support/fake_stores.dart';

AuthRepository _repository(FakeAuthService service) => AuthRepository(
  authService: service,
  deviceIdentityStore: FakeDeviceIdentityStore(),
  sessionStore: FakeSessionStore(),
);

void main() {
  group('RegistrationViewModel', () {
    test('starts at enterMobileNumber', () {
      final viewModel = RegistrationViewModel(
        repository: _repository(FakeAuthService()),
      );
      expect(viewModel.step, RegistrationStep.enterMobileNumber);
    });

    test(
      'submitting a mobile number with no Active device requests an OTP '
      'and moves to enterOtp — no device becomes Active yet (FR-002)',
      () async {
        final viewModel = RegistrationViewModel(
          repository: _repository(FakeAuthService()),
        );

        await viewModel.submitMobileNumber('+920000000001');

        expect(viewModel.step, RegistrationStep.enterOtp);
        expect(viewModel.prototypeOtpCode, isNotNull);
      },
    );

    test('a correct OTP moves to success (FR-040)', () async {
      final viewModel = RegistrationViewModel(
        repository: _repository(FakeAuthService()),
      );
      await viewModel.submitMobileNumber('+920000000001');

      await viewModel.submitOtp('111111');

      expect(viewModel.step, RegistrationStep.success);
    });

    test('an invalid OTP does not advance to success', () async {
      final service = FakeAuthService()
        ..registrationVerifyResult = const RegistrationVerifyResult(
          RegistrationVerifyStatus.invalidCode,
        );
      final viewModel = RegistrationViewModel(repository: _repository(service));
      await viewModel.submitMobileNumber('+920000000001');

      await viewModel.submitOtp('wrong');

      expect(viewModel.step, RegistrationStep.invalidOtp);
    });

    test(
      'an account with an existing Active device is refused registration',
      () async {
        final service = FakeAuthService()
          ..registrationOtpResult = const RegistrationOtpResult.failure(
            RegistrationOtpStatus.alreadyRegistered,
          );
        final viewModel = RegistrationViewModel(
          repository: _repository(service),
        );

        await viewModel.submitMobileNumber('+920000000001');

        expect(viewModel.step, RegistrationStep.alreadyRegistered);
      },
    );
  });
}
