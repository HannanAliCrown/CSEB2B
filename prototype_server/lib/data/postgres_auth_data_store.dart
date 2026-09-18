import 'package:postgres/postgres.dart';

import '../db/postgres_client.dart';
import '../otp/otp_generator.dart';
import 'auth_data_store.dart';
import 'models.dart';

/// The [AuthDataStore] implementation backed by PostgreSQL. Alongside
/// `postgres_client.dart`, this is where the `postgres` package is used —
/// it is never imported by route handlers directly, and never by the
/// Flutter app (FR-035).
class PostgresAuthDataStore implements AuthDataStore {
  PostgresAuthDataStore(this._client);

  final PostgresClient _client;

  @override
  Future<Account?> findAccountByMobileNumber(String mobileNumber) async {
    final result = await _client.pool.execute(
      Sql.named(
        'SELECT id, mobile_number, user_type FROM accounts '
        'WHERE mobile_number = @mobileNumber',
      ),
      parameters: {'mobileNumber': mobileNumber},
    );
    if (result.isEmpty) return null;
    final row = result.first.toColumnMap();
    return Account(
      id: row['id'] as String,
      mobileNumber: row['mobile_number'] as String,
      userType: row['user_type'] as String,
    );
  }

  @override
  Future<Device> findOrCreateDevice(String installationUuid) async {
    final result = await _client.pool.execute(
      Sql.named(
        'INSERT INTO devices (installation_uuid) VALUES (@uuid) '
        'ON CONFLICT (installation_uuid) DO UPDATE SET updated_at = now() '
        'RETURNING id, installation_uuid',
      ),
      parameters: {'uuid': installationUuid},
    );
    final row = result.first.toColumnMap();
    return Device(
      id: row['id'] as String,
      installationUuid: row['installation_uuid'] as String,
    );
  }

  @override
  Future<AccountDeviceBinding?> getActiveBindingForAccount(
    String accountId,
  ) async {
    final result = await _client.pool.execute(
      Sql.named(
        'SELECT id, account_id, device_id, status FROM account_device_bindings '
        "WHERE account_id = @accountId AND status = 'active'",
      ),
      parameters: {'accountId': accountId},
    );
    if (result.isEmpty) return null;
    return _bindingFromRow(result.first.toColumnMap());
  }

  @override
  Future<AccountDeviceBinding?> getActiveBindingForDevice(
    String deviceId,
  ) async {
    final result = await _client.pool.execute(
      Sql.named(
        'SELECT id, account_id, device_id, status FROM account_device_bindings '
        "WHERE device_id = @deviceId AND status = 'active'",
      ),
      parameters: {'deviceId': deviceId},
    );
    if (result.isEmpty) return null;
    return _bindingFromRow(result.first.toColumnMap());
  }

  @override
  Future<DeviceMoveTier> getDeviceMoveTier(String accountId) async {
    final result = await _client.pool.execute(
      Sql.named(
        'SELECT count(*) AS move_count FROM account_device_bindings '
        "WHERE account_id = @accountId AND context = 'rebinding'",
      ),
      parameters: {'accountId': accountId},
    );
    final moveCount = (result.first.toColumnMap()['move_count'] as num).toInt();
    return moveCount == 0
        ? DeviceMoveTier.secondDevice
        : DeviceMoveTier.thirdOrLater;
  }

  @override
  Future<DeviceBindingStatus> getDeviceBindingStatus({
    required String accountId,
    required String deviceId,
  }) async {
    final result = await _client.pool.execute(
      Sql.named(
        'SELECT status FROM account_device_bindings '
        'WHERE account_id = @accountId AND device_id = @deviceId '
        'ORDER BY created_at DESC LIMIT 1',
      ),
      parameters: {'accountId': accountId, 'deviceId': deviceId},
    );
    if (result.isEmpty) return DeviceBindingStatus.newUntrusted;
    final status = result.first.toColumnMap()['status'] as String;
    return status == 'active'
        ? DeviceBindingStatus.active
        : DeviceBindingStatus.revoked;
  }

