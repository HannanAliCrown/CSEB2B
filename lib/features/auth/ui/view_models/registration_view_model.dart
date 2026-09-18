// ignore_for_file: prefer_initializing_formals
import 'package:flutter/foundation.dart';

import '../../data/repositories/auth_repository.dart';
import '../../data/services/auth_service.dart';

/// States for User Story 1 (Registration): mobile number → registration
/// OTP → successful verification → initial device binding, atomically
/// (FR-001–FR-005, FR-040).
enum RegistrationStep {
  enterMobileNumber,
  requestingOtp,
  enterOtp,
  verifyingOtp,
  success,
  accountNotFound,
  alreadyRegistered,
  invalidOtp,
  failed,
}

class RegistrationViewModel extends ChangeNotifier {
  RegistrationViewModel({required AuthRepository repository})
    : _repository = repository;

  final AuthRepository _repository;

  RegistrationStep step = RegistrationStep.enterMobileNumber;

  /// Prototype-only: the simulated OTP, surfaced so the flow can be
  /// exercised without a real SMS provider (research.md). Never present
  /// in a production build.
  String? prototypeOtpCode;

  String? _accountId;
  String? _deviceId;

  Future<void> submitMobileNumber(String mobileNumber) async {
    step = RegistrationStep.requestingOtp;
    notifyListeners();

    final result = await _repository.requestRegistrationOtp(mobileNumber);
    switch (result.status) {
      case RegistrationOtpStatus.issued:
        _accountId = result.accountId;
        _deviceId = result.deviceId;
        prototypeOtpCode = result.prototypeCode;
        step = RegistrationStep.enterOtp;
      case RegistrationOtpStatus.accountNotFound:
        step = RegistrationStep.accountNotFound;
      case RegistrationOtpStatus.alreadyRegistered:
        step = RegistrationStep.alreadyRegistered;
    }
    notifyListeners();
  }

  Future<void> submitOtp(String code) async {
    step = RegistrationStep.verifyingOtp;
    notifyListeners();

    final result = await _repository.verifyRegistrationOtp(
      accountId: _accountId!,
      deviceId: _deviceId!,
      code: code,
    );
    step = switch (result.status) {
      RegistrationVerifyStatus.activated => RegistrationStep.success,
      RegistrationVerifyStatus.invalidCode => RegistrationStep.invalidOtp,
      RegistrationVerifyStatus.notFound => RegistrationStep.invalidOtp,
      RegistrationVerifyStatus.failed => RegistrationStep.failed,
    };
    notifyListeners();
  }
}
