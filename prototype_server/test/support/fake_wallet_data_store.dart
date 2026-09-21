import 'package:prototype_server/data/postgres_partner_data_store.dart'
    show normaliseMobile;
import 'package:prototype_server/data/wallet_data_store.dart';

/// An in-memory [WalletDataStore] enforcing the same rules the SQL does: the
/// balance is derived from the entries rather than stored, money sent leaves
/// the available balance at once, and only the selling roles can be paid.
class FakeWalletDataStore implements WalletDataStore {
  final Map<String, String> _roles = {};
  final Map<String, String> _names = {};
  final Map<String, List<WalletEntryRow>> _entries = {};
  final Set<String> _paidBefore = {};

  var _nextReference = 6;

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

  /// An opening balance, so a transfer has something to move.
  void credit({required String mobileNumber, required int amountPaisa}) =>
      _entries[normaliseMobile(mobileNumber)]!.add(
        WalletEntryRow(
          id: 'e${_nextReference++}',
          reference: 'TX-0001',
          title: 'Opening balance',
          subtitle: 'Crown Solar CRM',
          direction: 'credit',
          type: 'crm_adjustment',
          state: 'cleared',
          amountPaisa: amountPaisa,
          postedAt: DateTime.now().subtract(const Duration(days: 18)),
        ),
      );

  // --- WalletDataStore ---

  @override
  Future<List<WalletEntryRow>?> ledger(String mobileNumber) async {
    final entries = _entries[normaliseMobile(mobileNumber)];
    if (entries == null) return null;
    return [...entries]..sort((a, b) => b.postedAt.compareTo(a.postedAt));
  }

  @override
  Future<({int availablePaisa, int heldPaisa})?> totals(
    String mobileNumber,
  ) async {
    final entries = _entries[normaliseMobile(mobileNumber)];
    if (entries == null) return null;

    var available = 0;
    var held = 0;
    for (final entry in entries) {
      if (entry.state == 'rejected') continue;
      if (entry.direction == 'credit') {
        if (entry.state == 'cleared') available += entry.amountPaisa;
      } else {
        available -= entry.amountPaisa;
        if (entry.state == 'held') held += entry.amountPaisa;
      }
    }
    return (availablePaisa: available, heldPaisa: held);
  }

  @override
  Future<List<CashRecipientRow>?> recipients(String mobileNumber) async {
    final mine = normaliseMobile(mobileNumber);
    if (!_roles.containsKey(mine)) return null;

    final all = [
      for (final number in _roles.keys)
        if (number != mine && cashReceivingRoles.contains(_roles[number]))
          CashRecipientRow(
            mobileNumber: number,
            name: _names[number]!,
            role: _capitalise(_roles[number]!),
          ),
    ];
    // Paid before first, as the SQL orders them.
    all.sort((a, b) {
      final aPaid = _paidBefore.contains('$mine>${a.mobileNumber}');
      final bPaid = _paidBefore.contains('$mine>${b.mobileNumber}');
      if (aPaid != bPaid) return aPaid ? -1 : 1;
      return a.name.compareTo(b.name);
    });
    return all;
  }

  @override
  Future<CashRecipientRow?> lookupRecipient(String mobileNumber) async {
    final number = normaliseMobile(mobileNumber);
    final role = _roles[number];
    if (role == null || !cashReceivingRoles.contains(role)) return null;
    return CashRecipientRow(
      mobileNumber: number,
      name: _names[number]!,
      role: _capitalise(role),
    );
  }

  /// Transfers by reference, so both sides read the same record.
  final Map<String, _Transfer> _transfers = {};

  @override
  Future<List<CashRequestRow>?> cashRequests(String mobileNumber) async {
    final mine = normaliseMobile(mobileNumber);
    if (!_roles.containsKey(mine)) return null;

    return [
      for (final transfer in _transfers.values)
        if (transfer.to == mine)
          CashRequestRow(
            reference: transfer.reference,
            fromName: _names[transfer.from]!,
            fromRole: _capitalise(_roles[transfer.from]!),
            amountPaisa: transfer.amountPaisa,
            state: transfer.state,
            note: transfer.note,
            sentAt: transfer.sentAt,
            decidedAt: transfer.decidedAt,
          ),
    ]..sort((a, b) => b.sentAt.compareTo(a.sentAt));
  }

