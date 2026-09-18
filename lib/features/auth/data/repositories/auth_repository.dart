// Constructor parameters are deliberately named differently from the
// private fields they populate (public API naming vs. internal storage),
// so the initializing-formal shorthand the linter suggests isn't
// available here.
// ignore_for_file: prefer_initializing_formals

import '../models/session.dart';
import '../services/auth_service.dart';
import '../services/device_identity_store.dart';
import '../services/session_store.dart';

/// Outcome of [AuthRepository.restoreSession] (FR-033). The local
/// [Session] record is never, by itself, sufficient evidence of continued
/// access — [restored] only happens after the current device's binding is
/// confirmed still `active`.
enum SessionRestoreOutcome { restored, noSession, deviceNoLongerActive }

class RestoreResult {
  const RestoreResult(this.outcome, {this.accountId});
  final SessionRestoreOutcome outcome;
  final String? accountId;
}

/// The Repository between ViewModels and [AuthService]. Deliberately
/// thin: it calls [AuthService] and translates results for the UI layer —
/// it holds no independent copy of device-trust, device-move-tier, or
/// rebinding business rules, since those are enforced entirely by
/// `prototype_server` (FR-037, FR-046; plan.md "Prototype Business-Rule
/// Enforcement & Atomicity"). Logout and Keep-Me-Signed-In persistence are
/// handled entirely here via [SessionStore], never through [AuthService]
/// (contracts/auth-service.md).
class AuthRepository {
  AuthRepository({
    required AuthService authService,
    required DeviceIdentityStore deviceIdentityStore,
    required SessionStore sessionStore,
  }) : _authService = authService,
       _deviceIdentityStore = deviceIdentityStore,
       _sessionStore = sessionStore;

  final AuthService _authService;
  final DeviceIdentityStore _deviceIdentityStore;
  final SessionStore _sessionStore;

  Future<String> currentDeviceId() =>
      _deviceIdentityStore.getOrCreateInstallationUuid();

  // --- Registration (US1, FR-001–FR-005, FR-043) ---

  Future<RegistrationOtpResult> requestRegistrationOtp(
    String mobileNumber,
  ) async {
    final deviceId = await currentDeviceId();
    return _authService.requestRegistrationOtp(
      mobileNumber: mobileNumber,
      deviceId: deviceId,
    );
  }

  Future<RegistrationVerifyResult> verifyRegistrationOtp({
    required String accountId,
    required String deviceId,
    required String code,
  }) {
    return _authService.verifyRegistrationOtp(
      accountId: accountId,
      deviceId: deviceId,
      code: code,
    );
  }

  // --- Login (US2/US3, FR-006, FR-007, FR-011, FR-012) ---

  Future<LoginResult> evaluateLogin(String mobileNumber) async {
    final deviceId = await currentDeviceId();
    return _authService.evaluateLogin(
      mobileNumber: mobileNumber,
      deviceId: deviceId,
    );
  }

  /// Called only after the user explicitly confirms a reported device
  /// conflict (FR-014) — see `LoginViewModel.confirmDeviceConflict`.
  Future<ConfirmTakeoverResult> confirmTakeover(String mobileNumber) async {
    final deviceId = await currentDeviceId();
    return _authService.confirmTakeover(
      mobileNumber: mobileNumber,
      deviceId: deviceId,
    );
  }

  // --- New/untrusted-device OTP (US3, FR-005, FR-016, FR-017, FR-018) ---

  Future<LoginOtpResult> requestLoginOtp({
    required String accountId,
    required String deviceId,
  }) {
    return _authService.requestLoginOtp(
      accountId: accountId,
      deviceId: deviceId,
    );
  }

  Future<OtpVerifyResult> verifyLoginOtp({
    required String accountId,
    required String deviceId,
    required String code,
  }) {
    return _authService.verifyLoginOtp(
      accountId: accountId,
      deviceId: deviceId,
      code: code,
    );
  }

  // --- Rebinding (US4/US5/US6, FR-016–FR-018, FR-022–FR-024, FR-041, FR-042) ---

  Future<RebindingAuthorizationResult> checkRebindingAuthorization({
    required String accountId,
    required String deviceId,
  }) {
    return _authService.checkRebindingAuthorization(
      accountId: accountId,
      deviceId: deviceId,
    );
  }

  Future<RebindResult> completeRebinding({
    required String accountId,
    required String deviceId,
  }) {
    return _authService.completeRebinding(
      accountId: accountId,
      deviceId: deviceId,
    );
  }

  // --- Session (US8, FR-030–FR-034) ---

  /// Called from the success path of registration, trusted login, and
  /// rebinding — writes a local [Session] record only if [keepSignedIn]
  /// was selected (FR-030, FR-031).
  Future<void> persistSessionIfRequested({
    required String accountId,
    required bool keepSignedIn,
  }) async {
    if (!keepSignedIn) return;
    final deviceId = await currentDeviceId();
    await _sessionStore.save(
      Session(
        accountId: accountId,
        deviceInstallationUuid: deviceId,
        keepSignedIn: true,
        createdAt: DateTime.now(),
      ),
    );
  }

  /// On app start: restores authenticated state only if a session exists
  /// AND the current device is still confirmed `active` for that account
  /// (FR-033). Never trusts the local record alone.
  Future<RestoreResult> restoreSession() async {
    final session = await _sessionStore.read();
    if (session == null || !session.keepSignedIn) {
      return const RestoreResult(SessionRestoreOutcome.noSession);
    }
    final statusResult = await _authService.getDeviceBindingStatus(
      accountId: session.accountId,
      deviceId: session.deviceInstallationUuid,
    );
    if (statusResult.status != DeviceBindingStatus.active) {
      await _sessionStore.clear();
      return const RestoreResult(SessionRestoreOutcome.deviceNoLongerActive);
    }
    return RestoreResult(
      SessionRestoreOutcome.restored,
      accountId: session.accountId,
    );
  }

  // --- Logout (US9, FR-035, FR-036) ---

  /// Ends the local session only. Never calls [AuthService] — logout must
  /// never revoke or unbind the device (FR-036).
  Future<void> logout() => _sessionStore.clear();
}
