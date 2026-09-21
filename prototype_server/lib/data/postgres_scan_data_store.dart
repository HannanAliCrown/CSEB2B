import 'package:postgres/postgres.dart';

import '../db/postgres_client.dart';
import 'postgres_partner_data_store.dart' show normaliseMobile;
import 'scan_data_store.dart';

/// The [ScanDataStore] backed by PostgreSQL.
///
/// The rule that one code is worth one claim to an installer and one to a
/// retailer is `scan_claims`' unique key, not a check in Dart. Two phones
/// scanning the same box at the same moment cannot both win: one insert
/// wins and the other is turned away by the database.
class PostgresScanDataStore implements ScanDataStore {
  PostgresScanDataStore(this._client);

  final PostgresClient _client;

  @override
  Future<ScanIntroRow?> intro(String mobileNumber) async {
    final account = await _client.pool.execute(
      Sql.named('SELECT user_type FROM accounts WHERE mobile_number = @number'),
      parameters: {'number': normaliseMobile(mobileNumber)},
    );
    if (account.isEmpty) return null;
    final role = account.first.toColumnMap()['user_type'] as String;

    final result = await _client.pool.execute(
      Sql.named('''
        SELECT p.code, p.state, p.wins_prize,
               (SELECT amount_paisa FROM scan_prize_rules WHERE role = @role)
                 AS prize_paisa,
               EXISTS (
                 SELECT 1 FROM scan_claims c
                  WHERE c.product_id = p.id AND c.role = @role
               ) AS taken
          FROM products p
         ORDER BY p.created_at, p.code
      '''),
      parameters: {'role': role},
    );

    int? prize;
    final samples = <ScanSampleRow>[];
    for (final record in result) {
      final row = record.toColumnMap();
      prize ??= row['prize_paisa'] as int?;
      samples.add(
        ScanSampleRow(
          code: row['code'] as String,
          meaning: _meaningFor(row, canWin: row['prize_paisa'] != null),
        ),
      );
    }
    return ScanIntroRow(prizePaisa: prize, samples: samples);
  }

  /// What this code will do for this partner, from its own row rather than
  /// from a list written beside it.
  static String _meaningFor(Map<String, dynamic> row, {required bool canWin}) {
    if (row['state'] == 'blocked') return 'Blocked batch';
    if (!canWin) return 'Genuine product';
    if (row['taken'] == true) return 'Already scanned';
    return row['wins_prize'] == true
        ? 'Genuine · wins a prize'
        : 'Genuine · no prize this time';
  }

  @override
  Future<ScanOutcomeRow?> check({
    required String code,
    required String mobileNumber,
    required bool claim,
  }) async {
    final normalised = code.trim().toUpperCase();

    final account = await _client.pool.execute(
      Sql.named(
        'SELECT id, user_type, display_name FROM accounts '
        'WHERE mobile_number = @number',
      ),
      parameters: {'number': normaliseMobile(mobileNumber)},
    );
    if (account.isEmpty) return null;
    final accountId = '${account.first.toColumnMap()['id']}';
    final role = account.first.toColumnMap()['user_type'] as String;

    final found = await _client.pool.execute(
      Sql.named('''
        SELECT p.id, p.name, p.batch, p.plant, p.state, p.wins_prize,
               -- Formatted here rather than in Dart: a `date` column has no
               -- time and no zone, and turning it into a DateTime would give
               -- it both.
               to_char(p.made_on, 'DD/MM/YYYY') AS made_on_text,
               (SELECT amount_paisa FROM scan_prize_rules WHERE role = @role)
                 AS prize_paisa
          FROM products p
         WHERE p.code = @code
      '''),
      parameters: {'code': normalised, 'role': role},
    );

    // Not a Crown Solar code at all.
    if (found.isEmpty) {
      return ScanOutcomeRow(code: normalised, verdict: 'not_recognised');
    }

    final row = found.first.toColumnMap();
    final product = _productFrom(row);

    // Withdrawn. Still genuine, which is why it is its own answer.
    if (row['state'] == 'blocked') {
      return ScanOutcomeRow(
        code: normalised,
        verdict: 'blocked',
        product: product,
      );
    }

    if (!claim) {
      return ScanOutcomeRow(
        code: normalised,
        verdict: 'genuine',
        product: product,
      );
    }

    // Only this role's claim can stand in the way: what an installer took
    // says nothing about what a retailer may take.
    final existing = await _existingClaim('${row['id']}', role);
    if (existing != null) {
      return ScanOutcomeRow(
        code: normalised,
        verdict: 'already_scanned',
        product: product,
        claim: existing,
      );
    }

    // No prize band for this role means it cannot win — how wholesalers and
    // distributors are kept to authenticity checks. They take no claim
    // either, so they can never use up a code an installer is owed.
    final prize = row['prize_paisa'] as int?;
    if (prize == null) {
      return ScanOutcomeRow(
        code: normalised,
        verdict: 'genuine',
        product: product,
      );
    }

    // A Reward Program award earned last month adds its percentage to every
    // scan of that programme's products this month. The bonus is read from
    // the award rather than recomputed, so a tier re-rated since does not
    // change what somebody already earned.
    final base = row['wins_prize'] == true ? prize : null;
    final paid = base == null
        ? null
        : base +
              (base * await _rewardBonusPercent(accountId, '${row['id']}')) ~/
                  100;
    final taken = await _takeClaim(
      productId: '${row['id']}',
      accountId: accountId,
      role: role,
      productName: product.name,
      code: normalised,
      prizePaisa: paid,
    );

    // Lost the race: someone in this role claimed it between the check above
    // and the insert. They hold it, not this partner.
    if (!taken) {
      return ScanOutcomeRow(
        code: normalised,
        verdict: 'already_scanned',
        product: product,
        claim: await _existingClaim('${row['id']}', role),
      );
    }

    return ScanOutcomeRow(
      code: normalised,
      verdict: 'genuine',
      product: product,
      prizePaisa: paid,
    );
  }

