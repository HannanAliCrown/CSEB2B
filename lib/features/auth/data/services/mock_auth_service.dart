// Constructor parameters are named for their public API rather than the
// private fields they populate, so the initializing-formal shorthand the
// linter suggests is not available here.
// ignore_for_file: prefer_initializing_formals

import 'dart:convert';
import 'dart:math';

import '../../../../core/mock/partner_directory.dart';
import '../../../../core/mock/pending_registrations.dart';
import '../../../../core/prefs/app_preferences.dart';
import 'auth_service.dart';

/// Sign-in against the bundled directory, for a build with no server.
///
/// It stands in for `prototype_server` at the [AuthService] boundary the same
/// way `MockSessionService` stands in at the session boundary, so a build
/// started with the default `DATA_SOURCE=mock` reaches Home on the numbers in
/// [PartnerDirectory] instead of failing on an unreachable host.
///
/// It is a stand-in, not a second rulebook: it does not reproduce the
/// device-move tiers, CRM rebinding authorization or cross-account takeover
/// that `prototype_server` decides. A phone is untrusted until it has
/// verified a code once, and trusted afterwards — which is what the Board 02
/// screens need in order to be reachable without a server.
class MockAuthService implements AuthService {
  MockAuthService({required AppPreferences preferences, Random? random})
    : _preferences = preferences,
      _random = random ?? Random();

  /// The numbers this installation has already verified, as a JSON list of
  /// normalised digits. Kept on the phone so a verified phone stays verified
  /// across restarts, the way a real binding would.
  static const _trustedKey = 'auth.mock_trusted_numbers';

  /// A small delay so the UI's loading states are exercised the way they
  /// will be against a real network.
  static const _latency = Duration(milliseconds: 250);

  final AppPreferences _preferences;
  final Random _random;

  /// The code currently outstanding, per normalised number. The prototype has
  /// no SMS gateway, so the code is handed back to the screen instead.
  final _challenges = <String, String>{};

  // --- Registration ---------------------------------------------------------

  @override
  Future<RegistrationOtpResult> requestRegistrationOtp({
    required String mobileNumber,
    required String deviceId,
  }) async {
    await Future<void>.delayed(_latency);
    final id = _accountId(mobileNumber);
    if (id == null) {
      return const RegistrationOtpResult.failure(
        RegistrationOtpStatus.accountNotFound,
      );
    }
    if (await _isTrusted(mobileNumber)) {
      return const RegistrationOtpResult.failure(
        RegistrationOtpStatus.alreadyRegistered,
      );
    }
    return RegistrationOtpResult.issued(
      accountId: id,
      deviceId: deviceId,
      prototypeCode: _issueCode(mobileNumber),
    );
  }

  @override
  Future<RegistrationVerifyResult> verifyRegistrationOtp({
    required String accountId,
    required String deviceId,
    required String code,
  }) async {
    await Future<void>.delayed(_latency);
    return switch (_checkCode(accountId, code)) {
      OtpVerifyStatus.verified => () {
        _trust(accountId);
        return const RegistrationVerifyResult(
          RegistrationVerifyStatus.activated,
        );
      }(),
      OtpVerifyStatus.invalidCode => const RegistrationVerifyResult(
        RegistrationVerifyStatus.invalidCode,
      ),
      OtpVerifyStatus.notFound => const RegistrationVerifyResult(
        RegistrationVerifyStatus.notFound,
      ),
    };
  }

  // --- Login ----------------------------------------------------------------

  @override
  Future<LoginResult> evaluateLogin({
    required String mobileNumber,
    required String deviceId,
  }) async {
    await Future<void>.delayed(_latency);
    final id = _accountId(mobileNumber);
    if (id == null) return const LoginResult.accountNotFound();

    // A phone that has verified this number once is the phone the account is
    // on, so it goes straight in. Nothing here is a second device: the mock
    // never reports the tier that sends the partner to the locked screen.
    if (await _isTrusted(mobileNumber)) {
      return LoginResult.success(
        status: LoginStatus.trusted,
        accountId: id,
        deviceId: deviceId,
      );
    }

    return LoginResult.success(
      status: LoginStatus.newUntrusted,
      accountId: id,
      deviceId: deviceId,
      tier: DeviceMoveTier.secondDevice,
    );
  }

  /// Never reached: [evaluateLogin] reports no conflict, because one phone
  /// holding another partner's account is a server-side fact the mock has no
  /// way to know.
  @override
  Future<ConfirmTakeoverResult> confirmTakeover({
    required String mobileNumber,
    required String deviceId,
  }) async => const ConfirmTakeoverResult(acknowledged: true);

  @override
  Future<LoginOtpResult> requestLoginOtp({
    required String accountId,
    required String deviceId,
  }) async {
    await Future<void>.delayed(_latency);
    return LoginOtpResult.issued(
      challengeId: accountId,
      prototypeCode: _issueCode(accountId),
    );
  }

  @override
  Future<OtpVerifyResult> verifyLoginOtp({
    required String accountId,
    required String deviceId,
    required String code,
  }) async {
    await Future<void>.delayed(_latency);
    return OtpVerifyResult(_checkCode(accountId, code));
  }

  /// Never reached: the mock only ever reports
  /// [DeviceMoveTier.secondDevice], which the login flow does not gate on
  /// CRM authorization.
  @override
  Future<RebindingAuthorizationResult> checkRebindingAuthorization({
    required String accountId,
    required String deviceId,
  }) async => const RebindingAuthorizationResult(
    RebindingAuthorizationStatus.authorized,
  );

  @override
  Future<RebindResult> completeRebinding({
    required String accountId,
    required String deviceId,
  }) async {
    await Future<void>.delayed(_latency);
    await _trust(accountId);
    return const RebindResult(RebindStatus.activated);
  }

  @override
  Future<DeviceStatusResult> getDeviceBindingStatus({
    required String accountId,
    required String deviceId,
  }) async => DeviceStatusResult(
    await _isTrusted(accountId)
        ? DeviceBindingStatus.active
        : DeviceBindingStatus.newUntrusted,
  );

  // --- The directory, the codes, and what this phone has verified ----------

  /// The account behind a number, which for the mock is the number itself:
  /// every other call carries it back, and both the bundled directory and an
  /// application submitted on this phone can sign in.
  String? _accountId(String mobileNumber) {
    final key = PartnerDirectory.normalise(mobileNumber);
    final known =
        PartnerDirectory.find(mobileNumber) != null ||
        PendingRegistrations.find(mobileNumber) != null;
    return known ? key : null;
  }

  String _issueCode(String accountId) {
    final code = (_random.nextInt(900000) + 100000).toString();
    _challenges[PartnerDirectory.normalise(accountId)] = code;
    return code;
  }

  OtpVerifyStatus _checkCode(String accountId, String code) {
    final key = PartnerDirectory.normalise(accountId);
    final expected = _challenges[key];
    if (expected == null) return OtpVerifyStatus.notFound;
    if (expected != code) return OtpVerifyStatus.invalidCode;
    _challenges.remove(key);
    return OtpVerifyStatus.verified;
  }

  Future<Set<String>> _trusted() async {
    final raw = await _preferences.readString(_trustedKey);
    if (raw == null) return {};
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded.cast<String>().toSet();
  }

  Future<bool> _isTrusted(String accountId) async =>
      (await _trusted()).contains(PartnerDirectory.normalise(accountId));

  Future<void> _trust(String accountId) async {
    final numbers = await _trusted();
    numbers.add(PartnerDirectory.normalise(accountId));
    await _preferences.writeString(_trustedKey, jsonEncode(numbers.toList()));
  }
}
