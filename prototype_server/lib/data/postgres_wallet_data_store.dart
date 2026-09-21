import 'package:postgres/postgres.dart';

import '../db/postgres_client.dart';
import 'postgres_partner_data_store.dart' show normaliseMobile;
import 'wallet_data_store.dart';

/// The [WalletDataStore] backed by PostgreSQL.
///
/// No balance is stored. Every figure the app shows is a SUM over
/// `wallet_entries` computed here, which is why the ledger and Home can
/// never drift apart.
class PostgresWalletDataStore implements WalletDataStore {
  PostgresWalletDataStore(this._client);

  final PostgresClient _client;

  /// The two sums Home and the ledger both show.
  ///
  /// Available counts cleared credits and every debit that has not been
  /// refused: money sent is gone from what can be spent the moment it is
  /// sent, even while the receiver is still deciding. Held is the part of
  /// that which has settled nowhere yet.
  static const _totalsSql = '''
    SELECT
      COALESCE(SUM(CASE
        WHEN state = 'rejected' THEN 0
        WHEN direction = 'credit' AND state = 'cleared' THEN amount_paisa
        WHEN direction = 'debit' THEN -amount_paisa
        ELSE 0
      END), 0)::bigint AS available_paisa,
      COALESCE(SUM(CASE
        WHEN state = 'held' AND direction = 'debit' THEN amount_paisa
        ELSE 0
      END), 0)::bigint AS held_paisa
    FROM wallet_entries
   WHERE account_id = @accountId
  ''';

  @override
  Future<List<WalletEntryRow>?> ledger(String mobileNumber) async {
    final accountId = await _accountId(mobileNumber);
    if (accountId == null) return null;

    final result = await _client.pool.execute(
      Sql.named('''
        SELECT e.id, e.reference, e.title, e.direction, e.type, e.state,
               e.amount_paisa, e.posted_at,
               c.display_name AS counterparty_name,
               c.user_type    AS counterparty_role,
               c.mobile_number AS counterparty_number
          FROM wallet_entries e
          LEFT JOIN accounts c ON c.id = e.counterparty_account_id
         WHERE e.account_id = @accountId
         ORDER BY e.posted_at DESC
      '''),
      parameters: {'accountId': accountId},
    );

    return [for (final record in result) _entryFrom(record.toColumnMap())];
  }

  @override
  Future<({int availablePaisa, int heldPaisa})?> totals(
    String mobileNumber,
  ) async {
    final accountId = await _accountId(mobileNumber);
    if (accountId == null) return null;

    final result = await _client.pool.execute(
      Sql.named(_totalsSql),
      parameters: {'accountId': accountId},
    );
    final row = result.first.toColumnMap();
    return (
      availablePaisa: (row['available_paisa'] as int?) ?? 0,
      heldPaisa: (row['held_paisa'] as int?) ?? 0,
    );
  }

  @override
  Future<List<CashRecipientRow>?> recipients(String mobileNumber) async {
    final accountId = await _accountId(mobileNumber);
    if (accountId == null) return null;

    // Everyone who can be paid, with the ones already paid before at the
    // top: the partner is far more likely to be paying the same wholesaler
    // again than someone they have never dealt with.
    final result = await _client.pool.execute(
      Sql.named('''
        SELECT a.mobile_number, a.display_name, a.user_type,
               MAX(t.sent_at) AS last_sent_at
          FROM accounts a
          LEFT JOIN cash_transfers t
            ON t.to_account_id = a.id AND t.from_account_id = @accountId
         WHERE a.id <> @accountId
           AND a.user_type = ANY(@roles)
           -- Nobody is offered as a recipient the app cannot name. The
           -- oldest fixtures in prototype_server/seed/seed.sql have no
           -- display name, and "pay +923000000002" is not a choice a
           -- partner could make safely.
           AND a.display_name IS NOT NULL
         GROUP BY a.id, a.mobile_number, a.display_name, a.user_type
         ORDER BY MAX(t.sent_at) DESC NULLS LAST, a.display_name
      '''),
      parameters: {
        'accountId': accountId,
        'roles': cashReceivingRoles.toList(),
      },
    );

    return [for (final record in result) _recipientFrom(record.toColumnMap())];
  }

