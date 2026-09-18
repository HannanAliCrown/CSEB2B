import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/session.dart';

/// Local-only "Keep Me Signed In" session persistence boundary
/// (data-model.md `Session`; FR-027–FR-029, FR-044). Never touches
/// PostgreSQL — the session record itself has no authority;
/// [AuthRepository] always re-validates it against current device-binding
/// state before restoring authenticated state (FR-030).
///
/// An interface (mirroring [AuthService]'s pattern) so tests can supply
/// an in-memory fake instead of touching the `flutter_secure_storage`
/// plugin (constitution Principle VII).
abstract interface class SessionStore {
  Future<void> save(Session session);
  Future<Session?> read();
  Future<void> clear();
}

/// The real [SessionStore]. No `expiresAt` field is stored, matching the
/// session-expiration Open Question in spec.md.
class SecureSessionStore implements SessionStore {
  SecureSessionStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _key = 'auth.session';

  final FlutterSecureStorage _storage;

  @override
  Future<void> save(Session session) async {
    await _storage.write(key: _key, value: jsonEncode(session.toJson()));
  }

  @override
  Future<Session?> read() async {
    final raw = await _storage.read(key: _key);
    if (raw == null) return null;
    return Session.fromJson(jsonDecode(raw) as Map<String, Object?>);
  }

  @override
  Future<void> clear() async {
    await _storage.delete(key: _key);
  }
}
