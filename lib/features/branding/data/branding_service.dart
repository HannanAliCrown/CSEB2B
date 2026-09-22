// Constructor parameters are named for their public API rather than the
// private fields they populate, so the initializing-formal shorthand the
// linter suggests is not available here.
// ignore_for_file: prefer_initializing_formals

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/mock/partner_directory.dart';
import '../../points/data/points_service.dart';
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

/// Shop Branding's data boundary.
///
/// [HttpBrandingService] reads the database behind `prototype_server`.
/// [MockBrandingService] applies the same rules in memory against the same
/// configuration.
abstract interface class BrandingService {
  Future<BrandingLanding?> landing(String mobileNumber);

  Future<BrandingOptions?> boardTypes(String mobileNumber);

  Future<BrandingRequest?> request({
    required String mobileNumber,
    required String reference,
  });

  /// Files a request. The board types are re-checked, so a refusal here is a
  /// real change in what the partner may have.
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
  });
}

/// Shop Branding's data boundary, backed by the database behind
/// `prototype_server`.
///
/// No eligibility rule lives here. Which board types a partner may ask for
/// is decided by the server against their role, points, signed scheme,
/// recent scanning and existing board — this only shows what came back, and
/// a request is re-checked server-side when it is filed.
class HttpBrandingService implements BrandingService {
  HttpBrandingService({required String baseUrl, http.Client? client})
    : _baseUrl = baseUrl,
      _client = client ?? http.Client();

  final String _baseUrl;
  final http.Client _client;

  @override
  Future<BrandingLanding?> landing(String mobileNumber) async {
    final body = await _get('/branding', {'mobileNumber': mobileNumber});
    return body == null ? null : BrandingLanding.fromJson(body);
  }

  @override
  Future<BrandingOptions?> boardTypes(String mobileNumber) async {
    final body = await _get('/branding/board-types', {
      'mobileNumber': mobileNumber,
    });
    return body == null ? null : BrandingOptions.fromJson(body);
  }

  @override
  Future<BrandingRequest?> request({
    required String mobileNumber,
    required String reference,
  }) async {
    final body = await _get('/branding/requests/$reference', {
      'mobileNumber': mobileNumber,
    });
    return body == null ? null : BrandingRequest.fromJson(body);
  }

  @override
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

/// One row of `branding_board_types`, with the conditions each role must
/// satisfy to be offered it.
class _SeededBoardType {
  const _SeededBoardType({
    required this.code,
    required this.name,
    required this.description,
    required this.unitPricePaisa,
    required this.roles,
    this.replacesCode,
  });

  final String code;
  final String name;
  final String description;
  final int unitPricePaisa;

  /// Every board type the seed writes carries the same share.
  int get companyPercent => 60;

  /// Set on the two replacement options, naming the board they redo.
  final String? replacesCode;

  /// `branding_board_type_roles`, by role.
  final Map<String, _RoleRule> roles;
}

/// What one role must satisfy for one board type.
class _RoleRule {
  const _RoleRule({
    this.minPoints = 0,
    this.requiresScheme = false,
    this.requiresRecentScan = false,
  });

  final int minPoints;
  final bool requiresScheme;
  final bool requiresRecentScan;
}

/// A board already on a partner's shopfront.
class _Installation {
  const _Installation({required this.code, required this.monthsAgo});

  final String code;
  final int monthsAgo;
}

/// One board inside a seeded request.
class _SeededBoard {
  const _SeededBoard({required this.position, required this.code});

  final int position;
  final String code;
}

/// One row of `branding_requests`.
class _SeededRequest {
  _SeededRequest({
    required this.reference,
    required this.number,
    required this.status,
    required this.stage,
    required this.heightFt,
    required this.widthFt,
    required this.boardCount,
    required this.boards,
    required this.createdAt,
    this.rejectionReason,
  });

