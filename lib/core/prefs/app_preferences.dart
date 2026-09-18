import 'package:shared_preferences/shared_preferences.dart';

/// Small, non-sensitive preferences the app needs before anything else can
/// run: whether first-launch onboarding has completed, the remembered
/// language, and the outcome of the two first-launch permission prompts.
///
/// An interface (mirroring `SessionStore`) so tests and the prototype can
/// supply an in-memory implementation instead of touching platform storage.
abstract interface class AppPreferences {
  Future<bool> isFirstLaunchComplete();
  Future<void> setFirstLaunchComplete({required bool complete});

  /// The language the partner asked us to remember, or null when they left
  /// "Remember my choice" unchecked — in which case the language modal is
  /// shown again on every launch.
  Future<String?> rememberedLanguage();
  Future<void> setRememberedLanguage(String? languageCode);

  Future<String?> notificationOutcome();
  Future<void> setNotificationOutcome(String outcome);

  Future<String?> locationOutcome();
  Future<void> setLocationOutcome(String outcome);

  /// The phone's own location, captured once during first launch. It is not
  /// the shop's location — the shop pin is placed separately in the
  /// registration wizard.
  Future<({double latitude, double longitude})?> currentLocation();
  Future<void> setCurrentLocation(double latitude, double longitude);

  /// Development support: restores the deterministic starting state.
  Future<void> clear();
}

/// The real implementation, backed by `shared_preferences`.
class SharedAppPreferences implements AppPreferences {
  SharedAppPreferences({SharedPreferencesAsync? prefs})
    : _prefs = prefs ?? SharedPreferencesAsync();

  static const _firstLaunch = 'app.first_launch_complete';
  static const _language = 'app.remembered_language';
  static const _notification = 'app.notification_outcome';
  static const _location = 'app.location_outcome';
  static const _latitude = 'app.current_latitude';
  static const _longitude = 'app.current_longitude';

  final SharedPreferencesAsync _prefs;

  @override
  Future<bool> isFirstLaunchComplete() async =>
      await _prefs.getBool(_firstLaunch) ?? false;

  @override
  Future<void> setFirstLaunchComplete({required bool complete}) =>
      _prefs.setBool(_firstLaunch, complete);

  @override
  Future<String?> rememberedLanguage() => _prefs.getString(_language);

  @override
  Future<void> setRememberedLanguage(String? languageCode) async {
    if (languageCode == null) {
      await _prefs.remove(_language);
      return;
    }
    await _prefs.setString(_language, languageCode);
  }

  @override
  Future<String?> notificationOutcome() => _prefs.getString(_notification);

  @override
  Future<void> setNotificationOutcome(String outcome) =>
      _prefs.setString(_notification, outcome);

  @override
  Future<String?> locationOutcome() => _prefs.getString(_location);

  @override
  Future<void> setLocationOutcome(String outcome) =>
      _prefs.setString(_location, outcome);

  @override
  Future<({double latitude, double longitude})?> currentLocation() async {
    final latitude = await _prefs.getDouble(_latitude);
    final longitude = await _prefs.getDouble(_longitude);
    if (latitude == null || longitude == null) return null;
    return (latitude: latitude, longitude: longitude);
  }

  @override
  Future<void> setCurrentLocation(double latitude, double longitude) async {
    await _prefs.setDouble(_latitude, latitude);
    await _prefs.setDouble(_longitude, longitude);
  }

  @override
  Future<void> clear() async {
    await _prefs.remove(_firstLaunch);
    await _prefs.remove(_language);
    await _prefs.remove(_notification);
    await _prefs.remove(_location);
    await _prefs.remove(_latitude);
    await _prefs.remove(_longitude);
  }
}

/// In-memory preferences for tests and for the prototype's reset support.
class InMemoryAppPreferences implements AppPreferences {
  final Map<String, Object?> _values = {};

  @override
  Future<bool> isFirstLaunchComplete() async =>
      _values['firstLaunch'] as bool? ?? false;

  @override
  Future<void> setFirstLaunchComplete({required bool complete}) async =>
      _values['firstLaunch'] = complete;

  @override
  Future<String?> rememberedLanguage() async => _values['language'] as String?;

  @override
  Future<void> setRememberedLanguage(String? languageCode) async {
    if (languageCode == null) {
      _values.remove('language');
      return;
    }
    _values['language'] = languageCode;
  }

  @override
  Future<String?> notificationOutcome() async =>
      _values['notification'] as String?;

  @override
  Future<void> setNotificationOutcome(String outcome) async =>
      _values['notification'] = outcome;

  @override
  Future<String?> locationOutcome() async => _values['location'] as String?;

  @override
  Future<void> setLocationOutcome(String outcome) async =>
      _values['location'] = outcome;

  @override
  Future<({double latitude, double longitude})?> currentLocation() async {
    final latitude = _values['latitude'] as double?;
    final longitude = _values['longitude'] as double?;
    if (latitude == null || longitude == null) return null;
    return (latitude: latitude, longitude: longitude);
  }

  @override
  Future<void> setCurrentLocation(double latitude, double longitude) async {
    _values['latitude'] = latitude;
    _values['longitude'] = longitude;
  }

  @override
  Future<void> clear() async => _values.clear();
}
