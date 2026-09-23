import 'package:flutter/foundation.dart';

import '../../../core/mock/partner_directory.dart';
import '../../../core/mock/pending_registrations.dart';
import '../../session/data/signed_in_user.dart';

/// An amount in rupees, held as whole paisa so no total is ever a rounded
/// double.
class Money implements Comparable<Money> {
  const Money(this.paisa);

  factory Money.rupees(num rupees) => Money((rupees * 100).round());

  final int paisa;

  Money operator +(Money other) => Money(paisa + other.paisa);
  Money operator -(Money other) => Money(paisa - other.paisa);

  bool get isZero => paisa == 0;

  /// "12,480" — grouped, and without decimals when there are none.
  String get formatted {
    final whole = paisa ~/ 100;
    final remainder = paisa.remainder(100).abs();
    final digits = whole.abs().toString();
    final grouped = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i != 0 && (digits.length - i) % 3 == 0) grouped.write(',');
      grouped.write(digits[i]);
    }
    final sign = paisa < 0 ? '-' : '';
    if (remainder == 0) return '$sign$grouped';
    return '$sign$grouped.${remainder.toString().padLeft(2, '0')}';
  }

  @override
  int compareTo(Money other) => paisa.compareTo(other.paisa);

  @override
  bool operator ==(Object other) => other is Money && other.paisa == paisa;

  @override
  int get hashCode => paisa.hashCode;
}

enum LedgerDirection { credit, debit }

enum LedgerState {
  /// Settled and reflected in the spendable balance.
  cleared,

  /// Sent, but waiting on the person receiving it to accept.
  held,

  /// Refused; the money never left.
  rejected,
}

/// What put a line in the ledger. The filter sheet offers these by name.
enum LedgerType {
  sendCash,
  cashRequest,
  scanPrize,
  spinPrize,
  returned,
  adjustment,
}

extension LedgerTypeX on LedgerType {
  String get label => switch (this) {
    LedgerType.sendCash => 'Send Cash',
    LedgerType.cashRequest => 'Cash Request',
    LedgerType.scanPrize => 'QR prize',
    LedgerType.spinPrize => 'Spin prize',
    LedgerType.returned => 'Returned',
    LedgerType.adjustment => 'CRM adjustment',
  };
}

/// One line in the wallet ledger.
class LedgerEntry {
  const LedgerEntry({
    required this.id,
    required this.postedAt,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.direction,
    required this.state,
    required this.type,
    this.counterpartyNumber,
  });

  final LedgerType type;

  final String id;
  final DateTime postedAt;
  final String title;
  final String subtitle;
  final Money amount;
  final LedgerDirection direction;
  final LedgerState state;

  /// The partner on the other side of a transfer, so the person it was sent
  /// to can be found without reading the line's wording. Null on anything
  /// that has no other side, such as a prize or a CRM adjustment.
  final String? counterpartyNumber;

  bool get isCredit => direction == LedgerDirection.credit;

  /// "+12,480" / "-3,000", as the ledger prints it.
  String get signedAmount => '${isCredit ? '+' : '-'}${amount.formatted}';

  /// A held line settles or is returned; nothing else about it ever changes.
  LedgerEntry withState(LedgerState value) => LedgerEntry(
    id: id,
    postedAt: postedAt,
    title: title,
    subtitle: subtitle,
    amount: amount,
    direction: direction,
    state: value,
    type: type,
    counterpartyNumber: counterpartyNumber,
  );
}

/// A transfer as the partner it was sent to sees it: the sender's own ledger
/// line, and who sent it.
class IncomingTransfer {
  const IncomingTransfer({required this.entry, required this.fromNumber});

  final LedgerEntry entry;
  final String fromNumber;
}

/// Someone cash can be sent to.
///
/// Cash moves up the chain — an installer pays a retailer, a retailer pays a
/// wholesaler — so only the selling roles can receive it.
class CashRecipient {
  const CashRecipient({
    required this.mobileNumber,
    required this.name,
    required this.role,
  });

  final String mobileNumber;
  final String name;
  final String role;
}

/// Why a transfer could not be made.
enum TransferFailure {
  unknownRecipient,
  notEnoughBalance,
  amountTooSmall,
  self,
}

class TransferResult {
  const TransferResult.success(this.entry, {required this.held})
    : failure = null;
  const TransferResult.failed(this.failure) : entry = null, held = false;

  final LedgerEntry? entry;

  /// Every transfer waits on the receiver accepting it.
  final bool held;
  final TransferFailure? failure;

  bool get succeeded => entry != null;
}

