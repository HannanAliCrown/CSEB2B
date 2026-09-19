// Constructor parameters are named for their public API rather than the
// private fields they populate, so the initializing-formal shorthand the
// linter suggests is not available here.
// ignore_for_file: prefer_initializing_formals

import 'dart:convert';

import '../../../core/mock/partner_directory.dart';
import '../../../core/mock/pending_registrations.dart';
import '../../../core/prefs/app_preferences.dart';
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
  SessionRepository({required AppPreferences preferences})
    : _preferences = preferences;

  final AppPreferences _preferences;

  static const _key = 'session.user';

  /// Simulated latency, so the sign-in button's loading state is exercised
  /// the way it will be against a real network.
  static const _latency = Duration(milliseconds: 250);

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
    await Future<void>.delayed(_latency);

    if (PartnerDirectory.normalise(mobileNumber).length != 10) {
      return const SignInResult.failed(SignInFailure.malformedNumber);
    }

    // An application submitted on this phone signs in too — to watch its
    // approvals, not to use the app.
    final pending = PendingRegistrations.find(mobileNumber);
    final account = PartnerDirectory.find(mobileNumber);
    if (pending == null && account == null) {
      return const SignInResult.failed(SignInFailure.unknownNumber);
    }

    final user = switch ((pending, account)) {
      // A submitted application, still waiting: signed in, but unapproved.
      (final p?, _) when !p.isApproved => SignedInUser.fromPending(p),
      // Approved, or an account that already existed.
      (_, final a?) => SignedInUser.fromAccount(a),
      (final p?, _) => SignedInUser.fromPending(p).copyWith(approved: true),
      _ => throw StateError('unreachable: no pending record and no account'),
    };
    if (keepSignedIn) {
      await _preferences.writeString(_key, jsonEncode(user.toJson()));
    } else {
      await _preferences.removeKey(_key);
    }
    return SignInResult.success(user);
  }

  Future<void> signOut() => _preferences.removeKey(_key);
}
