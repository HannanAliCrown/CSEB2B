// ignore_for_file: prefer_initializing_formals
import 'package:flutter/foundation.dart';

import '../../data/repositories/auth_repository.dart';
import '../../data/services/auth_service.dart';

/// States spanning User Stories 2–7: trusted-device login (no OTP),
/// New/Untrusted detection, the device-conflict confirmation gate (Claude
/// Design A4, always BEFORE any OTP), the two device-move tiers —
/// second-device (OTP alone) and third-or-later (authorization checked
/// BEFORE OTP, gated on Authorized) — and the resulting atomic rebinding,
/// including the device-conflict transfer case — one continuous user
/// journey from a single mobile-number submission (FR-006, FR-007,
/// FR-011–FR-018, FR-022–FR-024).
enum LoginStep {
  enterMobileNumber,
  submitting,
  trustedSuccess,
  accountNotFound,

  /// Claude Design A4: the target device is Active for a *different*
  /// account. Always shown BEFORE any OTP is requested, at either tier
  /// (FR-013, FR-014).
  deviceConflictConfirmation,

  /// Third-or-later tier only (FR-017): checked BEFORE any OTP is
  /// requested, never after. Second-device tier never reaches this step.
  checkingAuthorization,
  authorizationPending,
  authorizationNotAuthorized,

  enterOtp,
  verifyingOtp,
  invalidOtp,
  completingRebinding,
  rebindingSuccess,
  rebindingFailed,
}

class LoginViewModel extends ChangeNotifier {
  LoginViewModel({required AuthRepository repository})
    : _repository = repository;

  final AuthRepository _repository;

  LoginStep step = LoginStep.enterMobileNumber;

  /// Prototype-only testability surface (research.md) — never present in
  /// production.
  String? prototypeOtpCode;

  bool keepSignedIn = false;
  String? _mobileNumber;
  String? _accountId;
  String? _deviceId;
  DeviceMoveTier? _tier;
  ConflictInfo? _conflict;

  String? get accountId => _accountId;

  /// The mobile number submitted this attempt, so the OTP-entry screen can
  /// state where the code was sent (Claude Design A2/B2) — read-only
  /// exposure of state the ViewModel already holds; no new business logic.
  String? get mobileNumber => _mobileNumber;

  /// The requesting account's device-move tier for the in-progress
  /// New/Untrusted attempt, once known — exposed for the UI to decide
  /// between the A2 (second-device) and B2 (third-or-later, authorized)
  /// OTP presentations. Null before `evaluateLogin` has reported it.
  DeviceMoveTier? get tier => _tier;

  /// The other account a device conflict was reported against, for the
  /// A4 confirmation dialog. Null when there is no conflict pending.
  ConflictInfo? get pendingConflict => _conflict;

  void setKeepSignedIn(bool value) {
    keepSignedIn = value;
    notifyListeners();
  }

  Future<void> submitMobileNumber(String mobileNumber) async {
    step = LoginStep.submitting;
    notifyListeners();

    _mobileNumber = mobileNumber;
    final result = await _repository.evaluateLogin(mobileNumber);
    switch (result.status) {
      case LoginStatus.accountNotFound:
        step = LoginStep.accountNotFound;
        notifyListeners();
        return;
      case LoginStatus.trusted:
        _accountId = result.accountId;
        await _repository.persistSessionIfRequested(
          accountId: result.accountId!,
          keepSignedIn: keepSignedIn,
        );
        step = LoginStep.trustedSuccess;
        notifyListeners();
        return;
      case LoginStatus.newUntrusted:
        _accountId = result.accountId;
        _deviceId = result.deviceId;
        _tier = result.tier;
        _conflict = result.conflict;

        if (_conflict != null) {
          // FR-013/FR-014: conflict confirmation ALWAYS precedes tier/OTP
          // processing, regardless of which tier applies to this account.
          step = LoginStep.deviceConflictConfirmation;
          notifyListeners();
          return;
        }
        await _proceedPastConflict();
    }
  }

  /// Called when the user confirms the A4 takeover dialog. Only then does
  /// the flow proceed to the requesting account's tier-gated path
  /// (FR-014).
  Future<void> confirmDeviceConflict() async {
    await _repository.confirmTakeover(_mobileNumber!);
    _conflict = null;
    await _proceedPastConflict();
  }

