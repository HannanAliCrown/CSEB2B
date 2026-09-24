import 'staff_models.dart';

/// What a partner is measured against when board types are filtered.
class BrandingEligibilityRow {
  const BrandingEligibilityRow({
    required this.role,
    required this.schemeSigned,
    required this.points,
    required this.scanWindowDays,
    required this.replacementMonths,
    required this.daysSinceLastScan,
    this.existingBoardName,
    this.existingBoardInstalledOn,
    this.existingBoardMonths,
  });

  final String role;
  final bool schemeSigned;
  final int points;

  /// How recently an installer must have scanned for options to open.
  final int scanWindowDays;

  /// How new an installed board must be for replacement detection to take
  /// over.
  final int replacementMonths;

  /// Null when they have never scanned.
  final int? daysSinceLastScan;

  /// The board already on the shopfront, if any.
  final String? existingBoardName;
  final DateTime? existingBoardInstalledOn;

  /// Whole months since it went up, so the client can say "under 6 months"
  /// without recomputing a date the server already compared.
  final int? existingBoardMonths;

  Map<String, dynamic> toJson() => {
    'role': role,
    'schemeSigned': schemeSigned,
    'points': points,
    'scanWindowDays': scanWindowDays,
    'replacementMonths': replacementMonths,
    'daysSinceLastScan': daysSinceLastScan,
    'existingBoardName': existingBoardName,
    'existingBoardInstalledOn': existingBoardInstalledOn?.toIso8601String(),
    'existingBoardMonths': existingBoardMonths,
  };
}

/// One board type as it stands for one partner: what it is, what it costs,
/// and either that it is available or the one thing standing in the way.
class BrandingBoardTypeRow {
  const BrandingBoardTypeRow({
    required this.code,
    required this.name,
    required this.description,
    required this.unitPricePaisa,
    required this.companyPercent,
    required this.available,
    required this.condition,
    this.lockedReason,
  });

  final String code;
  final String name;
  final String description;
  final int unitPricePaisa;
  final int companyPercent;

  final bool available;

  /// Why it is open, in the partner's own terms — "Scheme signed",
  /// "15,000 points and a signed scheme". Shown under the name once picked.
  final String condition;

  /// What would open it, for an option that is locked. Deliberately the
  /// same vocabulary as [condition]: what to do, never which internal rule
  /// refused.
  final String? lockedReason;

  Map<String, dynamic> toJson() => {
    'code': code,
    'name': name,
    'description': description,
    'unitPricePaisa': unitPricePaisa,
    'companyPercent': companyPercent,
    'available': available,
    'condition': condition,
    'lockedReason': lockedReason,
  };
}

/// The board types open to a partner right now, and why that set is what it
/// is.
class BrandingOptionsRow {
  const BrandingOptionsRow({
    required this.eligibility,
    required this.boardTypes,
    required this.replacementOnly,
    this.replacementNotice,
  });

  final BrandingEligibilityRow eligibility;
  final List<BrandingBoardTypeRow> boardTypes;

  /// True when a board new enough to replace has collapsed the list. The
  /// screen says so plainly, because options vanishing without explanation
  /// reads as a fault.
  final bool replacementOnly;
  final String? replacementNotice;

  Map<String, dynamic> toJson() => {
    'eligibility': eligibility.toJson(),
    'boardTypes': [for (final type in boardTypes) type.toJson()],
    'replacementOnly': replacementOnly,
    'replacementNotice': replacementNotice,
  };
}

/// One board inside a request.
class BrandingRequestBoardRow {
  const BrandingRequestBoardRow({
    required this.position,
    required this.code,
    required this.name,
    required this.unitPricePaisa,
    required this.companyPercent,
  });

  final int position;
  final String code;
  final String name;
  final int unitPricePaisa;
  final int companyPercent;

  int get companyPaisa => unitPricePaisa * companyPercent ~/ 100;
  int get partnerPaisa => unitPricePaisa - companyPaisa;

