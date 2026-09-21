import 'dart:math';

import 'package:postgres/postgres.dart';

import '../db/postgres_client.dart';
import 'inaam_data_store.dart';
import 'postgres_partner_data_store.dart' show normaliseMobile;

/// The [InaamDataStore] backed by PostgreSQL.
///
/// Nothing here decides what a reward is worth. The wheel's segments and
/// odds, the schemes and their tiers, and the monthly programme are all
/// configuration the Teams app owns; this reads them, counts scans, and pays
/// what was won into the cash wallet.
class PostgresInaamDataStore implements InaamDataStore {
  PostgresInaamDataStore(this._client, {Random? random})
    : _random = random ?? Random.secure();

  final PostgresClient _client;

  /// Injectable so a test can make the wheel deterministic. Secure by
  /// default: a predictable prize wheel is a prize wheel someone can game.
  final Random _random;

  // --- Spin and Win ---------------------------------------------------------

  @override
  Future<SpinStateRow?> spinState(String mobileNumber) async {
    final accountId = await _accountId(mobileNumber);
    if (accountId == null) return null;

    final config = await _activeConfig();
    if (config == null) {
      return const SpinStateRow(
        scansToday: 0,
        scansPerSpin: 0,
        spinsAvailable: 0,
        segments: [],
        history: [],
      );
    }

    final scansToday = await _scansToday(accountId);
    final spinsToday = await _spinsToday(accountId);
    final scansPerSpin = config.scansPerSpin;

    final segments = await _client.pool.execute(
      Sql.named(
        'SELECT amount_paisa, position FROM spin_prizes '
        'WHERE config_id = @id::uuid ORDER BY position',
      ),
      parameters: {'id': config.id},
    );

    final history = await _client.pool.execute(
      Sql.named('''
        SELECT reference, amount_paisa, spun_at
          FROM spins
         WHERE account_id = @accountId::uuid
         ORDER BY spun_at DESC
         LIMIT 20
      '''),
      parameters: {'accountId': accountId},
    );

    return SpinStateRow(
      scansToday: scansToday,
      scansPerSpin: scansPerSpin,
      // Earned, less taken. Never negative: moving the threshold up must not
      // put a partner into a debt of spins.
      spinsAvailable: max(0, scansToday ~/ scansPerSpin - spinsToday),
      segments: [
        for (final record in segments)
          SpinSegmentRow(
            amountPaisa: record.toColumnMap()['amount_paisa'] as int,
            position: record.toColumnMap()['position'] as int,
          ),
      ],
      history: [
        for (final record in history)
          SpinRow(
            reference: record.toColumnMap()['reference'] as String,
            amountPaisa: record.toColumnMap()['amount_paisa'] as int,
            spunAt: record.toColumnMap()['spun_at'] as DateTime,
          ),
      ],
    );
  }

  @override
  Future<(SpinRow?, SpinRefusal?)> spin(String mobileNumber) async {
    final accountId = await _accountId(mobileNumber);
    if (accountId == null) return (null, SpinRefusal.unknownAccount);

    final config = await _activeConfig();
    if (config == null) return (null, SpinRefusal.notConfigured);

    SpinRefusal? refusal;
    SpinRow? result;

    await _client.pool.runTx((session) async {
      // The account row is locked first, which serialises this partner's
      // spins. Two taps cannot both find the same entitlement free.
      await session.execute(
        Sql.named('SELECT id FROM accounts WHERE id = @id::uuid FOR UPDATE'),
        parameters: {'id': accountId},
      );

      final earned =
          (await _scansToday(accountId, session)) ~/ config.scansPerSpin;
      final taken = await _spinsToday(accountId, session);
      if (earned - taken <= 0) {
        refusal = SpinRefusal.noSpinsAvailable;
        return;
      }

      final prizes = await session.execute(
        Sql.named(
          'SELECT id, amount_paisa, weight FROM spin_prizes '
          'WHERE config_id = @id::uuid ORDER BY position',
        ),
        parameters: {'id': config.id},
      );
      if (prizes.isEmpty) {
        refusal = SpinRefusal.notConfigured;
        return;
      }

      // Weighted pick. The weights never leave this method.
      var total = 0;
      for (final record in prizes) {
        total += record.toColumnMap()['weight'] as int;
      }
      var roll = _random.nextInt(total);
      Map<String, dynamic> won = prizes.first.toColumnMap();
      for (final record in prizes) {
        final row = record.toColumnMap();
        roll -= row['weight'] as int;
        if (roll < 0) {
          won = row;
          break;
        }
      }
      final amount = won['amount_paisa'] as int;

      final reference = await session.execute(
        Sql.named(
          "SELECT 'SPN-' || to_char(now(), 'YYYY') || '-' "
          "|| lpad(nextval('wallet_reference_seq')::text, 5, '0') AS reference",
        ),
      );
      final ref = reference.first.toColumnMap()['reference'] as String;

      // The prize is Crown Solar's own money: nobody has to accept it, so it
      // clears at once.
      final entry = await session.execute(
        Sql.named('''
          INSERT INTO wallet_entries (
            account_id, reference, title, direction, type, state, amount_paisa
          )
          VALUES (@accountId::uuid, @reference, 'Spin and Win prize',
                  'credit', 'spin_prize', 'cleared', @amount)
          RETURNING id
        '''),
        parameters: {
          'accountId': accountId,
          'reference': ref,
          'amount': amount,
        },
      );

      final spun = await session.execute(
        Sql.named('''
          INSERT INTO spins (reference, account_id, config_id, prize_id,
                             amount_paisa, wallet_entry_id)
          VALUES (@reference, @accountId::uuid, @configId::uuid,
                  @prizeId::uuid, @amount, @entryId::uuid)
          RETURNING spun_at
        '''),
        parameters: {
          'reference': ref,
          'accountId': accountId,
          'configId': config.id,
          'prizeId': '${won['id']}',
          'amount': amount,
          'entryId': '${entry.first.toColumnMap()['id']}',
        },
      );

      result = SpinRow(
        reference: ref,
        amountPaisa: amount,
        spunAt: spun.first.toColumnMap()['spun_at'] as DateTime,
      );
    });

    return refusal != null ? (null, refusal) : (result, null);
  }

