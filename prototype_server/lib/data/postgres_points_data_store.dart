import 'package:postgres/postgres.dart';

import '../db/postgres_client.dart';
import 'points_data_store.dart';
import 'postgres_partner_data_store.dart' show normaliseMobile;

/// The [PointsDataStore] backed by PostgreSQL.
///
/// Points are a separate ledger from the wallet and are never joined to it.
/// No balance and no score is stored: both are sums over `point_entries`
/// computed here.
class PostgresPointsDataStore implements PointsDataStore {
  PostgresPointsDataStore(this._client);

  final PostgresClient _client;

  /// What a target counts: points that arrived, less what SAP took back.
  /// Points sent out reduce the balance and are deliberately absent.
  static const _countingAmount = '''
    CASE e.type
      WHEN 'purchase_accrual' THEN e.amount
      WHEN 'transfer_in'      THEN e.amount
      WHEN 'reversal'         THEN -e.amount
      ELSE 0
    END
  ''';

  static const _signedAmount =
      "CASE WHEN e.direction = 'credit' THEN e.amount ELSE -e.amount END";

  @override
  Future<List<PointEntryRow>?> ledger(String mobileNumber) async {
    final accountId = await _accountId(mobileNumber);
    if (accountId == null) return null;

    // The running balance is computed in SQL, over the same rows, in one
    // pass — so the figure beside a line is arithmetic on the lines above
    // it rather than a number carried along separately.
    final result = await _client.pool.execute(
      Sql.named('''
        SELECT e.reference, e.direction, e.type, e.amount, e.posted_at,
               e.sap_document, e.note,
               SUM($_signedAmount) OVER (
                 ORDER BY e.posted_at, e.id
                 ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
               )::bigint AS balance_after,
               c.display_name AS counterparty_name,
               c.user_type    AS counterparty_role
          FROM point_entries e
          LEFT JOIN accounts c ON c.id = e.counterparty_account_id
         WHERE e.account_id = @accountId
         ORDER BY e.posted_at DESC, e.id DESC
      '''),
      parameters: {'accountId': accountId},
    );

    return [for (final record in result) _entryFrom(record.toColumnMap())];
  }

  @override
  Future<int?> balance(String mobileNumber) async {
    final accountId = await _accountId(mobileNumber);
    if (accountId == null) return null;
    return _balanceOf(accountId);
  }

  @override
  Future<({bool canSend, String? reason})?> sendingStatus(
    String mobileNumber,
  ) async {
    final accountId = await _accountId(mobileNumber);
    if (accountId == null) return null;

    final result = await _client.pool.execute(
      Sql.named(
        'SELECT can_send, reason FROM point_restrictions '
        'WHERE account_id = @accountId::uuid',
      ),
      parameters: {'accountId': accountId},
    );
    // No row means no restriction.
    if (result.isEmpty) return (canSend: true, reason: null);

    final row = result.first.toColumnMap();
    return (canSend: row['can_send'] as bool, reason: row['reason'] as String?);
  }

  @override
  Future<List<PointRecipientRow>?> recipients(String mobileNumber) async {
    final accountId = await _accountId(mobileNumber);
    if (accountId == null) return null;

    // Permitted by `point_transfer_rules` and able to receive. Installers
    // hold no points and have no rule row, so they never appear here even
    // when they are in the partner's contacts.
    final result = await _client.pool.execute(
      Sql.named('''
        SELECT a.mobile_number, a.display_name, a.user_type,
               last.sent_at, last.amount
          FROM accounts me
          JOIN point_transfer_rules r ON r.from_role = me.user_type
          JOIN accounts a
            ON a.user_type = r.to_role
           AND a.id <> me.id
           AND a.display_name IS NOT NULL
          LEFT JOIN LATERAL (
            SELECT e.posted_at AS sent_at, e.amount
              FROM point_entries e
             WHERE e.account_id = me.id
               AND e.type = 'transfer_out'
               AND e.counterparty_account_id = a.id
             ORDER BY e.posted_at DESC
             LIMIT 1
          ) AS last ON true
         WHERE me.id = @accountId
           AND NOT EXISTS (
             SELECT 1 FROM point_restrictions p
              WHERE p.account_id = a.id AND NOT p.can_receive
           )
         ORDER BY last.sent_at DESC NULLS LAST, a.display_name
      '''),
      parameters: {'accountId': accountId},
    );

    return [for (final record in result) _recipientFrom(record.toColumnMap())];
  }

