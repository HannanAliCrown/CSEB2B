/// One line in the ledger.
///
/// The balance is not here, and is not stored anywhere: it is the sum of
/// these rows, so the figure on Home and the lines in the ledger can never
/// disagree about each other.
class WalletEntryRow {
  const WalletEntryRow({
    required this.id,
    required this.reference,
    required this.title,
    required this.subtitle,
    required this.direction,
    required this.type,
    required this.state,
    required this.amountPaisa,
    required this.postedAt,
  });

  final String id;

  /// What a partner quotes to CRM, e.g. 'TX-0004'.
  final String reference;

  final String title;

  /// The line under the title: who the other party was, or what it was for.
  final String subtitle;

  /// 'credit' | 'debit'.
  final String direction;

  /// 'send_cash' | 'cash_request' | 'scan_prize' | 'spin_prize' |
  /// 'returned' | 'crm_adjustment'.
  final String type;

  /// 'cleared' | 'held' | 'rejected'.
  final String state;

  final int amountPaisa;
  final DateTime postedAt;

  Map<String, Object?> toJson() => {
    'id': id,
    'reference': reference,
    'title': title,
    'subtitle': subtitle,
    'direction': direction,
    'type': type,
    'state': state,
    'amountPaisa': amountPaisa,
    'postedAt': postedAt.toUtc().toIso8601String(),
  };
}

/// A partner cash can be sent to.
class CashRecipientRow {
  const CashRecipientRow({
    required this.mobileNumber,
    required this.name,
    required this.role,
  });

  final String mobileNumber;
  final String name;

  /// Capitalised as the screens print it: 'Retailer', 'Wholesaler'.
  final String role;

  Map<String, Object?> toJson() => {
    'mobileNumber': mobileNumber,
    'name': name,
    'role': role,
  };
}

/// Why a transfer was refused.
enum TransferRefusal {
  /// No account on that number, or one that cannot receive cash.
  unknownRecipient,

  /// The available balance does not cover it.
  notEnoughBalance,

  /// Below the smallest transfer Crown Solar accepts.
  amountTooSmall,

  /// Sending to yourself is not a transfer.
  self,

  /// No account on the sender's number.
  unknownSender,
}

/// The wallet's persistence boundary: the ledger, who can be paid, and
/// transfers between partners.
abstract interface class WalletDataStore {
  /// Every movement for this partner, newest first. Null when the number is
  /// not an account.
  Future<List<WalletEntryRow>?> ledger(String mobileNumber);

  /// What can be spent, and what is waiting on a receiver. Derived from the
  /// same rows the ledger returns.
  Future<({int availablePaisa, int heldPaisa})?> totals(String mobileNumber);

  /// Partners this one has paid before, most recent first, then the rest of
  /// the receiving roles.
  Future<List<CashRecipientRow>?> recipients(String mobileNumber);

  /// Resolves a typed number to someone who can receive cash.
  Future<CashRecipientRow?> lookupRecipient(String mobileNumber);

  /// Transfers sent to this partner: what is waiting, and what they have
  /// already decided. Null when the number is not an account.
  Future<List<CashRequestRow>?> cashRequests(String mobileNumber);

  /// Approves or rejects one.
  ///
  /// Approving credits this partner and settles the sender's debit.
  /// Rejecting returns the money to the sender — the debit stops counting
  /// against their balance, which is the same thing as giving it back.
  Future<CashRequestRefusal?> decideCashRequest({
    required String mobileNumber,
    required String reference,
    required bool approved,
  });

  /// Sends cash. The money leaves the sender's available balance at once and
  /// is held until the receiver accepts it.
  Future<(WalletEntryRow?, TransferRefusal?)> sendCash({
    required String fromMobileNumber,
    required String toMobileNumber,
    required int amountPaisa,
    String? note,
  });
}

/// The smallest transfer Crown Solar accepts, in paisa.
///
/// A company rule rather than a technical one, so it is stated once here and
/// the refusal names it.
const int minimumTransferPaisa = 10000;

/// The roles cash can be sent to.
///
/// Cash moves up the chain — an installer pays a retailer, a retailer pays a
/// wholesaler — so an installer can never be a recipient.
const Set<String> cashReceivingRoles = {
  'retailer',
  'wholesaler',
  'distributor',
};

/// One transfer waiting on, or already decided by, the partner it was sent
/// to.
///
/// The money is already out of the sender's wallet: approving moves it into
/// the receiver's, rejecting puts it back. It is never in both places and
/// never in neither.
class CashRequestRow {
  const CashRequestRow({
    required this.reference,
    required this.fromName,
    required this.fromRole,
    required this.amountPaisa,
    required this.state,
    required this.sentAt,
    this.note,
    this.expiresAt,
    this.decidedAt,
  });

  final String reference;
  final String fromName;

  /// Capitalised as the screens print it: 'Installer', 'Retailer'.
  final String fromRole;

  final int amountPaisa;

  /// 'held' | 'accepted' | 'rejected' | 'expired'.
  final String state;

  /// What the sender said it was for, when they said anything.
  final String? note;

  final DateTime sentAt;

  /// When it returns to the sender if nobody answers.
  final DateTime? expiresAt;
  final DateTime? decidedAt;

  Map<String, Object?> toJson() => {
    'reference': reference,
    'fromName': fromName,
    'fromRole': fromRole,
    'amountPaisa': amountPaisa,
    'state': state,
    'note': note,
    'sentAt': sentAt.toUtc().toIso8601String(),
    'expiresAt': expiresAt?.toUtc().toIso8601String(),
    'decidedAt': decidedAt?.toUtc().toIso8601String(),
  };
}

/// Why a decision on a cash request could not be recorded.
enum CashRequestRefusal {
  /// No account on the deciding number.
  unknownAccount,

  /// No transfer waiting on this partner under that reference — either it
  /// was never theirs to decide, or someone already decided it.
  notWaiting,
}
