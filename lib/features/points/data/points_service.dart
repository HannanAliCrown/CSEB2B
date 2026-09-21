// Constructor parameters are named for their public API rather than the
// private fields they populate, so the initializing-formal shorthand the
// linter suggests is not available here.
// ignore_for_file: prefer_initializing_formals

import 'dart:convert';

import 'package:http/http.dart' as http;

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

/// Points' data boundary, backed by the database behind `prototype_server`.
///
/// There is deliberately no in-memory implementation. Points arrive at once
/// and cannot be recalled, so a transfer that is only remembered until the
/// app restarts would be worse than one that plainly fails.
class PointsService {
  PointsService({required String baseUrl, http.Client? client})
    : _baseUrl = baseUrl,
      _client = client ?? http.Client();

  final String _baseUrl;
  final http.Client _client;

  /// The balance and every movement. Null when the server was unreachable —
  /// which the screen says, rather than showing a balance of zero.
  Future<PointsLedger?> ledger(String mobileNumber) async {
    final body = await _get('/points/ledger', {'mobileNumber': mobileNumber});
    return body == null ? null : PointsLedger.fromJson(body);
  }

  Future<PointTargets?> targets(String mobileNumber) async {
    final body = await _get('/points/targets', {'mobileNumber': mobileNumber});
    return body == null ? null : PointTargets.fromJson(body);
  }

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

  /// Resolves a number from a contact or a scanned QR code. Null when this
  /// partner may not send to them.
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

  /// Sends points. They arrive at once.
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