  /// Called when the user declines the A4 takeover dialog. Writes
  /// nothing at all — no OTP is ever requested and every account's
  /// binding state is left completely unchanged (FR-014).
  void declineDeviceConflict() {
    _conflict = null;
    _tier = null;
    _accountId = null;
    _deviceId = null;
    _mobileNumber = null;
    step = LoginStep.enterMobileNumber;
    notifyListeners();
  }

  /// Branches on the requesting account's device-move tier (FR-015):
  /// second-device tier goes straight to requesting an OTP (FR-016);
  /// third-or-later tier checks authorization FIRST (FR-017) and only
  /// requests an OTP once that resolves to Authorized (FR-018).
  Future<void> _proceedPastConflict() async {
    if (_tier == DeviceMoveTier.secondDevice) {
      await _requestOtp();
    } else {
      await _checkAuthorizationBeforeOtp();
    }
  }

  /// Third-or-later tier only. Re-checking this is also the retry entry
  /// point exposed to the UI for the `authorizationPending` state — every
  /// call is a fresh check, exactly as the spec requires; OTP is only
  /// ever requested once the outcome is Authorized (FR-017, FR-018).
  Future<void> checkAuthorizationAndRebindIfPossible() =>
      _checkAuthorizationBeforeOtp();

  Future<void> _checkAuthorizationBeforeOtp() async {
    step = LoginStep.checkingAuthorization;
    notifyListeners();

    final authResult = await _repository.checkRebindingAuthorization(
      accountId: _accountId!,
      deviceId: _deviceId!,
    );

    switch (authResult.status) {
      case RebindingAuthorizationStatus.pending:
        step = LoginStep.authorizationPending;
        notifyListeners();
      case RebindingAuthorizationStatus.notAuthorized:
        step = LoginStep.authorizationNotAuthorized;
        notifyListeners();
      case RebindingAuthorizationStatus.authorized:
        await _requestOtp();
    }
  }

  Future<void> _requestOtp() async {
    final otp = await _repository.requestLoginOtp(
      accountId: _accountId!,
      deviceId: _deviceId!,
    );
    if (otp.status == LoginOtpStatus.notYetAuthorized) {
      // Defensive fallback only: the third-or-later branch above never
      // calls this until authorization is confirmed Authorized, but the
      // server independently re-checks (FR-046) and this is how a race
      // would surface.
      step = LoginStep.authorizationNotAuthorized;
      notifyListeners();
      return;
    }
    prototypeOtpCode = otp.prototypeCode;
    step = LoginStep.enterOtp;
    notifyListeners();
  }

  /// Re-requests a login-context OTP for the same account/device pair
  /// (Claude Design A2/B2 "Resend"). This is not a new business rule — it
  /// re-invokes exactly the same `requestLoginOtp` call path as the
  /// initial automatic request, so it is gated identically (unconditional
  /// at the second-device tier; already past the authorization check by
  /// the time OTP entry is showing at the third-or-later tier). No
  /// cooldown/countdown is enforced here, since none is defined by the
  /// business (spec.md's OTP Open Question) — the UI must not invent one.
  Future<void> resendOtp() => _requestOtp();

  Future<void> submitOtp(String code) async {
    step = LoginStep.verifyingOtp;
    notifyListeners();

    final otpResult = await _repository.verifyLoginOtp(
      accountId: _accountId!,
      deviceId: _deviceId!,
      code: code,
    );
    if (otpResult.status != OtpVerifyStatus.verified) {
      step = LoginStep.invalidOtp;
      notifyListeners();
      return;
    }

    step = LoginStep.completingRebinding;
    notifyListeners();
    final rebindResult = await _repository.completeRebinding(
      accountId: _accountId!,
      deviceId: _deviceId!,
    );
    if (rebindResult.status == RebindStatus.activated) {
      await _repository.persistSessionIfRequested(
        accountId: _accountId!,
        keepSignedIn: keepSignedIn,
      );
      step = LoginStep.rebindingSuccess;
    } else {
      step = LoginStep.rebindingFailed;
    }
    notifyListeners();
  }
}
