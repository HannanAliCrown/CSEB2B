import 'package:prototype_server/data/partner_data_store.dart';
import 'package:prototype_server/data/partner_models.dart';
import 'package:prototype_server/data/postgres_partner_data_store.dart'
    show normaliseMobile;

/// An in-memory [PartnerDataStore], so route behaviour can be tested without
/// a database. It enforces the same rules the SQL does — one account per
/// number, one per CNIC, one open application per number — because those are
/// the rules the routes are being tested against.
class FakePartnerDataStore implements PartnerDataStore {
  final List<Market> _markets = [];
  final List<PartnerAccountRow> _accounts = [];
  final List<ApplicationRow> _applications = [];
  final Map<String, String> _otpByNumber = {};

  /// The last device launch recorded, for asserting first launch reported.
  DeviceLaunchInput? lastLaunch;

  var _nextId = 1;

  // --- Test setup ---

  Market addMarket(String name, {String city = 'Lahore'}) {
    final market = Market(id: 'm${_nextId++}', name: name, city: city);
    _markets.add(market);
    return market;
  }

  PartnerAccountRow addAccount({
    required String mobileNumber,
    required String userType,
    String? displayName,
    String? contactName,
    String? marketName,
    String? cnicNumber,
  }) {
    final account = PartnerAccountRow(
      id: 'a${_nextId++}',
      mobileNumber: normaliseMobile(mobileNumber),
      userType: userType,
      displayName: displayName,
      contactName: contactName,
      marketName: marketName,
      cnicNumber: cnicNumber,
    );
    _accounts.add(account);
    return account;
  }

  /// The code issued to a number, so a test can verify without reading the
  /// response it was handed.
  String? issuedOtpFor(String mobileNumber) =>
      _otpByNumber[normaliseMobile(mobileNumber)];

  final List<({PromoSlideRow slide, String audience})> _slides = [];
  final List<({TickerMessageRow message, String audience})> _ticker = [];
  final Map<String, ({int available, int held})> _wallets = {};

  PromoSlideRow addSlide({
    String audience = 'all',
    String? imageUrl,
    String? eyebrow,
    String? headline,
  }) {
    final slide = PromoSlideRow(
      id: 's${_nextId++}',
      imageUrl: imageUrl,
      eyebrow: eyebrow,
      headline: headline,
    );
    _slides.add((slide: slide, audience: audience));
    return slide;
  }

  void addTicker({
    required String message,
    String audience = 'all',
    String? textColour,
    String? backgroundColour,
  }) => _ticker.add((
    message: TickerMessageRow(
      message: message,
      textColour: textColour,
      backgroundColour: backgroundColour,
    ),
    audience: audience,
  ));

  void setWallet(String mobileNumber, {required int available, int held = 0}) =>
      _wallets[normaliseMobile(mobileNumber)] = (
        available: available,
        held: held,
      );

  // --- PartnerDataStore ---

  @override
  Future<void> recordDeviceLaunch(DeviceLaunchInput input) async {
    lastLaunch = input;
  }

  @override
  Future<List<Market>> markets() async =>
      [..._markets]..sort((a, b) => a.name.compareTo(b.name));

  @override
  Future<PartnerAccountRow?> findAccountByMobileNumber(
    String mobileNumber,
  ) async {
    final wanted = normaliseMobile(mobileNumber);
    for (final account in _accounts) {
      if (account.mobileNumber == wanted) return account;
    }
    return null;
  }

  @override
  Future<PartnerAccountRow?> findAccountByCnic(String cnicNumber) async {
    for (final account in _accounts) {
      if (account.cnicNumber == cnicNumber.trim()) return account;
    }
    return null;
  }

  @override
  Future<ApplicationRow?> openApplicationForNumber(String mobileNumber) async {
    final latest = await latestApplicationForNumber(mobileNumber);
    return latest?.status == 'submitted' ? latest : null;
  }

  @override
  Future<ApplicationRow?> latestApplicationForNumber(
    String mobileNumber,
  ) async {
    final wanted = normaliseMobile(mobileNumber);
    ApplicationRow? newest;
    for (final application in _applications) {
      if (application.mobileNumber != wanted) continue;
      if (newest == null ||
          application.submittedAt.isAfter(newest.submittedAt)) {
        newest = application;
      }
    }
    return newest;
  }

  @override
  Future<DashboardRow?> dashboardFor(String mobileNumber) async {
    final account = await findAccountByMobileNumber(mobileNumber);
    if (account == null) return null;

    bool reaches(String audience) =>
        audience == 'all' || audience == account.userType;

    final wallet =
        _wallets[normaliseMobile(mobileNumber)] ?? (available: 0, held: 0);

    return DashboardRow(
      availablePaisa: wallet.available,
      heldPaisa: wallet.held,
      slides: [
        for (final entry in _slides)
          if (reaches(entry.audience)) entry.slide,
      ],
      ticker: [
        for (final entry in _ticker)
          if (reaches(entry.audience)) entry.message,
      ],
    );
  }

  @override
  Future<String> issueWizardOtp(String mobileNumber) async {
    const code = '123456';
    _otpByNumber[normaliseMobile(mobileNumber)] = code;
    return code;
  }

