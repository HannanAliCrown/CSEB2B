import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../data/auth_data_store.dart';
import '../data/models.dart';
import 'json_helpers.dart';

/// `POST /login` (contracts/auth-service.md: `evaluateLogin`) and
/// `POST /login/confirm-takeover` (`confirmTakeover`).
///
/// `evaluateLogin` identifies whether the current device is the account's
/// Active device (trusted) or not (New/Untrusted) — grants no access
/// itself, and never treats the mobile number or device ID alone as
/// sufficient (FR-007, FR-011, FR-012). For a New/Untrusted device, it
/// ALWAYS checks for a device conflict (the device Active for a
/// *different* account) BEFORE computing the requesting account's
/// device-move tier (FR-013, FR-015) — conflict detection precedes
/// tiering, never the reverse.
///
/// `confirmTakeover` writes nothing at all (FR-014): it exists only so the
/// Flutter client has an explicit step to call once the user confirms the
/// A4 takeover dialog, before it proceeds to request an OTP. Declining
/// (the client simply never calling this) leaves every account's binding
/// state completely unchanged.
Router loginRoutes(AuthDataStore store) {
  final router = Router();

  router.post('/login', (Request request) async {
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

    final device = await store.findOrCreateDevice(deviceId);
    final activeBinding = await store.getActiveBindingForAccount(account.id);

    final trusted =
        activeBinding != null && activeBinding.deviceId == device.id;
    if (trusted) {
      return jsonResponse(200, {
        'accountId': account.id,
        'deviceId': device.id,
        'outcome': 'trusted',
      });
    }

    // New/Untrusted from here on. Conflict check MUST precede tiering
    // (FR-013, FR-014) — it runs unconditionally, independent of which
    // tier will end up applying to the requesting account.
    final conflictingBinding = await store.getActiveBindingForDevice(device.id);
    final conflict =
        conflictingBinding != null && conflictingBinding.accountId != account.id
        ? {'otherAccountId': conflictingBinding.accountId}
        : null;

    final tier = await store.getDeviceMoveTier(account.id);

    return jsonResponse(200, {
      'accountId': account.id,
      'deviceId': device.id,
      'outcome': 'new_untrusted',
      'conflict': conflict,
      'tier': deviceMoveTierToJson(tier),
    });
  });

  router.post('/login/confirm-takeover', (Request request) async {
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
    final device = await store.findOrCreateDevice(deviceId);

    // Deliberately no writes here (FR-014) — see class-level doc comment.
    return jsonResponse(200, {
      'accountId': account.id,
      'deviceId': device.id,
      'acknowledged': true,
    });
  });

  return router;
}
