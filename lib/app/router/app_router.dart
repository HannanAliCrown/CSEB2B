import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:cse_b2b/app/router/route_not_found_screen.dart';
import 'package:cse_b2b/features/auth/data/repositories/auth_repository.dart';
import 'package:cse_b2b/features/auth/data/services/device_identity_store.dart';
import 'package:cse_b2b/features/auth/data/services/http_auth_service.dart';
import 'package:cse_b2b/features/auth/data/services/session_store.dart';
import 'package:cse_b2b/features/auth/ui/view_models/home_view_model.dart';
import 'package:cse_b2b/features/auth/ui/view_models/login_view_model.dart';
import 'package:cse_b2b/features/auth/ui/view_models/registration_view_model.dart';
import 'package:cse_b2b/features/auth/ui/views/home_screen.dart';
import 'package:cse_b2b/features/auth/ui/views/login_screen.dart';
import 'package:cse_b2b/features/auth/ui/views/registration_screen.dart';
import 'package:cse_b2b/core/prefs/app_preferences.dart';
import 'package:cse_b2b/features/design_preview/preview_catalog.dart';
import 'package:cse_b2b/features/design_preview/preview_gallery_screen.dart';
import 'package:cse_b2b/features/login/ui/views/sign_in_screen.dart';
import 'package:cse_b2b/features/registration/data/repositories/registration_repository.dart';
import 'package:cse_b2b/features/registration/data/services/media_capture_service.dart';
import 'package:cse_b2b/features/registration/data/services/mock_registration_service.dart';
import 'package:cse_b2b/features/registration/data/services/registration_draft_store.dart';
import 'package:cse_b2b/features/registration/data/services/registration_service.dart';
import 'package:cse_b2b/features/registration/ui/view_models/registration_flow_view_model.dart';
import 'package:cse_b2b/features/registration/ui/views/registration_flow_screen.dart';
import 'package:cse_b2b/features/onboarding/data/repositories/onboarding_repository.dart';
import 'package:cse_b2b/features/onboarding/data/services/permission_service.dart';
import 'package:cse_b2b/features/onboarding/ui/view_models/first_launch_view_model.dart';
import 'package:cse_b2b/features/onboarding/ui/views/first_launch_flow_screen.dart';

/// Route paths, so callers never spell a location as a bare string.
abstract final class AppRoutes {
  /// First launch: notification permission, language, current location.
  static const firstLaunch = '/';
  static const login = '/login';

  /// The earlier spec-driven login screen, kept reachable while its
  /// device-binding logic is finished separately.
  static const legacyLogin = '/login/legacy';
  static const register = '/register';

  /// The earlier spec-driven registration screen.
  static const legacyRegister = '/register/legacy';
  static const home = '/home';

  /// The static design preview: an index of every screen built from the
  /// approved design, reviewable without a running backend.
  static const preview = '/preview';
}

/// The application route table.
///
/// Each feature adds its own routes here as it is specified. Routes are not
/// created ahead of the feature that needs them.
///
/// [authRepository] defaults to a real [AuthRepository] wired to
/// [HttpAuthService] (which calls `prototype_server`, never PostgreSQL
/// directly — FR-035); tests inject a fake in its place.
GoRouter createAppRouter({
  AuthRepository? authRepository,
  AppPreferences? preferences,
  PermissionService? permissions,
  RegistrationService? registrationService,
  RegistrationDraftStore? registrationDraftStore,
  MediaCaptureService? mediaCapture,
}) {
  final repository =
      authRepository ??
      AuthRepository(
        authService: HttpAuthService(),
        deviceIdentityStore: SecureDeviceIdentityStore(),
        sessionStore: SecureSessionStore(),
      );

  final onboarding = OnboardingRepository(
    preferences: preferences ?? SharedAppPreferences(),
    permissions: permissions ?? const DevicePermissionService(),
  );

  // No registration API exists yet, so the local mock stands in behind the
  // same repository boundary an HTTP service will use later.
  final registration = RegistrationRepository(
    service: registrationService ?? MockRegistrationService(),
    draftStore: registrationDraftStore ?? SharedRegistrationDraftStore(),
  );
  final capture = mediaCapture ?? DeviceMediaCaptureService();

  return GoRouter(
    initialLocation: AppRoutes.firstLaunch,
    redirect: (context, state) async {
      // Session restoration (US8, FR-030): decide the landing route once,
      // on first navigation, without trusting the local session record by
      // itself — restoreSession() re-validates against the current
      // device-binding state via prototype_server.
      if (state.matchedLocation != AppRoutes.legacyLogin) return null;
      final result = await repository.restoreSession();
      return result.outcome == SessionRestoreOutcome.restored
          ? AppRoutes.home
          : null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.firstLaunch,
        builder: (context, state) => ChangeNotifierProvider(
          create: (_) => FirstLaunchViewModel(repository: onboarding),
          child: FirstLaunchFlowScreen(
            onComplete: () => context.go(AppRoutes.login),
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.preview,
        builder: (context, state) => const PreviewGalleryScreen(),
        routes: [
          // Every preview screen is addressable as /preview/<board>/<id>
          // (e.g. /preview/01/B3), so a specific state can be opened
          // directly instead of navigated to.
          GoRoute(
            path: ':board/:screen',
            builder: (context, state) => previewScreenFor(
              board: state.pathParameters['board']!,
              screen: state.pathParameters['screen']!,
            ),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => ChangeNotifierProvider(
          create: (_) => RegistrationFlowViewModel(
            repository: registration,
            mediaCapture: capture,
          ),
          child: RegistrationFlowScreen(
            onGoToLogin: () => context.go(AppRoutes.login),
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.legacyRegister,
        builder: (context, state) => Provider<AuthRepository>.value(
          value: repository,
          child: ChangeNotifierProvider(
            create: (_) => RegistrationViewModel(repository: repository),
            child: const RegistrationScreen(),
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.login,
        // The Crown Solar sign-in screen is the visual source of truth.
        // Login's own device-binding logic is a separate piece of work; this
        // route exists so first launch can hand off to it, and so "Register"
        // reaches the registration wizard.
        builder: (context, state) =>
            SignInScreen(onRegister: () => context.go(AppRoutes.register)),
      ),
      GoRoute(
        path: AppRoutes.legacyLogin,
        builder: (context, state) => Provider<AuthRepository>.value(
          value: repository,
          child: ChangeNotifierProvider(
            create: (_) => LoginViewModel(repository: repository),
            child: LoginScreen(
              onAuthenticated: (_) => context.go(AppRoutes.home),
            ),
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => Provider<AuthRepository>.value(
          value: repository,
          child: ChangeNotifierProvider(
            create: (_) => HomeViewModel(repository: repository),
            child: HomeScreen(onLoggedOut: () => context.go(AppRoutes.login)),
          ),
        ),
      ),
    ],
    errorBuilder: (context, state) => const RouteNotFoundScreen(),
  );
}
