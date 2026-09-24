import 'package:postgres/postgres.dart';

import '../db/postgres_client.dart';
import 'branding_data_store.dart';
import 'postgres_partner_data_store.dart' show normaliseMobile;
import 'staff_models.dart';

/// The [BrandingDataStore] backed by PostgreSQL.
///
/// Which board types exist, what each costs, how the bill splits and what
/// each role must satisfy are all configuration the Teams app owns. What
/// this does is measure a partner against that configuration — their role,
/// their points, their signed scheme, how recently they scanned and what is
/// already on their shopfront — and record what they asked for.
///
/// Points and scheme signing are read from the points tables, and recent
/// scanning from the scan claims. Branding keeps no counters of its own, so
/// it can never disagree with the modules that own those numbers.
class PostgresBrandingDataStore implements BrandingDataStore {
  PostgresBrandingDataStore(this._client);

  final PostgresClient _client;

  // --- Landing --------------------------------------------------------------

  @override
  Future<BrandingLandingRow?> landing(String mobileNumber) async {
    final accountId = await _accountId(mobileNumber);
    if (accountId == null) return null;

    final eligibility = await _eligibility(accountId);
    final requests = await _requestsFor(accountId);

    return BrandingLandingRow(
      eligibility: eligibility,
      // At most one request is live at a time, so the newest unfinished one
      // is the one the landing card points at.
      current: requests
          .where((request) => request.status == 'in_progress')
          .firstOrNull,
      requests: requests,
    );
  }

  @override
  Future<BrandingRequestRow?> request({
    required String mobileNumber,
    required String reference,
  }) async {
    final accountId = await _accountId(mobileNumber);
    if (accountId == null) return null;

    final rows = await _client.pool.execute(
      Sql.named('''
        SELECT id, reference, status, stage, height_ft, width_ft,
               board_count, shop_address, contact_number, person_name,
               rejection_reason, created_at,
               raised_by_staff_name, raised_by_staff_role
          FROM branding_requests
         WHERE account_id = @accountId::uuid AND reference = @reference
      '''),
      parameters: {'accountId': accountId, 'reference': reference},
    );
    if (rows.isEmpty) return null;
    return _requestFrom(rows.first.toColumnMap());
  }

  // --- Board types ----------------------------------------------------------

  @override
  Future<BrandingOptionsRow?> options(String mobileNumber) async {
    final accountId = await _accountId(mobileNumber);
    if (accountId == null) return null;

    final eligibility = await _eligibility(accountId);
    final (types, notice) = await _optionsFor(accountId, eligibility);

    return BrandingOptionsRow(
      eligibility: eligibility,
      boardTypes: types,
      replacementOnly: notice != null,
      replacementNotice: notice,
    );
  }

  /// The options this partner may pick from, and the replacement notice when
  /// one applies.
  ///
  /// Replacement detection is evaluated first and overrides everything: a
  /// board young enough leaves exactly one option, whatever the partner's
  /// points and scheme would otherwise allow.
  Future<(List<BrandingBoardTypeRow>, String?)> _optionsFor(
    String accountId,
    BrandingEligibilityRow eligibility,
  ) async {
    final rows = await _client.pool.execute(
      Sql.named('''
        SELECT t.code, t.name, t.description, t.unit_price_paisa,
               t.company_percent, t.replaces_code,
               r.min_points, r.requires_scheme, r.requires_recent_scan
          FROM branding_board_types t
          JOIN branding_board_type_roles r ON r.board_type_id = t.id
         WHERE r.role = @role
         ORDER BY t.position
      '''),
      parameters: {'role': eligibility.role},
    );

    final replacing = await _replacementCode(accountId);

    // A board too new to replace collapses the list to its own skin or flex
    // change. Everything else is not merely locked but absent: there is no
    // action that would bring it back inside the window.
    if (replacing != null) {
      final options = [
        for (final record in rows)
          if (record.toColumnMap()['replaces_code'] == replacing)
            _boardTypeFrom(
              record.toColumnMap(),
              eligibility,
              availableOverride: true,
              conditionOverride: 'Replaces your existing board',
            ),
      ];
      return (
        options,
        'Installed less than ${eligibility.replacementMonths} months ago. '
            'While it is this new, the only option is a change of face on '
            'the existing board.',
      );
    }

    // No recent board, so the replacement options have nothing to replace
    // and the ordinary ladder applies.
    return (
      [
        for (final record in rows)
          if (record.toColumnMap()['replaces_code'] == null)
            _boardTypeFrom(record.toColumnMap(), eligibility),
      ],
      null,
    );
  }

