import 'package:flutter_test/flutter_test.dart';

import 'package:cse_b2b/core/prefs/app_preferences.dart';
import 'package:cse_b2b/features/onboarding/data/repositories/onboarding_repository.dart';
import 'package:cse_b2b/features/onboarding/data/services/permission_service.dart';
import 'package:cse_b2b/features/onboarding/ui/view_models/first_launch_view_model.dart';

/// Answers the permission prompts without touching the platform.
class _FakePermissionService implements PermissionService {
  _FakePermissionService({
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

({
  FirstLaunchViewModel model,
  InMemoryAppPreferences prefs,
  _FakePermissionService permissions,
})
_build({
  PermissionOutcome notifications = PermissionOutcome.granted,
  PermissionOutcome location = PermissionOutcome.granted,
  InMemoryAppPreferences? preferences,
}) {
  final prefs = preferences ?? InMemoryAppPreferences();
  final permissions = _FakePermissionService(
    notifications: notifications,
    location: location,
  );
  return (
    model: FirstLaunchViewModel(
      repository: OnboardingRepository(
        preferences: prefs,
        permissions: permissions,
      ),
    ),
    prefs: prefs,
    permissions: permissions,
  );
}

void main() {
  group('first launch', () {
    test(
      'FL-01 a fresh install runs notification → language → location',
      () async {
        final harness = _build();

        await harness.model.start();

        expect(harness.permissions.calls, contains('notifications'));
        expect(harness.model.step, FirstLaunchStep.language);

        await harness.model.confirmLanguage();
        expect(harness.model.step, FirstLaunchStep.locationEducation);

        await harness.model.allowLocation();
        expect(harness.model.step, FirstLaunchStep.complete);
        expect(await harness.prefs.isFirstLaunchComplete(), isTrue);
      },
    );

    test('FL-02 a denied notification still continues to language', () async {
      final harness = _build(notifications: PermissionOutcome.denied);

      await harness.model.start();

      expect(harness.model.notificationOutcome, PermissionOutcome.denied);
      expect(harness.model.step, FirstLaunchStep.language);
    });

    test(
      'FL-03 remembering the language skips the modal next launch',
      () async {
        final first = _build();
        await first.model.start();
        first.model.selectLanguage('ur');
        await first.model.confirmLanguage();
        await first.model.allowLocation();

        expect(await first.prefs.rememberedLanguage(), 'ur');

        final next = _build(preferences: first.prefs);
        await next.model.start();

        expect(next.model.step, FirstLaunchStep.complete);
        expect(next.model.selectedLanguage, 'ur');
        // The OS prompt is not repeated on a later launch.
        expect(next.permissions.calls, isEmpty);
      },
    );

    test('FL-04 leaving Remember unchecked asks again next launch', () async {
      final first = _build();
      await first.model.start();
      first.model.setRememberLanguage(remember: false);
      await first.model.confirmLanguage();
      await first.model.allowLocation();

      expect(await first.prefs.rememberedLanguage(), isNull);

      final next = _build(preferences: first.prefs);
      await next.model.start();

      expect(next.model.step, FirstLaunchStep.language);

      // Confirming it now completes the launch without redoing onboarding.
      await next.model.confirmLanguage();
      expect(next.model.step, FirstLaunchStep.complete);
    });

    test('FL-05 allowing location stores the phone position', () async {
      final harness = _build();
      await harness.model.start();
      await harness.model.confirmLanguage();

      await harness.model.allowLocation();

      expect(await harness.prefs.locationOutcome(), 'granted');
      expect(await harness.prefs.currentLocation(), isNotNull);
    });

    test(
      'FL-06 a denied location shows the switched-off screen, then continues',
      () async {
        final harness = _build(location: PermissionOutcome.denied);
        await harness.model.start();
        await harness.model.confirmLanguage();

        await harness.model.allowLocation();
        expect(harness.model.step, FirstLaunchStep.locationOff);
        expect(await harness.prefs.currentLocation(), isNull);

        await harness.model.continueWithoutLocation();
        expect(harness.model.step, FirstLaunchStep.complete);
      },
    );

    test('"Not now" skips location without capturing a position', () async {
      final harness = _build();
      await harness.model.start();
      await harness.model.confirmLanguage();

      await harness.model.skipLocation();

      expect(harness.permissions.calls, isNot(contains('location')));
      expect(await harness.prefs.currentLocation(), isNull);
      expect(harness.model.step, FirstLaunchStep.complete);
    });
  });
}