/// The wallet's data boundary: balance, ledger, recipients and transfers.
abstract interface class WalletRepository {
  /// Fires whenever money moves, so anything showing a balance can reload
  /// rather than going stale behind another screen.
  Listenable get changes;

  /// Says a balance moved without this repository being the one that moved
  /// it. Inaam prizes are credited by the server inside the transaction that
  /// awarded them, so the row exists before anything here knows of it.
  void announceChange();

  Future<Money> balance(SignedInUser user);

  /// Credits a prize won by scanning a product, so the wallet and the ledger
  /// agree about it immediately.
  Future<LedgerEntry> creditScanPrize({
    required SignedInUser user,
    required Money amount,
    required String productName,
    required String code,
  });

  /// The part of the balance that is not spendable yet.
  Future<Money> heldTotal(SignedInUser user);

  Future<List<LedgerEntry>> ledger(SignedInUser user);

  /// Partners this user has sent to before, most recent first.
  Future<List<CashRecipient>> recentRecipients(SignedInUser user);

  /// Resolves a typed number to a partner who can receive cash.
  Future<CashRecipient?> lookupRecipient(String mobileNumber);

  Future<TransferResult> sendCash({
    required SignedInUser from,
    required String toMobileNumber,
    required Money amount,
    String? note,
  });
}

/// A deterministic in-memory wallet. Balances and history are seeded per
/// partner, and a transfer really does move the balance and add a ledger
/// line, so the screens above behave as they will against a real service.
class MockWalletRepository implements WalletRepository {
  MockWalletRepository();

  static const _latency = Duration(milliseconds: 220);

  /// The smallest transfer Crown Solar accepts.
  static final minimumTransfer = Money.rupees(100);

  /// Cash moves up the chain, so only these roles can receive it.
  static const receivingRoles = {'Retailer', 'Wholesaler', 'Distributor'};

  final Map<String, List<LedgerEntry>> _ledgers = {};
  var _nextId = 1000;

  final _changes = _Broadcast();

  @override
  Listenable get changes => _changes;

  /// Anything watching a balance is told the moment one moves.
  void _announce() => _changes.announce();

  @override
  void announceChange() => _announce();

  @override
  Future<LedgerEntry> creditScanPrize({
    required SignedInUser user,
    required Money amount,
    required String productName,
    required String code,
  }) async {
    final entry = LedgerEntry(
      id: 'PRZ-${_nextId++}',
      postedAt: DateTime.now(),
      title: 'Scan prize · $productName',
      subtitle: code,
      amount: amount,
      direction: LedgerDirection.credit,
      // A prize is Crown Solar's own money: nobody has to accept it.
      state: LedgerState.cleared,
      type: LedgerType.scanPrize,
    );
    _ledgerFor(user).add(entry);
    _announce();
    return entry;
  }

  /// Credits a Spin and Win prize, as the database does when a spin is
  /// taken: the prize and the wallet entry are written together, so what the
  /// wheel showed is what the balance moved by.
  ///
  /// Keyed by number rather than by the signed-in user because Inaam works
  /// from the number alone, as the server's routes do.
  Future<LedgerEntry?> creditSpinPrize({
    required String mobileNumber,
    required Money amount,
    required String reference,
  }) async {
    final account = PartnerDirectory.find(mobileNumber);
    if (account == null) return null;

    final entry = LedgerEntry(
      id: reference,
      postedAt: DateTime.now(),
      title: 'Spin and Win prize',
      subtitle: reference,
      amount: amount,
      direction: LedgerDirection.credit,
      // A prize is Crown Solar's own money: nobody has to accept it.
      state: LedgerState.cleared,
      type: LedgerType.spinPrize,
    );
    _ledgerFor(SignedInUser.fromAccount(account)).add(entry);
    _announce();
    return entry;
  }

  List<LedgerEntry> _ledgerFor(SignedInUser user) =>
      _ledgerForNumber(user.mobileNumber);

  /// The ledger behind a number, whether or not that partner is the one
  /// signed in — a transfer credits a wallet nobody is looking at.
  List<LedgerEntry> _ledgerForNumber(String mobileNumber) {
    final account = PartnerDirectory.find(mobileNumber);
    return _ledgers.putIfAbsent(
      PartnerDirectory.normalise(mobileNumber),
      // Someone who registered on this phone is not in the directory and
      // starts at zero; there is no opening history to carry over.
      () => account == null
          ? <LedgerEntry>[]
          : _seedFor(SignedInUser.fromAccount(account)),
    );
  }

