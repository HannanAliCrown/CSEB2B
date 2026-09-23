/// Where one of the three approvals stands.
enum ApprovalState { outstanding, approved, rejected }

/// Who has to approve a registration before the account opens.
enum Approver { receiver, marketingOfficer, crm }

extension ApproverX on Approver {
  String get title => switch (this) {
    Approver.receiver => 'Buying Source',
    Approver.marketingOfficer => 'Marketing Officer',
    Approver.crm => 'CRM',
  };
}

/// A registration that has been submitted and is waiting on its approvals.
class PendingRegistration {
  PendingRegistration({
    required this.reference,
    required this.mobileNumber,
    required this.businessName,
    required this.contactName,
    required this.role,
    required this.market,
    required this.verifyingSourceName,
    required this.submittedAt,
    this.verifyingSourceNumber,
    this.businessAddress,
    this.alternateNumber,
    this.shopLatitude,
    this.shopLongitude,
    this.otherBuyingSources = const [],
    this.videoLinks = const [],
    this.shopImageSlots = const [],
    this.hasSelfie = false,
  });

  final String reference;
  final String mobileNumber;
  final String businessName;
  final String contactName;
  final String role;
  final String market;

  /// The buying source asked to confirm the applicant really buys from them.
  final String? verifyingSourceName;

  /// That same buying source's number, which is how their own inbox finds
  /// this application. Null when the applicant named nobody the directory
  /// knows — nothing is then routed anywhere.
  final String? verifyingSourceNumber;

  final DateTime submittedAt;

  /// The rest of what was submitted, kept as plain values so the features
  /// that show it — the buying source's inbox among them — can shape it
  /// however their own screens need. The CNIC number and its images are
  /// deliberately absent: they never leave CRM.
  final String? businessAddress;
  final String? alternateNumber;
  final String? shopLatitude;
  final String? shopLongitude;

  /// Every other source the applicant named, by the name they were matched
  /// to, or by number when the directory did not know them.
  final List<String> otherBuyingSources;

  final List<String> videoLinks;

  /// Which shop photos were taken, by the slot they filled.
  final List<String> shopImageSlots;

  final bool hasSelfie;

  /// All three start outstanding. Nothing is approved on submission.
  final Map<Approver, ApprovalState> approvals = {
    for (final approver in Approver.values) approver: ApprovalState.outstanding,
  };

  int get approvedCount =>
      approvals.values.where((s) => s == ApprovalState.approved).length;

  bool get isApproved => approvedCount == Approver.values.length;

  bool get isRejected =>
      approvals.values.any((s) => s == ApprovalState.rejected);
}

/// Registrations submitted on this phone, waiting on approval.
///
/// A submitted application is not an account yet: the partner can sign in,
/// but only to watch the approvals land. This is the prototype's stand-in for
/// the approval queue a real backend would own.
abstract final class PendingRegistrations {
  static final Map<String, PendingRegistration> _byNumber = {};

  static String _key(String mobileNumber) {
    final digits = mobileNumber.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('92')) return digits.substring(2);
    if (digits.startsWith('0')) return digits.substring(1);
    return digits;
  }

  static void add(PendingRegistration registration) =>
      _byNumber[_key(registration.mobileNumber)] = registration;

  static PendingRegistration? find(String mobileNumber) =>
      _byNumber[_key(mobileNumber)];

  /// The applications that named this partner as the buying source who has
  /// to verify them, newest first. This is how an application submitted on
  /// this phone reaches the inbox of the partner it names.
  static List<PendingRegistration> awaitingVerificationBy(String mobileNumber) {
    final needle = _key(mobileNumber);
    return [
      for (final registration in _byNumber.values)
        if (registration.verifyingSourceNumber != null &&
            _key(registration.verifyingSourceNumber!) == needle)
          registration,
    ]..sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
  }

  static void clear() => _byNumber.clear();
}
