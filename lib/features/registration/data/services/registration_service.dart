import '../models/registration_draft.dart';

/// Whether the number the applicant typed already belongs to an account.
class AccountLookupResult {
  const AccountLookupResult.notFound()
    : exists = false,
      role = null,
      displayName = null;
  const AccountLookupResult.existing({
    required this.role,
    required this.displayName,
  }) : exists = true;

  final bool exists;

  /// The role of the account that already holds the number, e.g. 'Retailer'.
  final String? role;
  final String? displayName;
}

/// The result of asking for a registration OTP. The code is returned for the
/// prototype only — a real SMS gateway would deliver it instead.
class OtpIssueResult {
  const OtpIssueResult({required this.prototypeCode});
  final String prototypeCode;
}

enum OtpVerifyOutcome { verified, invalidCode, noChallenge }

/// The business a buying-source number resolves to.
class BuyingSourceLookup {
  const BuyingSourceLookup.notFound()
    : found = false,
      name = null,
      role = null,
      market = null;
  const BuyingSourceLookup.found({
    required this.name,
    required this.role,
    required this.market,
  }) : found = true;

  final bool found;
  final String? name;
  final String? role;
  final String? market;
}

enum RegistrationApprovalState { outstanding, approved, rejected }

/// A submitted registration and where its three approvals stand.
class RegistrationSubmission {
  const RegistrationSubmission({
    required this.reference,
    required this.submittedAt,
    required this.verifyingSourceName,
    required this.buyingSourceState,
    required this.marketingOfficerState,
    required this.crmState,
  });

  final String reference;
  final DateTime submittedAt;
  final String? verifyingSourceName;
  final RegistrationApprovalState buyingSourceState;
  final RegistrationApprovalState marketingOfficerState;
  final RegistrationApprovalState crmState;

  int get approvalsReceived => [
    buyingSourceState,
    marketingOfficerState,
    crmState,
  ].where((s) => s == RegistrationApprovalState.approved).length;
}

/// The registration boundary the app talks to.
///
/// One implementation exists today — the local mock — and an HTTP one can
/// replace it later without the ViewModel or any screen changing.
abstract interface class RegistrationService {
  /// Markets the applicant can pick from on the details step.
  Future<List<String>> markets();

  Future<AccountLookupResult> lookupAccount(String mobileNumber);

  Future<OtpIssueResult> requestRegistrationOtp(String mobileNumber);

  Future<OtpVerifyOutcome> verifyRegistrationOtp({
    required String mobileNumber,
    required String code,
  });

  Future<BuyingSourceLookup> lookupBuyingSource(String mobileNumber);

  /// Records the application. Only the first buying source is asked to
  /// verify it; the rest are kept with the request.
  Future<RegistrationSubmission> submit(RegistrationDraft draft);

  Future<RegistrationSubmission?> latestSubmission();
}
