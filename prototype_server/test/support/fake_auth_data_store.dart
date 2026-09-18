import 'package:prototype_server/data/auth_data_store.dart';
import 'package:prototype_server/data/models.dart';

/// In-memory [AuthDataStore] used by prototype_server's test suite so
/// `dart test` never requires a live PostgreSQL instance
/// (research.md "Testing approach"). Mirrors the same all-or-nothing
/// semantics as [PostgresAuthDataStore] for every operation that must be
/// atomic; the two partial-unique-index invariants are enforced here by
/// explicit checks instead of a database constraint, so tests validate the
/// same business behavior without a real database.
class FakeAuthDataStore implements AuthDataStore {
  final List<Account> accounts = [];
  final List<Device> devices = [];
  final List<BindingRecord> bindings = [];
  final List<OtpRecord> otpChallenges = [];
  final List<AuthorizationRecord> authorizations = [];

  int _idCounter = 0;
  String _nextId(String prefix) => '$prefix-${_idCounter++}';

  /// Test helper: seed an account directly (mirrors seed.sql).
  Account addAccount({required String mobileNumber, required String userType}) {
    final account = Account(
      id: _nextId('account'),
      mobileNumber: mobileNumber,
      userType: userType,
    );
    accounts.add(account);
    return account;
  }

  /// Test helper: directly set an authorization's status, simulating the
  /// one deliberate prototype exception (quickstart.md) where the
  /// external/CRM decision is poked directly rather than through an
  /// endpoint.
  void setAuthorizationStatus(
    String accountId,
    String deviceId,
    RebindingAuthorizationStatus status,
  ) {
    final record = authorizations.lastWhere(
      (a) => a.accountId == accountId && a.deviceId == deviceId,
    );
    record.status = status;
  }

  /// Test helper: read the current active binding for an account, if any.
  AccountDeviceBinding? activeBindingFor(String accountId) {
    try {
      final record = bindings.lastWhere(
        (b) => b.accountId == accountId && b.status == BindingStatus.active,
      );
      return record.toModel();
    } on StateError {
      return null;
    }
  }

  @override
  Future<Account?> findAccountByMobileNumber(String mobileNumber) async {
    try {
      return accounts.firstWhere((a) => a.mobileNumber == mobileNumber);
    } on StateError {
      return null;
    }
  }

  @override
  Future<Device> findOrCreateDevice(String installationUuid) async {
    try {
      return devices.firstWhere((d) => d.installationUuid == installationUuid);
    } on StateError {
      final device = Device(
        id: _nextId('device'),
        installationUuid: installationUuid,
      );
      devices.add(device);
      return device;
    }
  }

  @override
  Future<AccountDeviceBinding?> getActiveBindingForAccount(
    String accountId,
  ) async {
    return activeBindingFor(accountId);
  }

  @override
  Future<AccountDeviceBinding?> getActiveBindingForDevice(
    String deviceId,
  ) async {
    try {
      final record = bindings.lastWhere(
        (b) => b.deviceId == deviceId && b.status == BindingStatus.active,
      );
      return record.toModel();
    } on StateError {
      return null;
    }
  }

  /// Move count = number of `rebinding`-context bindings ever created for
  /// this account (spec.md "Device-Move Tiers"; data-model.md "Device-move
  /// tier is derived, not stored") — never a stored/cached value.
  int moveCountFor(String accountId) => bindings
      .where(
        (b) =>
            b.accountId == accountId && b.context == BindingContext.rebinding,
      )
      .length;

  @override
  Future<DeviceMoveTier> getDeviceMoveTier(String accountId) async {
    return moveCountFor(accountId) == 0
        ? DeviceMoveTier.secondDevice
        : DeviceMoveTier.thirdOrLater;
  }

  @override
  Future<DeviceBindingStatus> getDeviceBindingStatus({
    required String accountId,
    required String deviceId,
  }) async {
    final matches = bindings
        .where((b) => b.accountId == accountId && b.deviceId == deviceId)
        .toList();
    if (matches.isEmpty) return DeviceBindingStatus.newUntrusted;
    return matches.last.status == BindingStatus.active
        ? DeviceBindingStatus.active
        : DeviceBindingStatus.revoked;
  }

  @override
  Future<OtpChallenge> createOtpChallenge({
    required String accountId,
    required String deviceId,
    required OtpContext context,
  }) async {
    final record = OtpRecord(
      id: _nextId('otp'),
      accountId: accountId,
      deviceId: deviceId,
      context: context,
      code: '111111',
      verified: false,
    );
    otpChallenges.add(record);
    return record.toModel();
  }

