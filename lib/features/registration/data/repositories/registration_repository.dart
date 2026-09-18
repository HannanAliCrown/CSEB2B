// Constructor parameters are named for their public API rather than the
// private fields they populate, so the initializing-formal shorthand the
// linter suggests is not available here.
// ignore_for_file: prefer_initializing_formals

import '../models/registration_draft.dart';
import '../services/registration_draft_store.dart';
import '../services/registration_service.dart';

/// The registration application's data boundary: the draft on this phone,
/// and the lookups/submission that will one day be an API.
///
/// The ViewModel depends on this and nothing below it, so replacing
/// [RegistrationService]'s mock implementation with an HTTP one changes
/// nothing above this line.
class RegistrationRepository {
  RegistrationRepository({
    required RegistrationService service,
    required RegistrationDraftStore draftStore,
  }) : _service = service,
       _draftStore = draftStore;

  final RegistrationService _service;
  final RegistrationDraftStore _draftStore;

  // --- The unfinished application on this phone ---

  Future<RegistrationDraft?> readDraft() => _draftStore.read();

  Future<void> saveDraft(RegistrationDraft draft) =>
      _draftStore.save(draft.copyWith(updatedAt: DateTime.now()));

  /// Discards an unfinished draft. A submitted application is untouched.
  Future<void> discardDraft() => _draftStore.clear();

  // --- Lookups and submission ---

  Future<List<String>> markets() => _service.markets();

  Future<AccountLookupResult> lookupAccount(String mobileNumber) =>
      _service.lookupAccount(mobileNumber);

  Future<OtpIssueResult> requestOtp(String mobileNumber) =>
      _service.requestRegistrationOtp(mobileNumber);

  Future<OtpVerifyOutcome> verifyOtp({
    required String mobileNumber,
    required String code,
  }) => _service.verifyRegistrationOtp(mobileNumber: mobileNumber, code: code);

  Future<BuyingSourceLookup> lookupBuyingSource(String mobileNumber) =>
      _service.lookupBuyingSource(mobileNumber);

  Future<String?> cnicHolder(String cnicNumber) =>
      _service.cnicHolder(cnicNumber);

  Future<RegistrationSubmission> submit(RegistrationDraft draft) =>
      _service.submit(draft);

  Future<RegistrationSubmission?> latestSubmission() =>
      _service.latestSubmission();
}
