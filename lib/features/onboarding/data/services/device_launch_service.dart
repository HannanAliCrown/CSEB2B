// Constructor parameters are named for their public API rather than the
// private fields they populate, so the initializing-formal shorthand the
// linter suggests is not available here.
// ignore_for_file: prefer_initializing_formals

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../auth/data/services/device_identity_store.dart';

/// Reports what first launch settled about this phone: the language, the two
/// permission answers, and where the phone was.
///
/// The phone keeps its own copy in preferences and that copy alone decides
/// whether first launch runs again. This is the record Crown Solar can see,
/// so a partner's device is known before they ever register.
abstract interface class DeviceLaunchService {
  Future<void> record({
    String? languageCode,
    bool? languageRemembered,
    String? notificationPermission,
    String? locationPermission,
    double? latitude,
    double? longitude,
    bool firstLaunchComplete,
  });
}

/// The default when no backend is configured. First launch must work on a
/// phone that has never reached a server, so doing nothing is a real answer
/// rather than a gap.
class NoDeviceLaunchService implements DeviceLaunchService {
  const NoDeviceLaunchService();

  @override
  Future<void> record({
    String? languageCode,
    bool? languageRemembered,
    String? notificationPermission,
    String? locationPermission,
    double? latitude,
    double? longitude,
    bool firstLaunchComplete = false,
  }) async {}
}

/// Posts to `prototype_server`, which owns the PostgreSQL connection.
///
/// Every call is best-effort: first launch is the one journey that must not
/// depend on a reachable server, so a failure is swallowed and the partner
/// carries on. Nothing here is read back, so there is nothing to lose.
class HttpDeviceLaunchService implements DeviceLaunchService {
  HttpDeviceLaunchService({
    required DeviceIdentityStore identity,
    required String baseUrl,
    http.Client? client,
    String? platform,
  }) : _identity = identity,
       _baseUrl = baseUrl,
       _client = client ?? http.Client(),
       _platform = platform;

  final DeviceIdentityStore _identity;
  final String _baseUrl;
  final http.Client _client;
  final String? _platform;

  @override
  Future<void> record({
    String? languageCode,
    bool? languageRemembered,
    String? notificationPermission,
    String? locationPermission,
    double? latitude,
    double? longitude,
    bool firstLaunchComplete = false,
  }) async {
    try {
      final installationUuid = await _identity.getOrCreateInstallationUuid();
      await _client.post(
        Uri.parse('$_baseUrl/devices/launch'),
        headers: const {'content-type': 'application/json'},
        body: jsonEncode({
          'installationUuid': installationUuid,
          'platform': _platform,
          'languageCode': languageCode,
          'languageRemembered': languageRemembered,
          'notificationPermission': notificationPermission,
          'locationPermission': locationPermission,
          'latitude': latitude,
          'longitude': longitude,
          'firstLaunchComplete': firstLaunchComplete,
        }),
      );
    } on Object {
      // Deliberately silent. See the class comment: an unreachable server
      // must not stop someone opening the app for the first time.
    }
  }
}
