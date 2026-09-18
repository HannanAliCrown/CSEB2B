/// The `AuthService` boundary from
/// specs/001-login-auth-device-binding/contracts/auth-service.md.
///
/// `HttpAuthService` is the only implementation this feature ever needs —
/// it calls `prototype_server` now, and would call the production
/// ASP.NET Core API later, through the exact same interface (FR-037,
/// FR-038, FR-040). `AuthRepository` depends on this interface, never on
/// `http` or any server directly.
///
/// Every outcome below is a plain result value, never an exception, for
/// the business cases the spec defines (invalid OTP, not-yet-authorized,
/// etc.) — see contracts/auth-service.md "Error / outcome shape". Only
/// genuine infrastructure failure (the server is unreachable) throws.
library;

enum RegistrationOtpStatus { issued, accountNotFound, alreadyRegistered }

class RegistrationOtpResult {
  const RegistrationOtpResult.issued({
    required this.accountId,
    required this.deviceId,
    required this.prototypeCode,
  }) : status = RegistrationOtpStatus.issued;

  const RegistrationOtpResult.failure(this.status)
    : accountId = null,
      deviceId = null,
      prototypeCode = null;

  final RegistrationOtpStatus status;
  final String? accountId;
  final String? deviceId;

  /// Prototype-only: the real OTP would be delivered by SMS. Surfaced here
  /// purely so the flow is exercisable without a real phone
  /// (research.md "OTP simulation surfaced for prototype testability").
  final String? prototypeCode;
}

enum RegistrationVerifyStatus { activated, invalidCode, notFound, failed }

class RegistrationVerifyResult {
  const RegistrationVerifyResult(this.status);
  final RegistrationVerifyStatus status;
}

enum LoginStatus { trusted, newUntrusted, accountNotFound }

/// An account's device-move tier (spec.md "Device-Move Tiers"):
/// [secondDevice] — the account's first move since registration, gated by
/// login-context OTP alone; [thirdOrLater] — every move after that,
/// gated by CRM rebinding authorization *before* any OTP is requested.
/// Always reported by the server (`evaluateLogin`); never computed or
/// assumed client-side (FR-015, FR-046).
enum DeviceMoveTier { secondDevice, thirdOrLater }

/// Present on a New/Untrusted [LoginResult] when the requested device is
/// currently Active for a *different* account (FR-013). The UI must show
/// the takeover-confirmation step (Claude Design A4) and call
/// [AuthService.confirmTakeover] before any OTP is requested — regardless
/// of which [DeviceMoveTier] applies to the requesting account.
class ConflictInfo {
  const ConflictInfo({required this.otherAccountId});
  final String otherAccountId;
}

class LoginResult {
  const LoginResult.success({
    required this.status,
    this.accountId,
    this.deviceId,
    this.tier,
    this.conflict,
  });
  const LoginResult.accountNotFound()
    : status = LoginStatus.accountNotFound,
      accountId = null,
      deviceId = null,
      tier = null,
      conflict = null;

  final LoginStatus status;
  final String? accountId;
  final String? deviceId;

  /// Only meaningful when [status] is [LoginStatus.newUntrusted].
  final DeviceMoveTier? tier;

  /// Only meaningful when [status] is [LoginStatus.newUntrusted]; null
  /// means no conflict.
  final ConflictInfo? conflict;
}

/// Outcome of [AuthService.confirmTakeover] (FR-014). Writes nothing on
/// either side — it exists purely so the client has an explicit step to
/// call once the user confirms the A4 dialog, before requesting any OTP.
class ConfirmTakeoverResult {
  const ConfirmTakeoverResult({required this.acknowledged});
  final bool acknowledged;
}

/// Outcome of [AuthService.requestLoginOtp]. [notYetAuthorized] can only
/// happen at the [DeviceMoveTier.thirdOrLater] tier (FR-017) — the server
/// re-checks authorization itself rather than trusting that the client
/// already did (FR-046); `LoginViewModel`'s own tier branch is expected to
/// never reach this in practice, since it checks authorization first.
enum LoginOtpStatus { issued, notYetAuthorized }

class LoginOtpResult {
  const LoginOtpResult.issued({
    required this.challengeId,
    required this.prototypeCode,
  }) : status = LoginOtpStatus.issued;

  const LoginOtpResult.notYetAuthorized()
    : status = LoginOtpStatus.notYetAuthorized,
      challengeId = null,
      prototypeCode = null;

  final LoginOtpStatus status;
  final String? challengeId;
  final String? prototypeCode;
}

enum OtpVerifyStatus { verified, invalidCode, notFound }

class OtpVerifyResult {
  const OtpVerifyResult(this.status);
  final OtpVerifyStatus status;
}

enum RebindingAuthorizationStatus { pending, authorized, notAuthorized }

class RebindingAuthorizationResult {
  const RebindingAuthorizationResult(this.status);
  final RebindingAuthorizationStatus status;
}

enum RebindStatus { activated, otpNotVerified, notAuthorized, failed }

class RebindResult {
  const RebindResult(this.status);
  final RebindStatus status;
}

enum DeviceBindingStatus { active, revoked, newUntrusted }

class DeviceStatusResult {
  const DeviceStatusResult(this.status);
  final DeviceBindingStatus status;
}

abstract interface class AuthService {
  Future<RegistrationOtpResult> requestRegistrationOtp({
    required String mobileNumber,
    required String deviceId,
  });

  Future<RegistrationVerifyResult> verifyRegistrationOtp({
    required String accountId,
    required String deviceId,
    required String code,
  });

  Future<LoginResult> evaluateLogin({
    required String mobileNumber,
    required String deviceId,
  });

  /// Called only after the user explicitly confirms a reported
  /// [ConflictInfo] (FR-014); writes nothing itself. Never called at all
  /// when [LoginResult.conflict] was null.
  Future<ConfirmTakeoverResult> confirmTakeover({
    required String mobileNumber,
    required String deviceId,
  });

  Future<LoginOtpResult> requestLoginOtp({
    required String accountId,
    required String deviceId,
  });

  Future<OtpVerifyResult> verifyLoginOtp({
    required String accountId,
    required String deviceId,
    required String code,
  });

  Future<RebindingAuthorizationResult> checkRebindingAuthorization({
    required String accountId,
    required String deviceId,
  });

  Future<RebindResult> completeRebinding({
    required String accountId,
    required String deviceId,
  });

  /// Unlike the other methods here (where [deviceId] is the server's
  /// internal id, carried forward from a prior response in the same
  /// flow), this is a cold-start check — [deviceId] is this installation's
  /// own locally generated identifier (`DeviceIdentityStore`), since
  /// session restoration has no prior response to carry an internal id
  /// from. `prototype_server` resolves it internally either way.
  Future<DeviceStatusResult> getDeviceBindingStatus({
    required String accountId,
    required String deviceId,
  });
}