  @override
  Future<PointRecipientRow?> lookupRecipient({
    required String mobileNumber,
    required String recipientNumber,
  }) async {
    final all = await recipients(mobileNumber);
    if (all == null) return null;

    final wanted = normaliseMobile(recipientNumber);
    for (final recipient in all) {
      if (recipient.mobileNumber == wanted) return recipient;
    }
    return null;
  }

  @override
  Future<PointTargetsRow?> targets(String mobileNumber) async {
    final accountId = await _accountId(mobileNumber);
    if (accountId == null) return null;

    final extras = await _extraTargets(accountId);

    final signed = await _client.pool.execute(
      Sql.named('''
        SELECT s.name, s.year, s.annual_target_points, s.annual_prize,
               s.grand_prize, a.signed_on, s.id AS scheme_id
          FROM account_schemes a
          JOIN point_schemes s ON s.id = a.scheme_id
         WHERE a.account_id = @accountId::uuid
      '''),
      parameters: {'accountId': accountId},
    );

    // No scheme signed. Points still work; there is simply nothing measured
    // against this partner, which is what the app then says.
    if (signed.isEmpty) {
      return PointTargetsRow(
        periods: const [],
        extras: extras,
        breakdown: const PointBreakdownRow(
          purchases: 0,
          transferredIn: 0,
          reversals: 0,
        ),
      );
    }

    final scheme = signed.first.toColumnMap();
    final year = scheme['year'] as int;

    final periodRows = await _client.pool.execute(
      Sql.named('''
        SELECT label, starts_on, ends_on, target_points, prize
          FROM scheme_periods
         WHERE scheme_id = @schemeId::uuid
         ORDER BY position, starts_on
      '''),
      parameters: {'schemeId': '${scheme['scheme_id']}'},
    );

    final periods = <PointTargetRow>[];
    for (final record in periodRows) {
      final row = record.toColumnMap();
      periods.add(
        await _scored(
          accountId: accountId,
          kind: 'period',
          label: row['label'] as String,
          startsOn: row['starts_on'] as DateTime,
          endsOn: row['ends_on'] as DateTime,
          targetPoints: row['target_points'] as int,
          prize: row['prize'] as String?,
        ),
      );
    }

    final annual = await _scored(
      accountId: accountId,
      kind: 'annual',
      label: 'Year total · $year',
      startsOn: DateTime.utc(year),
      endsOn: DateTime.utc(year, 12, 31),
      targetPoints: scheme['annual_target_points'] as int,
      prize: scheme['annual_prize'] as String?,
    );

    // The breakdown belongs to whatever is running now — the period the
    // partner can still do something about. With none running it covers the
    // year, so the figures are never about a window nobody is in.
    final now = DateTime.now();
    final running = periods.cast<PointTargetRow?>().firstWhere(
      (period) =>
          period != null &&
          !now.isBefore(period.startsOn) &&
          !now.isAfter(period.endsOn),
      orElse: () => null,
    );

    return PointTargetsRow(
      schemeName: '${scheme['name']} $year',
      schemeSignedOn: scheme['signed_on'] as DateTime?,
      annual: annual,
      annualPrize: scheme['annual_prize'] as String?,
      grandPrize: scheme['grand_prize'] as String?,
      periods: periods,
      extras: extras,
      breakdown: await _breakdown(
        accountId: accountId,
        startsOn: running?.startsOn ?? annual.startsOn,
        endsOn: running?.endsOn ?? annual.endsOn,
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
    if (normaliseMobile(fromMobileNumber) == normaliseMobile(toMobileNumber)) {
      return (null, PointTransferRefusal.self);
    }

    final fromId = await _accountId(fromMobileNumber);
    if (fromId == null) return (null, PointTransferRefusal.unknownSender);
    final toId = await _accountId(toMobileNumber);
    if (toId == null) return (null, PointTransferRefusal.unknownRecipient);

    // Each refusal is checked separately so the partner is told the one that
    // actually applies, and each is stated before anything moves.
    final sending = await sendingStatus(fromMobileNumber);
    if (sending != null && !sending.canSend) {
      return (null, PointTransferRefusal.senderRestricted);
    }
    if (await _receivingBlocked(toId)) {
      return (null, PointTransferRefusal.recipientRestricted);
    }
    if (!await _pairPermitted(fromId, toId)) {
      return (null, PointTransferRefusal.pairNotPermitted);
    }

    PointTransferRefusal? refusal;
    String? reference;

    await _client.pool.runTx((session) async {
      // The sender's row is locked first, which serialises their transfers:
      // two sent at once cannot both pass a balance check only one could
      // afford. Points arrive immediately and cannot be recalled, so this
      // has to hold.
      await session.execute(
        Sql.named('SELECT id FROM accounts WHERE id = @id FOR UPDATE'),
        parameters: {'id': fromId},
      );

      final balance = await session.execute(
        Sql.named('''
          SELECT COALESCE(SUM($_signedAmount), 0)::bigint AS balance
            FROM point_entries e WHERE e.account_id = @id
        '''),
        parameters: {'id': fromId},
      );
      if (((balance.first.toColumnMap()['balance'] as int?) ?? 0) < amount) {
        refusal = PointTransferRefusal.notEnoughPoints;
        return;
      }

      final issued = await session.execute(
        Sql.named('SELECT next_point_reference() AS reference'),
      );
      reference = issued.first.toColumnMap()['reference'] as String;

      // Both legs in one statement: the sender's debit and the receiver's
      // credit share a reference, so the two partners are reading the same
      // event rather than two that happen to match.
      await session.execute(
        Sql.named('''
          INSERT INTO point_entries (account_id, reference, direction, type,
                                     amount, counterparty_account_id)
          VALUES (@fromId::uuid, @reference, 'debit',  'transfer_out',
                  @amount, @toId::uuid),
                 (@toId::uuid,   @reference, 'credit', 'transfer_in',
                  @amount, @fromId::uuid)
        '''),
        parameters: {
          'fromId': fromId,
          'toId': toId,
          'reference': reference,
          'amount': amount,
        },
      );
    });

    if (refusal != null) return (null, refusal);

    final entries = await ledger(fromMobileNumber);
    return (entries?.firstWhere((entry) => entry.reference == reference), null);
  }

  // --- Helpers -------------------------------------------------------------

  /// One target with what has been scored toward it, and when it was reached.
  Future<PointTargetRow> _scored({
    required String accountId,
    required String kind,
    required String label,
    required DateTime startsOn,
    required DateTime endsOn,
    required int targetPoints,
    String? prize,
  }) async {
    // The running total is carried along so the row where it first reached
    // the target can be named — "met in August" rather than merely "met".
    final result = await _client.pool.execute(
      Sql.named('''
        WITH counted AS (
          SELECT e.posted_at,
                 SUM($_countingAmount) OVER (
                   ORDER BY e.posted_at, e.id
                   ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
                 )::bigint AS running
            FROM point_entries e
           WHERE e.account_id = @accountId::uuid
             AND e.posted_at >= @startsOn
             AND e.posted_at < (@endsOn::date + 1)
        )
        SELECT COALESCE(MAX(running), 0)::bigint AS scored,
               MIN(posted_at) FILTER (WHERE running >= @target) AS met_on
          FROM counted
      '''),
      parameters: {
        'accountId': accountId,
        'startsOn': startsOn,
        'endsOn': endsOn,
        'target': targetPoints,
      },
    );

    final row = result.first.toColumnMap();
    return PointTargetRow(
      kind: kind,
      label: label,
      targetPoints: targetPoints,
      scoredPoints: (row['scored'] as int?) ?? 0,
      startsOn: startsOn,
      endsOn: endsOn,
      prize: prize,
      metOn: row['met_on'] as DateTime?,
    );
  }

  Future<PointBreakdownRow> _breakdown({
    required String accountId,
    required DateTime startsOn,
    required DateTime endsOn,
  }) async {
    final result = await _client.pool.execute(
      Sql.named('''
        SELECT
          COALESCE(SUM(amount) FILTER (WHERE type = 'purchase_accrual'), 0)
            ::bigint AS purchases,
          COALESCE(SUM(amount) FILTER (WHERE type = 'transfer_in'), 0)
            ::bigint AS transferred_in,
          COALESCE(SUM(amount) FILTER (WHERE type = 'reversal'), 0)
            ::bigint AS reversals
          FROM point_entries
         WHERE account_id = @accountId::uuid
           AND posted_at >= @startsOn
           AND posted_at < (@endsOn::date + 1)
      '''),
      parameters: {
        'accountId': accountId,
        'startsOn': startsOn,
        'endsOn': endsOn,
      },
    );

    final row = result.first.toColumnMap();
    return PointBreakdownRow(
      purchases: (row['purchases'] as int?) ?? 0,
      transferredIn: (row['transferred_in'] as int?) ?? 0,
      reversals: (row['reversals'] as int?) ?? 0,
    );
  }

  Future<List<PointTargetRow>> _extraTargets(String accountId) async {
    final result = await _client.pool.execute(
      Sql.named('''
        SELECT label, starts_on, ends_on, target_points, prize
          FROM account_extra_targets
         WHERE account_id = @accountId::uuid
         ORDER BY starts_on, label
      '''),
      parameters: {'accountId': accountId},
    );

    final extras = <PointTargetRow>[];
    for (final record in result) {
      final row = record.toColumnMap();
      extras.add(
        await _scored(
          accountId: accountId,
          kind: 'extra',
          label: row['label'] as String,
          startsOn: row['starts_on'] as DateTime,
          endsOn: row['ends_on'] as DateTime,
          targetPoints: row['target_points'] as int,
          prize: row['prize'] as String?,
        ),
      );
    }
    return extras;
  }

  Future<bool> _pairPermitted(String fromId, String toId) async {
    final result = await _client.pool.execute(
      Sql.named('''
        SELECT 1
          FROM accounts sender, accounts receiver, point_transfer_rules r
         WHERE sender.id = @fromId::uuid
           AND receiver.id = @toId::uuid
           AND r.from_role = sender.user_type
           AND r.to_role = receiver.user_type
      '''),
      parameters: {'fromId': fromId, 'toId': toId},
    );
    return result.isNotEmpty;
  }

  Future<bool> _receivingBlocked(String accountId) async {
    final result = await _client.pool.execute(
      Sql.named(
        'SELECT 1 FROM point_restrictions '
        'WHERE account_id = @id::uuid AND NOT can_receive',
      ),
      parameters: {'id': accountId},
    );
    return result.isNotEmpty;
  }

  Future<int> _balanceOf(String accountId) async {
    final result = await _client.pool.execute(
      Sql.named('''
        SELECT COALESCE(SUM($_signedAmount), 0)::bigint AS balance
          FROM point_entries e WHERE e.account_id = @id
      '''),
      parameters: {'id': accountId},
    );
    return (result.first.toColumnMap()['balance'] as int?) ?? 0;
  }

  Future<String?> _accountId(String mobileNumber) async {
    final result = await _client.pool.execute(
      Sql.named('SELECT id FROM accounts WHERE mobile_number = @number'),
      parameters: {'number': normaliseMobile(mobileNumber)},
    );
    if (result.isEmpty) return null;
    return '${result.first.toColumnMap()['id']}';
  }

  PointEntryRow _entryFrom(Map<String, dynamic> row) => PointEntryRow(
    reference: row['reference'] as String,
    direction: row['direction'] as String,
    type: row['type'] as String,
    amount: row['amount'] as int,
    balanceAfter: row['balance_after'] as int,
    postedAt: row['posted_at'] as DateTime,
    counterpartyName: row['counterparty_name'] as String?,
    counterpartyRole: _capitalise(row['counterparty_role'] as String?),
    sapDocument: row['sap_document'] as String?,
    note: row['note'] as String?,
  );

  PointRecipientRow _recipientFrom(Map<String, dynamic> row) =>
      PointRecipientRow(
        mobileNumber: row['mobile_number'] as String,
        name: row['display_name'] as String,
        role: _capitalise(row['user_type'] as String)!,
        lastSentAt: row['sent_at'] as DateTime?,
        lastSentAmount: row['amount'] as int?,
      );

  static String? _capitalise(String? value) => value == null || value.isEmpty
      ? value
      : value[0].toUpperCase() + value.substring(1);
}
