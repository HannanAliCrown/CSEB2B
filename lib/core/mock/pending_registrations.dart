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
  });

  final String reference;
  final String mobileNumber;
  final String businessName;
  final String contactName;
  final String role;
  final String market;

  /// The buying source asked to confirm the applicant really buys from them.
  final String? verifyingSourceName;

  final DateTime submittedAt;

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

  static void clear() => _byNumber.clear();
}
