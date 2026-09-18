import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

/// The current device's local identifier boundary (research.md "Decision:
/// `uuid` package"). This is an abstract, app-generated identifier, never
/// a real hardware ID, and never treated as an authentication factor by
/// itself (FR-015, FR-041) — it is only ever "the current device" for
/// comparison purposes.
///
/// An interface (mirroring [AuthService]'s pattern) so tests can supply an
/// in-memory fake instead of touching the `flutter_secure_storage` plugin
/// (constitution Principle VII: Testable Boundaries).
abstract interface class DeviceIdentityStore {
  Future<String> getOrCreateInstallationUuid();
}

/// The real [DeviceIdentityStore]: generated once per installation and
/// persisted in secure storage. A reinstall has no persisted value, so a
/// fresh UUID is generated — which will not match the account's stored
/// Active-device identifier, correctly classifying the reinstalled app
/// New/Untrusted.
class SecureDeviceIdentityStore implements DeviceIdentityStore {
  SecureDeviceIdentityStore({FlutterSecureStorage? storage, Uuid? uuid})
    : _storage = storage ?? const FlutterSecureStorage(),
      _uuid = uuid ?? const Uuid();

  static const _key = 'auth.device_installation_uuid';

  final FlutterSecureStorage _storage;
  final Uuid _uuid;

  @override
  Future<String> getOrCreateInstallationUuid() async {
    final existing = await _storage.read(key: _key);
    if (existing != null) return existing;
    final generated = _uuid.v4();
    await _storage.write(key: _key, value: generated);
    return generated;
  }
}
