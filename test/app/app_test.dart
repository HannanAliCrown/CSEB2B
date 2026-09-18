import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cse_b2b/app/app.dart';
import 'package:cse_b2b/app/router/app_router.dart';
import 'package:cse_b2b/core/prefs/app_preferences.dart';
import 'package:cse_b2b/features/auth/data/repositories/auth_repository.dart';
import 'package:cse_b2b/features/login/ui/views/sign_in_screen.dart';
import 'package:cse_b2b/features/registration/data/services/media_capture_service.dart';
import 'package:cse_b2b/features/registration/data/services/registration_draft_store.dart';
import 'package:cse_b2b/features/registration/ui/views/registration_flow_screen.dart';

import '../features/auth/support/fake_auth_service.dart';
import '../features/auth/support/fake_stores.dart';
import '../features/onboarding/support/fake_permission_service.dart';

AuthRepository _fakeRepository() => AuthRepository(
  authService: FakeAuthService(),
  deviceIdentityStore: FakeDeviceIdentityStore(),
  sessionStore: FakeSessionStore(),
);

/// A router whose first-launch and registration dependencies are all in
/// memory, so the app can be pumped without any platform plugin.
Future<GoRouterHarness> _harness({bool onboarded = true}) async {
  final preferences = InMemoryAppPreferences();
  if (onboarded) {
    await preferences.setFirstLaunchComplete(complete: true);
    await preferences.setRememberedLanguage('en');
  }
  return GoRouterHarness(
    preferences: preferences,
    router: createAppRouter(
      authRepository: _fakeRepository(),
      preferences: preferences,
      permissions: FakePermissionService(),
      registrationDraftStore: InMemoryRegistrationDraftStore(),
      mediaCapture: FakeMediaCaptureService(),
    ),
  );
}

class GoRouterHarness {
  const GoRouterHarness({required this.preferences, required this.router});
  final InMemoryAppPreferences preferences;
  final dynamic router;
}

void main() {
  testWidgets('a returning partner lands on the sign-in screen', (
    tester,
  ) async {
    final harness = await _harness();
    await tester.pumpWidget(CseApp(router: harness.router));
    await tester.pumpAndSettle();

    expect(find.byType(SignInScreen), findsOneWidget);
  });

  testWidgets('Register opens the registration wizard', (tester) async {
    final harness = await _harness();
    await tester.pumpWidget(CseApp(router: harness.router));
    await tester.pumpAndSettle();

    // "Register" is the emphasised span of the sign-in screen's one rich
    // line, so the whole line is what gets tapped.
    await tester.tap(find.textContaining('New to Crown Solar'));
    await tester.pumpAndSettle();

    expect(find.byType(RegistrationFlowScreen), findsOneWidget);
  });

  testWidgets('falls back to the not-found screen for unknown routes', (
    tester,
  ) async {
    final harness = await _harness();
    await tester.pumpWidget(CseApp(router: harness.router));
    await tester.pumpAndSettle();

    harness.router.go('/route-that-does-not-exist');
    await tester.pumpAndSettle();

    expect(find.text('Page not found'), findsOneWidget);
  });

  testWidgets('renders Urdu right to left', (tester) async {
    tester.platformDispatcher.localesTestValue = const [Locale('ur')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);

    final harness = await _harness();
    await tester.pumpWidget(CseApp(router: harness.router));
    await tester.pumpAndSettle();

    expect(
      Directionality.of(tester.element(find.byType(Scaffold).first)),
      TextDirection.rtl,
    );
  });

  testWidgets('renders Roman Urdu left to right', (tester) async {
    tester.platformDispatcher.localesTestValue = [
      Locale.fromSubtags(languageCode: 'ur', scriptCode: 'Latn'),
    ];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);

    final harness = await _harness();
    await tester.pumpWidget(CseApp(router: harness.router));
    await tester.pumpAndSettle();

    expect(
      Directionality.of(tester.element(find.byType(Scaffold).first)),
      TextDirection.ltr,
    );
  });
}
