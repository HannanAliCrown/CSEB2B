import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cse_b2b/app/app.dart';
import 'package:cse_b2b/app/router/app_router.dart';
import 'package:cse_b2b/features/auth/data/repositories/auth_repository.dart';
import 'package:cse_b2b/features/auth/ui/views/login_screen.dart';

import '../features/auth/support/fake_auth_service.dart';
import '../features/auth/support/fake_stores.dart';

AuthRepository _fakeRepository() => AuthRepository(
  authService: FakeAuthService(),
  deviceIdentityStore: FakeDeviceIdentityStore(),
  sessionStore: FakeSessionStore(),
);

void main() {
  testWidgets('starts on the login screen when no session is persisted', (
    tester,
  ) async {
    final router = createAppRouter(authRepository: _fakeRepository());
    await tester.pumpWidget(CseApp(router: router));
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('falls back to the not-found screen for unknown routes', (
    tester,
  ) async {
    final router = createAppRouter(authRepository: _fakeRepository());
    await tester.pumpWidget(CseApp(router: router));
    await tester.pumpAndSettle();

    router.go('/route-that-does-not-exist');
    await tester.pumpAndSettle();

    expect(find.text('Page not found'), findsOneWidget);
  });

  testWidgets('renders Urdu right to left', (tester) async {
    tester.platformDispatcher.localesTestValue = const [Locale('ur')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);

    final router = createAppRouter(authRepository: _fakeRepository());
    await tester.pumpWidget(CseApp(router: router));
    await tester.pumpAndSettle();

    expect(
      Directionality.of(tester.element(find.byType(Scaffold))),
      TextDirection.rtl,
    );
  });

  testWidgets('renders Roman Urdu left to right', (tester) async {
    tester.platformDispatcher.localesTestValue = [
      Locale.fromSubtags(languageCode: 'ur', scriptCode: 'Latn'),
    ];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);

    final router = createAppRouter(authRepository: _fakeRepository());
    await tester.pumpWidget(CseApp(router: router));
    await tester.pumpAndSettle();

    expect(
      Directionality.of(tester.element(find.byType(Scaffold))),
      TextDirection.ltr,
    );
  });
}