  // --- Item Schemes ---------------------------------------------------------

  @override
  Future<List<ItemSchemeRow>?> itemSchemes(String mobileNumber) async {
    final accountId = await _accountId(mobileNumber);
    if (accountId == null) return null;

    final schemes = await _client.pool.execute('''
      SELECT id, name, measure, starts_on, ends_on
        FROM item_schemes
       WHERE active AND ends_on >= current_date
       ORDER BY starts_on, name
    ''');

    final result = <ItemSchemeRow>[];
    for (final record in schemes) {
      final row = record.toColumnMap();
      result.add(await _scheme(row, accountId));
    }
    return result;
  }

  Future<ItemSchemeRow> _scheme(
    Map<String, dynamic> row,
    String accountId,
  ) async {
    final schemeId = '${row['id']}';
    final measure = row['measure'] as String;
    final progress = await _schemeProgress(
      schemeId: schemeId,
      accountId: accountId,
      measure: measure,
      startsOn: row['starts_on'] as DateTime,
      endsOn: row['ends_on'] as DateTime,
    );

    final tiers = await _client.pool.execute(
      Sql.named(
        'SELECT id, name, threshold, reward_paisa FROM item_scheme_tiers '
        'WHERE scheme_id = @id::uuid ORDER BY position, threshold',
      ),
      parameters: {'id': schemeId},
    );

    final claim = await _client.pool.execute(
      Sql.named('''
        SELECT t.name, c.amount_paisa, c.reference
          FROM item_scheme_claims c
          JOIN item_scheme_tiers t ON t.id = c.tier_id
         WHERE c.scheme_id = @schemeId::uuid
           AND c.account_id = @accountId::uuid
      '''),
      parameters: {'schemeId': schemeId, 'accountId': accountId},
    );
    final claimed = claim.isEmpty ? null : claim.first.toColumnMap();

    return ItemSchemeRow(
      id: schemeId,
      name: row['name'] as String,
      measure: measure,
      progress: progress,
      startsOn: row['starts_on'] as DateTime,
      endsOn: row['ends_on'] as DateTime,
      tiers: [
        for (final record in tiers)
          SchemeTierRow(
            id: '${record.toColumnMap()['id']}',
            name: record.toColumnMap()['name'] as String,
            threshold: record.toColumnMap()['threshold'] as int,
            rewardPaisa: record.toColumnMap()['reward_paisa'] as int,
            reached: progress >= (record.toColumnMap()['threshold'] as int),
          ),
      ],
      claimedTierName: claimed?['name'] as String?,
      claimedAmountPaisa: claimed?['amount_paisa'] as int?,
      claimedReference: claimed?['reference'] as String?,
    );
  }

