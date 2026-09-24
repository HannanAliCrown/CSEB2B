// Constructor parameters are named for their public API rather than the
// private fields they populate, so the initializing-formal shorthand the
// linter suggests is not available here.
// ignore_for_file: prefer_initializing_formals

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/staff/raised_by.dart';
import '../../wallet/data/wallet_repository.dart';

/// What a partner is measured against when board types are filtered.
class BrandingEligibility {
  const BrandingEligibility({
    required this.role,
    required this.schemeSigned,
    required this.points,
    required this.scanWindowDays,
    required this.replacementMonths,
    this.daysSinceLastScan,
    this.existingBoardName,
    this.existingBoardMonths,
  });

  final String role;
  final bool schemeSigned;
  final int points;
  final int scanWindowDays;
  final int replacementMonths;

  /// Null when they have never scanned.
  final int? daysSinceLastScan;

  final String? existingBoardName;
  final int? existingBoardMonths;

  bool get hasExistingBoard => existingBoardName != null;

  /// "182,400" — grouped as every other figure in the app is.
  String get pointsFormatted => Money(points * 100).formatted;

  /// "Backlit · under 6 months old", or "None recorded".
  String get existingBoardLabel {
    final name = existingBoardName;
    if (name == null) return 'None recorded';
    final months = existingBoardMonths;
    if (months == null) return name;
    return months < replacementMonths
        ? '$name · under $replacementMonths months old'
        : '$name · $months months old';
  }

  static const empty = BrandingEligibility(
    role: 'installer',
    schemeSigned: false,
    points: 0,
    scanWindowDays: 10,
    replacementMonths: 6,
  );

  static BrandingEligibility fromJson(Map<String, dynamic> json) =>
      BrandingEligibility(
        role: json['role'] as String? ?? 'installer',
        schemeSigned: json['schemeSigned'] == true,
        points: (json['points'] as num?)?.toInt() ?? 0,
        scanWindowDays: (json['scanWindowDays'] as num?)?.toInt() ?? 10,
        replacementMonths: (json['replacementMonths'] as num?)?.toInt() ?? 6,
        daysSinceLastScan: (json['daysSinceLastScan'] as num?)?.toInt(),
        existingBoardName: json['existingBoardName'] as String?,
        existingBoardMonths: (json['existingBoardMonths'] as num?)?.toInt(),
      );
}

/// One board type, with either the condition that opened it or the one
/// thing standing in the way.
class BrandingBoardType {
  const BrandingBoardType({
    required this.code,
    required this.name,
    required this.description,
    required this.unitPrice,
    required this.companyPercent,
    required this.available,
    required this.condition,
    this.lockedReason,
  });

  final String code;
  final String name;
  final String description;
  final Money unitPrice;
  final int companyPercent;
  final bool available;
  final String condition;
  final String? lockedReason;

  int get partnerPercent => 100 - companyPercent;
  Money get companyShare => Money(unitPrice.paisa * companyPercent ~/ 100);
  Money get partnerShare => Money(unitPrice.paisa - companyShare.paisa);

  static BrandingBoardType fromJson(Map<String, dynamic> json) =>
      BrandingBoardType(
        code: json['code'] as String,
        name: json['name'] as String,
        description: json['description'] as String,
        unitPrice: Money((json['unitPricePaisa'] as num).toInt()),
        companyPercent: (json['companyPercent'] as num).toInt(),
        available: json['available'] == true,
        condition: json['condition'] as String? ?? '',
        lockedReason: json['lockedReason'] as String?,
      );
}

/// What this partner may pick from right now, and why that set is what it is.
class BrandingOptions {
  const BrandingOptions({
    required this.eligibility,
    required this.boardTypes,
    required this.replacementOnly,
    this.replacementNotice,
  });

  final BrandingEligibility eligibility;
  final List<BrandingBoardType> boardTypes;

  /// True when a board too new to replace has collapsed the list.
  final bool replacementOnly;
  final String? replacementNotice;

  List<BrandingBoardType> get open => [
    for (final type in boardTypes)
      if (type.available) type,
  ];

  bool get hasAnyOpen => open.isNotEmpty;

  static const empty = BrandingOptions(
    eligibility: BrandingEligibility.empty,
    boardTypes: [],
    replacementOnly: false,
  );