  @override
  Future<Money> balance(SignedInUser user) async {
    await Future<void>.delayed(_latency);
    return _clearedBalance(user);
  }

  /// What can still be spent. Money sent is gone from the available balance
  /// the moment it is sent, even while the receiver is still deciding —
  /// which is what the review sheet promises. Money coming in only counts
  /// once it has cleared.
  Money _clearedBalance(SignedInUser user) {
    var total = const Money(0);
    for (final entry in _ledgerFor(user)) {
      if (entry.state == LedgerState.rejected) continue;
      if (entry.isCredit) {
        if (entry.state == LedgerState.cleared) total = total + entry.amount;
      } else {
        total = total - entry.amount;
      }
    }
    return total;
  }

  @override
  Future<Money> heldTotal(SignedInUser user) async {
    await Future<void>.delayed(_latency);
    var total = const Money(0);
    for (final entry in _ledgerFor(user)) {
      if (entry.state == LedgerState.held) total = total + entry.amount;
    }
    return total;
  }

  @override
  Future<List<LedgerEntry>> ledger(SignedInUser user) async {
    await Future<void>.delayed(_latency);
    final entries = [..._ledgerFor(user)]
      ..sort((a, b) => b.postedAt.compareTo(a.postedAt));
    return entries;
  }

  @override
  Future<List<CashRecipient>> recentRecipients(SignedInUser user) async {
    await Future<void>.delayed(_latency);
    final mine = PartnerDirectory.normalise(user.mobileNumber);
    return PartnerDirectory.accounts
        .where(
          (account) =>
              PartnerDirectory.normalise(account.mobileNumber) != mine &&
              receivingRoles.contains(account.role),
        )
        .map(
          (account) => CashRecipient(
            mobileNumber: account.mobileNumber,
            name: account.displayName,
            role: account.role,
          ),
        )
        .toList();
  }

  /// Who a number belongs to, for the purposes of a transfer.
  ///
  /// The bundled directory first, then a registration submitted on this
  /// phone that has all three approvals. A partner who registered here is a
  /// partner: leaving them out would mean cash could never be sent to anyone
  /// who joined after the directory was written.
  ///
  /// An application still waiting is deliberately nobody. They cannot open
  /// the app to answer a transfer, so nothing may be sent to them.
  CashRecipient? _partnerFor(String mobileNumber) {
    final account = PartnerDirectory.find(mobileNumber);
    if (account != null) {
      return CashRecipient(
        mobileNumber: account.mobileNumber,
        name: account.displayName,
        role: account.role,
      );
    }

    final pending = PendingRegistrations.find(mobileNumber);
    if (pending == null || !pending.isApproved) return null;
    return CashRecipient(
      mobileNumber: pending.mobileNumber,
      name: pending.businessName,
      role: pending.role,
    );
  }

  @override
  Future<CashRecipient?> lookupRecipient(String mobileNumber) async {
    await Future<void>.delayed(_latency);
    final partner = _partnerFor(mobileNumber);
    if (partner == null || !receivingRoles.contains(partner.role)) return null;
    return partner;
  }

  @override
  Future<TransferResult> sendCash({
    required SignedInUser from,
    required String toMobileNumber,
    required Money amount,
    String? note,
  }) async {
    await Future<void>.delayed(_latency);

    if (amount.compareTo(minimumTransfer) < 0) {
      return const TransferResult.failed(TransferFailure.amountTooSmall);
    }
    if (PartnerDirectory.normalise(toMobileNumber) ==
        PartnerDirectory.normalise(from.mobileNumber)) {
      return const TransferResult.failed(TransferFailure.self);
    }

    final account = _partnerFor(toMobileNumber);
    if (account == null || !receivingRoles.contains(account.role)) {
      return const TransferResult.failed(TransferFailure.unknownRecipient);
    }
    if (_clearedBalance(from).compareTo(amount) < 0) {
      return const TransferResult.failed(TransferFailure.notEnoughBalance);
    }

    // The person receiving the cash is the one who confirms it arrived, so
    // every transfer is held until they accept it. The buying source has no
    // part in a transfer — they only verify a registration.
    final entry = LedgerEntry(
      id: 'TX-${_nextId++}',
      postedAt: DateTime.now(),
      title: 'Sent to ${account.name}',
      subtitle: note == null || note.isEmpty
          ? '${account.role} · ${account.mobileNumber}'
          : note,
      amount: amount,
      direction: LedgerDirection.debit,
      state: LedgerState.held,
      type: LedgerType.sendCash,
      counterpartyNumber: PartnerDirectory.normalise(toMobileNumber),
    );

    _ledgerFor(from).add(entry);
    _announce();
    return TransferResult.success(entry, held: true);
  }