  final String reference;
  final String number;
  final String status;
  final int stage;
  final double heightFt;
  final double widthFt;
  final int boardCount;
  final List<_SeededBoard> boards;
  final DateTime createdAt;
  final String? rejectionReason;
}

/// Shop Branding's data boundary, held in memory.
///
/// The board types, their role conditions and the demo history
/// `db/seed/010_shop_branding.sql` writes, with eligibility measured the way
/// the server measures it: role, points, signed scheme, recent scanning and
/// the board already on the shopfront.
///
/// The points balance and the signed scheme are read from [MockPointsService]
/// rather than copied, so a transfer made on the Points screen moves what
/// Shop Branding offers, exactly as it would through the database.
class MockBrandingService implements BrandingService {
  MockBrandingService({required MockPointsService points})
    : _points = points,
      _seededAt = DateTime.now() {
    _requests.addAll(_seededRequests(_seededAt));
  }

  final MockPointsService _points;
  final DateTime _seededAt;

  final List<_SeededRequest> _requests = [];

  /// `branding_config`, at its defaults.
  static const _scanWindowDays = 10;
  static const _replacementMonths = 6;

  static const _installer = 'installer';
  static const _retailer = 'retailer';
  static const _wholesaler = 'wholesaler';
  static const _distributor = 'distributor';

  /// Every role that can have a board on its shop.
  static const _everyRole = <String>[
    _installer,
    _retailer,
    _wholesaler,
    _distributor,
  ];

  /// The three trading roles, which share a condition on most board types.
  static const _tradingRoles = <String>[_retailer, _wholesaler, _distributor];

  static final _boardTypes = <_SeededBoardType>[
    _SeededBoardType(
      code: 'frontlit',
      name: 'Frontlit Board',
      description: 'Printed flex face lit from the front',
      unitPricePaisa: 4500000,
      roles: {
        // An installer's one condition is that they are still working.
        _installer: const _RoleRule(requiresRecentScan: true),
        for (final role in _tradingRoles)
          role: const _RoleRule(requiresScheme: true),
      },
    ),
    _SeededBoardType(
      code: 'backlit',
      name: 'Backlit Board',
      description: 'Translucent face lit from inside the frame',
      unitPricePaisa: 8000000,
      roles: {
        for (final role in _tradingRoles)
          role: const _RoleRule(requiresScheme: true),
      },
    ),
    _SeededBoardType(
      code: 'inverter_wall',
      name: 'Inverter Wall Branding',
      description: 'Crown Solar inverter wall on your shopfront',
      unitPricePaisa: 3000000,
      roles: {
        for (final role in _tradingRoles)
          role: const _RoleRule(minPoints: 15000, requiresScheme: true),
      },
    ),
    _SeededBoardType(
      code: 'panel_wall',
      name: 'Panel Wall Branding',
      description: 'Crown Solar panel wall on your shopfront',
      unitPricePaisa: 3000000,
      roles: {
        for (final role in _tradingRoles)
          role: const _RoleRule(minPoints: 15000, requiresScheme: true),
      },
    ),
    _SeededBoardType(
      code: 'vinyl',
      name: 'Vinyl Pasting',
      description: 'Printed vinyl applied to glass or wall',
      unitPricePaisa: 2500000,
      roles: {
        for (final role in _tradingRoles)
          role: const _RoleRule(minPoints: 15000, requiresScheme: true),
      },
    ),
    _SeededBoardType(
      code: 'one_way_vision',
      name: 'One Way Vision',
      description: 'Perforated film — branding outside, daylight inside',
      unitPricePaisa: 2500000,
      roles: {
        for (final role in _tradingRoles)
          role: const _RoleRule(minPoints: 15000, requiresScheme: true),
      },
    ),
    _SeededBoardType(
      code: 'customer_care',
      name: 'Customer Care Branding',
      description: 'Full customer-care counter and signage',
      unitPricePaisa: 15000000,
      roles: {
        _wholesaler: const _RoleRule(minPoints: 100000),
        _distributor: const _RoleRule(minPoints: 100000),
      },
    ),
    _SeededBoardType(
      code: 'three_d',
      name: '3D Board',
      description: 'Raised lettering with its own lighting',
      unitPricePaisa: 25000000,
      roles: {_distributor: const _RoleRule(minPoints: 100000)},
    ),
    // The replacement options carry none of the three conditions: what opens
    // them is the installation itself.
    _SeededBoardType(
      code: 'backlit_skin',
      name: 'Backlit Skin Change',
      description: 'New printed skin on your existing frame',
      unitPricePaisa: 2000000,
      replacesCode: 'backlit',
      roles: {for (final role in _everyRole) role: const _RoleRule()},
    ),
    _SeededBoardType(
      code: 'frontlit_flex',
      name: 'Frontlit Flex Change',
      description: 'New printed flex on your existing frame',
      unitPricePaisa: 1500000,
      replacesCode: 'frontlit',
      roles: {for (final role in _everyRole) role: const _RoleRule()},
    ),
  ];

