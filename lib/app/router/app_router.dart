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
import 'package:cse_b2b/features/design_preview/preview_catalog.dart';
import 'package:cse_b2b/features/design_preview/preview_gallery_screen.dart';

/// Route paths, so callers never spell a location as a bare string.
abstract final class AppRoutes {
  static const login = '/login';
  static const register = '/register';
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
GoRouter createAppRouter({AuthRepository? authRepository}) {
  final repository =
      authRepository ??
      AuthRepository(
        authService: HttpAuthService(),
        deviceIdentityStore: SecureDeviceIdentityStore(),
        sessionStore: SecureSessionStore(),
      );

  return GoRouter(
    initialLocation: AppRoutes.preview,
    redirect: (context, state) async {
      // Session restoration (US8, FR-030): decide the landing route once,
      // on first navigation, without trusting the local session record by
      // itself — restoreSession() re-validates against the current
      // device-binding state via prototype_server.
      if (state.matchedLocation != AppRoutes.login) return null;
      final result = await repository.restoreSession();
      return result.outcome == SessionRestoreOutcome.restored
          ? AppRoutes.home
          : null;
    },
    routes: [
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
