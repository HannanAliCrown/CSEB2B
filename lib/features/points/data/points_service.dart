// Constructor parameters are named for their public API rather than the
// private fields they populate, so the initializing-formal shorthand the
// linter suggests is not available here.
// ignore_for_file: prefer_initializing_formals

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/mock/partner_directory.dart';

/// What put a line in the points ledger.
enum PointEntryType {
  /// SAP posting one percent of a purchase.
  purchaseAccrual,

  /// SAP taking that back when a purchase is reversed.
  reversal,

  transferIn,
  transferOut,

  /// Crown Solar correcting something by hand.
  crmAdjustment,
}

/// One line in the points ledger.
class PointEntry {
  const PointEntry({
    required this.reference,
    required this.type,
    required this.amount,
    required this.balanceAfter,
    required this.credit,
    required this.postedAt,
    this.counterpartyName,
    this.counterpartyRole,
    this.sapDocument,
    this.note,
  });

  final String reference;
  final PointEntryType type;
  final int amount;

  /// What the balance stood at once this line had posted.
  final int balanceAfter;

  final bool credit;
  final DateTime postedAt;

  final String? counterpartyName;
  final String? counterpartyRole;
  final String? sapDocument;
  final String? note;

  /// The line's title: who it was with, or what kind of movement it was.
  String get title => switch (type) {
    PointEntryType.transferIn ||
    PointEntryType.transferOut => counterpartyName ?? 'Another partner',
    PointEntryType.purchaseAccrual => 'Purchase accrual',
    PointEntryType.reversal =>
      sapDocument == null ? 'Reversal' : 'Reversal · SAP $sapDocument',
    PointEntryType.crmAdjustment => 'CRM adjustment',
  };

  /// What the line says under its title, after the time.
  String? get clause => switch (type) {
    PointEntryType.transferIn => 'Received',
    PointEntryType.transferOut => 'Sent',
    PointEntryType.purchaseAccrual =>
      sapDocument == null ? null : 'SAP $sapDocument',
    PointEntryType.reversal => 'Purchase reversed in SAP',
    // A number with no reason is not an answer.
    PointEntryType.crmAdjustment => note == null ? null : 'Reason: $note',
  };

  /// "+ 18,400" / "− 12,000", with a true minus sign rather than a hyphen.
  String get signedAmount => '${credit ? '+' : '−'} ${formatPoints(amount)}';

  static PointEntry fromJson(Map<String, dynamic> json) => PointEntry(
    reference: json['reference'] as String,
    type: switch (json['type']) {
      'purchase_accrual' => PointEntryType.purchaseAccrual,
      'reversal' => PointEntryType.reversal,
      'transfer_in' => PointEntryType.transferIn,
      'transfer_out' => PointEntryType.transferOut,
      _ => PointEntryType.crmAdjustment,
    },
    amount: (json['amount'] as num).toInt(),
    balanceAfter: (json['balanceAfter'] as num).toInt(),
    credit: json['direction'] == 'credit',
    postedAt: DateTime.parse(json['postedAt'] as String).toLocal(),
    counterpartyName: json['counterpartyName'] as String?,
    counterpartyRole: json['counterpartyRole'] as String?,
    sapDocument: json['sapDocument'] as String?,
    note: json['note'] as String?,
  );
}

/// The balance, the ledger, and whether this partner may send at all.
class PointsLedger {
  const PointsLedger({
    required this.balance,
    required this.entries,
    required this.canSend,
    this.restrictionReason,
  });

  final int balance;
  final List<PointEntry> entries;

  /// False when Crown Solar has stopped this account's transfers. The
  /// balance and the ledger stay visible either way — a partner is always
  /// entitled to see their own record.
  final bool canSend;
  final String? restrictionReason;

  static const empty = PointsLedger(balance: 0, entries: [], canSend: true);

  static PointsLedger fromJson(Map<String, dynamic> json) => PointsLedger(
    balance: (json['balance'] as num?)?.toInt() ?? 0,
    entries: [
      for (final entry in json['entries'] as List? ?? const [])
        PointEntry.fromJson(entry as Map<String, dynamic>),
    ],
    canSend: json['canSend'] != false,
    restrictionReason: json['restrictionReason'] as String?,
  );
}

/// A partner points can be sent to.
class PointRecipient {
  const PointRecipient({
    required this.mobileNumber,
    required this.name,
    required this.role,
    this.lastSentAt,
    this.lastSentAmount,
  });

  final String mobileNumber;
  final String name;
  final String role;
  final DateTime? lastSentAt;
  final int? lastSentAmount;

  bool get sentBefore => lastSentAt != null;

  /// "Sent 12,000 on 08 Sep".
  String? get historyLine => lastSentAt == null
      ? null
      : 'Sent ${formatPoints(lastSentAmount ?? 0)} on '
            '${formatPointsDate(lastSentAt!)}';

