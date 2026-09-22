// Constructor parameters are named for their public API rather than the
// private fields they populate, so the initializing-formal shorthand the
// linter suggests is not available here.
// ignore_for_file: prefer_initializing_formals

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../core/mock/partner_directory.dart';

/// The three languages the app offers.
enum AppLanguage { english, urdu, romanUrdu }

extension AppLanguageX on AppLanguage {
  /// What the database stores.
  String get code => switch (this) {
    AppLanguage.english => 'en',
    AppLanguage.urdu => 'ur',
    AppLanguage.romanUrdu => 'ur-Latn',
  };

  /// As the design lists it — each in its own script.
  String get label => switch (this) {
    AppLanguage.english => 'English',
    AppLanguage.urdu => 'اردو',
    AppLanguage.romanUrdu => 'Roman Urdu',
  };

  static AppLanguage? fromCode(String? code) => switch (code) {
    'en' => AppLanguage.english,
    'ur' => AppLanguage.urdu,
    'ur-Latn' => AppLanguage.romanUrdu,
    _ => null,
  };
}

/// What Profile knows about this partner's choices.
class ProfileSettings {
  const ProfileSettings({
    this.language,
    this.languageRemembered,
    this.themeMode = ThemeMode.system,
    this.pinSet = false,
    this.pinEnabled = false,
  });

  final AppLanguage? language;
  final bool? languageRemembered;
  final ThemeMode themeMode;

  /// Whether a PIN has ever been chosen. Turning the PIN off keeps it, so
  /// turning it back on need not ask for a new one.
  final bool pinSet;
  final bool pinEnabled;

  static ThemeMode _themeFrom(String? value) => switch (value) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.system,
  };

  static String themeCode(ThemeMode mode) => switch (mode) {
    ThemeMode.light => 'light',
    ThemeMode.dark => 'dark',
    ThemeMode.system => 'system',
  };

  static ProfileSettings fromJson(Map<String, dynamic> json) => ProfileSettings(
    language: AppLanguageX.fromCode(json['languageCode'] as String?),
    languageRemembered: json['languageRemembered'] as bool?,
    themeMode: _themeFrom(json['theme'] as String?),
    pinSet: json['pinSet'] == true,
    pinEnabled: json['pinEnabled'] == true,
  );
}

/// One number Call Support offers.
class SupportContact {
  const SupportContact({
    required this.label,
    required this.phoneNumber,
    this.description,
  });

  final String label;

  /// Dialled as written. The app opens the phone's dialler with it; it never
  /// places the call itself.
  final String phoneNumber;

  final String? description;
}

/// Why a PIN change was refused, in the words the screen shows.
enum PinFailure { wrongPin, malformed, unreachable }

extension PinFailureX on PinFailure {
  String get message => switch (this) {
    PinFailure.wrongPin => 'That PIN is not right. Try again.',
    PinFailure.malformed => 'A PIN is four digits.',
    PinFailure.unreachable =>
      'Could not reach Crown Solar. Check your connection and try again.',
  };
}

/// Profile's data boundary.
///
/// [HttpProfileSettingsService] reads the database behind `prototype_server`.
/// [MockProfileSettingsService] holds the same reference rows in memory, so a
/// build with no server running offers the same screens.
abstract interface class ProfileSettingsService {
  Future<ProfileSettings?> read(String mobileNumber);

  /// Applies only what is given; anything left null stays as it was.
  Future<ProfileSettings?> update({
    required String mobileNumber,
    AppLanguage? language,
    bool? languageRemembered,
    ThemeMode? themeMode,
  });

  /// Sets a PIN, or changes one. Changing needs [currentPin]; without it the
  /// change is refused, so a borrowed phone cannot lock its owner out.
  Future<PinFailure?> setPin({
    required String mobileNumber,
    required String pin,
    String? currentPin,
  });

  Future<PinFailure?> disablePin({
    required String mobileNumber,
    required String pin,
  });

  /// True when the PIN is right. A wrong PIN is an answer, not an error.
  Future<bool> verifyPin({required String mobileNumber, required String pin});

  Future<List<SupportContact>> supportContacts(String mobileNumber);

  /// The About copy. The version is not here — the installed binary knows
  /// its own, and a row on a server could disagree with what is running.
  Future<Map<String, String>> appInfo();
}

/// Profile's data boundary, backed by the database behind
/// `prototype_server`.
class HttpProfileSettingsService implements ProfileSettingsService {
  HttpProfileSettingsService({required String baseUrl, http.Client? client})
    : _baseUrl = baseUrl,
      _client = client ?? http.Client();

  final String _baseUrl;
  final http.Client _client;