  @override
  Future<CashRequestRefusal?> decideCashRequest({
    required String mobileNumber,
    required String reference,
    required bool approved,
  }) async {
    final mine = normaliseMobile(mobileNumber);
    if (!_roles.containsKey(mine)) return CashRequestRefusal.unknownAccount;

    final transfer = _transfers[reference];
    // Theirs to decide, and still waiting. Deciding twice changes nothing.
    if (transfer == null || transfer.to != mine || transfer.state != 'held') {
      return CashRequestRefusal.notWaiting;
    }

    transfer
      ..state = approved ? 'accepted' : 'rejected'
      ..decidedAt = DateTime.now();

    // The sender's held debit settles, or stops counting — a rejected debit
    // is excluded from the balance, which is what giving it back means.
    final debit = _entries[transfer.from]!.indexWhere(
      (entry) => entry.reference == reference && entry.direction == 'debit',
    );
    if (debit >= 0) {
      final old = _entries[transfer.from]![debit];
      _entries[transfer.from]![debit] = WalletEntryRow(
        id: old.id,
        reference: old.reference,
        title: old.title,
        subtitle: old.subtitle,
        direction: old.direction,
        type: old.type,
        state: approved ? 'cleared' : 'rejected',
        amountPaisa: old.amountPaisa,
        postedAt: old.postedAt,
      );
    }

    if (!approved) return null;

    _entries[mine]!.add(
      WalletEntryRow(
        id: 'entry-$reference-in',
        reference: reference,
        title: 'Received from ${_names[transfer.from]}',
        subtitle:
            '${_capitalise(_roles[transfer.from]!)} · +92 '
            '${transfer.from}',
        direction: 'credit',
        type: 'send_cash',
        state: 'cleared',
        amountPaisa: transfer.amountPaisa,
        postedAt: DateTime.now(),
      ),
    );
    return null;
  }

  @override
  Future<(WalletEntryRow?, TransferRefusal?)> sendCash({
    required String fromMobileNumber,
    required String toMobileNumber,
    required int amountPaisa,
    String? note,
  }) async {
    if (amountPaisa < minimumTransferPaisa) {
      return (null, TransferRefusal.amountTooSmall);
    }

    final from = normaliseMobile(fromMobileNumber);
    final to = normaliseMobile(toMobileNumber);
    if (from == to) return (null, TransferRefusal.self);
    if (!_roles.containsKey(from)) {
      return (null, TransferRefusal.unknownSender);
    }

    final recipient = await lookupRecipient(to);
    if (recipient == null) return (null, TransferRefusal.unknownRecipient);

    final balance = await totals(from);
    if ((balance?.availablePaisa ?? 0) < amountPaisa) {
      return (null, TransferRefusal.notEnoughBalance);
    }

    final entry = WalletEntryRow(
      id: 'entry-$_nextReference',
      reference: 'TX-${_nextReference.toString().padLeft(4, '0')}',
      title: 'Sent to ${recipient.name}',
      subtitle: '${recipient.role} · +92 $to',
      direction: 'debit',
      type: 'send_cash',
      // Every transfer waits on the receiver.
      state: 'held',
      amountPaisa: amountPaisa,
      postedAt: DateTime.now(),
    );
    _nextReference++;
    _entries[from]!.add(entry);
    _paidBefore.add('$from>$to');
    // The record both sides act on, as `cash_transfers` is.
    _transfers[entry.reference] = _Transfer(
      reference: entry.reference,
      from: from,
      to: to,
      amountPaisa: amountPaisa,
      note: note,
      sentAt: entry.postedAt,
    );

    // Nothing is written to the receiver: they have not accepted it yet, so
    // there is nothing of theirs to show.
    return (entry, null);
  }

  static String _capitalise(String value) =>
      value[0].toUpperCase() + value.substring(1);
}

/// A transfer both sides read, exactly as `cash_transfers` is.
class _Transfer {
  _Transfer({
    required this.reference,
    required this.from,
    required this.to,
    required this.amountPaisa,
    required this.sentAt,
    this.note,
  });

  final String reference;
  final String from;
  final String to;
  final int amountPaisa;
  final String? note;
  final DateTime sentAt;

  String state = 'held';
  DateTime? decidedAt;
}