  Map<String, dynamic> toJson() => {
    'position': position,
    'code': code,
    'name': name,
    'unitPricePaisa': unitPricePaisa,
    'companyPercent': companyPercent,
    'companyPaisa': companyPaisa,
    'partnerPaisa': partnerPaisa,
  };
}

/// One branding request, with everything its status screen shows.
class BrandingRequestRow {
  const BrandingRequestRow({
    required this.reference,
    required this.status,
    required this.stage,
    required this.heightFt,
    required this.widthFt,
    required this.boardCount,
    required this.boards,
    required this.createdAt,
    this.shopAddress,
    this.contactNumber,
    this.personName,
    this.rejectionReason,
    this.raisedBy,
  });

  final String reference;

  /// 'in_progress' | 'completed' | 'rejected'.
  final String status;

  /// 1 approved · 2 board installed · 3 call confirmed.
  final int stage;

  final double heightFt;
  final double widthFt;
  final int boardCount;
  final List<BrandingRequestBoardRow> boards;
  final DateTime createdAt;

  final String? shopAddress;
  final String? contactNumber;
  final String? personName;
  final String? rejectionReason;

  /// The officer who raised it through Crown Solar Teams; null when the
  /// partner raised it.
  final RaisedByRow? raisedBy;

  int get totalPaisa => boards.fold(0, (sum, b) => sum + b.unitPricePaisa);
  int get companyPaisa => boards.fold(0, (sum, b) => sum + b.companyPaisa);
  int get partnerPaisa => totalPaisa - companyPaisa;

  Map<String, dynamic> toJson() => {
    'reference': reference,
    'status': status,
    'stage': stage,
    'heightFt': heightFt,
    'widthFt': widthFt,
    'boardCount': boardCount,
    'boards': [for (final board in boards) board.toJson()],
    'createdAt': createdAt.toIso8601String(),
    'shopAddress': shopAddress,
    'contactNumber': contactNumber,
    'personName': personName,
    'rejectionReason': rejectionReason,
    'raisedBy': raisedBy?.toJson(),
    'totalPaisa': totalPaisa,
    'companyPaisa': companyPaisa,
    'partnerPaisa': partnerPaisa,
  };
}

/// The module landing: what is live, what came before, and the eligibility
/// facts that decide which board types appear later.
class BrandingLandingRow {
  const BrandingLandingRow({
    required this.eligibility,
    required this.requests,
    this.current,
  });

  final BrandingEligibilityRow eligibility;

  /// The request still moving, if there is one. At most one is live at a
  /// time, so this is a value rather than a list.
  final BrandingRequestRow? current;

  /// Every request this partner has made, newest first.
  final List<BrandingRequestRow> requests;

  Map<String, dynamic> toJson() => {
    'eligibility': eligibility.toJson(),
    'current': current?.toJson(),
    'requests': [for (final request in requests) request.toJson()],
  };
}

/// Why a request could not be created.
enum BrandingRefusal {
  unknownAccount,

  /// A board type was named that this partner cannot have right now.
  optionNotAvailable,

  /// One type per board, and as many as the request asked for.
  boardCountMismatch,

  /// One live request at a time.
  requestAlreadyOpen,
}

/// Shop Branding's data boundary.
abstract interface class BrandingDataStore {
  /// The landing screen: eligibility, the live request and the history.
  Future<BrandingLandingRow?> landing(String mobileNumber);

  /// The board types this partner may pick from right now, already filtered
  /// by replacement detection, role, points, scheme and recent scanning.
  Future<BrandingOptionsRow?> options(String mobileNumber);

  /// One request by its reference.
  Future<BrandingRequestRow?> request({
    required String mobileNumber,
    required String reference,
  });

  /// Files a request. The board types are re-checked here rather than
  /// trusted from the client: what was offered minutes ago may not be
  /// offered now.
  Future<(BrandingRequestRow?, BrandingRefusal?)> createRequest({
    required String mobileNumber,
    required String shopPhotoPath,
    required String cardPhotoPath,
    required double heightFt,
    required double widthFt,
    required int boardCount,
    required List<String> boardTypeCodes,
    String? shopAddress,
    String? contactNumber,
    String? personName,
  });
}