  /// Transfers sent to this partner, whatever has become of them, newest
  /// first. This is what the Cash Request inbox lists: a transfer is one
  /// record, held on the sender's ledger, seen from the other end.
  List<IncomingTransfer> incomingTransfers(String mobileNumber) {
    final needle = PartnerDirectory.normalise(mobileNumber);
    return [
      for (final ledger in _ledgers.entries)
        for (final entry in ledger.value)
          if (entry.type == LedgerType.sendCash &&
              entry.counterpartyNumber == needle)
            IncomingTransfer(entry: entry, fromNumber: ledger.key),
    ]..sort((a, b) => b.entry.postedAt.compareTo(a.entry.postedAt));
  }

  /// Settles a held transfer, which is the one moment the money is in two
  /// wallets' accounting at once and so has to happen together: approving
  /// releases the sender's hold and credits the receiver, rejecting returns
  /// it to the sender and credits nobody.
  ///
  /// False when there is no such transfer, or it was already decided.
  bool settleTransfer({required String id, required bool approved}) {
    for (final ledger in _ledgers.entries) {
      final index = ledger.value.indexWhere((entry) => entry.id == id);
      if (index < 0) continue;

      final entry = ledger.value[index];
      if (entry.state != LedgerState.held) return false;

      // Cleared, not removed: the money really did leave the sender. It
      // simply stops being held, which is what takes it out of their held
      // total while leaving the line in their history.
      ledger.value[index] = entry.withState(
        approved ? LedgerState.cleared : LedgerState.rejected,
      );

      if (approved) {
        final sender = _partnerFor(ledger.key);
        _ledgerForNumber(entry.counterpartyNumber!).add(
          LedgerEntry(
            id: 'RX-${_nextId++}',
            postedAt: DateTime.now(),
            title: 'Received from ${sender?.name ?? 'a partner'}',
            subtitle: entry.subtitle,
            amount: entry.amount,
            direction: LedgerDirection.credit,
            state: LedgerState.cleared,
            type: LedgerType.cashRequest,
            counterpartyNumber: ledger.key,
          ),
        );
      }

      _announce();
      return true;
    }
    return false;
  }

  /// Opening history, so a wallet is never empty on first sight. Only the
  /// partners the directory knows get one — see [_ledgerForNumber].
  List<LedgerEntry> _seedFor(SignedInUser user) {
    final now = DateTime.now();
    DateTime daysAgo(int days) => now.subtract(Duration(days: days));

    return [
      LedgerEntry(
        id: 'TX-0001',
        postedAt: daysAgo(18),
        title: 'Opening balance',
        subtitle: 'Carried over by Crown Solar CRM',
        amount: Money.rupees(user.role.earnsPrizes ? 18500 : 142000),
        direction: LedgerDirection.credit,
        state: LedgerState.cleared,
        type: LedgerType.adjustment,
      ),
      LedgerEntry(
        id: 'TX-0002',
        postedAt: daysAgo(11),
        title: 'Scan reward · inverter',
        subtitle: 'Eid scheme',
        amount: Money.rupees(1200),
        direction: LedgerDirection.credit,
        state: LedgerState.cleared,
        type: LedgerType.scanPrize,
      ),
      LedgerEntry(
        id: 'TX-0003',
        postedAt: daysAgo(6),
        title: 'Sent to Al-Noor Electric Store',
        subtitle: 'Retailer · +92 300 7781204',
        amount: Money.rupees(3000),
        direction: LedgerDirection.debit,
        state: LedgerState.cleared,
        type: LedgerType.sendCash,
      ),
      LedgerEntry(
        id: 'TX-0004',
        postedAt: daysAgo(2),
        title: 'Sent to Bilal Traders',
        subtitle: 'Retailer · +92 321 7745002',
        amount: Money.rupees(1500),
        direction: LedgerDirection.debit,
        state: LedgerState.held,
        type: LedgerType.sendCash,
      ),
      LedgerEntry(
        id: 'TX-0005',
        postedAt: daysAgo(1),
        title: 'Scan reward · panel',
        subtitle: 'Eid scheme',
        amount: Money.rupees(800),
        direction: LedgerDirection.credit,
        state: LedgerState.cleared,
        type: LedgerType.scanPrize,
      ),
    ];
  }
}

/// A [ChangeNotifier] its owner can fire, so the wallet can announce that a
/// balance moved without exposing the whole notifier API.
class _Broadcast extends ChangeNotifier {
  void announce() => notifyListeners();
}
