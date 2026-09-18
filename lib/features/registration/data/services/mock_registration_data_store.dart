/// An account that already exists in the prototype's world.
class MockAccount {
  const MockAccount({
    required this.mobileNumber,
    required this.role,
    required this.displayName,
    required this.market,
    required this.cnicNumber,
  });

  final String mobileNumber;
  final String role;
  final String displayName;
  final String market;

  /// The CNIC already on file for this account, so a second registration
  /// cannot claim the same identity.
  final String cnicNumber;
}

/// The prototype's stand-in for Crown Solar's records: the accounts that
/// already exist, the businesses a buying-source number resolves to, the
/// market list, and the OTP that was "sent".
///
/// Everything the registration journey decides comes from here, so no screen
/// ever contains a business rule. Swapping this for an API-backed
/// implementation of `RegistrationService` leaves the UI untouched.
class MockRegistrationDataStore {
  MockRegistrationDataStore() {
    reset();
  }

  /// Development numbers, documented so the journeys are reproducible.
  static const seededAccounts = <MockAccount>[
    MockAccount(
      mobileNumber: '+92 321 7745002',
      role: 'Retailer',
      displayName: 'Bilal Traders',
      market: 'Hall Road, Lahore',
      cnicNumber: '35202-1122334-5',
    ),
    MockAccount(
      mobileNumber: '+92 300 4821190',
      role: 'Installer',
      displayName: 'Adnan Solar Works',
      market: 'Ravi Road, Lahore',
      cnicNumber: '35202-7719480-3',
    ),
    MockAccount(
      mobileNumber: '+92 300 7781204',
      role: 'Retailer',
      displayName: 'Al-Noor Electric Store',
      market: 'Ravi Road, Lahore',
      cnicNumber: '35202-4410932-7',
    ),
    MockAccount(
      mobileNumber: '+92 301 4429911',
      role: 'Wholesaler',
      displayName: 'Hamza Solar House',
      market: 'Badami Bagh, Lahore',
      cnicNumber: '35202-9087651-1',
    ),
  ];

  static const seededMarkets = <String>[
    'Ravi Road, Lahore',
    'Hall Road, Lahore',
    'Badami Bagh, Lahore',
    'Shahdara, Lahore',
    'Model Town, Lahore',
  ];

  /// The code the prototype treats as the delivered SMS. It lives here, not
  /// in the UI, so a real OTP service can replace it.
  static const developmentOtp = '123456';

  final List<MockAccount> _accounts = [];
  final Map<String, String> _otpByNumber = {};

  void reset() {
    _accounts
      ..clear()
      ..addAll(seededAccounts);
    _otpByNumber.clear();
  }

  List<MockAccount> get accounts => List.unmodifiable(_accounts);

  MockAccount? accountFor(String mobileNumber) {
    final needle = normalise(mobileNumber);
    for (final account in _accounts) {
      if (normalise(account.mobileNumber) == needle) return account;
    }
    return null;
  }

  /// The account already holding this CNIC, if any. Digits only, so the
  /// dashes a partner types never decide the answer.
  MockAccount? accountForCnic(String cnicNumber) {
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
  static String normalise(String mobileNumber) {
    final digits = mobileNumber.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('92')) return digits.substring(2);
    if (digits.startsWith('0')) return digits.substring(1);
    return digits;
  }
}
