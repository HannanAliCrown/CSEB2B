import 'package:prototype_server/data/models.dart';
import 'package:prototype_server/router.dart';
import 'package:test/test.dart';

import '../support/fake_auth_data_store.dart';
import '../support/request_helpers.dart';

void main() {
  group('device binding status (FR-008, FR-030)', () {
    late FakeAuthDataStore store;

    setUp(() => store = FakeAuthDataStore());

    test('an unrecorded device returns new_untrusted', () async {
      final account = store.addAccount(
        mobileNumber: '+923000000050',
        userType: 'installer',
      );
      final router = buildRouter(store);
      final result = await getJson(
        router,
        '/accounts/${account.id}/devices/never-seen/status',
      );
      expect(result['statusCode'], 200);
      expect(result['body']['status'], 'new_untrusted');
    });

    test('the Active device returns active', () async {
      final account = store.addAccount(
        mobileNumber: '+923000000051',
        userType: 'retailer',
      );
      final device = await store.findOrCreateDevice('device-active-status');
      final challenge = await store.createOtpChallenge(
        accountId: account.id,
        deviceId: device.id,
        context: OtpContext.registration,
      );
      await store.verifyRegistrationOtpAndBind(
        accountId: account.id,
        deviceId: device.id,
        submittedCode: challenge.code,
      );

      final router = buildRouter(store);
      final result = await getJson(
        router,
        '/accounts/${account.id}/devices/${device.installationUuid}/status',
      );
      expect(result['body']['status'], 'active');
    });
  });
}
