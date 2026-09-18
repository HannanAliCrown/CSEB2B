import 'package:shelf_router/shelf_router.dart';

import 'data/auth_data_store.dart';
import 'routes/device_status_routes.dart';
import 'routes/login_otp_routes.dart';
import 'routes/login_routes.dart';
import 'routes/rebinding_authorization_routes.dart';
import 'routes/rebindings_routes.dart';
import 'routes/registration_routes.dart';

/// Aggregates every endpoint from contracts/auth-service.md's table into
/// one router, over the [AuthDataStore] abstraction — no route handler
/// here or in routes/ imports the `postgres` package directly.
Router buildRouter(AuthDataStore store) {
  final router = Router();
  router.mount('/', registrationRoutes(store).call);
  router.mount('/', loginRoutes(store).call);
  router.mount('/', loginOtpRoutes(store).call);
  router.mount('/', rebindingAuthorizationRoutes(store).call);
  router.mount('/', rebindingsRoutes(store).call);
  router.mount('/', deviceStatusRoutes(store).call);
  return router;
}