  static PointRecipient fromJson(Map<String, dynamic> json) => PointRecipient(
    mobileNumber: json['mobileNumber'] as String,
    name: json['name'] as String,
    role: json['role'] as String,
    lastSentAt: json['lastSentAt'] == null
        ? null
        : DateTime.parse(json['lastSentAt'] as String).toLocal(),
    lastSentAmount: (json['lastSentAmount'] as num?)?.toInt(),
  );
}

/// How a target is going.
enum TargetStatus { notStarted, running, achieved, notMet }

extension TargetStatusX on TargetStatus {
  String get label => switch (this) {
    TargetStatus.notStarted => 'Not started',
    TargetStatus.running => 'Running',
    TargetStatus.achieved => 'Achieved',
    TargetStatus.notMet => 'Not met',
  };
}

/// One target, and what has been scored toward it.
class PointTarget {
  const PointTarget({
    required this.kind,
    required this.label,
    required this.targetPoints,
    required this.scoredPoints,
    required this.startsOn,
    required this.endsOn,
    this.prize,
    this.metOn,
  });

  /// 'period' | 'annual' | 'extra'.
  final String kind;

  final String label;
  final int targetPoints;

  /// Points that arrived inside the window. Points sent out are not counted.
  final int scoredPoints;

  final DateTime startsOn;
  final DateTime endsOn;
  final String? prize;

  /// When the score first reached the target, or null if it has not.
  final DateTime? metOn;

  bool get met => metOn != null;

  double get percent => targetPoints == 0
      ? 0
      : (scoredPoints / targetPoints).clamp(0.0, 1.0).toDouble();

  int get toGo =>
      scoredPoints >= targetPoints ? 0 : targetPoints - scoredPoints;

  bool get running {
    final now = DateTime.now();
    return !now.isBefore(startsOn) && !now.isAfter(_endOfDay);
  }

  DateTime get _endOfDay =>
      DateTime(endsOn.year, endsOn.month, endsOn.day, 23, 59, 59);

  /// A period that has not started cannot be judged; one that has closed is
  /// judged on what it scored; one still open is simply running.
  TargetStatus get status {
    final now = DateTime.now();
    if (now.isBefore(startsOn)) return TargetStatus.notStarted;
    if (now.isAfter(_endOfDay)) {
      return met ? TargetStatus.achieved : TargetStatus.notMet;
    }
    return met ? TargetStatus.achieved : TargetStatus.running;
  }

  static PointTarget fromJson(Map<String, dynamic> json) => PointTarget(
    kind: json['kind'] as String,
    label: json['label'] as String,
    targetPoints: (json['targetPoints'] as num).toInt(),
    scoredPoints: (json['scoredPoints'] as num).toInt(),
    startsOn: DateTime.parse(json['startsOn'] as String).toLocal(),
    endsOn: DateTime.parse(json['endsOn'] as String).toLocal(),
    prize: json['prize'] as String?,
    metOn: json['metOn'] == null
        ? null
        : DateTime.parse(json['metOn'] as String).toLocal(),
  );
}

/// Where the points counting toward the running target came from.
class PointBreakdown {
  const PointBreakdown({
    required this.purchases,
    required this.transferredIn,
    required this.reversals,
  });

  final int purchases;
  final int transferredIn;

  /// Positive; the screen prints the minus sign.
  final int reversals;

  static const empty = PointBreakdown(
    purchases: 0,
    transferredIn: 0,
    reversals: 0,
  );

  static PointBreakdown fromJson(Map<String, dynamic> json) => PointBreakdown(
    purchases: (json['purchases'] as num?)?.toInt() ?? 0,
    transferredIn: (json['transferredIn'] as num?)?.toInt() ?? 0,
    reversals: (json['reversals'] as num?)?.toInt() ?? 0,
  );
}

/// Everything View Targets shows.
class PointTargets {
  const PointTargets({
    required this.periods,
    required this.extras,
    required this.breakdown,
    this.schemeName,
    this.annual,
    this.annualPrize,
    this.grandPrize,
  });

  /// Null when no scheme has been signed, which is a screen of its own —
  /// not an empty list of targets.
  final String? schemeName;

  final PointTarget? annual;
  final String? annualPrize;

  /// The prize for hitting every four-month target, on schemes that have one.
  final String? grandPrize;

  final List<PointTarget> periods;

  /// Targets Crown Solar set for this partner by hand, outside the scheme.
  final List<PointTarget> extras;

  final PointBreakdown breakdown;

  bool get hasScheme => schemeName != null;

  /// The four-month period that is open now, if any.
  PointTarget? get runningPeriod {
    for (final period in periods) {
      if (period.running) return period;
    }
    return null;
  }

  static const empty = PointTargets(
    periods: [],
    extras: [],
    breakdown: PointBreakdown.empty,
  );

