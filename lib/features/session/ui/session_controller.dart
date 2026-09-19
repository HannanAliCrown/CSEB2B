// Constructor parameters are named for their public API rather than the
// private fields they populate, so the initializing-formal shorthand the
// linter suggests is not available here.
// ignore_for_file: prefer_initializing_formals

import 'package:flutter/foundation.dart';

import '../data/session_repository.dart';
import '../data/signed_in_user.dart';

/// Holds the signed-in partner for the whole app.
///
/// Provided above the router, so Home, the wallet and the scanner all read
/// the same user rather than each carrying their own copy.
class SessionController extends ChangeNotifier {
  SessionController({required SessionRepository repository})
    : _repository = repository;

  final SessionRepository _repository;

  SignedInUser? user;
  bool busy = false;

  /// The reason the last sign-in attempt failed, cleared as soon as the
  /// number is edited.
  SignInFailure? failure;

  bool get isSignedIn => user != null;

  /// Restores "Keep me signed in" on launch.
  Future<void> restore() async {
    user = await _repository.restore();
    notifyListeners();
  }

  void clearFailure() {
    if (failure == null) return;
    failure = null;
    notifyListeners();
  }

  Future<bool> signIn(String mobileNumber, {required bool keepSignedIn}) async {
    busy = true;
    failure = null;
    notifyListeners();

    final result = await _repository.signIn(
      mobileNumber,
      keepSignedIn: keepSignedIn,
    );

    busy = false;
    user = result.user;
    failure = result.failure;
    notifyListeners();
    return result.succeeded;
  }

  Future<void> signOut() async {
    await _repository.signOut();
    user = null;
    notifyListeners();
  }
}