  @override
  Future<ProfileSettings?> read(String mobileNumber) async {
    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/profile/settings')
            .replace(queryParameters: {'mobileNumber': mobileNumber}),
      );
      if (response.statusCode != 200) return null;
      return ProfileSettings.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } on Object {
      return null;
    }
  }

  @override
  Future<ProfileSettings?> update({
    required String mobileNumber,
    AppLanguage? language,
    bool? languageRemembered,
    ThemeMode? themeMode,
  }) async {
    final body = await _send('PUT', '/profile/settings', {
      'mobileNumber': mobileNumber,
      'languageCode': ?language?.code,
      'languageRemembered': ?languageRemembered,
      'theme': ?(themeMode == null
          ? null
          : ProfileSettings.themeCode(themeMode)),
    });
    if (body == null) return null;
    return ProfileSettings.fromJson(body);
  }

  @override
  Future<PinFailure?> setPin({
    required String mobileNumber,
    required String pin,
    String? currentPin,
  }) => _pinCall('/profile/pin', {
    'mobileNumber': mobileNumber,
    'pin': pin,
    'currentPin': ?currentPin,
  });

  @override
  Future<PinFailure?> disablePin({
    required String mobileNumber,
    required String pin,
  }) => _pinCall('/profile/pin/disable', {
    'mobileNumber': mobileNumber,
    'pin': pin,
  });

  @override
  Future<bool> verifyPin({
    required String mobileNumber,
    required String pin,
  }) async {
    final body = await _send('POST', '/profile/pin/verify', {
      'mobileNumber': mobileNumber,
      'pin': pin,
    });
    return body?['verified'] == true;
  }

  @override
  Future<List<SupportContact>> supportContacts(String mobileNumber) async {
    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/support/contacts')
            .replace(queryParameters: {'mobileNumber': mobileNumber}),
      );
      if (response.statusCode != 200) return const [];

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return [
        for (final entry in body['contacts'] as List? ?? const [])
          SupportContact(
            label: (entry as Map<String, dynamic>)['label'] as String,
            phoneNumber: entry['phoneNumber'] as String,
            description: entry['description'] as String?,
          ),
      ];
    } on Object {
      return const [];
    }
  }

  @override
  Future<Map<String, String>> appInfo() async {
    try {
      final response = await _client.get(Uri.parse('$_baseUrl/app/about'));
      if (response.statusCode != 200) return const {};
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return {
        for (final entry in (body['info'] as Map? ?? const {}).entries)
          '${entry.key}': '${entry.value}',
      };
    } on Object {
      return const {};
    }
  }

  Future<PinFailure?> _pinCall(String path, Map<String, Object?> body) async {
    final http.Response response;
    try {
      response = await _client.post(
        Uri.parse('$_baseUrl$path'),
        headers: const {'content-type': 'application/json'},
        body: jsonEncode(body),
      );
    } on Object {
      return PinFailure.unreachable;
    }

    return switch (response.statusCode) {
      200 => null,
      400 => PinFailure.malformed,
      403 => PinFailure.wrongPin,
      _ => PinFailure.unreachable,
    };
  }

  Future<Map<String, dynamic>?> _send(
    String method,
    String path,
    Map<String, Object?> body,
  ) async {
    try {
      final request = http.Request(method, Uri.parse('$_baseUrl$path'))
        ..headers['content-type'] = 'application/json'
        ..body = jsonEncode(body);
      final response = await http.Response.fromStream(
        await _client.send(request),
      );
      if (response.statusCode != 200) return null;
      return jsonDecode(response.body) as Map<String, dynamic>;
    } on Object {
      return null;
    }
  }
}

/// One partner's choices, as the `accounts` columns and the `app_pins` row
/// hold them.
class _Choices {
  AppLanguage? language;
  bool? languageRemembered;
  ThemeMode? themeMode;

  /// The PIN itself, which the database stores hashed. Here it never leaves
  /// the process, and it is gone when the process is.
  String? pin;
  bool pinEnabled = false;
}

/// One number Call Support offers, with the role it is offered to.
class _SeededContact {
  const _SeededContact({
    required this.label,
    required this.phoneNumber,
    required this.description,
    required this.audience,
  });

  final String label;
  final String phoneNumber;
  final String description;

  /// 'all', or the single `user_type` it is meant for.
  final String audience;
}

/// Profile's data boundary, held in memory.
///
/// The support numbers and About copy `db/seed/004_profile_settings.sql`
/// writes. No PIN is seeded, for the reason the seed gives: a PIN is
/// something a partner chooses, and inventing one would be a lock nobody set.
///
/// A choice made here lasts as long as the process does. The database-backed
/// service outlives a restart; this one cannot, which is what a build with no
/// database can offer.
class MockProfileSettingsService implements ProfileSettingsService {
  /// Keyed by the ten national digits, as the `accounts` rows are.
  final Map<String, _Choices> _choices = {};