  /// Scans this app counts for itself. Rupees it does not: that figure is
  /// posted by SAP through the Teams app, so an amount scheme with no row
  /// reads zero rather than a number nobody posted.
  Future<int> _schemeProgress({
    required String schemeId,
    required String accountId,
    required String measure,
    required DateTime startsOn,
    required DateTime endsOn,
  }) async {
    if (measure == 'amount') {
      final result = await _client.pool.execute(
        Sql.named(
          'SELECT amount_paisa FROM item_scheme_progress '
          'WHERE scheme_id = @schemeId::uuid AND account_id = @accountId::uuid',
        ),
        parameters: {'schemeId': schemeId, 'accountId': accountId},
      );
      if (result.isEmpty) return 0;
      return result.first.toColumnMap()['amount_paisa'] as int;
    }

    final result = await _client.pool.execute(
      Sql.named('''
        SELECT count(*)::int AS scans
          FROM scan_claims c
          JOIN item_scheme_products p ON p.product_id = c.product_id
         WHERE p.scheme_id = @schemeId::uuid
           AND c.account_id = @accountId::uuid
           AND c.claimed_at >= @startsOn
           AND c.claimed_at < (@endsOn::date + 1)
      '''),
      parameters: {
        'schemeId': schemeId,
        'accountId': accountId,
        'startsOn': startsOn,
        'endsOn': endsOn,
      },
    );
    return (result.first.toColumnMap()['scans'] as int?) ?? 0;
  }

  @override
  Future<(ItemSchemeRow?, ClaimRefusal?)> claimTier({
    required String mobileNumber,
    required String schemeId,
    required String tierId,
  }) async {
    final accountId = await _accountId(mobileNumber);
    if (accountId == null) return (null, ClaimRefusal.unknownAccount);

    final schemes = await _client.pool.execute(
      Sql.named('''
        SELECT id, name, measure, starts_on, ends_on
          FROM item_schemes
         WHERE id = @id::uuid AND active AND ends_on >= current_date
      '''),
      parameters: {'id': schemeId},
    );
    if (schemes.isEmpty) return (null, ClaimRefusal.unknownTier);

    final scheme = await _scheme(schemes.first.toColumnMap(), accountId);
    if (scheme.claimed) return (null, ClaimRefusal.alreadyClaimed);

    SchemeTierRow? wanted;
    for (final candidate in scheme.tiers) {
      if (candidate.id == tierId) wanted = candidate;
    }
    if (wanted == null) return (null, ClaimRefusal.unknownTier);
    if (!wanted.reached) return (null, ClaimRefusal.notReached);
    final tier = wanted;

    ClaimRefusal? refusal;

    await _client.pool
        .runTx((session) async {
          final reference = await session.execute(
            Sql.named(
              "SELECT 'ITM-' || to_char(now(), 'YYYY') || '-' "
              "|| lpad(nextval('wallet_reference_seq')::text, 4, '0') AS reference",
            ),
          );
          final ref = reference.first.toColumnMap()['reference'] as String;

          final entry = await session.execute(
            Sql.named('''
          INSERT INTO wallet_entries (
            account_id, reference, title, direction, type, state, amount_paisa
          )
          VALUES (@accountId::uuid, @reference, @title,
                  'credit', 'scheme_prize', 'cleared', @amount)
          RETURNING id
        '''),
            parameters: {
              'accountId': accountId,
              'reference': ref,
              'title': '${scheme.name} · ${tier.name}',
              'amount': tier.rewardPaisa,
            },
          );

          // The primary key is (scheme, account): a second claim has nowhere to
          // go, so the one-claim rule holds even if two taps arrive together.
          final claimed = await session.execute(
            Sql.named('''
          INSERT INTO item_scheme_claims (scheme_id, account_id, tier_id,
                                          reference, amount_paisa,
                                          wallet_entry_id)
          VALUES (@schemeId::uuid, @accountId::uuid, @tierId::uuid,
                  @reference, @amount, @entryId::uuid)
          ON CONFLICT (scheme_id, account_id) DO NOTHING
          RETURNING scheme_id
        '''),
            parameters: {
              'schemeId': schemeId,
              'accountId': accountId,
              'tierId': tierId,
              'reference': ref,
              'amount': tier.rewardPaisa,
              'entryId': '${entry.first.toColumnMap()['id']}',
            },
          );

          if (claimed.isEmpty) {
            refusal = ClaimRefusal.alreadyClaimed;
            // The credit must not stand without the claim that earned it.
            throw _Rollback();
          }
        })
        .catchError((Object error) {
          if (error is! _Rollback) throw error;
        });

    if (refusal != null) return (null, refusal);
    return (await _scheme(schemes.first.toColumnMap(), accountId), null);
  }

  // --- Reward Program -------------------------------------------------------

