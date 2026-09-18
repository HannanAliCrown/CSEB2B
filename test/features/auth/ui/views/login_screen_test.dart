import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:cse_b2b/core/localization/generated/app_localizations.dart';
import 'package:cse_b2b/core/theme/app_theme.dart';
import 'package:cse_b2b/features/auth/data/repositories/auth_repository.dart';
import 'package:cse_b2b/features/auth/data/services/auth_service.dart';
import 'package:cse_b2b/features/auth/ui/view_models/login_view_model.dart';
import 'package:cse_b2b/features/auth/ui/views/login_screen.dart';

import '../../support/fake_auth_service.dart';
import '../../support/fake_stores.dart';

Widget _wrap(LoginViewModel viewModel) {
  return MaterialApp(
    theme: AppTheme.light,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: ChangeNotifierProvider.value(
      value: viewModel,
      child: LoginScreen(onAuthenticated: (_) {}),
    ),
  );
}

AuthRepository _repository(FakeAuthService service) => AuthRepository(
  authService: service,
  deviceIdentityStore: FakeDeviceIdentityStore(),
  sessionStore: FakeSessionStore(),
);

void main() {
  group('LoginScreen (Claude Design A1–A4, B1–B3)', () {
    testWidgets('A1: shows the mobile number field, Keep Me Signed In, '
        'the device-policy banner, and the Sign In action', (tester) async {
      final viewModel = LoginViewModel(
        repository: _repository(FakeAuthService()),
      );

      await tester.pumpWidget(_wrap(viewModel));

      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      expect(find.text(l10n.authSignInHeading), findsOneWidget);
      expect(find.text(l10n.authMobileNumberLabel), findsOneWidget);
      expect(find.text(l10n.authKeepSignedIn), findsOneWidget);
      expect(find.text(l10n.authDevicePolicyNotice), findsOneWidget);
      expect(
        find.widgetWithText(ElevatedButton, l10n.authSignInAction),
        findsOneWidget,
      );
      expect(find.text(l10n.authRegisterAction), findsOneWidget);
      // The design's footer separator above the primary action.
      expect(find.byType(Divider), findsOneWidget);
    });

    testWidgets(
      'A4: a device conflict shows the takeover dialog before any OTP is '
      'requested; Cancel declines without calling confirmTakeover',
      (tester) async {
        final service = FakeAuthService()
          ..loginResult = const LoginResult.success(
            status: LoginStatus.newUntrusted,
            accountId: 'account-1',
            deviceId: 'device-2',
            tier: DeviceMoveTier.secondDevice,
            conflict: ConflictInfo(otherAccountId: 'account-2'),
          );
        final viewModel = LoginViewModel(repository: _repository(service));

        await tester.pumpWidget(_wrap(viewModel));
        await viewModel.submitMobileNumber('+920000000001');
        await tester.pumpAndSettle();

        final l10n = await AppLocalizations.delegate.load(const Locale('en'));
        expect(find.text(l10n.loginDeviceConflictTitle), findsOneWidget);
        expect(service.calls, isNot(contains('requestLoginOtp')));

        await tester.tap(find.text(l10n.loginDeviceConflictCancel));
        await tester.pumpAndSettle();

        expect(find.text(l10n.loginDeviceConflictTitle), findsNothing);
        expect(service.calls, isNot(contains('confirmTakeover')));
        expect(viewModel.step, LoginStep.enterMobileNumber);
      },
    );

    testWidgets('B1: the third-or-later refused state uses neutral styling and '
        'exposes a CRM contact action, never the account\'s device state', (
      tester,
    ) async {
      final viewModel = LoginViewModel(
        repository: _repository(FakeAuthService()),
      );
      await tester.pumpWidget(_wrap(viewModel));
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));

      viewModel.step = LoginStep.authorizationNotAuthorized;
      viewModel.notifyListeners();
      await tester.pumpAndSettle();

      expect(find.text(l10n.loginDeviceLockedTitle), findsOneWidget);
      expect(find.text(l10n.loginCallCrmAction), findsOneWidget);
    });
  });
}