  static const _contacts = <_SeededContact>[
    _SeededContact(
      label: 'Crown Solar Helpline',
      phoneNumber: '042 111 276 963',
      description: 'General help, 9 am to 6 pm, Monday to Saturday',
      audience: 'all',
    ),
    _SeededContact(
      label: 'CRM',
      phoneNumber: '042 111 276 964',
      description: 'Accounts, device changes and points adjustments',
      audience: 'all',
    ),
    _SeededContact(
      label: 'Technical Support',
      phoneNumber: '042 111 276 965',
      description: 'Product and installation questions',
      audience: 'all',
    ),
    _SeededContact(
      label: 'Shop Branding',
      phoneNumber: '042 111 276 966',
      description: 'Frontlit boards and shop branding requests',
      audience: 'retailer',
    ),
  ];

  static const _appInfo = <String, String>{
    'company': 'Crown Solar Energy (Pvt) Ltd',
    'address': 'Ravi Road, Lahore, Pakistan',
    'website': 'https://crownsolar.com.pk',
    'email': 'support@crownsolar.com.pk',
    'legal':
        'This app is for registered Crown Solar partners. Prices, schemes '
        'and prize amounts are set by Crown Solar and may change.',
  };

  /// Exactly four digits. Anything else is not a PIN this app sets.
  static final _fourDigits = RegExp(r'^\d{4}$');

  /// Null for a number no account answers to, as the query returns no row.
  _Choices? _for(String mobileNumber) {
    if (PartnerDirectory.find(mobileNumber) == null) return null;
    return _choices.putIfAbsent(
      PartnerDirectory.normalise(mobileNumber),
      _Choices.new,
    );
  }

  ProfileSettings _settingsFrom(_Choices choices) => ProfileSettings(
    language: choices.language,
    languageRemembered: choices.languageRemembered,
    themeMode: choices.themeMode ?? ThemeMode.system,
    pinSet: choices.pin != null,
    pinEnabled: choices.pinEnabled,
  );

  @override
  Future<ProfileSettings?> read(String mobileNumber) async {
    final choices = _for(mobileNumber);
    return choices == null ? null : _settingsFrom(choices);
  }

  @override
  Future<ProfileSettings?> update({
    required String mobileNumber,
    AppLanguage? language,
    bool? languageRemembered,
    ThemeMode? themeMode,
  }) async {
    final choices = _for(mobileNumber);
    if (choices == null) return null;

    // Only what was given, so a screen that sets the theme does not clear
    // the language chosen on another one.
    choices.language = language ?? choices.language;
    choices.languageRemembered =
        languageRemembered ?? choices.languageRemembered;
    choices.themeMode = themeMode ?? choices.themeMode;
    return _settingsFrom(choices);
  }

  @override
  Future<PinFailure?> setPin({
    required String mobileNumber,
    required String pin,
    String? currentPin,
  }) async {
    if (!_fourDigits.hasMatch(pin)) return PinFailure.malformed;

    final choices = _for(mobileNumber);
    if (choices == null) return PinFailure.unreachable;

    // Changing an existing PIN needs the old one. Without this, anyone
    // holding an unlocked phone could lock the owner out of their own app.
    if (choices.pin != null && currentPin != choices.pin) {
      return PinFailure.wrongPin;
    }

    choices.pin = pin;
    choices.pinEnabled = true;
    return null;
  }

  @override
  Future<bool> verifyPin({
    required String mobileNumber,
    required String pin,
  }) async {
    final choices = _for(mobileNumber);
    return choices?.pin != null && choices!.pin == pin;
  }

  @override
  Future<PinFailure?> disablePin({
    required String mobileNumber,
    required String pin,
  }) async {
    final choices = _for(mobileNumber);
    if (choices == null) return PinFailure.unreachable;
    if (choices.pin == null || choices.pin != pin) return PinFailure.wrongPin;

    // The PIN stays, so turning it back on does not force a new one.
    choices.pinEnabled = false;
    return null;
  }

  @override
  Future<List<SupportContact>> supportContacts(String mobileNumber) async {
    // A number no account answers to still gets the numbers offered to
    // everyone, as the outer join leaves the role null rather than dropping
    // the row.
    final role = PartnerDirectory.find(mobileNumber)?.role.toLowerCase();
    return [
      for (final contact in _contacts)
        if (contact.audience == 'all' || contact.audience == role)
          SupportContact(
            label: contact.label,
            phoneNumber: contact.phoneNumber,
            description: contact.description,
          ),
    ];
  }

  @override
  Future<Map<String, String>> appInfo() async => _appInfo;
}

/// Wraps a value in left-to-right marks.
///
/// Phone numbers and version strings read the same way in every language.
/// Without this, Urdu's right-to-left run reorders the space-separated groups
/// and `042 111 276 963` appears as `963 276 111 042`.
String ltrText(String value) => '‎$value‎';
