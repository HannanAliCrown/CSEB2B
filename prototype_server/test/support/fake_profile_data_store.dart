import 'package:prototype_server/data/postgres_partner_data_store.dart'
    show normaliseMobile;
import 'package:prototype_server/data/profile_data_store.dart';

/// An in-memory [ProfileDataStore] enforcing the same rules the SQL does:
/// four digits, the current PIN needed to change or turn off one that
/// exists, and turning it off keeping it for later.
///
/// It stores the PIN in the clear because nothing here is persisted or
/// shared — the real store hashes it with pgcrypto and never reads it back.
class FakeProfileDataStore implements ProfileDataStore {
  final Map<String, _Account> _accounts = {};
  final List<({SupportContactRow contact, String audience})> _contacts = [];
  final Map<String, String> _info = {};

  var _nextId = 1;

  // --- Test setup ---

  void addAccount({required String mobileNumber, String role = 'installer'}) =>
      _accounts[normaliseMobile(mobileNumber)] = _Account(role);

  void addContact({
    required String label,
    required String phoneNumber,
    String audience = 'all',
    String? description,
  }) => _contacts.add((
    contact: SupportContactRow(
      id: 'c${_nextId++}',
      label: label,
      phoneNumber: phoneNumber,
      description: description,
    ),
    audience: audience,
  ));

  void addInfo(String key, String value) => _info[key] = value;

  /// What the store is holding, so a test can prove the PIN was actually
  /// changed rather than merely accepted.
  String? pinFor(String mobileNumber) =>
      _accounts[normaliseMobile(mobileNumber)]?.pin;

  // --- ProfileDataStore ---

  @override
  Future<ProfileSettingsRow?> settings(String mobileNumber) async {
    final account = _accounts[normaliseMobile(mobileNumber)];
    if (account == null) return null;
    return ProfileSettingsRow(
      languageCode: account.languageCode,
      languageRemembered: account.languageRemembered,
      theme: account.theme,
      pinSet: account.pin != null,
      pinEnabled: account.pin != null && account.pinEnabled,
    );
  }

  @override
  Future<ProfileSettingsRow?> updateSettings({
    required String mobileNumber,
    String? languageCode,
    bool? languageRemembered,
    String? theme,
  }) async {
    final account = _accounts[normaliseMobile(mobileNumber)];
    if (account == null) return null;

    // Only what was given; anything null is left alone.
    account.languageCode = languageCode ?? account.languageCode;
    account.languageRemembered =
        languageRemembered ?? account.languageRemembered;
    account.theme = theme ?? account.theme;
    return settings(mobileNumber);
  }

  @override
  Future<PinRefusal?> setPin({
    required String mobileNumber,
    required String pin,
    String? currentPin,
  }) async {
    if (!RegExp(r'^\d{4}$').hasMatch(pin)) return PinRefusal.malformed;

    final account = _accounts[normaliseMobile(mobileNumber)];
    if (account == null) return PinRefusal.unknownAccount;

    if (account.pin != null && currentPin != account.pin) {
      return PinRefusal.wrongPin;
    }
    account.pin = pin;
    account.pinEnabled = true;
    return null;
  }

  @override
  Future<bool> verifyPin({
    required String mobileNumber,
    required String pin,
  }) async {
    final account = _accounts[normaliseMobile(mobileNumber)];
    return account?.pin != null && account!.pin == pin;
  }

  @override
  Future<PinRefusal?> disablePin({
    required String mobileNumber,
    required String pin,
  }) async {
    final account = _accounts[normaliseMobile(mobileNumber)];
    if (account == null) return PinRefusal.unknownAccount;
    if (account.pin != pin) return PinRefusal.wrongPin;

    // Kept, so turning it back on need not ask for a new one.
    account.pinEnabled = false;
    return null;
  }

  @override
  Future<List<SupportContactRow>> supportContacts(String mobileNumber) async {
    final account = _accounts[normaliseMobile(mobileNumber)];
    return [
      for (final entry in _contacts)
        if (entry.audience == 'all' || entry.audience == account?.role)
          entry.contact,
    ];
  }

  @override
  Future<Map<String, String>> appInfo() async => Map.of(_info);
}

class _Account {
  _Account(this.role);

  final String role;
  String? languageCode;
  bool? languageRemembered;
  String? theme;
  String? pin;
  bool pinEnabled = false;
}