  static BrandingOptions fromJson(Map<String, dynamic> json) => BrandingOptions(
    eligibility: BrandingEligibility.fromJson(
      json['eligibility'] as Map<String, dynamic>? ?? const {},
    ),
    boardTypes: [
      for (final entry in json['boardTypes'] as List? ?? const [])
        BrandingBoardType.fromJson(entry as Map<String, dynamic>),
    ],
    replacementOnly: json['replacementOnly'] == true,
    replacementNotice: json['replacementNotice'] as String?,
  );
}

/// One board inside a request.
class BrandingRequestBoard {
  const BrandingRequestBoard({
    required this.position,
    required this.code,
    required this.name,
    required this.companyPercent,
    required this.company,
    required this.partner,
  });

  final int position;
  final String code;
  final String name;
  final int companyPercent;
  final Money company;
  final Money partner;

  int get partnerPercent => 100 - companyPercent;

  static BrandingRequestBoard fromJson(Map<String, dynamic> json) =>
      BrandingRequestBoard(
        position: (json['position'] as num).toInt(),
        code: json['code'] as String,
        name: json['name'] as String,
        companyPercent: (json['companyPercent'] as num).toInt(),
        company: Money((json['companyPaisa'] as num).toInt()),
        partner: Money((json['partnerPaisa'] as num).toInt()),
      );
}

