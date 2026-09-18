import 'dart:convert';

import 'package:http/http.dart' as http;

import 'auth_service.dart';

/// The base URL of the server answering the `AuthService` HTTP contract —
/// `prototype_server` for this feature, the real ASP.NET Core API in
/// production. Supplied via `--dart-define=API_BASE_URL=...`
/// (quickstart.md); never hardcoded, never a PostgreSQL connection detail
/// (FR-035 — this app never holds PostgreSQL credentials).
const String _apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://10.0.2.2:8080',
);

/// The only `AuthService` implementation this feature has, for its entire
/// lifetime (research.md). Every method is a thin HTTP call mapped 1:1 to
/// contracts/auth-service.md's table — all device-trust and rebinding
/// decisions are made server-side; this class never decides anything
/// itself (FR-043).
class HttpAuthService implements AuthService {
  HttpAuthService({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      _baseUrl = baseUrl ?? _apiBaseUrl;

  final http.Client _client;
  final String _baseUrl;

  Uri _uri(String path, [Map<String, String>? query]) =>
      Uri.parse('$_baseUrl$path').replace(queryParameters: query);

  Future<Map<String, dynamic>> _postJson(
    String path,
    Map<String, Object?> body,
  ) async {
    final response = await _client.post(
      _uri(path),
      headers: {'content-type': 'application/json'},
      body: jsonEncode(body),
    );
    return {
      'statusCode': response.statusCode,
      'body': response.body.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(response.body),
    };
  }

  Future<Map<String, dynamic>> _getJson(
    String path, [
    Map<String, String>? query,
  ]) async {
    final response = await _client.get(_uri(path, query));
    return {
      'statusCode': response.statusCode,
      'body': response.body.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(response.body),
    };
  }

  @override
  Future<RegistrationOtpResult> requestRegistrationOtp({
    required String mobileNumber,
    required String deviceId,
  }) async {
    final result = await _postJson('/registration/otp', {
      'mobileNumber': mobileNumber,
      'deviceId': deviceId,
    });
    final statusCode = result['statusCode'] as int;
    if (statusCode == 200) {
      final body = result['body'] as Map<String, dynamic>;
      return RegistrationOtpResult.issued(
        accountId: body['accountId'] as String,
        deviceId: body['deviceId'] as String,
        prototypeCode: body['code'] as String,
      );
    }
    if (statusCode == 409) {
      return const RegistrationOtpResult.failure(
        RegistrationOtpStatus.alreadyRegistered,
      );
    }
    return const RegistrationOtpResult.failure(
      RegistrationOtpStatus.accountNotFound,
    );
  }

  @override
  Future<RegistrationVerifyResult> verifyRegistrationOtp({
    required String accountId,
    required String deviceId,
    required String code,
  }) async {
    final result = await _postJson('/registration/otp/verify', {
      'accountId': accountId,
      'deviceId': deviceId,
      'code': code,
    });
    final status = switch (result['statusCode'] as int) {
      200 => RegistrationVerifyStatus.activated,
      400 => RegistrationVerifyStatus.invalidCode,
      404 => RegistrationVerifyStatus.notFound,
      _ => RegistrationVerifyStatus.failed,
    };
    return RegistrationVerifyResult(status);
  }

  @override
  Future<LoginResult> evaluateLogin({
    required String mobileNumber,
    required String deviceId,
  }) async {
    final result = await _postJson('/login', {
      'mobileNumber': mobileNumber,
      'deviceId': deviceId,
    });
    if (result['statusCode'] != 200) {
      return const LoginResult.accountNotFound();
    }
    final body = result['body'] as Map<String, dynamic>;
    final trusted = body['outcome'] == 'trusted';
    final conflictBody = body['conflict'] as Map<String, dynamic>?;
    return LoginResult.success(
      status: trusted ? LoginStatus.trusted : LoginStatus.newUntrusted,
      accountId: body['accountId'] as String,
      deviceId: body['deviceId'] as String,
      tier: trusted ? null : _tierFromJson(body['tier'] as String?),
      conflict: conflictBody == null
          ? null
          : ConflictInfo(
              otherAccountId: conflictBody['otherAccountId'] as String,
            ),
    );
  }

  @override
  Future<ConfirmTakeoverResult> confirmTakeover({
    required String mobileNumber,
    required String deviceId,
  }) async {
    final result = await _postJson('/login/confirm-takeover', {
      'mobileNumber': mobileNumber,
      'deviceId': deviceId,
    });
    final body = result['body'] as Map<String, dynamic>;
    return ConfirmTakeoverResult(
      acknowledged: body['acknowledged'] as bool? ?? false,
    );
  }

  @override
  Future<LoginOtpResult> requestLoginOtp({
    required String accountId,
    required String deviceId,
  }) async {
    final result = await _postJson('/login/otp', {
      'accountId': accountId,
      'deviceId': deviceId,
    });
    if (result['statusCode'] == 403) {
      return const LoginOtpResult.notYetAuthorized();
    }
    final body = result['body'] as Map<String, dynamic>;
    return LoginOtpResult.issued(
      challengeId: body['challengeId'] as String,
      prototypeCode: body['code'] as String,
    );
  }

  DeviceMoveTier? _tierFromJson(String? tier) => switch (tier) {
    'second_device' => DeviceMoveTier.secondDevice,
    'third_or_later' => DeviceMoveTier.thirdOrLater,
    _ => null,
  };

  @override
  Future<OtpVerifyResult> verifyLoginOtp({
    required String accountId,
    required String deviceId,
    required String code,
  }) async {
    final result = await _postJson('/login/otp/verify', {
      'accountId': accountId,
      'deviceId': deviceId,
      'code': code,
    });
    final status = switch (result['statusCode'] as int) {
      200 => OtpVerifyStatus.verified,
      400 => OtpVerifyStatus.invalidCode,
      _ => OtpVerifyStatus.notFound,
    };
    return OtpVerifyResult(status);
  }

  @override
  Future<RebindingAuthorizationResult> checkRebindingAuthorization({
    required String accountId,
    required String deviceId,
  }) async {
    final result = await _getJson('/rebinding-authorizations', {
      'accountId': accountId,
      'deviceId': deviceId,
    });
    final body = result['body'] as Map<String, dynamic>;
    final status = switch (body['status']) {
      'authorized' => RebindingAuthorizationStatus.authorized,
      'not_authorized' => RebindingAuthorizationStatus.notAuthorized,
      _ => RebindingAuthorizationStatus.pending,
    };
    return RebindingAuthorizationResult(status);
  }

  @override
  Future<RebindResult> completeRebinding({
    required String accountId,
    required String deviceId,
  }) async {
    final result = await _postJson('/rebindings', {
      'accountId': accountId,
      'deviceId': deviceId,
    });
    final status = switch (result['statusCode'] as int) {
      200 => RebindStatus.activated,
      400 => RebindStatus.otpNotVerified,
      403 => RebindStatus.notAuthorized,
      _ => RebindStatus.failed,
    };
    return RebindResult(status);
  }

  @override
  Future<DeviceStatusResult> getDeviceBindingStatus({
    required String accountId,
    required String deviceId,
  }) async {
    final result = await _getJson(
      '/accounts/$accountId/devices/$deviceId/status',
    );
    final body = result['body'] as Map<String, dynamic>;
    final status = switch (body['status']) {
      'active' => DeviceBindingStatus.active,
      'revoked' => DeviceBindingStatus.revoked,
      _ => DeviceBindingStatus.newUntrusted,
    };
    return DeviceStatusResult(status);
  }
}
