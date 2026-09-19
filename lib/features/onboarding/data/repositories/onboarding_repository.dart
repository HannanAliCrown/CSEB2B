// Constructor parameters are named for their public API rather than the
// private fields they populate, so the initializing-formal shorthand the
// linter suggests is not available here.
// ignore_for_file: prefer_initializing_formals

import '../../../../core/prefs/app_preferences.dart';
import '../services/device_launch_service.dart';
import '../services/permission_service.dart';

/// What the app knows about first launch when it starts up.
class OnboardingState {
  const OnboardingState({
    required this.firstLaunchComplete,
    required this.rememberedLanguage,
  });

  final bool firstLaunchComplete;

  /// Null when the partner left "Remember my choice" unchecked, which means
  /// the language modal is shown again on this launch.
  final String? rememberedLanguage;
}

/// Everything the first-launch journey needs: the persisted onboarding
/// state, the two OS permission prompts, and the phone's own location.
///
/// The ViewModel talks to this; it never touches preferences or the
/// permission plugin directly, so a real backend or a different platform
/// integration can replace either side without the UI changing.
class OnboardingRepository {
  OnboardingRepository({
    required AppPreferences preferences,
    required PermissionService permissions,
    CurrentLocationSource? locationSource,
    DeviceLaunchService? launchService,
  }) : _preferences = preferences,
       _permissions = permissions,
       _locationSource = locationSource ?? const MockCurrentLocationSource(),
       _launch = launchService ?? const NoDeviceLaunchService();

  final AppPreferences _preferences;
  final PermissionService _permissions;
  final CurrentLocationSource _locationSource;

  /// Where first launch is reported. Best-effort by contract — see
  /// [DeviceLaunchService].
  final DeviceLaunchService _launch;

  Future<OnboardingState> read() async {
    return OnboardingState(
      firstLaunchComplete: await _preferences.isFirstLaunchComplete(),
      rememberedLanguage: await _preferences.rememberedLanguage(),
    );
  }

  /// Asks the OS for notification permission. Either answer lets the
  /// journey continue — a denial never blocks the app.
  Future<PermissionOutcome> requestNotifications() async {
    final outcome = await _permissions.requestNotifications();
    await _preferences.setNotificationOutcome(outcome.name);
    await _launch.record(notificationPermission: outcome.name);
    return outcome;
  }

  /// Applies the chosen language, and remembers it only when the partner
  /// asked us to. An unchecked box clears any previously remembered value,
  /// so the modal returns on the next launch.
  Future<void> applyLanguage(
    String languageCode, {
    required bool remember,
  }) async {
    await _preferences.setRememberedLanguage(remember ? languageCode : null);
    await _launch.record(
      languageCode: languageCode,
      languageRemembered: remember,
    );
  }

  /// Asks the OS for location permission and, when granted, captures the
  /// phone's current position. This is never used as the shop's pin.
  Future<PermissionOutcome> requestLocation() async {
    final outcome = await _permissions.requestLocation();
    await _preferences.setLocationOutcome(outcome.name);
    if (outcome == PermissionOutcome.granted) {
      final position = await _locationSource.read();
      if (position != null) {
        await _preferences.setCurrentLocation(
          position.latitude,
          position.longitude,
        );
      }
      await _launch.record(
        locationPermission: outcome.name,
        latitude: position?.latitude,
        longitude: position?.longitude,
      );
    } else {
      await _launch.record(locationPermission: outcome.name);
    }
    return outcome;
  }

  /// Records that the partner declined location for now. Registration still
  /// works; only the shop-pin step notices the difference.
  Future<void> skipLocation() async {
    await _preferences.setLocationOutcome(PermissionOutcome.denied.name);
    await _launch.record(locationPermission: PermissionOutcome.denied.name);
  }

  Future<void> openSystemSettings() => _permissions.openSettings();

  Future<void> completeFirstLaunch() async {
    await _preferences.setFirstLaunchComplete(complete: true);
    await _launch.record(firstLaunchComplete: true);
  }

  Future<({double latitude, double longitude})?> currentLocation() =>
      _preferences.currentLocation();

  /// Development support: puts first launch back to a fresh install.
  Future<void> reset() => _preferences.clear();
}
