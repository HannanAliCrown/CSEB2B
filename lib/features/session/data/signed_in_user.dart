import '../../../core/mock/partner_directory.dart';
import '../../../core/mock/pending_registrations.dart';

/// The partner using the app right now.
///
/// Home's header, the wallet and every "who am I" question read this, so no
/// screen ever names a business or a role of its own.
class SignedInUser {
  const SignedInUser({
    required this.mobileNumber,
    required this.businessName,
    required this.contactName,
    required this.role,
    required this.market,
    this.approved = true,
  });

  factory SignedInUser.fromAccount(PartnerAccount account) => SignedInUser(
    mobileNumber: account.mobileNumber,
    businessName: account.displayName,
    contactName: account.contactName,
    role: PartnerRoleX.parse(account.role),
    market: account.market,
  );

  /// An application that has been submitted but not yet approved. The partner
  /// can sign in, but only to watch the approvals land.
  factory SignedInUser.fromPending(PendingRegistration pending) => SignedInUser(
    mobileNumber: pending.mobileNumber,
    businessName: pending.businessName,
    contactName: pending.contactName,
    role: PartnerRoleX.parse(pending.role),
    market: pending.market,
    approved: false,
  );

  /// False while the three approvals are still outstanding — nothing behind
  /// the dashboard opens until they are all in.
  final bool approved;

  SignedInUser copyWith({bool? approved}) => SignedInUser(
    mobileNumber: mobileNumber,
    businessName: businessName,
    contactName: contactName,
    role: role,
    market: market,
    approved: approved ?? this.approved,
  );

  final String mobileNumber;
  final String businessName;
  final String contactName;
  final PartnerRole role;
  final String market;

  Map<String, dynamic> toJson() => {
    'mobileNumber': mobileNumber,
    'businessName': businessName,
    'contactName': contactName,
    'role': role.name,
    'market': market,
    'approved': approved,
  };

  static SignedInUser? fromJson(Map<String, dynamic> json) {
    final role = PartnerRole.values
        .where((value) => value.name == json['role'])
        .firstOrNull;
    if (role == null) return null;
    return SignedInUser(
      mobileNumber: json['mobileNumber'] as String? ?? '',
      businessName: json['businessName'] as String? ?? '',
      contactName: json['contactName'] as String? ?? '',
      role: role,
      market: json['market'] as String? ?? '',
      approved: json['approved'] as bool? ?? true,
    );
  }
}

/// The four partner roles Crown Solar works with.
enum PartnerRole { installer, retailer, wholesaler, distributor }

extension PartnerRoleX on PartnerRole {
  /// As the header shows it: INSTALLER, RETAILER, …
  String get label => switch (this) {
    PartnerRole.installer => 'Installer',
    PartnerRole.retailer => 'Retailer',
    PartnerRole.wholesaler => 'Wholesaler',
    PartnerRole.distributor => 'Distributor',
  };

  /// Installers and retailers earn prizes by scanning; the trade roles move
  /// stock and points instead.
  bool get earnsPrizes =>
      this == PartnerRole.installer || this == PartnerRole.retailer;

  static PartnerRole parse(String raw) => PartnerRole.values.firstWhere(
    (role) => role.label.toLowerCase() == raw.trim().toLowerCase(),
    orElse: () => PartnerRole.installer,
  );
}
