import 'models.dart';

/// Outcome of [AuthDataStore.verifyRegistrationOtpAndBind] (FR-002, FR-003,
/// FR-043). Registration OTP verification and the initial device binding
/// commit together or not at all. [persistenceFailed] covers the case where
/// the OTP was valid but the binding insert itself failed (e.g. a
/// concurrent duplicate active binding) — the whole transaction rolls back,
/// including the OTP's `verified` flag, so no partial state is ever
/// observable.
enum RegistrationBindResult {
  activated,
  invalidCode,
  notFound,
  persistenceFailed,
}

/// Outcome of [AuthDataStore.verifyLoginOtp] (FR-020, FR-021). This only
/// ever marks a login-context OTP verified; it never touches device
/// bindings or rebinding authorization (that is a separate, later step,
/// possibly one that already happened earlier at the third-or-later tier).
enum OtpVerifyResult { verified, invalidCode, notFound }

/// Outcome of [AuthDataStore.completeRebinding] (FR-023, FR-024, FR-041,
/// FR-042). The store re-checks OTP-verified itself, and — only at the
/// third-or-later tier — authorization=authorized, rather than trusting
/// the caller.
enum RebindResult {
  activated,
  otpNotVerified,
  notAuthorized,
  persistenceFailed,
}

/// Data-access boundary between prototype_server's HTTP route handlers and
/// PostgreSQL. Route handlers depend on this interface, never on the
/// `postgres` package directly (see plan.md "Prototype server" structure).
///
/// [PostgresAuthDataStore] is the real implementation; tests use
/// `FakeAuthDataStore` (test/support/fake_auth_data_store.dart) so
/// `dart test` never requires a live database (research.md "Testing
/// approach").
abstract interface class AuthDataStore {
  Future<Account?> findAccountByMobileNumber(String mobileNumber);

  Future<Device> findOrCreateDevice(String installationUuid);

  Future<AccountDeviceBinding?> getActiveBindingForAccount(String accountId);

  /// Any account's current Active binding for [deviceId], regardless of
  /// which account holds it. Used to detect a device conflict (FR-013,
  /// FR-014) — this MUST be checked before any tier or OTP logic runs.
  /// Returns null if no active binding exists for this device at all.
  Future<AccountDeviceBinding?> getActiveBindingForDevice(String deviceId);

  /// The requesting account's device-move tier (spec.md "Device-Move
  /// Tiers"): [DeviceMoveTier.secondDevice] if it has completed zero prior
  /// `rebinding`-context moves since registration, else
  /// [DeviceMoveTier.thirdOrLater]. Computed fresh on every call from
  /// binding history — never cached, never a stored column (FR-015;
  /// data-model.md "Device-move tier is derived, not stored").
  Future<DeviceMoveTier> getDeviceMoveTier(String accountId);

  Future<DeviceBindingStatus> getDeviceBindingStatus({
    required String accountId,
    required String deviceId,
  });

  /// Creates and persists a new OTP challenge, returning its generated code
  /// (surfaced to the caller for prototype testability only — research.md
  /// "OTP simulation surfaced for prototype testability"; never a stand-in
  /// for real SMS delivery).
  Future<OtpChallenge> createOtpChallenge({
    required String accountId,
    required String deviceId,
    required OtpContext context,
  });

  /// Registration-context OTP verification, atomic with the resulting
  /// initial device binding (FR-002, FR-003, FR-043). Resolves the OTP
  /// failed-attempt question (FR-021): an
  /// [RegistrationBindResult.invalidCode] outcome leaves `verified = false`
  /// on the challenge and creates no binding row — no separate audit
  /// record.
  Future<RegistrationBindResult> verifyRegistrationOtpAndBind({
    required String accountId,
    required String deviceId,
    required String submittedCode,
  });

  /// Login-context OTP verification only (FR-020, FR-021). Never creates
  /// or modifies any `account_device_bindings` row, and never itself
  /// consults `rebinding_authorizations`.
  Future<OtpVerifyResult> verifyLoginOtp({
    required String accountId,
    required String deviceId,
    required String submittedCode,
  });

  /// Reads the current rebinding-authorization state for (account, device),
  /// creating a `pending` one if none exists yet (FR-017, FR-022). Never
  /// settable to authorized/not_authorized through this interface — that
  /// is the deliberate prototype-only exception documented in
  /// quickstart.md, applied directly against PostgreSQL, never through
  /// prototype_server (FR-028, FR-029). Only ever consulted by a route
  /// handler for a third-or-later-tier account/device pair (FR-016).
  Future<RebindingAuthorization> getOrCreateRebindingAuthorization({
    required String accountId,
    required String deviceId,
  });

  /// Atomically activates [deviceId] for [accountId], revokes
  /// [accountId]'s previous Active device, and — if [deviceId] was Active
  /// for a different account — revokes that binding too (FR-023, FR-024,
  /// FR-041, FR-042). Re-checks login-context OTP verified itself before
  /// writing anything, and — only at the third-or-later tier (FR-017,
  /// FR-018) — also re-checks authorization=authorized; a second-device-
  /// tier move (FR-016) never consults `rebinding_authorizations` at all
  /// (FR-042, FR-046: never trusts client-supplied call ordering or tier).
  Future<RebindResult> completeRebinding({
    required String accountId,
    required String deviceId,
  });
}
