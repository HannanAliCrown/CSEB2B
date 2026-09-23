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
      eligible = false,
      name = null,
      role = null,
      market = null;
  const BuyingSourceLookup.found({
    required this.name,
    required this.role,
    required this.market,
  }) : found = true,
       eligible = true;

  /// The number belongs to a real account, but not one this partner can buy
  /// from — an installer buys the same way they do.
  const BuyingSourceLookup.ineligible({required this.name, required this.role})
    : found = true,
      eligible = false,
      market = null;

  final bool found;

  /// Whether the account found may act as a buying source.
  final bool eligible;

  final String? name;
  final String? role;
  final String? market;

  /// Usable as a buying source: found, and of a role that sells.
  bool get usable => found && eligible;
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

  /// Whether this identity has already registered. Deliberately a yes or no:
  /// naming the holder would tell one applicant about another's business.
  Future<bool> cnicAlreadyRegistered(String cnicNumber);

  /// Records the application. Only the first buying source is asked to
  /// verify it; the rest are kept with the request.
  Future<RegistrationSubmission> submit(RegistrationDraft draft);

  /// The most recent application on this number, whatever state it is in.
  Future<RegistrationSubmission?> latestSubmission(String mobileNumber);

  /// Prototype only: records an approval a real approver would record in
  /// CRM, so the chain can be walked through without a back office — the
  /// same reason [RegistrationOtpResult.prototypeCode] is surfaced. A build
  /// with a server ignores it and answers with whatever the server holds.
  ///
  /// Returns the application as it now stands, or null when there is none.
  Future<RegistrationSubmission?> recordPrototypeApproval({
    required String mobileNumber,
    required PrototypeApprover approver,
  });
}

/// The approvals a server-less build can record from the app.
///
/// The buying source is absent on purpose: that verdict belongs to the
/// partner the applicant named, who gives it in New Profile. Nothing on the
/// applicant's own phone can stand in for them.
enum PrototypeApprover { marketingOfficer, crm }

/// A submission the server refused. The message is the one to show: the
/// wizard has already checked each of these, so reaching one means something
/// changed between the check and the submit.
class RegistrationSubmitFailure implements Exception {
  const RegistrationSubmitFailure(this.message);

  final String message;

  @override
  String toString() => message;
}
