import '../models/registration_draft.dart';
import '../../../../core/mock/pending_registrations.dart';
import 'mock_registration_data_store.dart';
import 'registration_service.dart';

/// The local implementation of [RegistrationService], backed by
/// [MockRegistrationDataStore]. It behaves the way the real backend is
/// expected to: lookups resolve names, the OTP is issued and verified
/// server-side, and a submitted application starts with all three approvals
/// outstanding.
class MockRegistrationService implements RegistrationService {
  MockRegistrationService({MockRegistrationDataStore? store})
    : _store = store ?? MockRegistrationDataStore();

  final MockRegistrationDataStore _store;

  /// A small delay so the UI's loading states are exercised the way they
  /// will be against a real network.
  static const _latency = Duration(milliseconds: 250);

  RegistrationSubmission? _submission;

  MockRegistrationDataStore get store => _store;

  @override
  Future<List<String>> markets() async {
    await Future<void>.delayed(_latency);
    return MockRegistrationDataStore.seededMarkets;
  }

  @override
  Future<AccountLookupResult> lookupAccount(String mobileNumber) async {
    await Future<void>.delayed(_latency);
    final account = _store.accountFor(mobileNumber);
    if (account == null) return const AccountLookupResult.notFound();
    return AccountLookupResult.existing(
      role: account.role,
      displayName: account.displayName,
    );
  }

  @override
  Future<OtpIssueResult> requestRegistrationOtp(String mobileNumber) async {
    await Future<void>.delayed(_latency);
    return OtpIssueResult(prototypeCode: _store.issueOtp(mobileNumber));
  }

  @override
  Future<OtpVerifyOutcome> verifyRegistrationOtp({
    required String mobileNumber,
    required String code,
  }) async {
    await Future<void>.delayed(_latency);
    final expected = _store.expectedOtp(mobileNumber);
    if (expected == null) return OtpVerifyOutcome.noChallenge;
    if (expected != code) return OtpVerifyOutcome.invalidCode;
    _store.clearOtp(mobileNumber);
    return OtpVerifyOutcome.verified;
  }

  /// Roles a partner can buy Crown Solar product from. An installer buys the
  /// same way this applicant does, so an installer is never a buying source.
  static const buyingSourceRoles = {'Retailer', 'Wholesaler', 'Distributor'};

  @override
  Future<BuyingSourceLookup> lookupBuyingSource(String mobileNumber) async {
    await Future<void>.delayed(_latency);
    final account = _store.accountFor(mobileNumber);
    if (account == null) return const BuyingSourceLookup.notFound();
    if (!buyingSourceRoles.contains(account.role)) {
      return BuyingSourceLookup.ineligible(
        name: account.displayName,
        role: account.role,
      );
    }
    return BuyingSourceLookup.found(
      name: account.displayName,
      role: account.role,
      market: account.market,
    );
  }

  @override
  Future<String?> cnicHolder(String cnicNumber) async {
    await Future<void>.delayed(_latency);
    return _store.accountForCnic(cnicNumber)?.displayName;
  }

  @override
  Future<RegistrationSubmission> submit(RegistrationDraft draft) async {
    await Future<void>.delayed(_latency);
    final submittedAt = DateTime.now();
    final reference =
        'CSE-PR-${submittedAt.year}-'
        '${submittedAt.millisecondsSinceEpoch.remainder(1000000)}';

    // The applicant can now sign in, but only to watch the approvals land.
    PendingRegistrations.add(
      PendingRegistration(
        reference: reference,
        mobileNumber: draft.fullMobileNumber,
        businessName: draft.businessName,
        contactName: draft.fullName,
        role: draft.role?.label ?? 'Installer',
        market: draft.market ?? '',
        verifyingSourceName: draft.verifyingSource?.matchedName,
        submittedAt: submittedAt,
      ),
    );

    _submission = RegistrationSubmission(
      reference: reference,
      submittedAt: submittedAt,
      verifyingSourceName: draft.verifyingSource?.matchedName,
      // Submitting starts the approval chain; it never grants it.
      buyingSourceState: RegistrationApprovalState.outstanding,
      marketingOfficerState: RegistrationApprovalState.outstanding,
      crmState: RegistrationApprovalState.outstanding,
    );
    return _submission!;
  }

  @override
  Future<RegistrationSubmission?> latestSubmission() async => _submission;

  /// Development support: clears issued OTPs, the submitted application and
  /// any account changes, restoring the deterministic starting state.
  void reset() {
    _store.reset();
    _submission = null;
  }
}