  /// What is already on the shopfronts. Shahdara Solar Services is absent:
  /// a bare shopfront is what makes an installer's ordinary path walkable.
  static const _installations = <String, _Installation>{
    '3004821190': _Installation(code: 'backlit', monthsAgo: 2),
    '3007781204': _Installation(code: 'frontlit', monthsAgo: 5),
  };

  /// How long ago each partner last took a claim, from the scan seed. An
  /// authenticity check takes no claim, so it is not scanning for this
  /// purpose either.
  static const _daysSinceLastScan = <String, int>{
    '3335560071': 2,
    '3217745002': 4,
  };

  static List<_SeededRequest> _seededRequests(DateTime seededAt) => [
    _SeededRequest(
      reference: 'BRD-2026-3391',
      number: '3007781204',
      status: 'in_progress',
      stage: 2,
      heightFt: 4,
      widthFt: 12,
      boardCount: 2,
      boards: const [
        _SeededBoard(position: 1, code: 'backlit'),
        _SeededBoard(position: 2, code: 'inverter_wall'),
      ],
      createdAt: seededAt.subtract(const Duration(days: 9)),
    ),
    // A finished one, which is what put a board on their shop.
    _SeededRequest(
      reference: 'BRD-2026-2988',
      number: '3007781204',
      status: 'completed',
      stage: 3,
      heightFt: 4,
      widthFt: 10,
      boardCount: 1,
      boards: const [_SeededBoard(position: 1, code: 'frontlit')],
      createdAt: seededAt.subtract(const Duration(days: 150)),
    ),
    // And one Crown Solar turned down, with the reason they gave.
    _SeededRequest(
      reference: 'BRD-2025-6602',
      number: '3007781204',
      status: 'rejected',
      stage: 1,
      heightFt: 3,
      widthFt: 8,
      boardCount: 1,
      boards: const [_SeededBoard(position: 1, code: 'vinyl')],
      createdAt: seededAt.subtract(const Duration(days: 425)),
      rejectionReason:
          'Wall surface is not suitable for vinyl pasting — too much '
          'surface damage to hold the material.',
    ),
  ];

  static _SeededBoardType? _typeOf(String code) {
    for (final type in _boardTypes) {
      if (type.code == code) return type;
    }
    return null;
  }

  BrandingEligibility _eligibility(String mobileNumber) {
    final account = PartnerDirectory.find(mobileNumber)!;
    final number = PartnerDirectory.normalise(mobileNumber);
    final role = account.role.toLowerCase();
    final installed = _installations[number];
    final boardName = installed == null ? null : _typeOf(installed.code)?.name;

    return BrandingEligibility(
      role: role,
      schemeSigned: _points.schemeSigned(mobileNumber),
      points: _points.balanceOf(mobileNumber),
      scanWindowDays: _scanWindowDays,
      replacementMonths: _replacementMonths,
      daysSinceLastScan: _daysSinceLastScan[number],
      existingBoardName: boardName,
      existingBoardMonths: installed?.monthsAgo,
    );
  }

  /// The board type a recent installation forces a replacement of, or null
  /// when the shopfront is bare or the board is old enough to be redone.
  String? _replacementCode(String number) {
    final installed = _installations[number];
    if (installed == null) return null;
    return installed.monthsAgo < _replacementMonths ? installed.code : null;
  }