  BrandingBoardTypeRow _boardTypeFrom(
    Map<String, dynamic> row,
    BrandingEligibilityRow eligibility, {
    bool availableOverride = false,
    String? conditionOverride,
  }) {
    final minPoints = row['min_points'] as int;
    final needsScheme = row['requires_scheme'] as bool;
    final needsScan = row['requires_recent_scan'] as bool;

    final scanned =
        eligibility.daysSinceLastScan != null &&
        eligibility.daysSinceLastScan! <= eligibility.scanWindowDays;

    final available =
        availableOverride ||
        (eligibility.points >= minPoints &&
            (!needsScheme || eligibility.schemeSigned) &&
            (!needsScan || scanned));

    return BrandingBoardTypeRow(
      code: row['code'] as String,
      name: row['name'] as String,
      description: row['description'] as String,
      unitPricePaisa: row['unit_price_paisa'] as int,
      companyPercent: row['company_percent'] as int,
      available: available,
      condition:
          conditionOverride ??
          _conditionText(
            minPoints: minPoints,
            needsScheme: needsScheme,
            needsScan: needsScan,
            eligibility: eligibility,
          ),
      lockedReason: available
          ? null
          : _lockedReason(
              minPoints: minPoints,
              needsScheme: needsScheme,
              needsScan: needsScan,
              eligibility: eligibility,
              scanned: scanned,
            ),
    );
  }

  /// What opened this option, as the partner would say it.
  static String _conditionText({
    required int minPoints,
    required bool needsScheme,
    required bool needsScan,
    required BrandingEligibilityRow eligibility,
  }) {
    if (needsScan) {
      final days = eligibility.daysSinceLastScan;
      if (days == null) {
        return 'Needs a scan in the last ${eligibility.scanWindowDays} days';
      }
      return days == 0
          ? 'Available because you scanned today'
          : 'Available because you scanned a product $days '
                '${days == 1 ? 'day' : 'days'} ago';
    }
    if (minPoints > 0 && needsScheme) {
      return '${_points(minPoints)} points and a signed scheme';
    }
    if (minPoints > 0) return '${_points(minPoints)} points';
    if (needsScheme) return 'Scheme signed';
    return 'Open to you';
  }

  /// The one thing standing in the way, named so the partner can act on it.
  ///
  /// Only the first unmet condition is given. A list of everything wrong at
  /// once reads as a wall rather than a next step, and the thresholds behind
  /// it are not something the partner can argue with.
  static String? _lockedReason({
    required int minPoints,
    required bool needsScheme,
    required bool needsScan,
    required BrandingEligibilityRow eligibility,
    required bool scanned,
  }) {
    if (needsScan && !scanned) {
      return 'Scan a Crown Solar product to open this';
    }
    if (needsScheme && !eligibility.schemeSigned) {
      return 'Needs a signed scheme';
    }
    if (eligibility.points < minPoints) {
      return 'Needs ${_points(minPoints)} points';
    }
    return null;
  }

