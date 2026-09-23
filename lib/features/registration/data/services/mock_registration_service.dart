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
  Future<bool> cnicAlreadyRegistered(String cnicNumber) async {
    await Future<void>.delayed(_latency);
    return _store.accountForCnic(cnicNumber) != null;
  }

  @override
  Future<RegistrationSubmission> submit(RegistrationDraft draft) async {
    await Future<void>.delayed(_latency);
    final submittedAt = DateTime.now();
    final reference =
        'CSE-PR-${submittedAt.year}-'
        '${submittedAt.millisecondsSinceEpoch.remainder(1000000)}';

    // The applicant can now sign in, but only to watch the approvals land —
    // and the buying source they named can now see the request, because the
    // application carries that source's number with it.
    PendingRegistrations.add(
      PendingRegistration(
        reference: reference,
        mobileNumber: draft.fullMobileNumber,
        businessName: draft.businessName,
        contactName: draft.fullName,
        role: draft.role?.label ?? 'Installer',
        market: draft.market ?? '',
        verifyingSourceName: draft.verifyingSource?.matchedName,
        // Only a source the directory matched can be asked to verify
        // anything: an unmatched number belongs to nobody who can answer.
        verifyingSourceNumber: draft.verifyingSource?.isFound == true
            ? draft.verifyingSource!.mobileNumber
            : null,
        submittedAt: submittedAt,
        // Both are optional on the form and arrive as empty rather than
        // absent; a row with nothing in it is worse than no row.
        businessAddress: draft.businessAddress.trim().isEmpty
            ? null
            : draft.businessAddress.trim(),
        alternateNumber: draft.alternateNumber.trim().isEmpty
            ? null
            : draft.alternateNumber.trim(),
        shopLatitude: draft.shopLatitude?.toStringAsFixed(6),
        shopLongitude: draft.shopLongitude?.toStringAsFixed(6),
        // Every source but the one being asked to verify the application.
        otherBuyingSources: [
          for (final source in draft.buyingSources.skip(1))
            source.matchedName ?? source.mobileNumber,
        ],
        videoLinks: draft.videoLinks,
        shopImageSlots: draft.shopImagePaths.keys.toList(),
        hasSelfie: draft.selfiePath != null,
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
  Future<RegistrationSubmission?> latestSubmission(String mobileNumber) async {
    // Read back from the same store `submit` wrote to, so the approval screen
    // finds an application by its number rather than relying on this service
    // instance having been the one that took it.
    final pending = PendingRegistrations.find(mobileNumber);
    if (pending == null) return null;

    RegistrationApprovalState stateOf(Approver approver) =>
        switch (pending.approvals[approver]!) {
          ApprovalState.approved => RegistrationApprovalState.approved,
          ApprovalState.rejected => RegistrationApprovalState.rejected,
          ApprovalState.outstanding => RegistrationApprovalState.outstanding,
        };

    return RegistrationSubmission(
      reference: pending.reference,
      submittedAt: pending.submittedAt,
      verifyingSourceName: pending.verifyingSourceName,
      buyingSourceState: stateOf(Approver.receiver),
      marketingOfficerState: stateOf(Approver.marketingOfficer),
      crmState: stateOf(Approver.crm),
    );
  }

  @override
  Future<RegistrationSubmission?> recordPrototypeApproval({
    required String mobileNumber,
    required PrototypeApprover approver,
  }) async {
    await Future<void>.delayed(_latency);
    final pending = PendingRegistrations.find(mobileNumber);
    if (pending == null) return null;

    pending.approvals[switch (approver) {
          PrototypeApprover.marketingOfficer => Approver.marketingOfficer,
          PrototypeApprover.crm => Approver.crm,
        }] =
        ApprovalState.approved;

    return latestSubmission(mobileNumber);
  }

  /// Development support: clears issued OTPs, the submitted application and
  /// any account changes, restoring the deterministic starting state.
  void reset() {
    _store.reset();
    _submission = null;
  }
}
