import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../data/auth_data_store.dart';
import 'json_helpers.dart';

/// `POST /rebindings` (contracts/auth-service.md: `completeRebinding`).
/// FR-023, FR-024, FR-025, FR-041, FR-042: the atomic device
/// activation/revocation/conflict-transfer operation. The data-store
/// implementation re-checks OTP-verified itself, and — only at the
/// third-or-later device-move tier (FR-017, FR-018) — re-checks
/// authorization=Authorized too; a second-device-tier move (FR-016) is
/// gated by the verified OTP alone. This handler never trusts
/// client-supplied call ordering or tier.
Router rebindingsRoutes(AuthDataStore store) {
  final router = Router();

  router.post('/rebindings', (Request request) async {
    final body = await readJsonBody(request);
    final accountId = body['accountId'] as String?;
    final deviceId = body['deviceId'] as String?;
    if (accountId == null || deviceId == null) {
      return jsonResponse(400, {
        'error': 'accountId and deviceId are required',
      });
    }

    final result = await store.completeRebinding(
      accountId: accountId,
      deviceId: deviceId,
    );

    return switch (result) {
      RebindResult.activated => jsonResponse(200, {'status': 'active'}),
      RebindResult.otpNotVerified => jsonResponse(400, {
        'error': 'otp_not_verified',
      }),
      RebindResult.notAuthorized => jsonResponse(403, {
        'error': 'not_authorized',
      }),
      RebindResult.persistenceFailed => jsonResponse(409, {
        'error': 'rebinding_failed',
      }),
    };
  });

  return router;
}
