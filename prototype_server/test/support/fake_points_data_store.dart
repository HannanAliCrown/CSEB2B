import 'package:prototype_server/data/points_data_store.dart';
import 'package:prototype_server/data/postgres_partner_data_store.dart'
    show normaliseMobile;

/// An in-memory [PointsDataStore] enforcing the same rules the SQL does: the
/// balance is derived from the entries, a pair with no rule is refused, and
/// a target counts points that arrived rather than points that moved.
class FakePointsDataStore implements PointsDataStore {
  final Map<String, String> _roles = {};
  final Map<String, String> _names = {};
  final Map<String, List<PointEntryRow>> _entries = {};
  final Set<String> _rules = {};
  final Map<String, ({bool canSend, bool canReceive, String? reason})>
  _restrictions = {};
  final Map<String, List<PointTargetRow>> _periods = {};
  final Map<String, String> _schemeNames = {};

  var _nextReference = 77411;

  // --- Test setup ---

  void addAccount({
    required String mobileNumber,
    required String role,
    String? name,
  }) {
    final number = normaliseMobile(mobileNumber);
    _roles[number] = role;
    _names[number] = name ?? 'Partner $number';
    _entries[number] ??= [];
  }

  /// A permitted pair. Anything not added here is refused.
  void allow({required String from, required String to}) =>
      _rules.add('$from>$to');

  void restrict({
    required String mobileNumber,
    bool canSend = true,
    bool canReceive = true,
    String? reason,
  }) => _restrictions[normaliseMobile(mobileNumber)] = (
    canSend: canSend,
    canReceive: canReceive,
    reason: reason,
  );

  /// Points posted by SAP, which count toward a target.
  void accrue({required String mobileNumber, required int amount}) =>
      _add(mobileNumber, 'credit', 'purchase_accrual', amount);

  void addScheme({
    required String mobileNumber,
    required String name,
    required List<PointTargetRow> periods,
  }) {
    _schemeNames[normaliseMobile(mobileNumber)] = name;
    _periods[normaliseMobile(mobileNumber)] = periods;
  }

  void _add(
    String mobileNumber,
    String direction,
    String type,
    int amount, {
    String? counterpartyName,
    String? reference,
  }) {
    final number = normaliseMobile(mobileNumber);
    _entries[number]!.add(
      PointEntryRow(
        reference: reference ?? 'PT-2026-${_nextReference++}',
        direction: direction,
        type: type,
        amount: amount,
        balanceAfter: 0,
        postedAt: DateTime.now(),
        counterpartyName: counterpartyName,
      ),
    );
  }

  // --- PointsDataStore ---

  @override
  Future<List<PointEntryRow>?> ledger(String mobileNumber) async {
    final entries = _entries[normaliseMobile(mobileNumber)];
    if (entries == null) return null;

    // The running balance is recomputed here too, so a test reading a line
    // sees arithmetic on the lines before it rather than a stored number.
    var running = 0;
    final withBalances = <PointEntryRow>[];
    for (final entry in entries) {
      running += entry.direction == 'credit' ? entry.amount : -entry.amount;
      withBalances.add(
        PointEntryRow(
          reference: entry.reference,
          direction: entry.direction,
          type: entry.type,
          amount: entry.amount,
          balanceAfter: running,
          postedAt: entry.postedAt,
          counterpartyName: entry.counterpartyName,
        ),
      );
    }
    return withBalances.reversed.toList();
  }

  @override
  Future<int?> balance(String mobileNumber) async {
    final entries = _entries[normaliseMobile(mobileNumber)];
    if (entries == null) return null;
    var total = 0;
    for (final entry in entries) {
      total += entry.direction == 'credit' ? entry.amount : -entry.amount;
    }
    return total;
  }

  @override
  Future<({bool canSend, String? reason})?> sendingStatus(
    String mobileNumber,
  ) async {
    final number = normaliseMobile(mobileNumber);
    if (!_roles.containsKey(number)) return null;
    final restriction = _restrictions[number];
    return (canSend: restriction?.canSend ?? true, reason: restriction?.reason);
  }

