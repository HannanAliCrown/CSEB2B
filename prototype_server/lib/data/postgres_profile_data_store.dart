import 'package:postgres/postgres.dart';

import '../db/postgres_client.dart';
import 'postgres_partner_data_store.dart' show normaliseMobile;
import 'profile_data_store.dart';

/// The [ProfileDataStore] backed by PostgreSQL.
///
/// The PIN is hashed by the database, with pgcrypto's `crypt()`. It is never
/// written to a column in the clear, never returned, and never logged.
class PostgresProfileDataStore implements ProfileDataStore {
  PostgresProfileDataStore(this._client);

  final PostgresClient _client;

  /// Exactly four digits. Anything else is not a PIN this app sets.
  static final _fourDigits = RegExp(r'^\d{4}$');

  @override
  Future<ProfileSettingsRow?> settings(String mobileNumber) async {
    final result = await _client.pool.execute(
      Sql.named('''
        SELECT a.language_code, a.language_remembered, a.theme,
               p.account_id IS NOT NULL AS pin_set,
               COALESCE(p.enabled, false) AS pin_enabled
          FROM accounts a
          LEFT JOIN app_pins p ON p.account_id = a.id
         WHERE a.mobile_number = @number
      '''),
      parameters: {'number': normaliseMobile(mobileNumber)},
    );
    if (result.isEmpty) return null;

    final row = result.first.toColumnMap();
    return ProfileSettingsRow(
      languageCode: row['language_code'] as String?,
      languageRemembered: row['language_remembered'] as bool?,
      theme: row['theme'] as String?,
      pinSet: row['pin_set'] as bool,
      pinEnabled: row['pin_enabled'] as bool,
    );
  }

  @override
  Future<ProfileSettingsRow?> updateSettings({
    required String mobileNumber,
    String? languageCode,
    bool? languageRemembered,
    String? theme,
  }) async {
    // COALESCE so a screen that only sets the theme does not clear the
    // language chosen on another one.
    final updated = await _client.pool.execute(
      Sql.named('''
        UPDATE accounts SET
          language_code       = COALESCE(@languageCode, language_code),
          language_remembered = COALESCE(@languageRemembered, language_remembered),
          theme               = COALESCE(@theme, theme)
         WHERE mobile_number = @number
        RETURNING id
      '''),
      parameters: {
        'number': normaliseMobile(mobileNumber),
        'languageCode': languageCode,
        'languageRemembered': languageRemembered,
        'theme': theme,
      },
    );
    if (updated.isEmpty) return null;
    return settings(mobileNumber);
  }

  Future<String?> _accountId(String mobileNumber) async {
    final result = await _client.pool.execute(
      Sql.named('SELECT id FROM accounts WHERE mobile_number = @number'),
      parameters: {'number': normaliseMobile(mobileNumber)},
    );
    if (result.isEmpty) return null;
    return '${result.first.toColumnMap()['id']}';
  }

  /// True when this account has a PIN and [pin] matches it. The comparison
  /// happens in the database: crypt() re-hashes the attempt with the stored
  /// salt, so nothing readable travels back.
  Future<bool> _matches(String accountId, String pin) async {
    final result = await _client.pool.execute(
      Sql.named(
        'SELECT 1 FROM app_pins '
        'WHERE account_id = @accountId AND pin_hash = crypt(@pin, pin_hash)',
      ),
      parameters: {'accountId': accountId, 'pin': pin},
    );
    return result.isNotEmpty;
  }

  Future<bool> _hasPin(String accountId) async {
    final result = await _client.pool.execute(
      Sql.named('SELECT 1 FROM app_pins WHERE account_id = @accountId'),
      parameters: {'accountId': accountId},
    );
    return result.isNotEmpty;
  }

  @override
  Future<PinRefusal?> setPin({
    required String mobileNumber,
    required String pin,
    String? currentPin,
  }) async {
    if (!_fourDigits.hasMatch(pin)) return PinRefusal.malformed;

    final accountId = await _accountId(mobileNumber);
    if (accountId == null) return PinRefusal.unknownAccount;

    // Changing an existing PIN needs the old one. Without this, anyone
    // holding an unlocked phone could lock the owner out of their own app.
    if (await _hasPin(accountId)) {
      if (currentPin == null || !await _matches(accountId, currentPin)) {
        return PinRefusal.wrongPin;
      }
    }

    await _client.pool.execute(
      Sql.named('''
        INSERT INTO app_pins (account_id, pin_hash, enabled)
        VALUES (@accountId, crypt(@pin, gen_salt('bf')), true)
        ON CONFLICT (account_id) DO UPDATE
          SET pin_hash = EXCLUDED.pin_hash, enabled = true
      '''),
      parameters: {'accountId': accountId, 'pin': pin},
    );
    return null;
  }

  @override
  Future<bool> verifyPin({
    required String mobileNumber,
    required String pin,
  }) async {
    final accountId = await _accountId(mobileNumber);
    if (accountId == null) return false;
    return _matches(accountId, pin);
  }

  @override
  Future<PinRefusal?> disablePin({
    required String mobileNumber,
    required String pin,
  }) async {
    final accountId = await _accountId(mobileNumber);
    if (accountId == null) return PinRefusal.unknownAccount;
    if (!await _matches(accountId, pin)) return PinRefusal.wrongPin;

    // The row stays, so turning the PIN back on does not force a new one.
    await _client.pool.execute(
      Sql.named('UPDATE app_pins SET enabled = false WHERE account_id = @id'),
      parameters: {'id': accountId},
    );
    return null;
  }

  @override
  Future<List<SupportContactRow>> supportContacts(String mobileNumber) async {
    final result = await _client.pool.execute(
      Sql.named('''
        SELECT s.id, s.label, s.phone_number, s.description
          FROM support_contacts s
          LEFT JOIN accounts a ON a.mobile_number = @number
         WHERE s.active
           AND (s.audience = 'all' OR s.audience = a.user_type)
         ORDER BY s.position, s.label
      '''),
      parameters: {'number': normaliseMobile(mobileNumber)},
    );

    return [
      for (final row in result)
        SupportContactRow(
          id: '${row.toColumnMap()['id']}',
          label: row.toColumnMap()['label'] as String,
          phoneNumber: row.toColumnMap()['phone_number'] as String,
          description: row.toColumnMap()['description'] as String?,
        ),
    ];
  }

  @override
  Future<Map<String, String>> appInfo() async {
    final result = await _client.pool.execute(
      'SELECT key, value FROM app_info ORDER BY position, key',
    );
    return {
      for (final row in result)
        row.toColumnMap()['key'] as String:
            row.toColumnMap()['value'] as String,
    };
  }
}
