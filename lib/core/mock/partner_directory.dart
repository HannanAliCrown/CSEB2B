/// A partner account that already exists in the prototype's world.
///
/// One record per partner, shared by every feature, so a number resolves to
/// the same business whether it is looked up at sign-in, as a buying source,
/// or as a cash recipient.
class PartnerAccount {
  const PartnerAccount({
    required this.mobileNumber,
    required this.role,
    required this.displayName,
    required this.market,
    required this.cnicNumber,
    required this.contactName,
  });

  final String mobileNumber;

  /// Installer, Retailer, Wholesaler or Distributor.
  final String role;

  /// The business name, as Home's header shows it.
  final String displayName;

  final String market;

  /// The CNIC already on file, so a second registration cannot claim the
  /// same identity.
  final String cnicNumber;

  /// The person, where the business name is not their own name.
  final String contactName;
}

/// The prototype's stand-in for Crown Solar's partner records.
///
/// Everything any journey decides about "who is this number" comes from here,
/// so no screen ever contains a partner's details. Swapping this for an
/// API-backed directory leaves every feature above it untouched.
abstract final class PartnerDirectory {
  static const accounts = <PartnerAccount>[
    PartnerAccount(
      mobileNumber: '+92 321 7745002',
      role: 'Retailer',
      displayName: 'Bilal Traders',
      market: 'Hall Road, Lahore',
      cnicNumber: '35202-1122334-5',
      contactName: 'Bilal Ahmed',
    ),
    PartnerAccount(
      mobileNumber: '+92 300 4821190',
      role: 'Installer',
      displayName: 'Adnan Solar Works',
      market: 'Ravi Road, Lahore',
      cnicNumber: '35202-7719480-3',
      contactName: 'Muhammad Adnan Shahid',
    ),
    PartnerAccount(
      mobileNumber: '+92 300 7781204',
      role: 'Retailer',
      displayName: 'Al-Noor Electric Store',
      market: 'Ravi Road, Lahore',
      cnicNumber: '35202-4410932-7',
      contactName: 'Noor Hassan',
    ),
    PartnerAccount(
      mobileNumber: '+92 301 4429911',
      role: 'Wholesaler',
      displayName: 'Hamza Solar House',
      market: 'Badami Bagh, Lahore',
      cnicNumber: '35202-9087651-1',
      contactName: 'Hamza Iqbal',
    ),
    PartnerAccount(
      mobileNumber: '+92 333 5560071',
      role: 'Installer',
      displayName: 'Shahdara Solar Services',
      market: 'Shahdara, Lahore',
      cnicNumber: '35202-3312098-4',
      contactName: 'Usman Tariq',
    ),
    PartnerAccount(
      mobileNumber: '+92 302 8890143',
      role: 'Distributor',
      displayName: 'Ravi Distribution Co.',
      market: 'Ravi Road, Lahore',
      cnicNumber: '35202-7765431-9',
      contactName: 'Kamran Sheikh',
    ),
  ];

  static const markets = <String>[
    'Ravi Road, Lahore',
    'Hall Road, Lahore',
    'Badami Bagh, Lahore',
    'Shahdara, Lahore',
    'Model Town, Lahore',
  ];

  /// Numbers are compared digits-only, so spacing, a leading 0 and a +92
  /// country code never decide whether an account is found.
  static String normalise(String mobileNumber) {
    final digits = mobileNumber.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('92')) return digits.substring(2);
    if (digits.startsWith('0')) return digits.substring(1);
    return digits;
  }

  static PartnerAccount? find(String mobileNumber) {
    final needle = normalise(mobileNumber);
    if (needle.isEmpty) return null;
    for (final account in accounts) {
      if (normalise(account.mobileNumber) == needle) return account;
    }
    return null;
  }
}
