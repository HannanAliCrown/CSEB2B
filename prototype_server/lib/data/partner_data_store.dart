import 'partner_models.dart';

/// The persistence boundary for first launch and the registration wizard.
///
/// Route handlers depend on this, never on the `postgres` package, so they
/// can be tested against an in-memory fake exactly as the auth routes are.
abstract interface class PartnerDataStore {
  // --- First launch ---

  /// Records what first launch settled about a phone, creating the device row
  /// on first sight. Safe to call more than once: later calls update only the
  /// fields supplied.
  Future<void> recordDeviceLaunch(DeviceLaunchInput input);

  // --- Reference data ---

  /// Active markets, alphabetically. The details step offers these and
  /// nothing else.
  Future<List<Market>> markets();

  // --- Lookups the wizard performs ---

  /// The account holding this number, or null. Numbers are matched on their
  /// ten national digits, so 0300…, 300… and +92 300… are one subscriber.
  Future<PartnerAccountRow?> findAccountByMobileNumber(String mobileNumber);

  /// The account holding this CNIC, or null. One identity registers once.
  Future<PartnerAccountRow?> findAccountByCnic(String cnicNumber);

  /// The open application on this number, or null. A rejected or withdrawn
  /// one does not count.
  Future<ApplicationRow?> openApplicationForNumber(String mobileNumber);

  /// The most recent application on this number, whatever its state — what
  /// the approval screen reads.
  Future<ApplicationRow?> latestApplicationForNumber(String mobileNumber);

  // --- Registration OTP ---

  /// Issues a challenge against a number that has no account yet, and returns
  /// the code. A real SMS gateway would deliver it instead.
  Future<String> issueWizardOtp(String mobileNumber);

  /// True when the code matches the newest unverified challenge on this
  /// number, which is then marked verified.
  Future<bool> verifyWizardOtp({
    required String mobileNumber,
    required String code,
  });

  // --- Home ---

  /// The wallet figure, the slider and the ticker for one partner.
  ///
  /// Slides and ticker messages are filtered here rather than in the app: an
  /// expired one or one aimed at another role never reaches the phone.
  /// Returns null when the number has no account.
  Future<DashboardRow?> dashboardFor(String mobileNumber);

  // --- Submission ---

  /// Writes the application, its buying sources, its media and its three
  /// outstanding approvals in one transaction.
  Future<SubmitResult> submitApplication(ApplicationInput input);

  // --- New profile requests ---

  /// Registrations naming this partner as their buying source and still
  /// waiting on them. Null when the number has no account.
  Future<List<ProfileRequestRow>?> profileRequests(String mobileNumber);

  /// The bands a buying source picks from before approving someone.
  Future<List<ExpectedPurchaseBand>> expectedPurchaseBands();

  /// Records this partner's verdict on one request.
  ///
  /// Only the buying source's own approval is touched: the marketing officer
  /// and CRM still have to make up their own minds, so approving here opens
  /// nobody's account by itself.
  /// Approving needs [expectedPurchaseBandId]; rejecting needs [note]. Both
  /// are also enforced by the database, so neither can be skipped.
  Future<ProfileRequestRefusal?> decideProfileRequest({
    required String mobileNumber,
    required String applicationId,
    required bool approved,
    String? expectedPurchaseBandId,
    String? note,
  });
}
