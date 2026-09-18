import 'package:cse_b2b/features/auth/data/services/auth_service.dart';

/// In-memory [AuthService] fake used across the Flutter test suite so
/// `flutter test` never touches `prototype_server` or the network
/// (research.md "Testing approach"). Scriptable per test via the queues/
/// flags below.
class FakeAuthService implements AuthService {
  RegistrationOtpResult registrationOtpResult =
      const RegistrationOtpResult.issued(
        accountId: 'account-1',
        deviceId: 'device-1',
        prototypeCode: '111111',
      );
  RegistrationVerifyResult registrationVerifyResult =
      const RegistrationVerifyResult(RegistrationVerifyStatus.activated);
  LoginResult loginResult = const LoginResult.success(
    status: LoginStatus.trusted,
    accountId: 'account-1',
    deviceId: 'device-1',
  );
  ConfirmTakeoverResult confirmTakeoverResult = const ConfirmTakeoverResult(
    acknowledged: true,
  );
  LoginOtpResult loginOtpResult = const LoginOtpResult.issued(
    challengeId: 'challenge-1',
    prototypeCode: '222222',
  );
  OtpVerifyResult otpVerifyResult = const OtpVerifyResult(
    OtpVerifyStatus.verified,
  );
  RebindingAuthorizationResult rebindingAuthorizationResult =
      const RebindingAuthorizationResult(
        RebindingAuthorizationStatus.authorized,
      );
  RebindResult rebindResult = const RebindResult(RebindStatus.activated);
  DeviceStatusResult deviceStatusResult = const DeviceStatusResult(
    DeviceBindingStatus.active,
  );

  final List<String> calls = [];

  @override
  Future<RegistrationOtpResult> requestRegistrationOtp({
    required String mobileNumber,
    required String deviceId,
  }) async {
    calls.add('requestRegistrationOtp');
    return registrationOtpResult;
  }

  @override
  Future<RegistrationVerifyResult> verifyRegistrationOtp({
    required String accountId,
    required String deviceId,
    required String code,
  }) async {
    calls.add('verifyRegistrationOtp');
    return registrationVerifyResult;
  }

  @override
  Future<LoginResult> evaluateLogin({
    required String mobileNumber,
    required String deviceId,
  }) async {
    calls.add('evaluateLogin');
    return loginResult;
  }

  @override
  Future<ConfirmTakeoverResult> confirmTakeover({
    required String mobileNumber,
    required String deviceId,
  }) async {
    calls.add('confirmTakeover');
    return confirmTakeoverResult;
  }

  @override
  Future<LoginOtpResult> requestLoginOtp({
    required String accountId,
    required String deviceId,
  }) async {
    calls.add('requestLoginOtp');
    return loginOtpResult;
  }

  @override
  Future<OtpVerifyResult> verifyLoginOtp({
    required String accountId,
    required String deviceId,
    required String code,
  }) async {
    calls.add('verifyLoginOtp');
    return otpVerifyResult;
  }

  @override
  Future<RebindingAuthorizationResult> checkRebindingAuthorization({
    required String accountId,
    required String deviceId,
  }) async {
    calls.add('checkRebindingAuthorization');
    return rebindingAuthorizationResult;
  }

  @override
  Future<RebindResult> completeRebinding({
    required String accountId,
    required String deviceId,
  }) async {
    calls.add('completeRebinding');
    return rebindResult;
  }

  @override
  Future<DeviceStatusResult> getDeviceBindingStatus({
    required String accountId,
    required String deviceId,
  }) async {
    calls.add('getDeviceBindingStatus');
    return deviceStatusResult;
  }
}
