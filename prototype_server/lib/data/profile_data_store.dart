/// What a partner has chosen, and whether the app asks for a PIN.
class ProfileSettingsRow {
  const ProfileSettingsRow({
    required this.languageCode,
    required this.languageRemembered,
    required this.theme,
    required this.pinSet,
    required this.pinEnabled,
  });

  /// 'en' | 'ur' | 'ur-Latn', or null when nothing has been chosen.
  final String? languageCode;
  final bool? languageRemembered;

  /// 'system' | 'light' | 'dark', or null for the app's default.
  final String? theme;

  /// Whether a PIN has ever been chosen. Distinct from [pinEnabled]: turning
  /// the PIN off keeps it, so turning it back on need not ask for a new one.
  final bool pinSet;
  final bool pinEnabled;

  Map<String, Object?> toJson() => {
    'languageCode': languageCode,
    'languageRemembered': languageRemembered,
    'theme': theme,
    'pinSet': pinSet,
    'pinEnabled': pinEnabled,
  };
}

/// One number Call Support offers.
class SupportContactRow {
  const SupportContactRow({
    required this.id,
    required this.label,
    required this.phoneNumber,
    this.description,
  });

  final String id;
  final String label;

  /// As it should be dialled. The app hands this to the phone's dialler and
  /// never places the call itself.
  final String phoneNumber;

  final String? description;

  Map<String, Object?> toJson() => {
    'id': id,
    'label': label,
    'phoneNumber': phoneNumber,
    'description': description,
  };
}

/// Why a PIN change was refused.
enum PinRefusal {
  /// The current PIN was wrong, or none was given when one was needed.
  wrongPin,

  /// Not four digits.
  malformed,

  /// No account on that number.
  unknownAccount,
}

/// Profile's persistence boundary.
///
/// The PIN never crosses this interface in a readable form on the way out —
/// only in, to be hashed or checked.
abstract interface class ProfileDataStore {
  Future<ProfileSettingsRow?> settings(String mobileNumber);

  /// Applies only the fields given; anything null is left as it was.
  Future<ProfileSettingsRow?> updateSettings({
    required String mobileNumber,
    String? languageCode,
    bool? languageRemembered,
    String? theme,
  });

  /// Sets or changes the PIN. When one already exists, [currentPin] must
  /// match it — otherwise anyone holding an unlocked phone could change it.
  Future<PinRefusal?> setPin({
    required String mobileNumber,
    required String pin,
    String? currentPin,
  });

  /// True when the PIN is correct. Used by the unlock screen.
  Future<bool> verifyPin({required String mobileNumber, required String pin});

  /// Turns the PIN off. Requires the current PIN, for the same reason
  /// changing it does.
  Future<PinRefusal?> disablePin({
    required String mobileNumber,
    required String pin,
  });

  /// Support numbers this partner's role should see, in order.
  Future<List<SupportContactRow>> supportContacts(String mobileNumber);

  /// The About copy, as key/value. The version is not here — the installed
  /// binary knows its own.
  Future<Map<String, String>> appInfo();
}
