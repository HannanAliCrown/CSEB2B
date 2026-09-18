// Constructor parameters are named for their public API rather than the
// private fields they populate, so the initializing-formal shorthand the
// linter suggests is not available here.
// ignore_for_file: prefer_initializing_formals

import 'package:flutter/foundation.dart';

import '../../data/repositories/onboarding_repository.dart';
import '../../data/services/permission_service.dart';

/// The first-launch journey, in the order the design lays it out:
/// notification permission → language → current location → Login.
enum FirstLaunchStep {
  /// Reading persisted state; the brand splash is on screen.
  starting,

  /// The OS notification dialog is up, over the splash.
  requestingNotifications,

  /// The Select Language modal (shown on every launch until the partner
  /// asks us to remember their choice).
  language,

  /// The "Allow location access" education screen.
  locationEducation,

  /// The OS location dialog is up.
  requestingLocation,

  /// "Location is switched off" — the partner can open Settings or carry on.
  locationOff,

  /// Onboarding is done; the app moves to Login.
  complete,
}

/// Drives the existing first-launch screens. It holds no layout and no copy:
/// each step names an existing screen, and the screen reports user intent
/// back through the methods below.
class FirstLaunchViewModel extends ChangeNotifier {
  FirstLaunchViewModel({required OnboardingRepository repository})
    : _repository = repository;

  final OnboardingRepository _repository;

  FirstLaunchStep step = FirstLaunchStep.starting;

  /// The language currently selected in the modal. English is preselected,
  /// matching the design.
  String selectedLanguage = 'en';

  /// "Remember my choice" is checked by default, per the design.
  bool rememberLanguage = true;

  PermissionOutcome notificationOutcome = PermissionOutcome.notRequested;
  PermissionOutcome locationOutcome = PermissionOutcome.notRequested;

  /// Decides where this launch starts: a returning partner with a remembered
  /// language skips straight to Login, one without it sees only the language
  /// modal, and a fresh install runs the whole journey.
  Future<void> start() async {
    final state = await _repository.read();

    if (state.firstLaunchComplete) {
      if (state.rememberedLanguage != null) {
        selectedLanguage = state.rememberedLanguage!;
        _setStep(FirstLaunchStep.complete);
        return;
      }
      _setStep(FirstLaunchStep.language);
      return;
    }

    await _requestNotifications();
  }

  Future<void> _requestNotifications() async {
    _setStep(FirstLaunchStep.requestingNotifications);
    notificationOutcome = await _repository.requestNotifications();
    // Either answer continues the journey — a denial never blocks the app.
    _setStep(FirstLaunchStep.language);
  }

  void selectLanguage(String languageCode) {
    selectedLanguage = languageCode;
    notifyListeners();
  }

  void setRememberLanguage({required bool remember}) {
    rememberLanguage = remember;
    notifyListeners();
  }

  /// Confirm applies the language for this session immediately and persists
  /// it only when "Remember my choice" is checked.
  Future<void> confirmLanguage() async {
    await _repository.applyLanguage(
      selectedLanguage,
      remember: rememberLanguage,
    );

    final state = await _repository.read();
    if (state.firstLaunchComplete) {
      // A returning partner only came back for the language modal.
      _setStep(FirstLaunchStep.complete);
      return;
    }
    _setStep(FirstLaunchStep.locationEducation);
  }

  Future<void> allowLocation() async {
    _setStep(FirstLaunchStep.requestingLocation);
    locationOutcome = await _repository.requestLocation();
    if (locationOutcome == PermissionOutcome.granted) {
      await _finish();
      return;
    }
    _setStep(FirstLaunchStep.locationOff);
  }

  /// "Not now" on the education screen: nothing is captured, and the journey
  /// continues to Login.
  Future<void> skipLocation() async {
    await _repository.skipLocation();
    locationOutcome = PermissionOutcome.denied;
    await _finish();
  }

  Future<void> openSystemSettings() => _repository.openSystemSettings();

  /// "Continue without location" from the switched-off state.
  Future<void> continueWithoutLocation() => _finish();

  Future<void> _finish() async {
    await _repository.completeFirstLaunch();
    _setStep(FirstLaunchStep.complete);
  }

  void _setStep(FirstLaunchStep next) {
    step = next;
    notifyListeners();
  }
}