  /// The options this partner may pick from, and the replacement notice when
  /// one applies.
  ///
  /// Replacement detection is evaluated first and overrides everything: a
  /// board young enough leaves exactly one option, whatever the partner's
  /// points and scheme would otherwise allow.
  (List<BrandingBoardType>, String?) _optionsFor(
    String number,
    BrandingEligibility eligibility,
  ) {
    final forRole = [
      for (final type in _boardTypes)
        if (type.roles.containsKey(eligibility.role)) type,
    ];

    final replacing = _replacementCode(number);

    // Everything else is not merely locked but absent: there is no action
    // that would bring it back inside the window.
    if (replacing != null) {
      return (
        [
          for (final type in forRole)
            if (type.replacesCode == replacing)
              _boardTypeFrom(
                type,
                eligibility,
                availableOverride: true,
                conditionOverride: 'Replaces your existing board',
              ),
        ],
        'Installed less than ${eligibility.replacementMonths} months ago. '
            'While it is this new, the only option is a change of face on '
            'the existing board.',
      );
    }

    // No recent board, so the replacement options have nothing to replace
    // and the ordinary ladder applies.
    return (
      [
        for (final type in forRole)
          if (type.replacesCode == null) _boardTypeFrom(type, eligibility),
      ],
      null,
    );
  }

  BrandingBoardType _boardTypeFrom(
    _SeededBoardType type,
    BrandingEligibility eligibility, {
    bool availableOverride = false,
    String? conditionOverride,
  }) {
    final rule = type.roles[eligibility.role] ?? const _RoleRule();
    final scanned =
        eligibility.daysSinceLastScan != null &&
        eligibility.daysSinceLastScan! <= eligibility.scanWindowDays;

    final available =
        availableOverride ||
        (eligibility.points >= rule.minPoints &&
            (!rule.requiresScheme || eligibility.schemeSigned) &&
            (!rule.requiresRecentScan || scanned));

    return BrandingBoardType(
      code: type.code,
      name: type.name,
      description: type.description,
      unitPrice: Money(type.unitPricePaisa),
      companyPercent: type.companyPercent,
      available: available,
      condition: conditionOverride ?? _conditionText(rule, eligibility),
      lockedReason: available
          ? null
          : _lockedReason(rule, eligibility, scanned: scanned),
    );
  }

  /// What opened this option, as the partner would say it.
  static String _conditionText(
    _RoleRule rule,
    BrandingEligibility eligibility,
  ) {
    if (rule.requiresRecentScan) {
      final days = eligibility.daysSinceLastScan;
      if (days == null) {
        return 'Needs a scan in the last ${eligibility.scanWindowDays} days';
      }
      return days == 0
          ? 'Available because you scanned today'
          : 'Available because you scanned a product $days '
                '${days == 1 ? 'day' : 'days'} ago';
    }
    if (rule.minPoints > 0 && rule.requiresScheme) {
      return '${_points_(rule.minPoints)} points and a signed scheme';
    }
    if (rule.minPoints > 0) return '${_points_(rule.minPoints)} points';
    if (rule.requiresScheme) return 'Scheme signed';
    return 'Open to you';
  }

  /// The one thing standing in the way, named so the partner can act on it.
  ///
  /// Only the first unmet condition is given. A list of everything wrong at
  /// once reads as a wall rather than a next step.
  static String? _lockedReason(
    _RoleRule rule,
    BrandingEligibility eligibility, {
    required bool scanned,
  }) {
    if (rule.requiresRecentScan && !scanned) {
      return 'Scan a Crown Solar product to open this';
    }
    if (rule.requiresScheme && !eligibility.schemeSigned) {
      return 'Needs a signed scheme';
    }
    if (eligibility.points < rule.minPoints) {
      return 'Needs ${_points_(rule.minPoints)} points';
    }
    return null;
  }

  /// "15,000" — grouped as the screens write every other figure.
  static String _points_(int value) {
    final digits = value.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i != 0 && (digits.length - i) % 3 == 0) buffer.write(',');
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }

