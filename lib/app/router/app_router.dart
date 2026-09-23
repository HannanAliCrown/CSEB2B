import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:cse_b2b/app/router/route_not_found_screen.dart';
import 'package:cse_b2b/features/auth/data/repositories/auth_repository.dart';
import 'package:cse_b2b/features/auth/data/services/device_identity_store.dart';
import 'package:cse_b2b/features/auth/data/services/http_auth_service.dart';
import 'package:cse_b2b/features/auth/data/services/mock_auth_service.dart';
import 'package:cse_b2b/features/auth/data/services/session_store.dart';
import 'package:cse_b2b/features/auth/ui/view_models/home_view_model.dart';
import 'package:cse_b2b/features/auth/ui/view_models/login_view_model.dart';
import 'package:cse_b2b/features/auth/ui/view_models/registration_view_model.dart';
import 'package:cse_b2b/features/auth/ui/views/home_screen.dart';
import 'package:cse_b2b/features/auth/ui/views/login_screen.dart';
import 'package:cse_b2b/features/auth/ui/views/registration_screen.dart';
import 'package:cse_b2b/app/shell/app_shell.dart';
import 'package:cse_b2b/core/prefs/app_preferences.dart';
import 'package:cse_b2b/features/home/data/dashboard_repository.dart';
import 'package:cse_b2b/features/home/data/http_dashboard_repository.dart';
import 'package:cse_b2b/features/scan/data/scan_repository.dart';
import 'package:cse_b2b/features/chat/data/chat_repository.dart';
import 'package:cse_b2b/features/complaints/data/complaints_service.dart';
import 'package:cse_b2b/features/complaints/ui/views/complaint_detail_screen.dart';
import 'package:cse_b2b/features/complaints/ui/views/complaints_screen.dart';
import 'package:cse_b2b/features/complaints/ui/views/new_complaint_screen.dart';
import 'package:cse_b2b/features/complaints/ui/views/notifications_screen.dart';
import 'package:cse_b2b/features/chat/data/http_chat_repository.dart';
import 'package:cse_b2b/features/chat/ui/views/conversation_screen.dart';
import 'package:cse_b2b/features/chat/ui/views/new_conversation_screen.dart';
import 'package:cse_b2b/features/branding/data/branding_service.dart';
import 'package:cse_b2b/features/branding/ui/views/branding_requests_screen.dart';
import 'package:cse_b2b/features/branding/ui/views/branding_status_screen.dart';
import 'package:cse_b2b/features/branding/ui/views/new_branding_request_screen.dart';
import 'package:cse_b2b/features/branding/ui/views/shop_branding_screen.dart';
import 'package:cse_b2b/features/inaam_baazar/data/inaam_service.dart';
import 'package:cse_b2b/features/points/data/points_service.dart';
import 'package:cse_b2b/features/points/ui/views/points_ledger_screen.dart';
import 'package:cse_b2b/features/points/ui/views/send_points_screen.dart';
import 'package:cse_b2b/features/points/ui/views/targets_screen.dart';
import 'package:cse_b2b/features/profile/data/contacts_repository.dart';
import 'package:cse_b2b/features/profile_requests/data/profile_requests_service.dart';
import 'package:cse_b2b/features/profile_requests/ui/views/profile_request_detail_screen.dart';
import 'package:cse_b2b/features/profile_requests/ui/views/profile_requests_screen.dart';
import 'package:cse_b2b/features/profile/data/profile_settings_service.dart';
import 'package:cse_b2b/features/profile/ui/views/app_security_page.dart';
import 'package:cse_b2b/features/profile/ui/views/pin_gate.dart';
import 'package:cse_b2b/features/profile/ui/views/settings_pages.dart';
import 'package:cse_b2b/features/profile/ui/views/my_qr_code_screen.dart';
import 'package:cse_b2b/features/profile/ui/views/sync_contacts_screen.dart';
import 'package:cse_b2b/features/scan/ui/views/scan_screen.dart';
import 'package:cse_b2b/features/session/data/session_repository.dart';
import 'package:cse_b2b/features/session/data/session_service.dart';
import 'package:cse_b2b/features/session/ui/session_controller.dart';
import 'package:cse_b2b/features/space/data/http_space_repository.dart';
import 'package:cse_b2b/features/space/data/space_repository.dart';
import 'package:cse_b2b/features/space/ui/views/post_detail_screen.dart';
import 'package:cse_b2b/features/wallet/data/cash_requests_service.dart';
import 'package:cse_b2b/features/wallet/data/http_wallet_repository.dart';
import 'package:cse_b2b/features/wallet/ui/views/cash_requests_screen.dart';
import 'package:cse_b2b/features/wallet/data/wallet_repository.dart';
import 'package:cse_b2b/features/scan/data/http_scan_repository.dart';
import 'package:cse_b2b/features/wallet/ui/ledger_view_model.dart';
import 'package:cse_b2b/features/wallet/ui/wallet_view_model.dart';
import 'package:cse_b2b/features/wallet/ui/views/ledger_screen.dart';
import 'package:cse_b2b/features/wallet/ui/views/send_cash_screen.dart';
import 'package:cse_b2b/features/design_preview/preview_catalog.dart';
import 'package:cse_b2b/features/design_preview/preview_gallery_screen.dart';
import 'package:cse_b2b/features/login/ui/views/login_flow_screen.dart';
import 'package:cse_b2b/features/registration/data/repositories/registration_repository.dart';
import 'package:cse_b2b/features/registration/data/services/media_capture_service.dart';
import 'package:cse_b2b/features/registration/data/services/http_registration_service.dart';
import 'package:cse_b2b/features/registration/data/services/mock_registration_service.dart';
import 'package:cse_b2b/features/registration/data/services/registration_draft_store.dart';
import 'package:cse_b2b/features/registration/data/services/registration_service.dart';
import 'package:cse_b2b/features/registration/ui/view_models/registration_flow_view_model.dart';
import 'package:cse_b2b/features/registration/ui/views/approval_status_flow_screen.dart';
import 'package:cse_b2b/features/registration/ui/views/registration_flow_screen.dart';
import 'package:cse_b2b/features/onboarding/data/repositories/onboarding_repository.dart';
import 'package:cse_b2b/features/onboarding/data/services/device_launch_service.dart';
import 'package:cse_b2b/features/onboarding/data/services/permission_service.dart';
import 'package:cse_b2b/features/onboarding/ui/view_models/first_launch_view_model.dart';
import 'package:cse_b2b/features/onboarding/ui/views/first_launch_flow_screen.dart';