  @override
  Future<OtpChallenge> createOtpChallenge({
    required String accountId,
    required String deviceId,
    required OtpContext context,
  }) async {
    final code = generateOtpCode();
    final result = await _client.pool.execute(
      Sql.named(
        'INSERT INTO otp_challenges (account_id, device_id, context, code) '
        'VALUES (@accountId, @deviceId, @context, @code) '
        'RETURNING id, account_id, device_id, context, code, verified',
      ),
      parameters: {
        'accountId': accountId,
        'deviceId': deviceId,
        'context': _otpContextToDb(context),
        'code': code,
      },
    );
    return _otpChallengeFromRow(result.first.toColumnMap());
  }

  @override
  Future<RegistrationBindResult> verifyRegistrationOtpAndBind({
    required String accountId,
    required String deviceId,
    required String submittedCode,
  }) async {
    try {
      return await _client.pool.runTx((tx) async {
        final challengeResult = await tx.execute(
          Sql.named(
            'SELECT id, code FROM otp_challenges '
            'WHERE account_id = @accountId AND device_id = @deviceId '
            "AND context = 'registration' AND verified = false "
            'ORDER BY created_at DESC LIMIT 1 FOR UPDATE',
          ),
          parameters: {'accountId': accountId, 'deviceId': deviceId},
        );
        if (challengeResult.isEmpty) {
          return RegistrationBindResult.notFound;
        }
        final challengeRow = challengeResult.first.toColumnMap();
        if (challengeRow['code'] != submittedCode) {
          return RegistrationBindResult.invalidCode;
        }

        await tx.execute(
          Sql.named(
            'UPDATE otp_challenges SET verified = true, verified_at = now() '
            'WHERE id = @id',
          ),
          parameters: {'id': challengeRow['id']},
        );
        await tx.execute(
          Sql.named(
            'INSERT INTO account_device_bindings '
            "(account_id, device_id, status, context) "
            "VALUES (@accountId, @deviceId, 'active', 'initial_registration')",
          ),
          parameters: {'accountId': accountId, 'deviceId': deviceId},
        );
        return RegistrationBindResult.activated;
      });
    } on PgException {
      return RegistrationBindResult.persistenceFailed;
    }
  }

  @override
  Future<OtpVerifyResult> verifyLoginOtp({
    required String accountId,
    required String deviceId,
    required String submittedCode,
  }) async {
    return _client.pool.runTx((tx) async {
      final challengeResult = await tx.execute(
        Sql.named(
          'SELECT id, code FROM otp_challenges '
          'WHERE account_id = @accountId AND device_id = @deviceId '
          "AND context = 'new_device_login' AND verified = false "
          'ORDER BY created_at DESC LIMIT 1 FOR UPDATE',
        ),
        parameters: {'accountId': accountId, 'deviceId': deviceId},
      );
      if (challengeResult.isEmpty) return OtpVerifyResult.notFound;
      final challengeRow = challengeResult.first.toColumnMap();
      if (challengeRow['code'] != submittedCode) {
        return OtpVerifyResult.invalidCode;
      }
      await tx.execute(
        Sql.named(
          'UPDATE otp_challenges SET verified = true, verified_at = now() '
          'WHERE id = @id',
        ),
        parameters: {'id': challengeRow['id']},
      );
      return OtpVerifyResult.verified;
    });
  }

  @override
  Future<RebindingAuthorization> getOrCreateRebindingAuthorization({
    required String accountId,
    required String deviceId,
  }) async {
    final existing = await _client.pool.execute(
      Sql.named(
        'SELECT id, account_id, device_id, status FROM rebinding_authorizations '
        'WHERE account_id = @accountId AND device_id = @deviceId '
        'ORDER BY requested_at DESC LIMIT 1',
      ),
      parameters: {'accountId': accountId, 'deviceId': deviceId},
    );
    if (existing.isNotEmpty) {
      return _authorizationFromRow(existing.first.toColumnMap());
    }
    final created = await _client.pool.execute(
      Sql.named(
        'INSERT INTO rebinding_authorizations (account_id, device_id) '
        'VALUES (@accountId, @deviceId) '
        'RETURNING id, account_id, device_id, status',
      ),
      parameters: {'accountId': accountId, 'deviceId': deviceId},
    );
    return _authorizationFromRow(created.first.toColumnMap());
  }

