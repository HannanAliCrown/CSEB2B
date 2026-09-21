/// One line in the points ledger.
///
/// The balance is not stored anywhere; `balanceAfter` is computed by running
/// the entries in order, which is why the hub, the ledger and a target's
/// score can never disagree about each other.
class PointEntryRow {
  const PointEntryRow({
    required this.reference,
    required this.direction,
    required this.type,
    required this.amount,
    required this.balanceAfter,
    required this.postedAt,
    this.counterpartyName,
    this.counterpartyRole,
    this.sapDocument,
    this.note,
  });

  final String reference;

  /// 'credit' | 'debit'.
  final String direction;

  /// 'purchase_accrual' | 'reversal' | 'transfer_in' | 'transfer_out' |
  /// 'crm_adjustment'.
  final String type;

  final int amount;

  /// What the balance stood at once this line had posted.
  final int balanceAfter;

  final DateTime postedAt;

  /// Set on a transfer only.
  final String? counterpartyName;
  final String? counterpartyRole;

  /// The SAP document a purchase or reversal came from.
  final String? sapDocument;

  /// Why, on a CRM adjustment.
  final String? note;

  Map<String, Object?> toJson() => {
    'reference': reference,
    'direction': direction,
    'type': type,
    'amount': amount,
    'balanceAfter': balanceAfter,
    'postedAt': postedAt.toUtc().toIso8601String(),
    'counterpartyName': counterpartyName,
    'counterpartyRole': counterpartyRole,
    'sapDocument': sapDocument,
    'note': note,
  };
}

/// A partner points can be sent to.
class PointRecipientRow {
  const PointRecipientRow({
    required this.mobileNumber,
    required this.name,
    required this.role,
    this.lastSentAt,
    this.lastSentAmount,
  });

  final String mobileNumber;
  final String name;

  /// Capitalised as the screens print it.
  final String role;

  /// When this partner last sent them points, for the history list.
  final DateTime? lastSentAt;
  final int? lastSentAmount;

  Map<String, Object?> toJson() => {
    'mobileNumber': mobileNumber,
    'name': name,
    'role': role,
    'lastSentAt': lastSentAt?.toUtc().toIso8601String(),
    'lastSentAmount': lastSentAmount,
  };
}

/// One target, scheme or company-assigned, with what has been scored toward
/// it so far.
class PointTargetRow {
  const PointTargetRow({
    required this.kind,
    required this.label,
    required this.targetPoints,
    required this.scoredPoints,
    required this.startsOn,
    required this.endsOn,
    this.prize,
    this.metOn,
  });

  /// 'period' — a four-month target inside the signed scheme.
  /// 'annual' — the year total.
  /// 'extra'  — one Crown Solar set for this partner by hand.
  final String kind;

  final String label;
  final int targetPoints;

  /// Points that arrived inside the window: purchases and transfers in, less
  /// reversals. Points sent out are deliberately not counted.
  final int scoredPoints;

  final DateTime startsOn;
  final DateTime endsOn;
  final String? prize;

  /// When the score first reached the target, or null if it has not. A real
  /// date rather than a flag, because "met in August" is worth more than
  /// "met".
  final DateTime? metOn;

  Map<String, Object?> toJson() => {
    'kind': kind,
    'label': label,
    'targetPoints': targetPoints,
    'scoredPoints': scoredPoints,
    'startsOn': startsOn.toUtc().toIso8601String(),
    'endsOn': endsOn.toUtc().toIso8601String(),
    'prize': prize,
    'metOn': metOn?.toUtc().toIso8601String(),
  };
}

/// Where the points counting toward the running target came from.
class PointBreakdownRow {
  const PointBreakdownRow({
    required this.purchases,
    required this.transferredIn,
    required this.reversals,
  });

  final int purchases;
  final int transferredIn;

  /// A positive figure; the screen prints the minus sign.
  final int reversals;

  Map<String, Object?> toJson() => {
    'purchases': purchases,
    'transferredIn': transferredIn,
    'reversals': reversals,
  };
}

/// Everything View Targets shows.
class PointTargetsRow {
  const PointTargetsRow({
    required this.periods,
    required this.extras,
    required this.breakdown,
    this.schemeName,
    this.schemeSignedOn,
    this.annual,
    this.annualPrize,
    this.grandPrize,
  });

  /// Null when no scheme has been signed. Everything else is then empty, and
  /// the app shows the "no scheme" screen rather than an empty target list.
  final String? schemeName;
  final DateTime? schemeSignedOn;

  /// The year total. Null without a scheme.
  final PointTargetRow? annual;
  final String? annualPrize;

  /// The prize for hitting every four-month target, on the schemes that
  /// carry one.
  final String? grandPrize;

  final List<PointTargetRow> periods;

  /// Targets Crown Solar set for this partner by hand, outside the scheme.
  final List<PointTargetRow> extras;

  /// Where the running target's points came from.
  final PointBreakdownRow breakdown;

  bool get hasScheme => schemeName != null;

  Map<String, Object?> toJson() => {
    'schemeName': schemeName,
    'schemeSignedOn': schemeSignedOn?.toUtc().toIso8601String(),
    'annual': annual?.toJson(),
    'annualPrize': annualPrize,
    'grandPrize': grandPrize,
    'periods': [for (final period in periods) period.toJson()],
    'extras': [for (final extra in extras) extra.toJson()],
    'breakdown': breakdown.toJson(),
  };
}

/// Why a points transfer was refused.
///
/// Each one is its own answer because each one has a different remedy: one
/// is fixed by sending less, one by choosing someone else, and two only by
/// talking to Crown Solar.
enum PointTransferRefusal {
  /// The balance does not cover it.
  notEnoughPoints,

  /// The Crown Solar team has not permitted this pair of roles.
  pairNotPermitted,

  /// This partner's own sending is blocked.
  senderRestricted,

  /// The other partner cannot receive right now.
  recipientRestricted,

  /// No account on the recipient's number.
  unknownRecipient,

  /// No account on the sender's number.
  unknownSender,

  /// Sending to yourself is not a transfer.
  self,

  /// Zero or a negative number of points.
  amountNotPositive,
}

/// Points' persistence boundary.
///
/// Points are not money: nothing here touches `wallet_entries`, and no
/// method returns a figure the two could be added together from.
abstract interface class PointsDataStore {
  /// Every movement for this partner, newest first, each carrying the
  /// balance it left behind. Null when the number is not an account.
  Future<List<PointEntryRow>?> ledger(String mobileNumber);

  /// The points balance. Derived from the same rows the ledger returns.
  Future<int?> balance(String mobileNumber);

  /// Whether this partner may send at all, and why not.
  Future<({bool canSend, String? reason})?> sendingStatus(String mobileNumber);

  /// Partners this one is permitted to send to, those already paid first.
  Future<List<PointRecipientRow>?> recipients(String mobileNumber);

  /// Resolves one number — from a contact or a scanned QR code — to someone
  /// this partner may send to. Null when they may not.
  Future<PointRecipientRow?> lookupRecipient({
    required String mobileNumber,
    required String recipientNumber,
  });

  /// The scheme, its targets, and what has been scored toward each.
  Future<PointTargetsRow?> targets(String mobileNumber);

  /// Sends points. They arrive at once: there is no approval step and no way
  /// back except a CRM adjustment, which is why every refusal is checked
  /// before anything moves.
  Future<(PointEntryRow?, PointTransferRefusal?)> sendPoints({
    required String fromMobileNumber,
    required String toMobileNumber,
    required int amount,
  });
}
