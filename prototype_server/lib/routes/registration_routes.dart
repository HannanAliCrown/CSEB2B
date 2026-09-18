import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../data/auth_data_store.dart';
import '../data/models.dart';
import 'json_helpers.dart';

/// `POST /registration/otp` and `POST /registration/otp/verify`
/// (contracts/auth-service.md: `requestRegistrationOtp`,
/// `verifyRegistrationOtp`). FR-001–FR-005, FR-040.
Router registrationRoutes(AuthDataStore store) {
  final router = Router();

  router.post('/registration/otp', (Request request) async {
    final body = await readJsonBody(request);
    final mobileNumber = body['mobileNumber'] as String?;
    final deviceId = body['deviceId'] as String?;
    if (mobileNumber == null || deviceId == null) {
      return jsonResponse(400, {
        'error': 'mobileNumber and deviceId are required',
      });
    }

    final account = await store.findAccountByMobileNumber(mobileNumber);
    if (account == null) {
      return jsonResponse(404, {'error': 'account_not_found'});
    }

    final existingBinding = await store.getActiveBindingForAccount(account.id);
    if (existingBinding != null) {
      return jsonResponse(409, {
        'error': 'already_registered',
        'message': 'Account already has an Active device; use /login instead.',
      });
    }

    final device = await store.findOrCreateDevice(deviceId);
    final challenge = await store.createOtpChallenge(
      accountId: account.id,
      deviceId: device.id,
      context: OtpContext.registration,
    );

    return jsonResponse(200, {
      'accountId': account.id,
      'deviceId': device.id,
      'challengeId': challenge.id,
      // Prototype-only: real SMS delivery does not exist, so the code is
      // returned directly for testability (research.md). Never a
      // production behavior.
      'code': challenge.code,
    });
  });

  router.post('/registration/otp/verify', (Request request) async {
    final body = await readJsonBody(request);
    final accountId = body['accountId'] as String?;
    final deviceId = body['deviceId'] as String?;
    final code = body['code'] as String?;
    if (accountId == null || deviceId == null || code == null) {
      return jsonResponse(400, {
        'error': 'accountId, deviceId, and code are required',
      });
    }

    final result = await store.verifyRegistrationOtpAndBind(
      accountId: accountId,
      deviceId: deviceId,
      submittedCode: code,
    );

    return switch (result) {
      RegistrationBindResult.activated => jsonResponse(200, {
        'status': 'active',
      }),
      RegistrationBindResult.invalidCode => jsonResponse(400, {
        'error': 'invalid_code',
      }),
      RegistrationBindResult.notFound => jsonResponse(404, {
        'error': 'challenge_not_found',
      }),
      RegistrationBindResult.persistenceFailed => jsonResponse(409, {
        'error': 'binding_failed',
        'message': 'Registration did not complete; no partial state was left.',
      }),
    };
  });

  return router;
}
