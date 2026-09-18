import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/registration_draft.dart';

/// Keeps the unfinished application on the phone, so closing the app and
/// coming back offers "Continue your registration?" at the step it stopped
/// on.
abstract interface class RegistrationDraftStore {
  Future<RegistrationDraft?> read();
  Future<void> save(RegistrationDraft draft);
  Future<void> clear();
}

class SharedRegistrationDraftStore implements RegistrationDraftStore {
  SharedRegistrationDraftStore({SharedPreferencesAsync? prefs})
    : _prefs = prefs ?? SharedPreferencesAsync();

  static const _key = 'registration.draft';

  final SharedPreferencesAsync _prefs;

  @override
  Future<RegistrationDraft?> read() async {
    final raw = await _prefs.getString(_key);
    if (raw == null) return null;
    return RegistrationDraft.fromJson(jsonDecode(raw) as Map<String, Object?>);
  }

  @override
  Future<void> save(RegistrationDraft draft) =>
      _prefs.setString(_key, jsonEncode(draft.toJson()));

  @override
  Future<void> clear() => _prefs.remove(_key);
}

/// In-memory draft storage for tests.
class InMemoryRegistrationDraftStore implements RegistrationDraftStore {
  RegistrationDraft? _draft;

  @override
  Future<RegistrationDraft?> read() async => _draft;

  @override
  Future<void> save(RegistrationDraft draft) async => _draft = draft;

  @override
  Future<void> clear() async => _draft = null;
}
