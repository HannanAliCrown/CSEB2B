// Constructor parameters are named for their public API rather than the
// private fields they populate, so the initializing-formal shorthand the
// linter suggests is not available here.
// ignore_for_file: prefer_initializing_formals

import 'dart:convert';

import '../../../core/mock/partner_directory.dart';
import '../../../core/prefs/app_preferences.dart';
import 'session_service.dart';
import 'signed_in_user.dart';

/// Why a sign-in did not produce a session.
enum SignInFailure { unknownNumber, malformedNumber }

/// The outcome of a sign-in attempt: a user, or the reason there is none.
class SignInResult {
  const SignInResult.success(this.user) : failure = null;
  const SignInResult.failed(this.failure) : user = null;

  final SignedInUser? user;
  final SignInFailure? failure;

  bool get succeeded => user != null;
}

/// Who is signed in, and how they got there.
///
/// This is the boundary the rest of the app depends on: replacing the
/// directory lookup with an authentication API changes nothing above it.
class SessionRepository {
  SessionRepository({
    required AppPreferences preferences,
    SessionService? service,
  }) : _preferences = preferences,
       _service = service ?? const MockSessionService();

  final AppPreferences _preferences;

  /// Where "is this number anybody" is answered — the bundled directory, or
  /// the database behind the server.
  final SessionService _service;

  static const _key = 'session.user';

  /// Restores the session saved by "Keep me signed in", if there is one.
  Future<SignedInUser?> restore() async {
    final raw = await _preferences.readString(_key);
    if (raw == null) return null;
    try {
      return SignedInUser.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on FormatException {
      // A record we cannot read is no session at all.
      await _preferences.removeKey(_key);
      return null;
    }
  }

  Future<SignInResult> signIn(
    String mobileNumber, {
    required bool keepSignedIn,
  }) async {
    if (PartnerDirectory.normalise(mobileNumber).length != 10) {
      return const SignInResult.failed(SignInFailure.malformedNumber);
    }

    // An application still waiting on approval signs in too — to watch its
    // approvals, not to use the app. The service decides which this is.
    final user = await _service.findPartner(mobileNumber);
    if (user == null) {
      return const SignInResult.failed(SignInFailure.unknownNumber);
    }

    if (keepSignedIn) {
      await _preferences.writeString(_key, jsonEncode(user.toJson()));
    } else {
      await _preferences.removeKey(_key);
    }
    return SignInResult.success(user);
  }

  Future<void> signOut() => _preferences.removeKey(_key);
}