  static PointTargets fromJson(Map<String, dynamic> json) => PointTargets(
    schemeName: json['schemeName'] as String?,
    annual: json['annual'] == null
        ? null
        : PointTarget.fromJson(json['annual'] as Map<String, dynamic>),
    annualPrize: json['annualPrize'] as String?,
    grandPrize: json['grandPrize'] as String?,
    periods: [
      for (final entry in json['periods'] as List? ?? const [])
        PointTarget.fromJson(entry as Map<String, dynamic>),
    ],
    extras: [
      for (final entry in json['extras'] as List? ?? const [])
        PointTarget.fromJson(entry as Map<String, dynamic>),
    ],
    breakdown: PointBreakdown.fromJson(
      json['breakdown'] as Map<String, dynamic>? ?? const {},
    ),
  );
}

/// Why a transfer was refused, in the words the screen shows.
///
/// Each has its own message because each has a different remedy: one is
/// fixed by sending less, one by choosing someone else, and two only by
/// talking to Crown Solar.
enum PointTransferFailure {
  notEnoughPoints,
  pairNotPermitted,
  senderRestricted,
  recipientRestricted,
  unknownRecipient,
  self,
  unreachable,
}

extension PointTransferFailureX on PointTransferFailure {
  String get title => switch (this) {
    PointTransferFailure.notEnoughPoints => 'Not enough points',
    PointTransferFailure.pairNotPermitted =>
      'You cannot send points to this person',
    PointTransferFailure.senderRestricted =>
      'Your points transfers are restricted',
    PointTransferFailure.recipientRestricted =>
      'This person cannot receive points right now',
    PointTransferFailure.unknownRecipient => 'No Crown Solar account',
    PointTransferFailure.self => 'That is your own account',
    PointTransferFailure.unreachable => 'Could not reach Crown Solar',
  };

  String message(int balance) => switch (this) {
    PointTransferFailure.notEnoughPoints =>
      'You hold ${formatPoints(balance)} points. Reduce the amount.',
    PointTransferFailure.pairNotPermitted =>
      'The Crown Solar team sets which roles may exchange points. This pair '
          'is not permitted.',
    PointTransferFailure.senderRestricted =>
      'Sending is not available on your account. Your balance and ledger '
          'stay visible. Contact Support.',
    PointTransferFailure.recipientRestricted =>
      'Their account has a points restriction. Ask them to contact Crown '
          'Solar CRM.',
    PointTransferFailure.unknownRecipient =>
      'That number does not belong to a partner who can hold points.',
    PointTransferFailure.self => 'Points cannot be sent to yourself.',
    PointTransferFailure.unreachable =>
      'Nothing has been sent. Check your connection and try again.',
  };
}

/// What a completed transfer came back with.
class PointTransferReceipt {
  const PointTransferReceipt({
    required this.reference,
    required this.amount,
    required this.balance,
    required this.sentAt,
  });

  final String reference;
  final int amount;

  /// The sender's balance once the points had left.
  final int balance;

  final DateTime sentAt;
}

/// Points' data boundary.
///
/// [HttpPointsService] reads the database behind `prototype_server`.
/// [MockPointsService] holds the same movements in memory and derives the
/// balance, the ledger and every target from them, exactly as the database
/// does — nothing here is a stored total.
abstract interface class PointsService {
  /// The balance and every movement. Null when it could not be read — which
  /// the screen says, rather than showing a balance of zero.
  Future<PointsLedger?> ledger(String mobileNumber);

  Future<PointTargets?> targets(String mobileNumber);

  Future<List<PointRecipient>?> recipients(String mobileNumber);

  /// Resolves a number from a contact or a scanned QR code. Null when this
  /// partner may not send to them.
  Future<PointRecipient?> lookup({
    required String mobileNumber,
    required String recipientNumber,
  });

  /// Sends points. They arrive at once.
  Future<(PointTransferReceipt?, PointTransferFailure?)> send({
    required String fromMobileNumber,
    required String toMobileNumber,
    required int amount,
  });
}

/// Points' data boundary, backed by the database behind `prototype_server`.
class HttpPointsService implements PointsService {
  HttpPointsService({required String baseUrl, http.Client? client})
    : _baseUrl = baseUrl,
      _client = client ?? http.Client();

  final String _baseUrl;
  final http.Client _client;

  @override
  Future<PointsLedger?> ledger(String mobileNumber) async {
    final body = await _get('/points/ledger', {'mobileNumber': mobileNumber});
    return body == null ? null : PointsLedger.fromJson(body);
  }

  @override
  Future<PointTargets?> targets(String mobileNumber) async {
    final body = await _get('/points/targets', {'mobileNumber': mobileNumber});
    return body == null ? null : PointTargets.fromJson(body);
  }

  @override
  Future<List<PointRecipient>?> recipients(String mobileNumber) async {
    final body = await _get('/points/recipients', {
      'mobileNumber': mobileNumber,
    });
    if (body == null) return null;
    return [
      for (final entry in body['recipients'] as List? ?? const [])
        PointRecipient.fromJson(entry as Map<String, dynamic>),
    ];
  }

