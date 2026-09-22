import 'package:shelf_router/shelf_router.dart';

import 'data/auth_data_store.dart';
import 'data/branding_data_store.dart';
import 'data/complaints_data_store.dart';
import 'data/inaam_data_store.dart';
import 'data/partner_data_store.dart';
import 'data/points_data_store.dart';
import 'data/profile_data_store.dart';
import 'data/scan_data_store.dart';
import 'data/wallet_data_store.dart';
import 'data/social_data_store.dart';
import 'routes/branding_routes.dart';
import 'routes/complaints_routes.dart';
import 'routes/device_status_routes.dart';
import 'routes/login_otp_routes.dart';
import 'routes/login_routes.dart';
import 'routes/inaam_routes.dart';
import 'routes/partner_routes.dart';
import 'routes/points_routes.dart';
import 'routes/profile_routes.dart';
import 'routes/social_routes.dart';
import 'routes/wallet_routes.dart';
import 'routes/rebinding_authorization_routes.dart';
import 'routes/rebindings_routes.dart';
import 'routes/registration_routes.dart';

/// Aggregates every endpoint from contracts/auth-service.md's table into
/// one router, over the [AuthDataStore] abstraction — no route handler
/// here or in routes/ imports the `postgres` package directly.
Router buildRouter(
  AuthDataStore store, {
  PartnerDataStore? partners,
  SocialDataStore? social,
  ProfileDataStore? profile,
  ComplaintsDataStore? complaints,
  WalletDataStore? wallet,
  ScanDataStore? scan,
  PointsDataStore? points,
  InaamDataStore? inaam,
  BrandingDataStore? branding,
}) {
  final router = Router();
  // First launch and the registration wizard. Optional so the auth tests can
  // build a router without standing up a second store.
  if (partners != null) {
    router.mount('/', partnerRoutes(partners).call);
    // New profile requests: the buying source's side of a registration.
    router.mount('/', profileRequestRoutes(partners).call);
  }
  // Space and Chat.
  if (social != null) router.mount('/', socialRoutes(social).call);
  // Profile: language, theme, the app PIN, support numbers and About.
  if (profile != null) router.mount('/', profileRoutes(profile).call);
  // Complaints and Notifications.
  if (complaints != null) {
    router.mount('/', complaintsRoutes(complaints).call);
  }
  // Inaam Baazar: spins, item schemes and the monthly programme.
  if (inaam != null) router.mount('/', inaamRoutes(inaam).call);
  // Shop Branding: the request, its status, and which boards are offered.
  if (branding != null) router.mount('/', brandingRoutes(branding).call);
  // Points: their own ledger, never joined to the wallet's.
  if (points != null) router.mount('/', pointsRoutes(points).call);
  // Send Cash, the ledger and the scanner — one money, one store.
  if (wallet != null) {
    router.mount('/', walletRoutes(wallet, scan: scan).call);
  }
  router.mount('/', registrationRoutes(store).call);
  router.mount('/', loginRoutes(store).call);
  router.mount('/', loginOtpRoutes(store).call);
  router.mount('/', rebindingAuthorizationRoutes(store).call);
  router.mount('/', rebindingsRoutes(store).call);
  router.mount('/', deviceStatusRoutes(store).call);
  return router;
}
