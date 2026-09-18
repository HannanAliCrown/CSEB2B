import 'package:cse_b2b/features/auth/data/models/session.dart';
import 'package:cse_b2b/features/auth/data/services/device_identity_store.dart';
import 'package:cse_b2b/features/auth/data/services/session_store.dart';

class FakeDeviceIdentityStore implements DeviceIdentityStore {
  FakeDeviceIdentityStore([this.installationUuid = 'device-installation-uuid']);

  final String installationUuid;

  @override
  Future<String> getOrCreateInstallationUuid() async => installationUuid;
}

class FakeSessionStore implements SessionStore {
  Session? stored;

  @override
  Future<void> save(Session session) async => stored = session;

  @override
  Future<Session?> read() async => stored;

  @override
  Future<void> clear() async => stored = null;
}