  @override
  Future<bool> verifyWizardOtp({
    required String mobileNumber,
    required String code,
  }) async {
    final number = normaliseMobile(mobileNumber);
    if (_otpByNumber[number] != code) return false;
    _otpByNumber.remove(number);
    return true;
  }

  @override
  Future<SubmitResult> submitApplication(ApplicationInput input) async {
    final number = normaliseMobile(input.mobileNumber);

    final taken = await findAccountByMobileNumber(number);
    if (taken != null) {
      return SubmitResult.rejected(
        SubmitRejection.numberTaken,
        heldBy: taken.displayName,
      );
    }
    if (await findAccountByCnic(input.cnicNumber) != null) {
      return const SubmitResult.rejected(SubmitRejection.cnicTaken);
    }
    if (await openApplicationForNumber(number) != null) {
      return const SubmitResult.rejected(SubmitRejection.applicationOpen);
    }

    final first = input.buyingSources.isEmpty
        ? null
        : await findAccountByMobileNumber(
            input.buyingSources.first.mobileNumber,
          );

    final application = ApplicationRow(
      id: 'app${_nextId++}',
      reference: 'CSE-${number.substring(number.length - 7)}',
      mobileNumber: number,
      status: 'submitted',
      submittedAt: DateTime.now(),
      verifyingSourceName: first?.displayName,
      businessName: input.businessName,
      contactName: input.fullName,
      role: input.role,
      marketName: input.marketName,
      // All three start outstanding. Nothing is approved on submission.
      approvals: const [
        ApprovalRow(approver: 'buying_source', state: 'outstanding'),
        ApprovalRow(approver: 'crm', state: 'outstanding'),
        ApprovalRow(approver: 'marketing_officer', state: 'outstanding'),
      ],
    );
    _applications.add(application);
    // The first buying source is the one asked to verify, exactly as the SQL
    // has it — which is what puts this application in their inbox.
    if (first != null) _sourceAccountByApplication[application.id] = first.id;
    return SubmitResult.accepted(application);
  }

  // --- New profile requests ---

  /// Who the applicant named as their buying source, by application id. The
  /// SQL joins `registration_buying_sources`; here it is kept beside the
  /// application because nothing else needs it.
  final Map<String, String> _sourceAccountByApplication = {};

  /// The buying source's verdict, absent while it is still outstanding.
  final Map<String, bool> _decisionByApplication = {};

  @override
  Future<List<ProfileRequestRow>?> profileRequests(String mobileNumber) async {
    final account = await findAccountByMobileNumber(mobileNumber);
    if (account == null) return null;

    return [
      for (final application in _applications)
        if (application.status == 'submitted' &&
            _sourceAccountByApplication[application.id] == account.id &&
            !_decisionByApplication.containsKey(application.id))
          ProfileRequestRow(
            applicationId: application.id,
            reference: application.reference,
            mobileNumber: application.mobileNumber,
            contactName: application.contactName ?? '',
            businessName: application.businessName ?? '',
            role: application.role ?? 'installer',
            submittedAt: application.submittedAt,
            marketName: application.marketName,
          ),
    ]..sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
  }

  @override
  Future<List<ExpectedPurchaseBand>> expectedPurchaseBands() async => const [
    ExpectedPurchaseBand(id: 'band1', label: 'Up to PKR 100,000 a month'),
    ExpectedPurchaseBand(id: 'band2', label: 'Over PKR 100,000 a month'),
  ];

  @override
  Future<ProfileRequestRefusal?> decideProfileRequest({
    required String mobileNumber,
    required String applicationId,
    required bool approved,
    String? expectedPurchaseBandId,
    String? note,
  }) async {
    // The same two rules the SQL constraints enforce.
    if (approved && expectedPurchaseBandId == null) {
      return ProfileRequestRefusal.expectationMissing;
    }
    if (!approved && (note == null || note.trim().isEmpty)) {
      return ProfileRequestRefusal.reasonMissing;
    }

    final account = await findAccountByMobileNumber(mobileNumber);
    if (account == null) return ProfileRequestRefusal.unknownAccount;

    // Not theirs to decide, or already decided — the same answer either way,
    // so neither reveals anything about the other.
    if (_sourceAccountByApplication[applicationId] != account.id ||
        _decisionByApplication.containsKey(applicationId)) {
      return ProfileRequestRefusal.notOutstanding;
    }

    _decisionByApplication[applicationId] = approved;
    if (!approved) _reject(applicationId);
    return null;
  }

  void _reject(String applicationId) {
    final index = _applications.indexWhere((a) => a.id == applicationId);
    if (index < 0) return;
    final old = _applications[index];
    _applications[index] = ApplicationRow(
      id: old.id,
      reference: old.reference,
      mobileNumber: old.mobileNumber,
      status: 'rejected',
      submittedAt: old.submittedAt,
      verifyingSourceName: old.verifyingSourceName,
      approvals: old.approvals,
      businessName: old.businessName,
      contactName: old.contactName,
      role: old.role,
      marketName: old.marketName,
    );
  }
}