  /// The extra percentage this partner earned on this product, or zero.
  ///
  /// Zero when there is no award, no live window, or the product is not in
  /// the programme — three different reasons for the same answer, none of
  /// which is worth telling the scanner apart.
  Future<int> _rewardBonusPercent(String accountId, String productId) async {
    final result = await _client.pool.execute(
      Sql.named('''
        SELECT w.bonus_percent
          FROM reward_program_awards w
          JOIN reward_program_products p
            ON p.program_id = w.program_id
           AND p.product_id = @productId::uuid
         WHERE w.account_id = @accountId::uuid
           AND current_date BETWEEN w.applies_from AND w.applies_until
         ORDER BY w.bonus_percent DESC
         LIMIT 1
      '''),
      parameters: {'accountId': accountId, 'productId': productId},
    );
    if (result.isEmpty) return 0;
    return result.first.toColumnMap()['bonus_percent'] as int;
  }

  Future<ScanClaimRow?> _existingClaim(String productId, String role) async {
    final result = await _client.pool.execute(
      Sql.named('''
        SELECT COALESCE(a.display_name, a.mobile_number) AS name,
               c.role, c.claimed_at
          FROM scan_claims c
          JOIN accounts a ON a.id = c.account_id
         WHERE c.product_id = @productId::uuid AND c.role = @role
      '''),
      parameters: {'productId': productId, 'role': role},
    );
    if (result.isEmpty) return null;

    final row = result.first.toColumnMap();
    return ScanClaimRow(
      name: row['name'] as String,
      role: _capitalise(row['role'] as String),
      claimedAt: row['claimed_at'] as DateTime,
    );
  }

  /// Takes the claim and, when the code pays, credits the wallet — both in
  /// one transaction, so a prize can never be paid without the claim that
  /// earned it, or a claim taken without the money arriving.
  ///
  /// False when the claim was already gone.
  Future<bool> _takeClaim({
    required String productId,
    required String accountId,
    required String role,
    required String productName,
    required String code,
    required int? prizePaisa,
  }) async {
    var taken = false;

    await _client.pool.runTx((session) async {
      final claim = await session.execute(
        Sql.named('''
          INSERT INTO scan_claims (product_id, account_id, role, prize_paisa)
          VALUES (@productId::uuid, @accountId::uuid, @role, @prize)
          ON CONFLICT (product_id, role) DO NOTHING
          RETURNING id
        '''),
        parameters: {
          'productId': productId,
          'accountId': accountId,
          'role': role,
          'prize': prizePaisa,
        },
      );
      if (claim.isEmpty) return;
      taken = true;

      // The entry is spent whether or not this code was a winning one.
      if (prizePaisa == null) return;

      final entry = await session.execute(
        Sql.named('''
          INSERT INTO wallet_entries (
            account_id, reference, title, direction, type, state, amount_paisa
          )
          VALUES (@accountId::uuid, next_wallet_reference(),
                  'Scan prize · ' || @productName,
                  'credit', 'scan_prize',
                  -- A prize is Crown Solar's own money: nobody has to accept
                  -- it, so it clears at once.
                  'cleared', @amount)
          RETURNING id
        '''),
        parameters: {
          'accountId': accountId,
          'productName': productName,
          'amount': prizePaisa,
        },
      );

      await session.execute(
        Sql.named(
          'UPDATE scan_claims SET wallet_entry_id = @entryId::uuid '
          'WHERE id = @claimId::uuid',
        ),
        parameters: {
          'entryId': '${entry.first.toColumnMap()['id']}',
          'claimId': '${claim.first.toColumnMap()['id']}',
        },
      );
    });

    return taken;
  }

  ScannedProductRow _productFrom(Map<String, dynamic> row) {
    final plant = row['plant'] as String?;
    final madeOn = row['made_on_text'] as String?;
    return ScannedProductRow(
      name: row['name'] as String,
      batch: row['batch'] as String? ?? '',
      madeOn: [?plant, if (madeOn != null) 'made $madeOn'].join(' · '),
    );
  }

  static String _capitalise(String value) =>
      value.isEmpty ? value : value[0].toUpperCase() + value.substring(1);
}
