import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../data/auth_data_store.dart';
import '../data/models.dart';
import 'json_helpers.dart';

/// `GET /accounts/{accountId}/devices/{deviceId}/status`
/// (contracts/auth-service.md: `getDeviceBindingStatus`). FR-008, FR-030:
/// read-only check used both internally by `evaluateLogin` and by the
/// Flutter Repository when restoring a persisted "Keep Me Signed In"
/// session.
///
/// Unlike the chained registration/login/rebinding calls (where the
/// client already carries forward the server's internal device id from
/// the previous response), session restoration is a cold start: the
/// client only ever has its own locally generated installation UUID. So
/// `{deviceId}` here is that installation UUID, and this route resolves
/// it to the internal device id itself before checking binding status.
Router deviceStatusRoutes(AuthDataStore store) {
  final router = Router();

  router.get('/accounts/<accountId>/devices/<installationUuid>/status', (
    Request request,
    String accountId,
    String installationUuid,
  ) async {
    final device = await store.findOrCreateDevice(installationUuid);
    final status = await store.getDeviceBindingStatus(
      accountId: accountId,
      deviceId: device.id,
    );
    return jsonResponse(200, {'status': _statusToJson(status)});
  });

  return router;
}

String _statusToJson(DeviceBindingStatus status) => switch (status) {
  DeviceBindingStatus.active => 'active',
  DeviceBindingStatus.revoked => 'revoked',
  DeviceBindingStatus.newUntrusted => 'new_untrusted',
};
