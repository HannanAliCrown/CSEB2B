import '../../../core/mock/partner_directory.dart';
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
  });

  final String id;
  final DateTime postedAt;
  final String title;
  final String subtitle;
  final Money amount;
  final LedgerDirection direction;
  final LedgerState state;

  bool get isCredit => direction == LedgerDirection.credit;

  /// "+12,480" / "-3,000", as the ledger prints it.
  String get signedAmount => '${isCredit ? '+' : '-'}${amount.formatted}';
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
  Future<Money> balance(SignedInUser user);

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

  List<LedgerEntry> _ledgerFor(SignedInUser user) => _ledgers.putIfAbsent(
    PartnerDirectory.normalise(user.mobileNumber),
    () => _seedFor(user),
  );

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

  @override
  Future<CashRecipient?> lookupRecipient(String mobileNumber) async {
    await Future<void>.delayed(_latency);
    final account = PartnerDirectory.find(mobileNumber);
    if (account == null || !receivingRoles.contains(account.role)) return null;
    return CashRecipient(
      mobileNumber: account.mobileNumber,
      name: account.displayName,
      role: account.role,
    );
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

    final account = PartnerDirectory.find(toMobileNumber);
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
      title: 'Sent to ${account.displayName}',
      subtitle: note == null || note.isEmpty
          ? '${account.role} · ${account.mobileNumber}'
          : note,
      amount: amount,
      direction: LedgerDirection.debit,
      state: LedgerState.held,
    );

    _ledgerFor(from).add(entry);
    return TransferResult.success(entry, held: true);
  }

  /// Opening history, so a wallet is never empty on first sight.
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
      ),
      LedgerEntry(
        id: 'TX-0002',
        postedAt: daysAgo(11),
        title: 'Scan reward · inverter',
        subtitle: 'Eid scheme',
        amount: Money.rupees(1200),
        direction: LedgerDirection.credit,
        state: LedgerState.cleared,
      ),
      LedgerEntry(
        id: 'TX-0003',
        postedAt: daysAgo(6),
        title: 'Sent to Al-Noor Electric Store',
        subtitle: 'Retailer · +92 300 7781204',
        amount: Money.rupees(3000),
        direction: LedgerDirection.debit,
        state: LedgerState.cleared,
      ),
      LedgerEntry(
        id: 'TX-0004',
        postedAt: daysAgo(2),
        title: 'Sent to Bilal Traders',
        subtitle: 'Retailer · +92 321 7745002',
        amount: Money.rupees(1500),
        direction: LedgerDirection.debit,
        state: LedgerState.held,
      ),
      LedgerEntry(
        id: 'TX-0005',
        postedAt: daysAgo(1),
        title: 'Scan reward · panel',
        subtitle: 'Eid scheme',
        amount: Money.rupees(800),
        direction: LedgerDirection.credit,
        state: LedgerState.cleared,
      ),
    ];
  }
}
