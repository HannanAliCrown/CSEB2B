import 'package:permission_handler/permission_handler.dart' as ph;

/// What the operating system told us after a permission prompt.
enum PermissionOutcome { granted, denied, permanentlyDenied, notRequested }

/// The boundary in front of the real OS permission prompts.
///
/// The notification and location prompts are the platform's own dialogs —
/// the app never draws an imitation of them. Tests supply a fake.
abstract interface class PermissionService {
  Future<PermissionOutcome> requestNotifications();
  Future<PermissionOutcome> requestLocation();

  /// Opens the OS settings page, for the "Location is switched off" state.
  Future<void> openSettings();
}

/// The real implementation, backed by `permission_handler`.
class DevicePermissionService implements PermissionService {
  const DevicePermissionService();

  @override
  Future<PermissionOutcome> requestNotifications() =>
      _request(ph.Permission.notification);

  @override
  Future<PermissionOutcome> requestLocation() =>
      _request(ph.Permission.locationWhenInUse);

  @override
  Future<void> openSettings() => ph.openAppSettings();

  Future<PermissionOutcome> _request(ph.Permission permission) async {
    final status = await permission.request();
    return switch (status) {
      ph.PermissionStatus.granted ||
      ph.PermissionStatus.limited ||
      ph.PermissionStatus.provisional => PermissionOutcome.granted,
      ph.PermissionStatus.permanentlyDenied ||
      ph.PermissionStatus.restricted => PermissionOutcome.permanentlyDenied,
      ph.PermissionStatus.denied => PermissionOutcome.denied,
    };
  }
}

/// Where the phone currently is. Separate from the shop pin the partner
/// places later in the registration wizard.
abstract interface class CurrentLocationSource {
  Future<({double latitude, double longitude})?> read();
}

/// The prototype's stand-in for a real positioning call: a fixed Lahore
/// coordinate, so the journey behaves the same on every run and on an
/// emulator with no location fix.
class MockCurrentLocationSource implements CurrentLocationSource {
  const MockCurrentLocationSource();

  @override
  Future<({double latitude, double longitude})?> read() async =>
      (latitude: 31.5204, longitude: 74.3587);
}
