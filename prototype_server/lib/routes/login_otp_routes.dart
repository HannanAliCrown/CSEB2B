import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../data/auth_data_store.dart';
import '../data/models.dart';
import 'json_helpers.dart';

/// `POST /login/otp` and `POST /login/otp/verify`
/// (contracts/auth-service.md: `requestLoginOtp`, `verifyLoginOtp`).
/// FR-005, FR-020, FR-021: a distinct challenge from any registration OTP;
/// verification alone never itself activates a device.
///
/// `requestLoginOtp` is tier-gated (FR-016, FR-017): at the second-device
/// tier it issues unconditionally, exactly as before; at the
/// third-or-later tier it re-checks the rebinding-authorization outcome
/// itself and refuses (403) unless it is already `authorized` — this
/// SERVER-SIDE check never trusts that the Flutter client called
/// `checkRebindingAuthorization` first, even though the client's own
/// `LoginViewModel` is expected to do exactly that (FR-046).
Router loginOtpRoutes(AuthDataStore store) {
  final router = Router();

  router.post('/login/otp', (Request request) async {
    final body = await readJsonBody(request);
    final accountId = body['accountId'] as String?;
    final deviceId = body['deviceId'] as String?;
    if (accountId == null || deviceId == null) {
      return jsonResponse(400, {
        'error': 'accountId and deviceId are required',
      });
    }

    final tier = await store.getDeviceMoveTier(accountId);
    if (tier == DeviceMoveTier.thirdOrLater) {
      // Third-or-later tier only: authorization is consulted, and MUST be
      // Authorized, before any OTP is issued (FR-017). Second-device tier
      // never reaches this branch — it never consults this table (FR-016).
      final authorization = await store.getOrCreateRebindingAuthorization(
        accountId: accountId,
        deviceId: deviceId,
      );
      if (authorization.status != RebindingAuthorizationStatus.authorized) {
        return jsonResponse(403, {
          'error': 'not_authorized',
          'authorizationStatus': rebindingAuthorizationStatusToJson(
            authorization.status,
          ),
        });
      }
    }

    final challenge = await store.createOtpChallenge(
      accountId: accountId,
      deviceId: deviceId,
      context: OtpContext.newDeviceLogin,
    );

    return jsonResponse(200, {
      'challengeId': challenge.id,
      // Prototype-only testability surface — see registration_routes.dart.
      'code': challenge.code,
    });
  });

  router.post('/login/otp/verify', (Request request) async {
    final body = await readJsonBody(request);
    final accountId = body['accountId'] as String?;
    final deviceId = body['deviceId'] as String?;
    final code = body['code'] as String?;
    if (accountId == null || deviceId == null || code == null) {
      return jsonResponse(400, {
        'error': 'accountId, deviceId, and code are required',
      });
    }

    final result = await store.verifyLoginOtp(
      accountId: accountId,
      deviceId: deviceId,
      submittedCode: code,
    );

    return switch (result) {
      OtpVerifyResult.verified => jsonResponse(200, {'verified': true}),
      OtpVerifyResult.invalidCode => jsonResponse(400, {
        'error': 'invalid_code',
      }),
      OtpVerifyResult.notFound => jsonResponse(404, {
        'error': 'challenge_not_found',
      }),
    };
  });

  return router;
}