  @override
  Future<List<PointRecipientRow>?> recipients(String mobileNumber) async {
    final mine = normaliseMobile(mobileNumber);
    final myRole = _roles[mine];
    if (myRole == null) return null;

    return [
      for (final number in _roles.keys)
        if (number != mine &&
            _rules.contains('$myRole>${_roles[number]}') &&
            (_restrictions[number]?.canReceive ?? true))
          PointRecipientRow(
            mobileNumber: number,
            name: _names[number]!,
            role: _roles[number]!,
            lastSentAt: _lastSentTo(mine, number),
          ),
    ];
  }

  DateTime? _lastSentTo(String from, String to) {
    for (final entry in _entries[from]!.reversed) {
      if (entry.type == 'transfer_out' &&
          entry.counterpartyName == _names[to]) {
        return entry.postedAt;
      }
    }
    return null;
  }

  @override
  Future<PointRecipientRow?> lookupRecipient({
    required String mobileNumber,
    required String recipientNumber,
  }) async {
    final all = await recipients(mobileNumber);
    final wanted = normaliseMobile(recipientNumber);
    for (final recipient in all ?? const <PointRecipientRow>[]) {
      if (recipient.mobileNumber == wanted) return recipient;
    }
    return null;
  }

  @override
  Future<PointTargetsRow?> targets(String mobileNumber) async {
    final number = normaliseMobile(mobileNumber);
    if (!_roles.containsKey(number)) return null;

    final scheme = _schemeNames[number];
    if (scheme == null) {
      return const PointTargetsRow(
        periods: [],
        extras: [],
        breakdown: PointBreakdownRow(
          purchases: 0,
          transferredIn: 0,
          reversals: 0,
        ),
      );
    }

    var purchases = 0;
    var transferredIn = 0;
    var reversals = 0;
    for (final entry in _entries[number]!) {
      switch (entry.type) {
        case 'purchase_accrual':
          purchases += entry.amount;
        case 'transfer_in':
          transferredIn += entry.amount;
        case 'reversal':
          reversals += entry.amount;
      }
    }

    return PointTargetsRow(
      schemeName: scheme,
      periods: _periods[number] ?? const [],
      extras: const [],
      breakdown: PointBreakdownRow(
        purchases: purchases,
        transferredIn: transferredIn,
        reversals: reversals,
      ),
    );
  }

  @override
  Future<(PointEntryRow?, PointTransferRefusal?)> sendPoints({
    required String fromMobileNumber,
    required String toMobileNumber,
    required int amount,
  }) async {
    if (amount <= 0) return (null, PointTransferRefusal.amountNotPositive);

    final from = normaliseMobile(fromMobileNumber);
    final to = normaliseMobile(toMobileNumber);
    if (from == to) return (null, PointTransferRefusal.self);
    if (!_roles.containsKey(from)) {
      return (null, PointTransferRefusal.unknownSender);
    }
    if (!_roles.containsKey(to)) {
      return (null, PointTransferRefusal.unknownRecipient);
    }

    if (!(_restrictions[from]?.canSend ?? true)) {
      return (null, PointTransferRefusal.senderRestricted);
    }
    if (!(_restrictions[to]?.canReceive ?? true)) {
      return (null, PointTransferRefusal.recipientRestricted);
    }
    if (!_rules.contains('${_roles[from]}>${_roles[to]}')) {
      return (null, PointTransferRefusal.pairNotPermitted);
    }
    if ((await balance(from) ?? 0) < amount) {
      return (null, PointTransferRefusal.notEnoughPoints);
    }

    // Both legs, sharing one reference.
    final reference = 'PT-2026-${_nextReference++}';
    _add(
      from,
      'debit',
      'transfer_out',
      amount,
      counterpartyName: _names[to],
      reference: reference,
    );
    _add(
      to,
      'credit',
      'transfer_in',
      amount,
      counterpartyName: _names[from],
      reference: reference,
    );

    final entries = await ledger(from);
    return (entries!.firstWhere((e) => e.reference == reference), null);
  }
}