  /// "15,000" — grouped as the screens write every other figure.
  static String _points(int value) {
    final digits = value.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i != 0 && (digits.length - i) % 3 == 0) buffer.write(',');
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }

  // --- Creating a request ---------------------------------------------------

  @override
  Future<(BrandingRequestRow?, BrandingRefusal?)> createRequest({
    required String mobileNumber,
    required String shopPhotoPath,
    required String cardPhotoPath,
    required double heightFt,
    required double widthFt,
    required int boardCount,
    required List<String> boardTypeCodes,
    String? shopAddress,
    String? contactNumber,
    String? personName,
  }) async {
    final accountId = await _accountId(mobileNumber);
    if (accountId == null) return (null, BrandingRefusal.unknownAccount);

    if (boardTypeCodes.length != boardCount) {
      return (null, BrandingRefusal.boardCountMismatch);
    }

    // Re-checked here rather than trusted from the client: a scan window can
    // close, and a board can be installed, between the step that offered an
    // option and the submit that uses it.
    final eligibility = await _eligibility(accountId);
    final (available, _) = await _optionsFor(accountId, eligibility);
    final open = {
      for (final type in available)
        if (type.available) type.code: type,
    };
    for (final code in boardTypeCodes) {
      if (!open.containsKey(code)) {
        return (null, BrandingRefusal.optionNotAvailable);
      }
    }

    String? reference;
    var refused = false;

    await _client.pool.runTx((session) async {
      // One live request at a time. Checked inside the transaction so two
      // taps cannot both find the slot empty.
      final live = await session.execute(
        Sql.named('''
          SELECT 1 FROM branding_requests
           WHERE account_id = @accountId::uuid AND status = 'in_progress'
           FOR UPDATE
        '''),
        parameters: {'accountId': accountId},
      );
      if (live.isNotEmpty) {
        refused = true;
        return;
      }

      final created = await session.execute(
        Sql.named('''
          INSERT INTO branding_requests
            (reference, account_id, shop_photo_path, card_photo_path,
             height_ft, width_ft, board_count, shop_address,
             contact_number, person_name)
          VALUES
            (@reference, @accountId::uuid, @shopPhoto, @cardPhoto,
             @height, @width, @count, @address, @contact, @person)
          RETURNING id, reference
        '''),
        parameters: {
          'reference': _newReference(),
          'accountId': accountId,
          'shopPhoto': shopPhotoPath,
          'cardPhoto': cardPhotoPath,
          'height': heightFt,
          'width': widthFt,
          'count': boardCount,
          'address': shopAddress,
          'contact': contactNumber,
          'person': personName,
        },
      );

      final requestId = '${created.first.toColumnMap()['id']}';
      reference = created.first.toColumnMap()['reference'] as String;

      for (var i = 0; i < boardTypeCodes.length; i++) {
        final type = open[boardTypeCodes[i]]!;
        await session.execute(
          Sql.named('''
            INSERT INTO branding_request_boards
              (request_id, position, board_type_id,
               unit_price_paisa, company_percent)
            SELECT @requestId::uuid, @position, id, @price, @percent
              FROM branding_board_types WHERE code = @code
          '''),
          parameters: {
            'requestId': requestId,
            'position': i + 1,
            'code': type.code,
            // Copied from what was quoted, so a price changed after this
            // submit does not rewrite what was agreed.
            'price': type.unitPricePaisa,
            'percent': type.companyPercent,
          },
        );
      }
    });

    if (refused) return (null, BrandingRefusal.requestAlreadyOpen);
    return (
      await request(mobileNumber: mobileNumber, reference: reference!),
      null,
    );
  }

  /// BRD-2026-3391 — the year, then a run of digits wide enough that two
  /// requests filed in the same second do not collide.
  static String _newReference() {
    final now = DateTime.now();
    final tail = now.microsecondsSinceEpoch.remainder(10000);
    return 'BRD-${now.year}-${tail.toString().padLeft(4, '0')}';
  }

  // --- Reading ---------------------------------------------------------------

  Future<BrandingEligibilityRow> _eligibility(String accountId) async {
    final config = await _client.pool.execute(
      'SELECT scan_window_days, replacement_months FROM branding_config',
    );
    final scanWindow = config.isEmpty
        ? 10
        : config.first.toColumnMap()['scan_window_days'] as int;
    final replacementMonths = config.isEmpty
        ? 6
        : config.first.toColumnMap()['replacement_months'] as int;

    final role = await _client.pool.execute(
      Sql.named('SELECT user_type FROM accounts WHERE id = @id::uuid'),
      parameters: {'id': accountId},
    );

    final points = await _client.pool.execute(
      Sql.named('''
        SELECT COALESCE(SUM(
          CASE WHEN direction = 'credit' THEN amount ELSE -amount END
        ), 0)::bigint AS balance
          FROM point_entries WHERE account_id = @id::uuid
      '''),
      parameters: {'id': accountId},
    );

    final scheme = await _client.pool.execute(
      Sql.named('SELECT 1 FROM account_schemes WHERE account_id = @id::uuid'),
      parameters: {'id': accountId},
    );

    // An authenticity check takes no claim, so it is not scanning for this
    // purpose either — the same rule Inaam applies to spin entitlement.
    final scan = await _client.pool.execute(
      Sql.named('''
        SELECT (current_date - MAX(claimed_at)::date) AS days
          FROM scan_claims WHERE account_id = @id::uuid
      '''),
      parameters: {'id': accountId},
    );

    final installed = await _client.pool.execute(
      Sql.named('''
        SELECT t.name, i.installed_on,
               (EXTRACT(YEAR FROM age(current_date, i.installed_on)) * 12
                 + EXTRACT(MONTH FROM age(current_date, i.installed_on)))::int
                 AS months
          FROM branding_installations i
          JOIN branding_board_types t ON t.id = i.board_type_id
         WHERE i.account_id = @id::uuid
         ORDER BY i.installed_on DESC
         LIMIT 1
      '''),
      parameters: {'id': accountId},
    );

    final board = installed.isEmpty ? null : installed.first.toColumnMap();

    return BrandingEligibilityRow(
      role: role.isEmpty
          ? 'installer'
          : role.first.toColumnMap()['user_type'] as String,
      schemeSigned: scheme.isNotEmpty,
      points: points.isEmpty
          ? 0
          : (points.first.toColumnMap()['balance'] as int?) ?? 0,
      scanWindowDays: scanWindow,
      replacementMonths: replacementMonths,
      daysSinceLastScan: scan.isEmpty
          ? null
          : (scan.first.toColumnMap()['days'] as int?),
      existingBoardName: board?['name'] as String?,
      existingBoardInstalledOn: board?['installed_on'] as DateTime?,
      existingBoardMonths: board?['months'] as int?,
    );
  }

  /// The board type a recent installation forces a replacement of, or null
  /// when the shopfront is bare or the board is old enough to be redone.
  Future<String?> _replacementCode(String accountId) async {
    final result = await _client.pool.execute(
      Sql.named('''
        SELECT t.code
          FROM branding_installations i
          JOIN branding_board_types t ON t.id = i.board_type_id
          CROSS JOIN branding_config c
         WHERE i.account_id = @id::uuid
           AND i.installed_on
                 > (current_date - (c.replacement_months || ' months')::interval)
         ORDER BY i.installed_on DESC
         LIMIT 1
      '''),
      parameters: {'id': accountId},
    );
    if (result.isEmpty) return null;
    return result.first.toColumnMap()['code'] as String;
  }

  Future<List<BrandingRequestRow>> _requestsFor(String accountId) async {
    final rows = await _client.pool.execute(
      Sql.named('''
        SELECT id, reference, status, stage, height_ft, width_ft,
               board_count, shop_address, contact_number, person_name,
               rejection_reason, created_at,
               raised_by_staff_name, raised_by_staff_role
          FROM branding_requests
         WHERE account_id = @accountId::uuid
         ORDER BY created_at DESC
      '''),
      parameters: {'accountId': accountId},
    );
    return [
      for (final record in rows) await _requestFrom(record.toColumnMap()),
    ];
  }

  Future<BrandingRequestRow> _requestFrom(Map<String, dynamic> row) async {
    final boards = await _client.pool.execute(
      Sql.named('''
        SELECT b.position, t.code, t.name,
               b.unit_price_paisa, b.company_percent
          FROM branding_request_boards b
          JOIN branding_board_types t ON t.id = b.board_type_id
         WHERE b.request_id = @requestId::uuid
         ORDER BY b.position
      '''),
      parameters: {'requestId': '${row['id']}'},
    );

    return BrandingRequestRow(
      reference: row['reference'] as String,
      status: row['status'] as String,
      stage: row['stage'] as int,
      heightFt: _feet(row['height_ft']),
      widthFt: _feet(row['width_ft']),
      boardCount: row['board_count'] as int,
      createdAt: row['created_at'] as DateTime,
      shopAddress: row['shop_address'] as String?,
      contactNumber: row['contact_number'] as String?,
      personName: row['person_name'] as String?,
      rejectionReason: row['rejection_reason'] as String?,
      raisedBy: RaisedByRow.fromColumns(row),
      boards: [
        for (final record in boards)
          BrandingRequestBoardRow(
            position: record.toColumnMap()['position'] as int,
            code: record.toColumnMap()['code'] as String,
            name: record.toColumnMap()['name'] as String,
            unitPricePaisa: record.toColumnMap()['unit_price_paisa'] as int,
            companyPercent: record.toColumnMap()['company_percent'] as int,
          ),
      ],
    );
  }

  /// A measurement off a `numeric` column, which the driver hands back as
  /// text rather than a number so no precision is lost on the way.
  static double _feet(Object? value) => switch (value) {
    num(:final toDouble) => toDouble(),
    final String text => double.tryParse(text) ?? 0,
    _ => 0,
  };

  Future<String?> _accountId(String mobileNumber) async {
    final result = await _client.pool.execute(
      Sql.named('SELECT id FROM accounts WHERE mobile_number = @number'),
      parameters: {'number': normaliseMobile(mobileNumber)},
    );
    if (result.isEmpty) return null;
    return '${result.first.toColumnMap()['id']}';
  }
}