  BrandingRequest _requestFrom(_SeededRequest row) {
    final boards = <BrandingRequestBoard>[];
    var total = 0;
    var company = 0;
    for (final board in row.boards) {
      final type = _typeOf(board.code)!;
      // Copied from what was quoted, so a price changed after the submit
      // does not rewrite what was agreed.
      final companyPaisa = type.unitPricePaisa * type.companyPercent ~/ 100;
      total += type.unitPricePaisa;
      company += companyPaisa;
      boards.add(
        BrandingRequestBoard(
          position: board.position,
          code: type.code,
          name: type.name,
          companyPercent: type.companyPercent,
          company: Money(companyPaisa),
          partner: Money(type.unitPricePaisa - companyPaisa),
        ),
      );
    }

    return BrandingRequest(
      reference: row.reference,
      status: row.status,
      stage: row.stage,
      heightFt: row.heightFt,
      widthFt: row.widthFt,
      boardCount: row.boardCount,
      boards: boards,
      createdAt: row.createdAt,
      total: Money(total),
      company: Money(company),
      partner: Money(total - company),
      rejectionReason: row.rejectionReason,
    );
  }

  /// This partner's requests, newest first.
  List<_SeededRequest> _requestsFor(String number) => [
    for (final row in _requests)
      if (row.number == number) row,
  ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  @override
  Future<BrandingLanding?> landing(String mobileNumber) async {
    if (PartnerDirectory.find(mobileNumber) == null) return null;
    final number = PartnerDirectory.normalise(mobileNumber);

    final requests = [
      for (final row in _requestsFor(number)) _requestFrom(row),
    ];

    return BrandingLanding(
      eligibility: _eligibility(mobileNumber),
      // At most one request is live at a time, so the newest unfinished one
      // is the one the landing card points at.
      current: requests.where((request) => request.inProgress).firstOrNull,
      requests: requests,
    );
  }

  @override
  Future<BrandingOptions?> boardTypes(String mobileNumber) async {
    if (PartnerDirectory.find(mobileNumber) == null) return null;

    final eligibility = _eligibility(mobileNumber);
    final (types, notice) = _optionsFor(
      PartnerDirectory.normalise(mobileNumber),
      eligibility,
    );

    return BrandingOptions(
      eligibility: eligibility,
      boardTypes: types,
      replacementOnly: notice != null,
      replacementNotice: notice,
    );
  }

  @override
  Future<BrandingRequest?> request({
    required String mobileNumber,
    required String reference,
  }) async {
    if (PartnerDirectory.find(mobileNumber) == null) return null;
    final number = PartnerDirectory.normalise(mobileNumber);
    for (final row in _requests) {
      if (row.number == number && row.reference == reference) {
        return _requestFrom(row);
      }
    }
    return null;
  }

  @override
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
    if (PartnerDirectory.find(mobileNumber) == null) {
      return (null, BrandingFailure.unreachable);
    }
    if (boardTypeCodes.length != boardCount) {
      return (null, BrandingFailure.boardCountMismatch);
    }

    final number = PartnerDirectory.normalise(mobileNumber);

    // Re-checked here rather than trusted from the screen: a scan window can
    // close, and a board can be installed, between the step that offered an
    // option and the submit that uses it.
    final (available, _) = _optionsFor(number, _eligibility(mobileNumber));
    final open = {
      for (final type in available)
        if (type.available) type.code,
    };
    for (final code in boardTypeCodes) {
      if (!open.contains(code)) {
        return (null, BrandingFailure.optionNotAvailable);
      }
    }

    // One live request at a time. Crown Solar finishes one before starting
    // the next.
    for (final row in _requests) {
      if (row.number == number && row.status == 'in_progress') {
        return (null, BrandingFailure.requestAlreadyOpen);
      }
    }

    final created = _SeededRequest(
      reference: _newReference(),
      number: number,
      status: 'in_progress',
      stage: 1,
      heightFt: heightFt,
      widthFt: widthFt,
      boardCount: boardCount,
      boards: [
        for (var i = 0; i < boardTypeCodes.length; i++)
          _SeededBoard(position: i + 1, code: boardTypeCodes[i]),
      ],
      createdAt: DateTime.now(),
    );
    _requests.add(created);
    return (_requestFrom(created), null);
  }

  /// BRD-2026-3391 — the year, then a run of digits wide enough that two
  /// requests filed in the same second do not collide.
  static String _newReference() {
    final now = DateTime.now();
    final tail = now.microsecondsSinceEpoch.remainder(10000);
    return 'BRD-${now.year}-${tail.toString().padLeft(4, '0')}';
  }
}