  @override
  Future<PointRecipient?> lookup({
    required String mobileNumber,
    required String recipientNumber,
  }) async {
    final body = await _get('/points/recipients/lookup', {
      'mobileNumber': mobileNumber,
      'number': recipientNumber,
    });
    return body == null ? null : PointRecipient.fromJson(body);
  }

  @override
  Future<(PointTransferReceipt?, PointTransferFailure?)> send({
    required String fromMobileNumber,
    required String toMobileNumber,
    required int amount,
  }) async {
    final http.Response response;
    try {
      response = await _client.post(
        Uri.parse('$_baseUrl/points/transfers'),
        headers: const {'content-type': 'application/json'},
        body: jsonEncode({
          'fromMobileNumber': fromMobileNumber,
          'toMobileNumber': toMobileNumber,
          'amount': amount,
        }),
      );
    } on Object {
      return (null, PointTransferFailure.unreachable);
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 201) {
      return (
        null,
        switch (body['error']) {
          'not_enough_points' => PointTransferFailure.notEnoughPoints,
          'pair_not_permitted' => PointTransferFailure.pairNotPermitted,
          'sender_restricted' => PointTransferFailure.senderRestricted,
          'recipient_restricted' => PointTransferFailure.recipientRestricted,
          'self' => PointTransferFailure.self,
          'unknown_recipient' => PointTransferFailure.unknownRecipient,
          _ => PointTransferFailure.unreachable,
        },
      );
    }

    final entry = body['entry'] as Map<String, dynamic>;
    return (
      PointTransferReceipt(
        reference: entry['reference'] as String,
        amount: (entry['amount'] as num).toInt(),
        balance: (body['balance'] as num?)?.toInt() ?? 0,
        sentAt: DateTime.parse(entry['postedAt'] as String).toLocal(),
      ),
      null,
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

/// One row of `point_entries`, as the seed writes it.
///
/// A movement, never a balance: every figure the app shows is derived from
/// these, so holding a total here would be holding a lie.
class _Movement {
  _Movement({
    required this.number,
    required this.reference,
    required this.type,
    required this.amount,
    required this.credit,
    required this.postedAt,
    this.counterpartyNumber,
    this.sapDocument,
    this.note,
  });

  /// The account the movement belongs to, in ten national digits.
  final String number;

  final String reference;
  final PointEntryType type;
  final int amount;
  final bool credit;
  final DateTime postedAt;
  final String? counterpartyNumber;
  final String? sapDocument;
  final String? note;

  /// What a target counts: points that arrived, less what SAP took back.
  /// Points sent out reduce the balance and are deliberately absent.
  int get counting => switch (type) {
    PointEntryType.purchaseAccrual || PointEntryType.transferIn => amount,
    PointEntryType.reversal => -amount,
    _ => 0,
  };

  int get signed => credit ? amount : -amount;
}

/// One four-month or year-long window a partner is measured against.
class _SeededTarget {
  const _SeededTarget({
    required this.label,
    required this.startsOn,
    required this.endsOn,
    required this.targetPoints,
    this.prize,
  });

  final String label;
  final DateTime startsOn;
  final DateTime endsOn;
  final int targetPoints;
  final String? prize;
}

/// One scheme, signed on paper.
class _SeededScheme {
  const _SeededScheme({
    required this.name,
    required this.year,
    required this.annualTargetPoints,
    required this.annualPrize,
    required this.periods,
    this.grandPrize,
  });

  final String name;
  final int year;
  final int annualTargetPoints;
  final String annualPrize;
  final String? grandPrize;
  final List<_SeededTarget> periods;
}

/// Points' data boundary, held in memory.
///
/// Every movement `db/seed/007_points_and_targets.sql` writes, with the
/// balance, the ledger, each target and the breakdown derived from them the
/// way the database derives them. A transfer made here lasts as long as the
/// process does, which is what a build with no database can offer.
class MockPointsService implements PointsService {
  MockPointsService() {
    _movements.addAll(_seededMovements());
  }

  final List<_Movement> _movements = [];

  /// `point_reference_seq` starts here, and every seeded SAP movement takes
  /// one before the first transfer does.
  int _nextReference = 77411 + 9;

  static const _retailerScheme = 'Retailer Scheme';
  static const _wholesalerScheme = 'Wholesaler Scheme';
  static const _distributorScheme = 'Distributor Scheme';

  /// Which scheme each partner signed. Bilal Traders is deliberately absent:
  /// a partner with no scheme is a state the app has to show.
  static const _schemeByNumber = <String, String>{
    '3007781204': _retailerScheme,
    '3014429911': _wholesalerScheme,
    '3028890143': _distributorScheme,
  };

  static final _schemes = <String, _SeededScheme>{
    _retailerScheme: _SeededScheme(
      name: _retailerScheme,
      year: 2026,
      annualTargetPoints: 1000000,
      annualPrize: 'Umrah package for two',
      periods: [
        _SeededTarget(
          label: 'Jan — Apr 2026',
          startsOn: DateTime(2026),
          endsOn: DateTime(2026, 4, 30),
          targetPoints: 280000,
          prize: '32-inch LED television',
        ),
        _SeededTarget(
          label: 'May — Aug 2026',
          startsOn: DateTime(2026, 5),
          endsOn: DateTime(2026, 8, 31),
          targetPoints: 320000,
          prize: 'Haier 1-ton inverter AC',
        ),
        _SeededTarget(
          label: 'Sep — Dec 2026',
          startsOn: DateTime(2026, 9),
          endsOn: DateTime(2026, 12, 31),
          targetPoints: 400000,
          prize: 'Honda 125 motorcycle',
        ),
      ],
    ),
    _wholesalerScheme: _SeededScheme(
      name: _wholesalerScheme,
      year: 2026,
      annualTargetPoints: 1000000,
      annualPrize: 'Umrah package for two',
      grandPrize: 'Foreign tour for two, for hitting every four-month target',
      periods: [
        _SeededTarget(
          label: 'Jan — Apr 2026',
          startsOn: DateTime(2026),
          endsOn: DateTime(2026, 4, 30),
          targetPoints: 280000,
          prize: '32-inch LED television',
        ),
        _SeededTarget(
          label: 'May — Aug 2026',
          startsOn: DateTime(2026, 5),
          endsOn: DateTime(2026, 8, 31),
          targetPoints: 320000,
          prize: 'Honda 125 motorcycle',
        ),
        _SeededTarget(
          label: 'Sep — Dec 2026',
          startsOn: DateTime(2026, 9),
          endsOn: DateTime(2026, 12, 31),
          targetPoints: 400000,
          prize: 'Gold coin, 2 tola',
        ),
      ],
    ),
    _distributorScheme: _SeededScheme(
      name: _distributorScheme,
      year: 2026,
      annualTargetPoints: 5000000,
      annualPrize: 'Hajj package for two',
      periods: [
        _SeededTarget(
          label: 'Jan — Apr 2026',
          startsOn: DateTime(2026),
          endsOn: DateTime(2026, 4, 30),
          targetPoints: 1200000,
          prize: 'Toyota Hilux service package',
        ),
        _SeededTarget(
          label: 'May — Aug 2026',
          startsOn: DateTime(2026, 5),
          endsOn: DateTime(2026, 8, 31),
          targetPoints: 1400000,
          prize: 'Foreign tour for two',
        ),
        _SeededTarget(
          label: 'Sep — Dec 2026',
          startsOn: DateTime(2026, 9),
          endsOn: DateTime(2026, 12, 31),
          targetPoints: 1600000,
          prize: 'Gold coin, 5 tola',
        ),
      ],
    ),
  };

  /// Targets Crown Solar set by hand for Hamza, who reached the year total
  /// in August. They run alongside the signed scheme.
  static final _extraTargets = <String, List<_SeededTarget>>{
    '3014429911': [
      _SeededTarget(
        label: 'Extra · Jul — Aug 2026',
        startsOn: DateTime(2026, 7),
        endsOn: DateTime(2026, 8, 31),
        targetPoints: 150000,
        prize: 'Gold coin, 1 tola',
      ),
      _SeededTarget(
        label: 'Extra · Sep — Dec 2026',
        startsOn: DateTime(2026, 9),
        endsOn: DateTime(2026, 12, 31),
        targetPoints: 300000,
        prize: '32-inch LED television',
      ),
      _SeededTarget(
        label: 'Stretch · Jul — Dec 2026',
        startsOn: DateTime(2026, 7),
        endsOn: DateTime(2026, 12, 31),
        targetPoints: 500000,
        prize: 'Foreign tour for two',
      ),
    ],
  };

  /// The three trading roles may exchange points in any direction.
  /// Installers appear nowhere: they hold no points and have no rule row.
  static const _tradingRoles = {'retailer', 'wholesaler', 'distributor'};

  static List<_Movement> _seededMovements() {
    // The SAP postings, in the order the seed inserts them. Each takes the
    // next value of `point_reference_seq`, which starts at 77411.
    var sequence = 77411;
    String next() => 'PT-2026-${sequence++}';

    final movements = <_Movement>[
      for (final row in const [
        (
          '3007781204',
          'purchase_accrual',
          312600,
          'INV-71204',
          2026,
          2,
          15,
          10,
          20,
        ),
        (
          '3007781204',
          'purchase_accrual',
          191900,
          'INV-74418',
          2026,
          6,
          20,
          11,
          5,
        ),
        (
          '3007781204',
          'purchase_accrual',
          123500,
          'INV-76540',
          2026,
          9,
          1,
          9,
          30,
        ),
        ('3007781204', 'reversal', 4300, 'INV-76980', 2026, 9, 5, 14, 12),
        (
          '3007781204',
          'purchase_accrual',
          18400,
          'INV-77213',
          2026,
          9,
          21,
          6,
          2,
        ),
        (
          '3014429911',
          'purchase_accrual',
          470000,
          'INV-70880',
          2026,
          3,
          10,
          9,
          15,
        ),
        (
          '3014429911',
          'purchase_accrual',
          332300,
          'INV-75012',
          2026,
          7,
          18,
          15,
          40,
        ),
        (
          '3028890143',
          'purchase_accrual',
          1850000,
          'INV-72330',
          2026,
          4,
          12,
          8,
          50,
        ),
      ])
        _Movement(
          number: row.$1,
          reference: next(),
          type: row.$2 == 'reversal'
              ? PointEntryType.reversal
              : PointEntryType.purchaseAccrual,
          amount: row.$3,
          credit: row.$2 != 'reversal',
          sapDocument: row.$4,
          postedAt: DateTime(row.$5, row.$6, row.$7, row.$8, row.$9),
        ),
      // A correction Crown Solar made by hand. The reason travels with it:
      // a number with no reason is not an answer.
      _Movement(
        number: '3007781204',
        reference: next(),
        type: PointEntryType.crmAdjustment,
        amount: 9000,
        credit: true,
        note: 'Wrong recipient corrected',
        postedAt: DateTime(2026, 9, 8, 11, 45),
      ),
    ];

    // Both legs of every transfer, exactly as the app writes them: the
    // sender's debit and the receiver's credit share one reference.
    for (final row in const [
      ('PT-2026-77002', '3007781204', '3028890143', 180500, 2026, 5, 10, 10, 0),
      ('PT-2026-77118', '3007781204', '3014429911', 200000, 2026, 7, 2, 12, 30),
      ('PT-2026-77260', '3007781204', '3217745002', 6000, 2026, 8, 14, 16, 20),
      ('PT-2026-77304', '3007781204', '3028890143', 75000, 2026, 8, 21, 9, 10),
      ('PT-2026-77351', '3007781204', '3014429911', 40000, 2026, 9, 2, 10, 5),
      ('PT-2026-77366', '3014429911', '3007781204', 19800, 2026, 9, 3, 13, 25),
      ('PT-2026-77389', '3014429911', '3007781204', 25000, 2026, 9, 7, 17, 40),
      ('PT-2026-77405', '3007781204', '3217745002', 12000, 2026, 9, 20, 15, 14),
    ]) {
      final postedAt = DateTime(row.$5, row.$6, row.$7, row.$8, row.$9);
      movements
        ..add(
          _Movement(
            number: row.$2,
            reference: row.$1,
            type: PointEntryType.transferOut,
            amount: row.$4,
            credit: false,
            counterpartyNumber: row.$3,
            postedAt: postedAt,
          ),
        )
        ..add(
          _Movement(
            number: row.$3,
            reference: row.$1,
            type: PointEntryType.transferIn,
            amount: row.$4,
            credit: true,
            counterpartyNumber: row.$2,
            postedAt: postedAt,
          ),
        );
    }
    return movements;
  }

  /// This partner's movements oldest first, which is the order every running
  /// total is carried in.
  List<_Movement> _oldestFirst(String number) => [
    for (final m in _movements)
      if (m.number == number) m,
  ]..sort((a, b) => a.postedAt.compareTo(b.postedAt));

  /// The balance, as the sum of what has moved.
  int balanceOf(String mobileNumber) {
    final number = PartnerDirectory.normalise(mobileNumber);
    var balance = 0;
    for (final movement in _oldestFirst(number)) {
      balance += movement.signed;
    }
    return balance;
  }

  /// Whether this partner has a scheme, which Shop Branding measures board
  /// types against.
  bool schemeSigned(String mobileNumber) =>
      _schemeByNumber.containsKey(PartnerDirectory.normalise(mobileNumber));

  @override
  Future<PointsLedger?> ledger(String mobileNumber) async {
    if (PartnerDirectory.find(mobileNumber) == null) return null;
    final number = PartnerDirectory.normalise(mobileNumber);

    final entries = <PointEntry>[];
    var running = 0;
    for (final movement in _oldestFirst(number)) {
      running += movement.signed;
      final counterparty = movement.counterpartyNumber == null
          ? null
          : PartnerDirectory.find(movement.counterpartyNumber!);
      entries.add(
        PointEntry(
          reference: movement.reference,
          type: movement.type,
          amount: movement.amount,
          balanceAfter: running,
          credit: movement.credit,
          postedAt: movement.postedAt,
          counterpartyName: counterparty?.displayName,
          counterpartyRole: counterparty?.role.toLowerCase(),
          sapDocument: movement.sapDocument,
          note: movement.note,
        ),
      );
    }

    // Newest first, as the ledger reads.
    return PointsLedger(
      balance: running,
      entries: entries.reversed.toList(),
      canSend: true,
    );
  }

  @override
  Future<PointTargets?> targets(String mobileNumber) async {
    if (PartnerDirectory.find(mobileNumber) == null) return null;
    final number = PartnerDirectory.normalise(mobileNumber);

    final extras = [
      for (final target in _extraTargets[number] ?? const <_SeededTarget>[])
        _scored(number, 'extra', target),
    ];

    // No scheme signed. Points still work; there is simply nothing measured
    // against this partner, which is what the app then says.
    final scheme = _schemes[_schemeByNumber[number]];
    if (scheme == null) {
      return PointTargets(
        periods: const [],
        extras: extras,
        breakdown: PointBreakdown.empty,
      );
    }

    final periods = [
      for (final period in scheme.periods) _scored(number, 'period', period),
    ];
    final annual = _scored(
      number,
      'annual',
      _SeededTarget(
        label: 'Year total · ${scheme.year}',
        startsOn: DateTime.utc(scheme.year),
        endsOn: DateTime.utc(scheme.year, 12, 31),
        targetPoints: scheme.annualTargetPoints,
        prize: scheme.annualPrize,
      ),
    );

    // The breakdown belongs to whatever is running now — the period the
    // partner can still do something about. With none running it covers the
    // year, so the figures are never about a window nobody is in.
    final now = DateTime.now();
    PointTarget? running;
    for (final period in periods) {
      if (!now.isBefore(period.startsOn) && !now.isAfter(period.endsOn)) {
        running = period;
        break;
      }
    }

    return PointTargets(
      schemeName: '${scheme.name} ${scheme.year}',
      annual: annual,
      annualPrize: scheme.annualPrize,
      grandPrize: scheme.grandPrize,
      periods: periods,
      extras: extras,
      breakdown: _breakdown(
        number,
        running?.startsOn ?? annual.startsOn,
        running?.endsOn ?? annual.endsOn,
      ),
    );
  }

  /// Whether a movement falls inside a target's window, which runs to the
  /// end of its last day.
  bool _inside(_Movement movement, DateTime startsOn, DateTime endsOn) {
    final end = DateTime(
      endsOn.year,
      endsOn.month,
      endsOn.day,
    ).add(const Duration(days: 1));
    return !movement.postedAt.isBefore(startsOn) &&
        movement.postedAt.isBefore(end);
  }

  /// One target with what has been scored toward it, and when it was reached.
  ///
  /// The running total is carried along so the row where it first reached
  /// the target can be named — "met in August" rather than merely "met".
  PointTarget _scored(String number, String kind, _SeededTarget target) {
    var running = 0;
    var scored = 0;
    DateTime? metOn;

    for (final movement in _oldestFirst(number)) {
      if (!_inside(movement, target.startsOn, target.endsOn)) continue;
      running += movement.counting;
      if (running > scored) scored = running;
      if (metOn == null && running >= target.targetPoints) {
        metOn = movement.postedAt;
      }
    }

    return PointTarget(
      kind: kind,
      label: target.label,
      targetPoints: target.targetPoints,
      scoredPoints: scored,
      startsOn: target.startsOn,
      endsOn: target.endsOn,
      prize: target.prize,
      metOn: metOn,
    );
  }

  PointBreakdown _breakdown(String number, DateTime startsOn, DateTime endsOn) {
    var purchases = 0;
    var transferredIn = 0;
    var reversals = 0;
    for (final movement in _oldestFirst(number)) {
      if (!_inside(movement, startsOn, endsOn)) continue;
      switch (movement.type) {
        case PointEntryType.purchaseAccrual:
          purchases += movement.amount;
        case PointEntryType.transferIn:
          transferredIn += movement.amount;
        case PointEntryType.reversal:
          reversals += movement.amount;
        case PointEntryType.transferOut:
        case PointEntryType.crmAdjustment:
          break;
      }
    }
    return PointBreakdown(
      purchases: purchases,
      transferredIn: transferredIn,
      reversals: reversals,
    );
  }

  /// The last transfer this partner sent to that one, for the history line.
  _Movement? _lastSentTo(String from, String to) {
    _Movement? last;
    for (final movement in _oldestFirst(from)) {
      if (movement.type == PointEntryType.transferOut &&
          movement.counterpartyNumber == to) {
        last = movement;
      }
    }
    return last;
  }

  @override
  Future<List<PointRecipient>?> recipients(String mobileNumber) async {
    final me = PartnerDirectory.find(mobileNumber);
    if (me == null) return null;

    final myRole = me.role.toLowerCase();
    if (!_tradingRoles.contains(myRole)) return const <PointRecipient>[];

    final number = PartnerDirectory.normalise(mobileNumber);
    final found = <PointRecipient>[];
    for (final account in PartnerDirectory.accounts) {
      final theirNumber = PartnerDirectory.normalise(account.mobileNumber);
      if (theirNumber == number) continue;
      if (!_tradingRoles.contains(account.role.toLowerCase())) continue;

      final last = _lastSentTo(number, theirNumber);
      found.add(
        PointRecipient(
          mobileNumber: theirNumber,
          name: account.displayName,
          role: account.role.toLowerCase(),
          lastSentAt: last?.postedAt,
          lastSentAmount: last?.amount,
        ),
      );
    }

    // Most recently paid first, then by name, as the list reads.
    found.sort((a, b) {
      final at = a.lastSentAt;
      final bt = b.lastSentAt;
      if (at != null && bt != null) return bt.compareTo(at);
      if (at != null) return -1;
      if (bt != null) return 1;
      return a.name.compareTo(b.name);
    });
    return found;
  }

  @override
  Future<PointRecipient?> lookup({
    required String mobileNumber,
    required String recipientNumber,
  }) async {
    final all = await recipients(mobileNumber);
    if (all == null) return null;

    final wanted = PartnerDirectory.normalise(recipientNumber);
    for (final recipient in all) {
      if (recipient.mobileNumber == wanted) return recipient;
    }
    return null;
  }

  @override
  Future<(PointTransferReceipt?, PointTransferFailure?)> send({
    required String fromMobileNumber,
    required String toMobileNumber,
    required int amount,
  }) async {
    final from = PartnerDirectory.normalise(fromMobileNumber);
    final to = PartnerDirectory.normalise(toMobileNumber);
    if (from == to) return (null, PointTransferFailure.self);

    final sender = PartnerDirectory.find(fromMobileNumber);
    if (sender == null) return (null, PointTransferFailure.unreachable);
    final receiver = PartnerDirectory.find(toMobileNumber);
    if (receiver == null) {
      return (null, PointTransferFailure.unknownRecipient);
    }

    // Each refusal is checked separately so the partner is told the one that
    // actually applies, and each is stated before anything moves.
    if (!_tradingRoles.contains(sender.role.toLowerCase()) ||
        !_tradingRoles.contains(receiver.role.toLowerCase())) {
      return (null, PointTransferFailure.pairNotPermitted);
    }
    if (balanceOf(from) < amount) {
      return (null, PointTransferFailure.notEnoughPoints);
    }

    final reference = 'PT-2026-${_nextReference++}';
    final postedAt = DateTime.now();

    // Both legs share a reference, so the two partners are reading the same
    // event rather than two that happen to match.
    _movements
      ..add(
        _Movement(
          number: from,
          reference: reference,
          type: PointEntryType.transferOut,
          amount: amount,
          credit: false,
          counterpartyNumber: to,
          postedAt: postedAt,
        ),
      )
      ..add(
        _Movement(
          number: to,
          reference: reference,
          type: PointEntryType.transferIn,
          amount: amount,
          credit: true,
          counterpartyNumber: from,
          postedAt: postedAt,
        ),
      );

    return (
      PointTransferReceipt(
        reference: reference,
        amount: amount,
        balance: balanceOf(from),
        sentAt: postedAt,
      ),
      null,
    );
  }
}

/// "182,400" — grouped in threes.
///
/// Points are whole. There is no decimal here because there is no fraction
/// of a point.
String formatPoints(int points) {
  final digits = points.abs().toString();
  final grouped = StringBuffer(points < 0 ? '-' : '');
  for (var i = 0; i < digits.length; i++) {
    if (i != 0 && (digits.length - i) % 3 == 0) grouped.write(',');
    grouped.write(digits[i]);
  }
  return grouped.toString();
}

const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// "08 Sep".
String formatPointsDate(DateTime at) =>
    '${at.day.toString().padLeft(2, '0')} ${_months[at.month - 1]}';

/// "August" — for "met in August", where the month alone is the point.
String formatPointsMonth(DateTime at) => const [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
][at.month - 1];

/// "Today, 6:02 AM", then "Yesterday, 3:14 PM", then "07 Sep".
String formatPointsWhen(DateTime at) {
  final now = DateTime.now();
  final days = DateTime(
    now.year,
    now.month,
    now.day,
  ).difference(DateTime(at.year, at.month, at.day)).inDays;

  final hour = at.hour % 12 == 0 ? 12 : at.hour % 12;
  final time =
      '$hour:${at.minute.toString().padLeft(2, '0')} '
      '${at.hour < 12 ? 'AM' : 'PM'}';

  if (days == 0) return 'Today, $time';
  if (days == 1) return 'Yesterday, $time';
  return formatPointsDate(at);
}

/// "3 months and 21 days left in the year".
String formatTimeLeft(DateTime until) {
  final now = DateTime.now();
  if (!until.isAfter(now)) return 'closed';

  var months = (until.year - now.year) * 12 + until.month - now.month;
  var anchor = DateTime(now.year, now.month + months, now.day);
  if (anchor.isAfter(until)) {
    months -= 1;
    anchor = DateTime(now.year, now.month + months, now.day);
  }
  final days = until.difference(anchor).inDays;

  final parts = [
    if (months > 0) '$months month${months == 1 ? '' : 's'}',
    if (days > 0) '$days day${days == 1 ? '' : 's'}',
  ];
  if (parts.isEmpty) return 'today';
  return parts.join(' and ');
}