  @override
  Future<CashRecipientRow?> lookupRecipient(String mobileNumber) async {
    final result = await _client.pool.execute(
      Sql.named('''
        SELECT mobile_number, display_name, user_type
          FROM accounts
         WHERE mobile_number = @number
           AND user_type = ANY(@roles)
           AND display_name IS NOT NULL
      '''),
      parameters: {
        'number': normaliseMobile(mobileNumber),
        'roles': cashReceivingRoles.toList(),
      },
    );
    if (result.isEmpty) return null;
    return _recipientFrom(result.first.toColumnMap());
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
    if (normaliseMobile(fromMobileNumber) == normaliseMobile(toMobileNumber)) {
      return (null, TransferRefusal.self);
    }

    final fromId = await _accountId(fromMobileNumber);
    if (fromId == null) return (null, TransferRefusal.unknownSender);

    final recipient = await lookupRecipient(toMobileNumber);
    if (recipient == null) return (null, TransferRefusal.unknownRecipient);

    TransferRefusal? refusal;
    String? entryId;

    // One transaction: the balance is checked and the money leaves inside it,
    // so two transfers sent at the same moment cannot both pass a check that
    // only one of them could afford.
    await _client.pool.runTx((session) async {
      // The sender's own row is locked first, which serialises every
      // transfer they make. `FOR UPDATE` cannot be put on the SUM itself —
      // an aggregate has no rows to lock — so the account row stands in as
      // the thing two concurrent transfers queue behind.
      await session.execute(
        Sql.named('SELECT id FROM accounts WHERE id = @accountId FOR UPDATE'),
        parameters: {'accountId': fromId},
      );

      final balance = await session.execute(
        Sql.named(_totalsSql),
        parameters: {'accountId': fromId},
      );
      final available =
          (balance.first.toColumnMap()['available_paisa'] as int?) ?? 0;
      if (available < amountPaisa) {
        refusal = TransferRefusal.notEnoughBalance;
        return;
      }

      final transfer = await session.execute(
        Sql.named('''
          INSERT INTO cash_transfers (from_account_id, to_account_id,
                                      amount_paisa, note, expires_at)
          SELECT @fromId::uuid, a.id, @amount, @note,
                 now() + interval '7 days'
            FROM accounts a WHERE a.mobile_number = @toNumber
          RETURNING id, reference
        '''),
        parameters: {
          'fromId': fromId,
          'toNumber': normaliseMobile(toMobileNumber),
          'amount': amountPaisa,
          'note': note,
        },
      );
      final transferRow = transfer.first.toColumnMap();

      // Only the sender's leg is written now. The receiver's credit is
      // written when they accept — until then there is nothing of theirs to
      // show, and a line in their ledger would be a promise the app cannot
      // keep on their behalf.
      final entry = await session.execute(
        Sql.named('''
          INSERT INTO wallet_entries (
            account_id, reference, title, direction, type, state,
            amount_paisa, counterparty_account_id, transfer_id
          )
          SELECT @fromId::uuid, @reference, 'Sent to ' || a.display_name,
                 'debit', 'send_cash', 'held', @amount, a.id, @transferId::uuid
            FROM accounts a WHERE a.mobile_number = @toNumber
          RETURNING id
        '''),
        parameters: {
          'fromId': fromId,
          'toNumber': normaliseMobile(toMobileNumber),
          'reference': transferRow['reference'],
          'amount': amountPaisa,
          'transferId': transferRow['id'],
        },
      );
      entryId = '${entry.first.toColumnMap()['id']}';
    });

    if (refusal != null) return (null, refusal);
    return (await _entryById(entryId!), null);
  }

  @override
  Future<List<CashRequestRow>?> cashRequests(String mobileNumber) async {
    final accountId = await _accountId(mobileNumber);
    if (accountId == null) return null;

    final result = await _client.pool.execute(
      Sql.named('''
        SELECT t.reference, t.amount_paisa, t.state, t.note, t.sent_at,
               t.expires_at, t.decided_at,
               a.display_name AS from_name, a.user_type AS from_role
          FROM cash_transfers t
          JOIN accounts a ON a.id = t.from_account_id
         WHERE t.to_account_id = @accountId
         ORDER BY t.sent_at DESC
      '''),
      parameters: {'accountId': accountId},
    );

    return [
      for (final record in result)
        CashRequestRow(
          reference: record.toColumnMap()['reference'] as String,
          fromName: record.toColumnMap()['from_name'] as String? ?? 'A partner',
          fromRole: _capitalise(record.toColumnMap()['from_role'] as String),
          amountPaisa: record.toColumnMap()['amount_paisa'] as int,
          state: record.toColumnMap()['state'] as String,
          note: record.toColumnMap()['note'] as String?,
          sentAt: record.toColumnMap()['sent_at'] as DateTime,
          expiresAt: record.toColumnMap()['expires_at'] as DateTime?,
          decidedAt: record.toColumnMap()['decided_at'] as DateTime?,
        ),
    ];
  }