  @override
  Future<RebindResult> completeRebinding({
    required String accountId,
    required String deviceId,
  }) async {
    try {
      return await _client.pool.runTx((tx) async {
        final otpResult = await tx.execute(
          Sql.named(
            'SELECT 1 FROM otp_challenges '
            'WHERE account_id = @accountId AND device_id = @deviceId '
            "AND context = 'new_device_login' AND verified = true "
            'LIMIT 1',
          ),
          parameters: {'accountId': accountId, 'deviceId': deviceId},
        );
        if (otpResult.isEmpty) return RebindResult.otpNotVerified;

        // Device-move tier (FR-015), computed BEFORE this move's own binding
        // row is inserted below, so it reflects moves completed prior to
        // this one only. Second-device tier (FR-016) never consults
        // rebinding_authorizations at all; third-or-later tier (FR-017,
        // FR-018) re-checks it here rather than trusting the caller.
        final tierResult = await tx.execute(
          Sql.named(
            'SELECT count(*) AS move_count FROM account_device_bindings '
            "WHERE account_id = @accountId AND context = 'rebinding'",
          ),
          parameters: {'accountId': accountId},
        );
        final moveCount = (tierResult.first.toColumnMap()['move_count'] as num)
            .toInt();

        if (moveCount > 0) {
          final authResult = await tx.execute(
            Sql.named(
              'SELECT status FROM rebinding_authorizations '
              'WHERE account_id = @accountId AND device_id = @deviceId '
              'ORDER BY requested_at DESC LIMIT 1',
            ),
            parameters: {'accountId': accountId, 'deviceId': deviceId},
          );
          if (authResult.isEmpty ||
              authResult.first.toColumnMap()['status'] != 'authorized') {
            return RebindResult.notAuthorized;
          }
        }

        // Revoke the requesting account's previous Active device, if any.
        await tx.execute(
          Sql.named(
            "UPDATE account_device_bindings SET status = 'revoked', "
            'revoked_at = now() '
            "WHERE account_id = @accountId AND status = 'active'",
          ),
          parameters: {'accountId': accountId},
        );

        // Device-conflict case: revoke any OTHER account's active binding
        // to this device (FR-021).
        await tx.execute(
          Sql.named(
            "UPDATE account_device_bindings SET status = 'revoked', "
            'revoked_at = now() '
            "WHERE device_id = @deviceId AND status = 'active' "
            'AND account_id != @accountId',
          ),
          parameters: {'deviceId': deviceId, 'accountId': accountId},
        );

        // Activate the requested device for the requesting account.
        await tx.execute(
          Sql.named(
            'INSERT INTO account_device_bindings '
            "(account_id, device_id, status, context) "
            "VALUES (@accountId, @deviceId, 'active', 'rebinding')",
          ),
          parameters: {'accountId': accountId, 'deviceId': deviceId},
        );

        return RebindResult.activated;
      });
    } on PgException {
      return RebindResult.persistenceFailed;
    }
  }

  AccountDeviceBinding _bindingFromRow(Map<String, dynamic> row) {
    return AccountDeviceBinding(
      id: row['id'] as String,
      accountId: row['account_id'] as String,
      deviceId: row['device_id'] as String,
      status: row['status'] == 'active'
          ? BindingStatus.active
          : BindingStatus.revoked,
    );
  }

  OtpChallenge _otpChallengeFromRow(Map<String, dynamic> row) {
    return OtpChallenge(
      id: row['id'] as String,
      accountId: row['account_id'] as String,
      deviceId: row['device_id'] as String,
      context: row['context'] == 'registration'
          ? OtpContext.registration
          : OtpContext.newDeviceLogin,
      code: row['code'] as String,
      verified: row['verified'] as bool,
    );
  }

  RebindingAuthorization _authorizationFromRow(Map<String, dynamic> row) {
    final status = switch (row['status']) {
      'authorized' => RebindingAuthorizationStatus.authorized,
      'not_authorized' => RebindingAuthorizationStatus.notAuthorized,
      _ => RebindingAuthorizationStatus.pending,
    };
    return RebindingAuthorization(
      id: row['id'] as String,
      accountId: row['account_id'] as String,
      deviceId: row['device_id'] as String,
      status: status,
    );
  }

  String _otpContextToDb(OtpContext context) => switch (context) {
    OtpContext.registration => 'registration',
    OtpContext.newDeviceLogin => 'new_device_login',
  };
}
