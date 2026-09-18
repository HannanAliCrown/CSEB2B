import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../data/auth_data_store.dart';
import '../data/models.dart';
import 'json_helpers.dart';

/// `GET /rebinding-authorizations` (contracts/auth-service.md:
/// `checkRebindingAuthorization`). FR-017, FR-022, FR-028: reads (or
/// creates, defaulting to Pending) the externally-sourced authorization
/// state. This is the ONLY route that touches `rebinding_authorizations`,
/// and it never accepts a status from the caller — there is no way to
/// author your own authorization through this server (FR-028, FR-029).
/// The deliberate prototype exception for resolving Pending →
/// Authorized/Not Authorized is applied directly in PostgreSQL, outside
/// this server (see quickstart.md). Only ever meaningfully consulted at
/// the third-or-later device-move tier (FR-016) — nothing here rejects a
/// call for a second-device-tier pair, since the *client's* own tier
/// branch (per `contracts/auth-service.md`) never issues one.
Router rebindingAuthorizationRoutes(AuthDataStore store) {
  final router = Router();

  router.get('/rebinding-authorizations', (Request request) async {
    final accountId = request.url.queryParameters['accountId'];
    final deviceId = request.url.queryParameters['deviceId'];
    if (accountId == null || deviceId == null) {
      return jsonResponse(400, {
        'error': 'accountId and deviceId query parameters are required',
      });
    }

    final authorization = await store.getOrCreateRebindingAuthorization(
      accountId: accountId,
      deviceId: deviceId,
    );

    return jsonResponse(200, {
      'status': rebindingAuthorizationStatusToJson(authorization.status),
    });
  });

  return router;
}