  @override
  Future<RewardProgramRow?> rewardProgram(String mobileNumber) async {
    final accountId = await _accountId(mobileNumber);
    if (accountId == null) return null;

    final programs = await _client.pool.execute('''
      SELECT id, label, starts_on, ends_on
        FROM reward_programs
       WHERE current_date BETWEEN starts_on AND ends_on
       ORDER BY starts_on DESC
       LIMIT 1
    ''');

    // What last month earned, and is paying out now.
    final award = await _client.pool.execute(
      Sql.named('''
        SELECT t.name, w.bonus_percent, w.applies_until
          FROM reward_program_awards w
          JOIN reward_program_tiers t ON t.id = w.tier_id
         WHERE w.account_id = @accountId::uuid
           AND current_date BETWEEN w.applies_from AND w.applies_until
         ORDER BY w.awarded_at DESC
         LIMIT 1
      '''),
      parameters: {'accountId': accountId},
    );
    final won = award.isEmpty ? null : award.first.toColumnMap();

    if (programs.isEmpty) {
      return RewardProgramRow(
        tiers: const [],
        scans: 0,
        awardTierName: won?['name'] as String?,
        awardBonusPercent: won?['bonus_percent'] as int?,
        awardAppliesUntil: won?['applies_until'] as DateTime?,
      );
    }

    final program = programs.first.toColumnMap();
    final programId = '${program['id']}';

    final tiers = await _client.pool.execute(
      Sql.named(
        'SELECT name, scan_target, bonus_percent FROM reward_program_tiers '
        'WHERE program_id = @id::uuid ORDER BY position, scan_target',
      ),
      parameters: {'id': programId},
    );

    final scans = await _client.pool.execute(
      Sql.named('''
        SELECT count(*)::int AS scans
          FROM scan_claims c
          JOIN reward_program_products p ON p.product_id = c.product_id
         WHERE p.program_id = @programId::uuid
           AND c.account_id = @accountId::uuid
           AND c.claimed_at >= @startsOn
           AND c.claimed_at < (@endsOn::date + 1)
      '''),
      parameters: {
        'programId': programId,
        'accountId': accountId,
        'startsOn': program['starts_on'],
        'endsOn': program['ends_on'],
      },
    );

    return RewardProgramRow(
      label: program['label'] as String,
      startsOn: program['starts_on'] as DateTime,
      endsOn: program['ends_on'] as DateTime,
      scans: (scans.first.toColumnMap()['scans'] as int?) ?? 0,
      tiers: [
        for (final record in tiers)
          ProgramTierRow(
            name: record.toColumnMap()['name'] as String,
            scanTarget: record.toColumnMap()['scan_target'] as int,
            bonusPercent: record.toColumnMap()['bonus_percent'] as int,
          ),
      ],
      awardTierName: won?['name'] as String?,
      awardBonusPercent: won?['bonus_percent'] as int?,
      awardAppliesUntil: won?['applies_until'] as DateTime?,
    );
  }

  // --- Helpers --------------------------------------------------------------

  Future<({String id, int scansPerSpin})?> _activeConfig() async {
    final result = await _client.pool.execute(
      'SELECT id, scans_per_spin FROM spin_configs WHERE active LIMIT 1',
    );
    if (result.isEmpty) return null;
    final row = result.first.toColumnMap();
    return (id: '${row['id']}', scansPerSpin: row['scans_per_spin'] as int);
  }

  /// Claims taken today. An authenticity check takes no claim and so earns
  /// no spin — checking stock on a shelf is not scanning a product.
  Future<int> _scansToday(String accountId, [Session? session]) async {
    final result = await (session ?? _client.pool).execute(
      Sql.named('''
        SELECT count(*)::int AS scans FROM scan_claims
         WHERE account_id = @id::uuid
           AND claimed_at >= date_trunc('day', now())
      '''),
      parameters: {'id': accountId},
    );
    return (result.first.toColumnMap()['scans'] as int?) ?? 0;
  }

  Future<int> _spinsToday(String accountId, [Session? session]) async {
    final result = await (session ?? _client.pool).execute(
      Sql.named('''
        SELECT count(*)::int AS spins FROM spins
         WHERE account_id = @id::uuid
           AND spun_at >= date_trunc('day', now())
      '''),
      parameters: {'id': accountId},
    );
    return (result.first.toColumnMap()['spins'] as int?) ?? 0;
  }

  Future<String?> _accountId(String mobileNumber) async {
    final result = await _client.pool.execute(
      Sql.named('SELECT id FROM accounts WHERE mobile_number = @number'),
      parameters: {'number': normaliseMobile(mobileNumber)},
    );
    if (result.isEmpty) return null;
    return '${result.first.toColumnMap()['id']}';
  }
}

/// Thrown to roll a transaction back deliberately.
class _Rollback implements Exception {}
