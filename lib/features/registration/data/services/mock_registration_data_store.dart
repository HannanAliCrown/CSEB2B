import '../../../../core/mock/partner_directory.dart';

/// The prototype's registration-side view of Crown Solar's records: the
/// accounts that already exist, the market list, and the OTP that was "sent".
///
/// The accounts themselves come from [PartnerDirectory], so a number resolves
/// to the same business here, at sign-in and anywhere else it is used.
/// Swapping this for an API-backed implementation of `RegistrationService`
/// leaves the UI untouched.
class MockRegistrationDataStore {
  MockRegistrationDataStore() {
    reset();
  }

  static const seededAccounts = PartnerDirectory.accounts;
  static const seededMarkets = PartnerDirectory.markets;

  /// The code the prototype treats as the delivered SMS. It lives here, not
  /// in the UI, so a real OTP service can replace it.
  static const developmentOtp = '123456';

  final List<PartnerAccount> _accounts = [];
  final Map<String, String> _otpByNumber = {};

  void reset() {
    _accounts
      ..clear()
      ..addAll(seededAccounts);
    _otpByNumber.clear();
  }

  List<PartnerAccount> get accounts => List.unmodifiable(_accounts);

  PartnerAccount? accountFor(String mobileNumber) {
    final needle = normalise(mobileNumber);
    if (needle.isEmpty) return null;
    for (final account in _accounts) {
      if (normalise(account.mobileNumber) == needle) return account;
    }
    return null;
  }

  /// The account already holding this CNIC, if any. Digits only, so the
  /// dashes a partner types never decide the answer.
  PartnerAccount? accountForCnic(String cnicNumber) {
    final needle = digitsOf(cnicNumber);
    if (needle.length != 13) return null;
    for (final account in _accounts) {
      if (digitsOf(account.cnicNumber) == needle) return account;
    }
    return null;
  }

  static String digitsOf(String value) => value.replaceAll(RegExp(r'\D'), '');

  String issueOtp(String mobileNumber) {
    final code = developmentOtp;
    _otpByNumber[normalise(mobileNumber)] = code;
    return code;
  }

  String? expectedOtp(String mobileNumber) =>
      _otpByNumber[normalise(mobileNumber)];

  void clearOtp(String mobileNumber) =>
      _otpByNumber.remove(normalise(mobileNumber));

  /// Numbers are compared digits-only, so spacing and a leading 0 or +92
  /// never decide whether an account is found.
  static String normalise(String mobileNumber) =>
      PartnerDirectory.normalise(mobileNumber);
}
