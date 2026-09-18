import 'package:cse_b2b/features/onboarding/data/services/permission_service.dart';

/// Answers the first-launch permission prompts without touching the platform.
class FakePermissionService implements PermissionService {
  FakePermissionService({
    this.notifications = PermissionOutcome.granted,
    this.location = PermissionOutcome.granted,
  });

  PermissionOutcome notifications;
  PermissionOutcome location;
  int settingsOpened = 0;
  final List<String> calls = [];

  @override
  Future<PermissionOutcome> requestNotifications() async {
    calls.add('notifications');
    return notifications;
  }

  @override
  Future<PermissionOutcome> requestLocation() async {
    calls.add('location');
    return location;
  }

  @override
  Future<void> openSettings() async => settingsOpened++;
}
