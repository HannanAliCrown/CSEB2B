// ignore_for_file: prefer_initializing_formals
import 'package:flutter/foundation.dart';

import '../../data/repositories/auth_repository.dart';

/// Minimal authenticated-state ViewModel for User Story 9 (Logout).
/// Ends the local session only — never revokes or unbinds the device
/// (FR-032, FR-033).
class HomeViewModel extends ChangeNotifier {
  HomeViewModel({required AuthRepository repository})
    : _repository = repository;

  final AuthRepository _repository;

  bool _loggedOut = false;
  bool get loggedOut => _loggedOut;

  Future<void> logout() async {
    await _repository.logout();
    _loggedOut = true;
    notifyListeners();
  }
}