  @override
  Future<CashRequestRefusal?> decideCashRequest({
    required String mobileNumber,
    required String reference,
    required bool approved,
  }) async {
    final accountId = await _accountId(mobileNumber);
    if (accountId == null) return CashRequestRefusal.unknownAccount;

    var decided = false;

    await _client.pool.runTx((session) async {
      // The WHERE clause is the authorisation and the guard against a second
      // decision at once: it matches only a transfer still held and sent to
      // this partner, so two taps cannot both settle it.
      final transfer = await session.execute(
        Sql.named('''
          UPDATE cash_transfers SET
            state = @state,
            decided_at = now()
           WHERE reference = @reference
             AND to_account_id = @accountId::uuid
             AND state = 'held'
          RETURNING id, from_account_id, amount_paisa
        '''),
        parameters: {
          'state': approved ? 'accepted' : 'rejected',
          'reference': reference,
          'accountId': accountId,
        },
      );
      if (transfer.isEmpty) return;
      decided = true;

      final row = transfer.first.toColumnMap();

      // The sender's held debit settles, or stops counting. A rejected debit
      // is excluded from the balance sum, which is what giving the money
      // back means here — no second row is needed to say it twice.
      await session.execute(
        Sql.named('''
          UPDATE wallet_entries SET state = @state
           WHERE transfer_id = @transferId::uuid AND direction = 'debit'
        '''),
        parameters: {
          'state': approved ? 'cleared' : 'rejected',
          'transferId': '${row['id']}',
        },
      );

      if (!approved) return;

      // Only now does the receiver get a line. Until they accepted, there
      // was nothing of theirs to show.
      await session.execute(
        Sql.named('''
          INSERT INTO wallet_entries (
            account_id, reference, title, direction, type, state,
            amount_paisa, counterparty_account_id, transfer_id
          )
          SELECT @accountId::uuid, @reference,
                 'Received from ' || a.display_name,
                 'credit', 'send_cash', 'cleared', @amount, a.id,
                 @transferId::uuid
            FROM accounts a WHERE a.id = @fromId::uuid
        '''),
        parameters: {
          'accountId': accountId,
          'reference': reference,
          'amount': row['amount_paisa'],
          'fromId': '${row['from_account_id']}',
          'transferId': '${row['id']}',
        },
      );
    });

    return decided ? null : CashRequestRefusal.notWaiting;
  }

  Future<WalletEntryRow?> _entryById(String id) async {
    final result = await _client.pool.execute(
      Sql.named('''
        SELECT e.id, e.reference, e.title, e.direction, e.type, e.state,
               e.amount_paisa, e.posted_at,
               c.display_name AS counterparty_name,
               c.user_type    AS counterparty_role,
               c.mobile_number AS counterparty_number
          FROM wallet_entries e
          LEFT JOIN accounts c ON c.id = e.counterparty_account_id
         WHERE e.id = @id::uuid
      '''),
      parameters: {'id': id},
    );
    if (result.isEmpty) return null;
    return _entryFrom(result.first.toColumnMap());
  }

  Future<String?> _accountId(String mobileNumber) async {
    final result = await _client.pool.execute(
      Sql.named('SELECT id FROM accounts WHERE mobile_number = @number'),
      parameters: {'number': normaliseMobile(mobileNumber)},
    );
    if (result.isEmpty) return null;
    return '${result.first.toColumnMap()['id']}';
  }

  WalletEntryRow _entryFrom(Map<String, dynamic> row) => WalletEntryRow(
    id: '${row['id']}',
    reference: row['reference'] as String,
    title: row['title'] as String,
    subtitle: _subtitleFor(row),
    direction: row['direction'] as String,
    type: row['type'] as String,
    state: row['state'] as String,
    amountPaisa: row['amount_paisa'] as int,
    postedAt: row['posted_at'] as DateTime,
  );

  /// The line under the title. Who the other party was when there was one;
  /// otherwise what kind of movement it was. Never invented — a row with no
  /// counterparty and an unknown type says nothing rather than guessing.
  static String _subtitleFor(Map<String, dynamic> row) {
    final name = row['counterparty_name'] as String?;
    final role = row['counterparty_role'] as String?;
    final number = row['counterparty_number'] as String?;
    if (name != null && role != null) {
      return number == null
          ? _capitalise(role)
          : '${_capitalise(role)} · +92 $number';
    }
    return switch (row['type'] as String) {
      'scan_prize' => 'QR prize',
      'spin_prize' => 'Spin prize',
      'crm_adjustment' => 'Crown Solar CRM',
      'returned' => 'Returned to your wallet',
      'cash_request' => 'Cash request',
      _ => 'Send Cash',
    };
  }

  static String _capitalise(String value) =>
      value.isEmpty ? value : value[0].toUpperCase() + value.substring(1);

  CashRecipientRow _recipientFrom(Map<String, dynamic> row) => CashRecipientRow(
    mobileNumber: row['mobile_number'] as String,
    name: row['display_name'] as String? ?? row['mobile_number'] as String,
    role: _capitalise(row['user_type'] as String),
  );
}