  @override
  Future<RegistrationBindResult> verifyRegistrationOtpAndBind({
    required String accountId,
    required String deviceId,
    required String submittedCode,
  }) async {
    final challenge = _latestUnverified(
      accountId,
      deviceId,
      OtpContext.registration,
    );
    if (challenge == null) return RegistrationBindResult.notFound;
    if (challenge.code != submittedCode) {
      return RegistrationBindResult.invalidCode;
    }
    if (_hasActiveBinding(accountId: accountId) ||
        _hasActiveBinding(deviceId: deviceId)) {
      // Mirrors the partial unique index: refuse rather than double-activate.
      return RegistrationBindResult.persistenceFailed;
    }
    challenge.verified = true;
    bindings.add(
      BindingRecord(
        id: _nextId('binding'),
        accountId: accountId,
        deviceId: deviceId,
        status: BindingStatus.active,
        context: BindingContext.initialRegistration,
      ),
    );
    return RegistrationBindResult.activated;
  }

  @override
  Future<OtpVerifyResult> verifyLoginOtp({
    required String accountId,
    required String deviceId,
    required String submittedCode,
  }) async {
    final challenge = _latestUnverified(
      accountId,
      deviceId,
      OtpContext.newDeviceLogin,
    );
    if (challenge == null) return OtpVerifyResult.notFound;
    if (challenge.code != submittedCode) return OtpVerifyResult.invalidCode;
    challenge.verified = true;
    return OtpVerifyResult.verified;
  }

  @override
  Future<RebindingAuthorization> getOrCreateRebindingAuthorization({
    required String accountId,
    required String deviceId,
  }) async {
    final existing = authorizations
        .where((a) => a.accountId == accountId && a.deviceId == deviceId)
        .toList();
    if (existing.isNotEmpty) return existing.last.toModel();
    final record = AuthorizationRecord(
      id: _nextId('auth'),
      accountId: accountId,
      deviceId: deviceId,
      status: RebindingAuthorizationStatus.pending,
    );
    authorizations.add(record);
    return record.toModel();
  }

  @override
  Future<RebindResult> completeRebinding({
    required String accountId,
    required String deviceId,
  }) async {
    final otpVerified = otpChallenges.any(
      (o) =>
          o.accountId == accountId &&
          o.deviceId == deviceId &&
          o.context == OtpContext.newDeviceLogin &&
          o.verified,
    );
    if (!otpVerified) return RebindResult.otpNotVerified;

    // Second-device tier (moveCount == 0) never consults authorizations at
    // all (FR-016); third-or-later tier (FR-017, FR-018) re-checks it here.
    if (moveCountFor(accountId) > 0) {
      final authMatches = authorizations
          .where((a) => a.accountId == accountId && a.deviceId == deviceId)
          .toList();
      if (authMatches.isEmpty ||
          authMatches.last.status != RebindingAuthorizationStatus.authorized) {
        return RebindResult.notAuthorized;
      }
    }

    for (final b in bindings) {
      if (b.accountId == accountId && b.status == BindingStatus.active) {
        b.status = BindingStatus.revoked;
      }
      if (b.deviceId == deviceId &&
          b.accountId != accountId &&
          b.status == BindingStatus.active) {
        b.status = BindingStatus.revoked;
      }
    }
    bindings.add(
      BindingRecord(
        id: _nextId('binding'),
        accountId: accountId,
        deviceId: deviceId,
        status: BindingStatus.active,
        context: BindingContext.rebinding,
      ),
    );
    return RebindResult.activated;
  }

  OtpRecord? _latestUnverified(
    String accountId,
    String deviceId,
    OtpContext context,
  ) {
    final matches = otpChallenges.where(
      (o) =>
          o.accountId == accountId &&
          o.deviceId == deviceId &&
          o.context == context &&
          !o.verified,
    );
    return matches.isEmpty ? null : matches.last;
  }

  bool _hasActiveBinding({String? accountId, String? deviceId}) {
    return bindings.any(
      (b) =>
          b.status == BindingStatus.active &&
          (accountId == null || b.accountId == accountId) &&
          (deviceId == null || b.deviceId == deviceId),
    );
  }
}

class BindingRecord {
  BindingRecord({
    required this.id,
    required this.accountId,
    required this.deviceId,
    required this.status,
    required this.context,
  });

  final String id;
  final String accountId;
  final String deviceId;
  BindingStatus status;
  final BindingContext context;

  AccountDeviceBinding toModel() => AccountDeviceBinding(
    id: id,
    accountId: accountId,
    deviceId: deviceId,
    status: status,
  );
}

class OtpRecord {
  OtpRecord({
    required this.id,
    required this.accountId,
    required this.deviceId,
    required this.context,
    required this.code,
    required this.verified,
  });

  final String id;
  final String accountId;
  final String deviceId;
  final OtpContext context;
  final String code;
  bool verified;

  OtpChallenge toModel() => OtpChallenge(
    id: id,
    accountId: accountId,
    deviceId: deviceId,
    context: context,
    code: code,
    verified: verified,
  );
}

class AuthorizationRecord {
  AuthorizationRecord({
    required this.id,
    required this.accountId,
    required this.deviceId,
    required this.status,
  });

  final String id;
  final String accountId;
  final String deviceId;
  RebindingAuthorizationStatus status;

  RebindingAuthorization toModel() => RebindingAuthorization(
    id: id,
    accountId: accountId,
    deviceId: deviceId,
    status: status,
  );
}