/// One branding request, with everything its status screen shows.
class BrandingRequest {
  const BrandingRequest({
    required this.reference,
    required this.status,
    required this.stage,
    required this.heightFt,
    required this.widthFt,
    required this.boardCount,
    required this.boards,
    required this.createdAt,
    required this.total,
    required this.company,
    required this.partner,
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
  final List<BrandingRequestBoard> boards;
  final DateTime createdAt;

  final Money total;
  final Money company;
  final Money partner;
  final String? rejectionReason;

  /// Only when an officer raised it through Crown Solar Teams.
  final RaisedBy? raisedBy;

  bool get inProgress => status == 'in_progress';
  bool get completed => status == 'completed';
  bool get rejected => status == 'rejected';

  /// The share is one percentage across the request, so the first board
  /// speaks for all of them.
  int get companyPercent => boards.firstOrNull?.companyPercent ?? 60;
  int get partnerPercent => 100 - companyPercent;

  /// "Backlit Board", or "Backlit Board + 1 more" when the boards differ.
  String get boardSummary {
    if (boards.isEmpty) return 'No boards';
    final names = {for (final board in boards) board.name};
    if (names.length == 1) return names.first;
    return '${boards.first.name} + ${names.length - 1} more';
  }

  /// "4 ft × 12 ft × 2" — the measurements as the design writes them.
  String get dimensions =>
      '${_ft(heightFt)} ft × ${_ft(widthFt)} ft × $boardCount';

  static String _ft(double value) =>
      value == value.roundToDouble() ? '${value.round()}' : '$value';

  static BrandingRequest fromJson(Map<String, dynamic> json) => BrandingRequest(
    reference: json['reference'] as String,
    status: json['status'] as String,
    stage: (json['stage'] as num).toInt(),
    heightFt: (json['heightFt'] as num).toDouble(),
    widthFt: (json['widthFt'] as num).toDouble(),
    boardCount: (json['boardCount'] as num).toInt(),
    createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
    total: Money((json['totalPaisa'] as num).toInt()),
    company: Money((json['companyPaisa'] as num).toInt()),
    partner: Money((json['partnerPaisa'] as num).toInt()),
    rejectionReason: json['rejectionReason'] as String?,
    raisedBy: RaisedBy.fromJson(json['raisedBy']),
    boards: [
      for (final entry in json['boards'] as List? ?? const [])
        BrandingRequestBoard.fromJson(entry as Map<String, dynamic>),
    ],
  );
}

/// The module landing: what is live, what came before, and the eligibility
/// that decides which board types appear later.
class BrandingLanding {
  const BrandingLanding({
    required this.eligibility,
    required this.requests,
    this.current,
  });

  final BrandingEligibility eligibility;
  final BrandingRequest? current;
  final List<BrandingRequest> requests;

  static const empty = BrandingLanding(
    eligibility: BrandingEligibility.empty,
    requests: [],
  );

  static BrandingLanding fromJson(Map<String, dynamic> json) => BrandingLanding(
    eligibility: BrandingEligibility.fromJson(
      json['eligibility'] as Map<String, dynamic>? ?? const {},
    ),
    current: json['current'] == null
        ? null
        : BrandingRequest.fromJson(json['current'] as Map<String, dynamic>),
    requests: [
      for (final entry in json['requests'] as List? ?? const [])
        BrandingRequest.fromJson(entry as Map<String, dynamic>),
    ],
  );
}

/// Why a request could not be filed.
enum BrandingFailure {
  optionNotAvailable,
  boardCountMismatch,
  requestAlreadyOpen,
  unreachable,
}

extension BrandingFailureX on BrandingFailure {
  String get message => switch (this) {
    // What was offered minutes ago may not be offered now — a scan window
    // closes, a board goes up. Reloading is the whole fix.
    BrandingFailure.optionNotAvailable =>
      'One of those board types is no longer open to you. Pull down to see '
          'what is available now.',
    BrandingFailure.boardCountMismatch =>
      'Pick a type for every board you asked for.',
    BrandingFailure.requestAlreadyOpen =>
      'You already have a request in progress. Crown Solar finishes one '
          'before starting the next.',
    BrandingFailure.unreachable =>
      'Could not reach Crown Solar. Nothing has been sent — try again when '
          'you have signal.',
  };
}

/// Shop Branding's data boundary, backed by the database behind
/// `prototype_server`.
///
/// No eligibility rule lives here. Which board types a partner may ask for
/// is decided by the server against their role, points, signed scheme,
/// recent scanning and existing board — this only shows what came back, and
/// a request is re-checked server-side when it is filed.
class BrandingService {
  BrandingService({required String baseUrl, http.Client? client})
    : _baseUrl = baseUrl,
      _client = client ?? http.Client();

  final String _baseUrl;
  final http.Client _client;

  Future<BrandingLanding?> landing(String mobileNumber) async {
    final body = await _get('/branding', {'mobileNumber': mobileNumber});
    return body == null ? null : BrandingLanding.fromJson(body);
  }

  Future<BrandingOptions?> boardTypes(String mobileNumber) async {
    final body = await _get('/branding/board-types', {
      'mobileNumber': mobileNumber,
    });
    return body == null ? null : BrandingOptions.fromJson(body);
  }

  Future<BrandingRequest?> request({
    required String mobileNumber,
    required String reference,
  }) async {
    final body = await _get('/branding/requests/$reference', {
      'mobileNumber': mobileNumber,
    });
    return body == null ? null : BrandingRequest.fromJson(body);
  }

  /// Files a request. The board types are re-checked by the server, so a
  /// refusal here is a real change in what the partner may have.
  Future<(BrandingRequest?, BrandingFailure?)> createRequest({
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
  }) async {
    final http.Response response;
    try {
      response = await _client.post(
        Uri.parse('$_baseUrl/branding/requests'),
        headers: const {'content-type': 'application/json'},
        body: jsonEncode({
          'mobileNumber': mobileNumber,
          'shopPhotoPath': shopPhotoPath,
          'cardPhotoPath': cardPhotoPath,
          'heightFt': heightFt,
          'widthFt': widthFt,
          'boardCount': boardCount,
          'boardTypeCodes': boardTypeCodes,
          if (shopAddress != null && shopAddress.isNotEmpty)
            'shopAddress': shopAddress,
          if (contactNumber != null && contactNumber.isNotEmpty)
            'contactNumber': contactNumber,
          if (personName != null && personName.isNotEmpty)
            'personName': personName,
        }),
      );
    } on Object {
      return (null, BrandingFailure.unreachable);
    }

    if (response.statusCode == 201) {
      return (
        BrandingRequest.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>,
        ),
        null,
      );
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return (
      null,
      switch (body['error']) {
        'option_not_available' => BrandingFailure.optionNotAvailable,
        'board_count_mismatch' => BrandingFailure.boardCountMismatch,
        'request_already_open' => BrandingFailure.requestAlreadyOpen,
        _ => BrandingFailure.unreachable,
      },
    );
  }

  Future<Map<String, dynamic>?> _get(
    String path,
    Map<String, String> query,
  ) async {
    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl$path').replace(queryParameters: query),
      );
      if (response.statusCode != 200) return null;
      return jsonDecode(response.body) as Map<String, dynamic>;
    } on Object {
      return null;
    }
  }
}