/// Where `prototype_server` is, which is where PostgreSQL is reached from.
/// `10.0.2.2` is the host machine as the Android emulator sees it.
const String apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://10.0.2.2:8080',
);

/// Whether the features that have been moved to the database read from it.
///
/// Off by default, so a build with no server running still opens on the mock
/// data everyone knows. Turn it on with
/// `--dart-define=DATA_SOURCE=server`.
///
/// This is a migration switch, not a permanent setting: it goes away once
/// every feature is server-backed.
const bool _serverBacked =
    String.fromEnvironment('DATA_SOURCE', defaultValue: 'mock') == 'server';

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

  /// The wallet, reached from Home's card and its tiles.
  static const sendCash = '/wallet/send';
  static const ledger = '/wallet/ledger';

  /// Scan QR: product authenticity, and any prize a scan wins.
  static const scan = '/scan';

  /// Complaints: the ticket list, the wizard, and one ticket. A ticket's
  /// path carries its reference, so a notification can link straight to it.
  static const complaints = '/complaints';
  static const newComplaint = '/complaints/new';
  static String complaint(String reference) => '/complaints/$reference';

  /// The notification centre, which the bell on Home opens.
  static const notifications = '/notifications';

  /// Registrations naming this partner as their buying source: the inbox,
  /// and the one request a verdict is given on.
  static const profileRequests = '/profile-requests';
  static String profileRequest(String applicationId) =>
      '/profile-requests/$applicationId';

  /// Transfers waiting on this partner to approve or reject.
  static const cashRequests = '/wallet/cash-requests';

  /// Points: sending, the scheme's targets, and the full points ledger.
  static const sendPoints = '/points/send';
  static const targets = '/points/targets';
  static const pointsLedger = '/points/ledger';

  /// Shop Branding: the module landing, the request wizard, the history and
  /// one request. A request's path carries its reference, so the landing and
  /// the history can both lead to the same screen.
  static const branding = '/branding';
  static const newBranding = '/branding/new';
  static const brandingRequests = '/branding/requests';
  static String brandingRequest(String reference) =>
      '/branding/requests/$reference';

  /// Where a submitted registration waits for its three approvals.
  static const approval = '/approval';

  /// Starting a conversation, and one conversation itself.
  static const newConversation = '/chat/new';
  static const conversation = '/chat/thread';

  /// One Space post, its comments and the replies under them.
  static const post = '/space/post';

  /// The settings pages under Profile.
  static const language = '/profile/language';
  static const theme = '/profile/theme';
  static const appSecurity = '/profile/security';
  static const callSupport = '/profile/support';
  static const aboutApp = '/profile/about';

  /// The partner's own QR code, and the contact sync behind it.
  static const myQrCode = '/profile/qr';
  static const syncContacts = '/profile/contacts';

  /// The earlier spec-driven placeholder home, kept while its logout flow
  /// is finished separately.
  static const legacyHome = '/home/legacy';

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
  final prefs = preferences ?? SharedAppPreferences();

  // Sign-in and device binding. Without a server there is nothing to ask, so
  // the bundled directory answers instead and a phone that has verified a
  // code once counts as the phone the account is on.
  final repository =
      authRepository ??
      AuthRepository(
        authService: _serverBacked
            ? HttpAuthService()
            : MockAuthService(preferences: prefs),
        deviceIdentityStore: SecureDeviceIdentityStore(),
        sessionStore: SecureSessionStore(),
      );

  final onboarding = OnboardingRepository(
    preferences: prefs,
    permissions: permissions ?? const DevicePermissionService(),
    launchService: _serverBacked
        ? HttpDeviceLaunchService(
            identity: SecureDeviceIdentityStore(),
            baseUrl: apiBaseUrl,
            platform: defaultTargetPlatform.name,
          )
        : const NoDeviceLaunchService(),
  );

  // No registration API exists yet, so the local mock stands in behind the
  // same repository boundary an HTTP service will use later.
  final registration = RegistrationRepository(
    service:
        registrationService ??
        (_serverBacked
            ? HttpRegistrationService(baseUrl: apiBaseUrl)
            : MockRegistrationService()),
    draftStore: registrationDraftStore ?? SharedRegistrationDraftStore(),
  );
  final capture = mediaCapture ?? DeviceMediaCaptureService();

  // The signed-in partner, the wallet and the scanner. All three are mocks
  // behind the same repository boundaries their APIs will use later.
  final session = SessionController(
    repository: SessionRepository(
      preferences: prefs,
      service: _serverBacked
          ? HttpSessionService(baseUrl: apiBaseUrl)
          : const MockSessionService(),
    ),
  );
  final wallet = _serverBacked
      ? HttpWalletRepository(baseUrl: apiBaseUrl)
      : MockWalletRepository();
  final dashboard = _serverBacked
      ? HttpDashboardRepository(baseUrl: apiBaseUrl)
      : MockDashboardRepository(wallet: wallet);
  final scanner = _serverBacked
      ? HttpScanRepository(baseUrl: apiBaseUrl, wallet: wallet)
      : MockScanRepository(wallet: wallet as MockWalletRepository);
  final contacts = DeviceContactsRepository(preferences: prefs);
  final chat = _serverBacked
      ? HttpChatRepository(baseUrl: apiBaseUrl)
      : MockChatRepository();
  // Profile settings, kept on the database when there is one. The mock holds
  // them for the life of the process, which is all a server-less build can.
  final profileSettings = _serverBacked
      ? HttpProfileSettingsService(baseUrl: apiBaseUrl)
      : MockProfileSettingsService();
  final pinLock = PinLock();

  // Complaints and notifications. A ticket raised against the mock lasts as
  // long as the process does; against the database it outlives a restart.
  final complaints = _serverBacked
      ? HttpComplaintsService(baseUrl: apiBaseUrl)
      : MockComplaintsService();

  // The buying source's side of a registration. A verdict recorded against
  // the mock is remembered only while the process runs.
  final profileRequests = _serverBacked
      ? HttpProfileRequestsService(baseUrl: apiBaseUrl)
      : MockProfileRequestsService();

  // Points. Every figure is derived from the movements either way, so the
  // mock and the database answer the same question the same way.
  final points = _serverBacked
      ? HttpPointsService(baseUrl: apiBaseUrl)
      : MockPointsService();

  // The receiver's side of a transfer. A verdict against the mock lasts as
  // long as the process does.
  final cashRequests = _serverBacked
      ? HttpCashRequestsService(baseUrl: apiBaseUrl)
      : MockCashRequestsService(wallet: wallet as MockWalletRepository);

  // Inaam prizes are money. The mock credits the same wallet the wheel is
  // spun against, so a prize shown is a prize in the balance.
  final inaam = _serverBacked
      ? HttpInaamService(baseUrl: apiBaseUrl)
      : MockInaamService(
          scans: scanner as MockScanRepository,
          wallet: wallet as MockWalletRepository,
        );

  // Shop Branding decides nothing on the device: which board types a partner
  // may ask for is measured server-side against their role, points, scheme,
  // recent scanning and existing board.
  final branding = _serverBacked
      ? HttpBrandingService(baseUrl: apiBaseUrl)
      : MockBrandingService(points: points as MockPointsService);

  final space = _serverBacked
      ? HttpSpaceRepository(baseUrl: apiBaseUrl)
      : MockSpaceRepository();

  /// Everything behind sign-in shares one session and one wallet, so a
  /// transfer made on one screen is the balance another screen shows.
  Widget signedIn(Widget child) => MultiProvider(
    providers: [
      ChangeNotifierProvider<SessionController>.value(value: session),
      Provider<WalletRepository>.value(value: wallet),
      Provider<DashboardRepository>.value(value: dashboard),
      Provider<ScanRepository>.value(value: scanner),
      Provider<ContactsRepository>.value(value: contacts),
      Provider<ChatRepository>.value(value: chat),
      Provider<SpaceRepository>.value(value: space),
      Provider<ProfileSettingsService>.value(value: profileSettings),
      Provider<ProfileRequestsService>.value(value: profileRequests),
      Provider<PointsService>.value(value: points),
      Provider<CashRequestsService>.value(value: cashRequests),
      Provider<InaamService>.value(value: inaam),
      Provider<BrandingService>.value(value: branding),
      Provider<MediaCaptureService>.value(value: capture),
      Provider<ComplaintsService>.value(value: complaints),
      ChangeNotifierProvider<PinLock>.value(value: pinLock),
    ],
    child: child,
  );

  /// The wallet screens share one view model per visit, so Send Cash and the
  /// ledger never disagree about the balance.
  Widget withWallet(BuildContext context, Widget child) =>
      ChangeNotifierProvider(
        create: (_) => WalletViewModel(repository: wallet, user: session.user!),
        child: child,
      );

  return GoRouter(
    initialLocation: AppRoutes.firstLaunch,
    redirect: (context, state) async {
      // Session restoration (US8, FR-030): decide the landing route once,
      // on first navigation, without trusting the local session record by
      // itself — restoreSession() re-validates against the current
      // device-binding state via prototype_server.
      // "Keep me signed in" lands the partner on Home rather than asking for
      // the number again.
      if (state.matchedLocation == AppRoutes.login) {
        if (session.user == null) await session.restore();
        if (!session.isSignedIn) return null;
        // An application still waiting on approval has no app to open.
        return session.user!.approved ? AppRoutes.home : AppRoutes.approval;
      }

      // Nothing behind sign-in opens without a session.
      if (state.matchedLocation == AppRoutes.home ||
          state.matchedLocation == AppRoutes.sendCash ||
          state.matchedLocation == AppRoutes.ledger ||
          state.matchedLocation == AppRoutes.scan) {
        if (session.user == null) await session.restore();
        if (!session.isSignedIn) return AppRoutes.login;
        return session.user!.approved ? null : AppRoutes.approval;
      }

      if (state.matchedLocation != AppRoutes.legacyLogin) return null;
      final result = await repository.restoreSession();
      return result.outcome == SessionRestoreOutcome.restored
          ? AppRoutes.legacyHome
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
            preferences: prefs,
            mediaCapture: capture,
          ),
          child: RegistrationFlowScreen(
            onGoToLogin: () => context.go(AppRoutes.login),
            // The applicant is not signed in yet, so the number travels with
            // the route.
            onSeeApprovalStatus: (number) =>
                context.go('${AppRoutes.approval}?number=$number'),
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
        // The Crown Solar sign-in screen is the visual source of truth, and
        // the single-active-device policy now stands in front of it: the
        // flow asks the server whether this phone is trusted, and only a
        // trusted phone — or a verified move to this one — reaches Home.
        builder: (context, state) => MultiProvider(
          providers: [
            ChangeNotifierProvider<SessionController>.value(value: session),
            Provider<AuthRepository>.value(value: repository),
          ],
          child: LoginFlowScreen(
            // Pushed, not replaced, so the wizard's first step can go back
            // to sign-in.
            onRegister: () => context.push(AppRoutes.register),
            onSignedIn: () => context.go(AppRoutes.home),
          ),
        ),
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
        // The PIN gate stands in front of the signed-in app, because App
        // Security promises the PIN is asked for the next time it opens.
        builder: (context, state) => signedIn(
          PinGate(
            child: AppShell(
              onSendCash: () => context.push(AppRoutes.sendCash),
              onViewLedger: () => context.push(AppRoutes.ledger),
              onScan: () => context.push(AppRoutes.scan),
              onComplaints: () => context.push(AppRoutes.complaints),
              onNotifications: () => context.push(AppRoutes.notifications),
              onProfileRequests: () =>
                  context.push<void>(AppRoutes.profileRequests),
              onCashRequests: () => context.push<void>(AppRoutes.cashRequests),
              onSendPoints: () => context.push<void>(AppRoutes.sendPoints),
              onViewTargets: () => context.push<void>(AppRoutes.targets),
              onPointsLedger: () => context.push<void>(AppRoutes.pointsLedger),
              onSignOut: () => context.go(AppRoutes.login),
              onShowQrCode: () => context.push(AppRoutes.myQrCode),
              onSyncContacts: () => context.push(AppRoutes.syncContacts),
              onNewConversation: () => context.push(AppRoutes.newConversation),
              onOpenThread: (party) =>
                  context.push(AppRoutes.conversation, extra: party),
              onOpenPost: (post) => context.push(AppRoutes.post, extra: post),
              onOpenSetting: (route) => context.push<void>(route),
              onShopBranding: () => context.push<void>(AppRoutes.branding),
            ),
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.language,
        builder: (context, state) => signedIn(const LanguagePage()),
      ),
      GoRoute(
        path: AppRoutes.theme,
        builder: (context, state) => signedIn(const ThemePage()),
      ),
      GoRoute(
        path: AppRoutes.appSecurity,
        builder: (context, state) => signedIn(const AppSecurityPage()),
      ),
      GoRoute(
        path: AppRoutes.callSupport,
        builder: (context, state) => signedIn(const CallSupportPage()),
      ),
      GoRoute(
        path: AppRoutes.aboutApp,
        builder: (context, state) => signedIn(const AboutAppPage()),
      ),
      GoRoute(
        path: AppRoutes.sendCash,
        builder: (context, state) => signedIn(
          Builder(
            builder: (context) => withWallet(context, const SendCashScreen()),
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.ledger,
        builder: (context, state) => signedIn(
          ChangeNotifierProvider(
            create: (_) =>
                LedgerViewModel(repository: wallet, user: session.user!),
            child: const LedgerScreen(),
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.scan,
        builder: (context, state) => signedIn(const ScanScreen()),
      ),
      GoRoute(
        path: AppRoutes.branding,
        builder: (context, state) => signedIn(
          ShopBrandingScreen(
            onNewRequest: () => context.push<void>(AppRoutes.newBranding),
            onSeeAll: () => context.push<void>(AppRoutes.brandingRequests),
            onOpenRequest: (reference) =>
                context.push<void>(AppRoutes.brandingRequest(reference)),
          ),
        ),
        routes: [
          // Both declared before ':reference', which would otherwise match
          // "new" and "requests" as a reference.
          GoRoute(
            path: 'new',
            builder: (context, state) => signedIn(
              NewBrandingRequestScreen(
                onOpenScanner: () => context.push<void>(AppRoutes.scan),
              ),
            ),
          ),
          GoRoute(
            path: 'requests',
            builder: (context, state) => signedIn(
              BrandingRequestsScreen(
                onOpenRequest: (reference) =>
                    context.push<void>(AppRoutes.brandingRequest(reference)),
              ),
            ),
            routes: [
              GoRoute(
                path: ':reference',
                builder: (context, state) => signedIn(
                  BrandingStatusScreen(
                    reference: state.pathParameters['reference']!,
                    onNewRequest: () =>
                        context.push<void>(AppRoutes.newBranding),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.complaints,
        builder: (context, state) => signedIn(
          ComplaintsScreen(
            onNewComplaint: () => context.push<String>(AppRoutes.newComplaint),
            onOpenComplaint: (reference) =>
                context.push<void>(AppRoutes.complaint(reference)),
          ),
        ),
        routes: [
          // Declared before ':reference', which would otherwise match "new".
          GoRoute(
            path: 'new',
            builder: (context, state) => signedIn(const NewComplaintScreen()),
          ),
          GoRoute(
            path: ':reference',
            builder: (context, state) => signedIn(
              ComplaintDetailScreen(
                reference: state.pathParameters['reference']!,
                onMessageCrm: () => context.push(
                  AppRoutes.conversation,
                  extra: ChatParty.department(Department.crm),
                ),
              ),
            ),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.sendPoints,
        builder: (context, state) => signedIn(const SendPointsScreen()),
      ),
      GoRoute(
        path: AppRoutes.targets,
        builder: (context, state) => signedIn(
          TargetsScreen(
            // A scheme is signed on paper, so the only thing the app can
            // offer is the conversation that starts it.
            onChatWithTeam: () => context.push(
              AppRoutes.conversation,
              extra: ChatParty.department(Department.crm),
            ),
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.pointsLedger,
        builder: (context, state) => signedIn(const PointsLedgerScreen()),
      ),
      GoRoute(
        path: AppRoutes.cashRequests,
        builder: (context, state) => signedIn(const CashRequestsScreen()),
      ),
      GoRoute(
        path: AppRoutes.profileRequests,
        builder: (context, state) => signedIn(
          ProfileRequestsScreen(
            onOpenRequest: (applicationId) =>
                context.push<void>(AppRoutes.profileRequest(applicationId)),
          ),
        ),
        routes: [
          GoRoute(
            path: ':applicationId',
            builder: (context, state) => signedIn(
              ProfileRequestDetailScreen(
                applicationId: state.pathParameters['applicationId']!,
              ),
            ),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.notifications,
        builder: (context, state) => signedIn(
          NotificationsScreen(
            // A notification only navigates to a screen that exists. The
            // rest say so rather than going nowhere on a tap.
            onOpenDestination: (route) async {
              if (route != AppRoutes.ledger &&
                  route != AppRoutes.profileRequests &&
                  !route.startsWith('${AppRoutes.complaints}/')) {
                return false;
              }
              await context.push<void>(route);
              return true;
            },
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.newConversation,
        builder: (context, state) => signedIn(
          NewConversationScreen(
            // Replace the picker with the conversation, so Back from a chat
            // returns to the list rather than the picker.
            onOpenThread: (party) =>
                context.pushReplacement(AppRoutes.conversation, extra: party),
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.conversation,
        builder: (context, state) =>
            signedIn(ConversationScreen(party: state.extra! as ChatParty)),
      ),
      GoRoute(
        path: AppRoutes.post,
        builder: (context, state) =>
            signedIn(PostDetailScreen(post: state.extra! as SpacePost)),
      ),
      GoRoute(
        path: AppRoutes.myQrCode,
        builder: (context, state) => signedIn(const MyQrCodeScreen()),
      ),
      GoRoute(
        path: AppRoutes.syncContacts,
        builder: (context, state) => signedIn(const SyncContactsScreen()),
      ),
      GoRoute(
        path: AppRoutes.approval,
        builder: (context, state) => ApprovalStatusFlowScreen(
          repository: registration,
          mobileNumber:
              state.uri.queryParameters['number'] ??
              session.user?.mobileNumber ??
              '',
          // There is no app behind this screen until the account opens, so
          // leaving it always returns to sign-in.
          onBack: () async {
            await session.signOut();
            if (context.mounted) context.go(AppRoutes.login);
          },
        ),
      ),
      GoRoute(
        path: AppRoutes.legacyHome,
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
