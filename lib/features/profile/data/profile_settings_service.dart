// Constructor parameters are named for their public API rather than the
// private fields they populate, so the initializing-formal shorthand the
// linter suggests is not available here.
// ignore_for_file: prefer_initializing_formals

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

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

/// Profile's data boundary, backed by the database behind
/// `prototype_server`.
///
/// There is deliberately no in-memory implementation. A setting that is only
/// remembered until the app restarts is worse than one that plainly fails,
/// so when the server cannot be reached these screens say so.
class ProfileSettingsService {
  ProfileSettingsService({required String baseUrl, http.Client? client})
    : _baseUrl = baseUrl,
      _client = client ?? http.Client();

  final String _baseUrl;
  final http.Client _client;

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

  /// Applies only what is given; anything left null stays as it was.
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

  /// Sets a PIN, or changes one. Changing needs [currentPin]; without it the
  /// server refuses, so a borrowed phone cannot lock its owner out.
  Future<PinFailure?> setPin({
    required String mobileNumber,
    required String pin,
    String? currentPin,
  }) => _pinCall('/profile/pin', {
    'mobileNumber': mobileNumber,
    'pin': pin,
    'currentPin': ?currentPin,
  });

  Future<PinFailure?> disablePin({
    required String mobileNumber,
    required String pin,
  }) => _pinCall('/profile/pin/disable', {
    'mobileNumber': mobileNumber,
    'pin': pin,
  });

  /// True when the PIN is right. A wrong PIN is an answer, not an error.
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

  /// The About copy. The version is not here — the installed binary knows
  /// its own, and a row on a server could disagree with what is running.
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

class MockProfileSettingsService extends ProfileSettingsService {
  MockProfileSettingsService() : super(baseUrl: '');

  final Map<String, ProfileSettings> _settings = {};
  final Map<String, String> _pins = {};

  @override
  Future<ProfileSettings?> read(String mobileNumber) async =>
      _settings[mobileNumber] ?? const ProfileSettings();

  @override
  Future<ProfileSettings?> update({
    required String mobileNumber,
    AppLanguage? language,
    bool? languageRemembered,
    ThemeMode? themeMode,
  }) async {
    final current = _settings[mobileNumber] ?? const ProfileSettings();
    final next = ProfileSettings(
      language: language ?? current.language,
      languageRemembered: languageRemembered ?? current.languageRemembered,
      themeMode: themeMode ?? current.themeMode,
      pinSet: current.pinSet,
      pinEnabled: current.pinEnabled,
    );
    _settings[mobileNumber] = next;
    return next;
  }

  @override
  Future<PinFailure?> setPin({
    required String mobileNumber,
    required String pin,
    String? currentPin,
  }) async {
    if (pin.length != 4 || int.tryParse(pin) == null) {
      return PinFailure.malformed;
    }
    final existing = _pins[mobileNumber];
    if (existing != null && existing != currentPin) return PinFailure.wrongPin;
    _pins[mobileNumber] = pin;
    final current = _settings[mobileNumber] ?? const ProfileSettings();
    _settings[mobileNumber] = ProfileSettings(
      language: current.language,
      languageRemembered: current.languageRemembered,
      themeMode: current.themeMode,
      pinSet: true,
      pinEnabled: true,
    );
    return null;
  }

  @override
  Future<PinFailure?> disablePin({
    required String mobileNumber,
    required String pin,
  }) async {
    if (_pins[mobileNumber] != pin) return PinFailure.wrongPin;
    final current = _settings[mobileNumber] ?? const ProfileSettings();
    _settings[mobileNumber] = ProfileSettings(
      language: current.language,
      languageRemembered: current.languageRemembered,
      themeMode: current.themeMode,
      pinSet: true,
      pinEnabled: false,
    );
    return null;
  }

  @override
  Future<bool> verifyPin({
    required String mobileNumber,
    required String pin,
  }) async => _pins[mobileNumber] == pin;

  @override
  Future<List<SupportContact>> supportContacts(String mobileNumber) async =>
      const [];

  @override
  Future<Map<String, String>> appInfo() async => const {};
}

/// Wraps a value in left-to-right marks.
///
/// Phone numbers and version strings read the same way in every language.
/// Without this, Urdu's right-to-left run reorders the space-separated groups
/// and `042 111 276 963` appears as `963 276 111 042`.
String ltrText(String value) => '‎$value‎';
