import 'package:postgres/postgres.dart';

import '../db/postgres_client.dart';
import '../otp/otp_generator.dart';
import 'partner_data_store.dart';
import 'partner_models.dart';

/// The ten national digits of a Pakistani mobile, however it was typed.
///
/// A mobile is eleven digits written locally (0300 1122334) and the +92 code
/// stands in for that leading zero, so 0300…, 300… and +92 300… are one
/// subscriber. Every number reaches the database in this form.
String normaliseMobile(String raw) {
  var digits = raw.replaceAll(RegExp(r'\D'), '');
  if (digits.startsWith('0092')) digits = digits.substring(4);
  if (digits.startsWith('92')) digits = digits.substring(2);
  if (digits.startsWith('0')) digits = digits.substring(1);
  return digits;
}

/// The [PartnerDataStore] backed by PostgreSQL. Along with
/// `postgres_auth_data_store.dart` and `postgres_client.dart`, this is one of
/// the few places the `postgres` package is used — never a route handler,
/// and never the Flutter app.
class PostgresPartnerDataStore implements PartnerDataStore {
  PostgresPartnerDataStore(this._client);

  final PostgresClient _client;

  // --- First launch ---

  @override
  Future<void> recordDeviceLaunch(DeviceLaunchInput input) async {
    // COALESCE so a later call that only answers the location prompt does not
    // wipe the language chosen a moment earlier.
    await _client.pool.execute(
      Sql.named('''
        INSERT INTO devices (
          installation_uuid, platform, app_version,
          language_code, language_remembered,
          notification_permission, location_permission,
          launch_latitude, launch_longitude, launch_located_at,
          first_launch_completed_at
        ) VALUES (
          @uuid, @platform, @appVersion,
          @languageCode, @languageRemembered,
          @notificationPermission, @locationPermission,
          @latitude, @longitude,
          CASE WHEN @latitude IS NULL THEN NULL ELSE now() END,
          CASE WHEN @firstLaunchComplete THEN now() ELSE NULL END
        )
        ON CONFLICT (installation_uuid) DO UPDATE SET
          platform                  = COALESCE(EXCLUDED.platform, devices.platform),
          app_version               = COALESCE(EXCLUDED.app_version, devices.app_version),
          language_code             = COALESCE(EXCLUDED.language_code, devices.language_code),
          language_remembered       = COALESCE(EXCLUDED.language_remembered, devices.language_remembered),
          notification_permission   = COALESCE(EXCLUDED.notification_permission, devices.notification_permission),
          location_permission       = COALESCE(EXCLUDED.location_permission, devices.location_permission),
          launch_latitude           = COALESCE(EXCLUDED.launch_latitude, devices.launch_latitude),
          launch_longitude          = COALESCE(EXCLUDED.launch_longitude, devices.launch_longitude),
          launch_located_at         = COALESCE(EXCLUDED.launch_located_at, devices.launch_located_at),
          first_launch_completed_at = COALESCE(devices.first_launch_completed_at, EXCLUDED.first_launch_completed_at),
          updated_at                = now()
      '''),
      parameters: {
        'uuid': input.installationUuid,
        'platform': input.platform,
        'appVersion': input.appVersion,
        'languageCode': input.languageCode,
        'languageRemembered': input.languageRemembered,
        'notificationPermission': input.notificationPermission,
        'locationPermission': input.locationPermission,
        'latitude': input.latitude,
        'longitude': input.longitude,
        'firstLaunchComplete': input.firstLaunchComplete,
      },
    );
  }

  // --- Reference data ---

  @override
  Future<List<Market>> markets() async {
    final result = await _client.pool.execute(
      'SELECT id, name, city FROM markets WHERE active ORDER BY name',
    );
    return [
      for (final row in result)
        Market(
          id: '${row.toColumnMap()['id']}',
          name: row.toColumnMap()['name'] as String,
          city: row.toColumnMap()['city'] as String,
        ),
    ];
  }

  // --- Lookups ---

  static const _accountColumns = '''
    a.id, a.mobile_number, a.user_type, a.display_name,
    a.contact_name, a.cnic_number, m.name AS market_name
  ''';

  @override
  Future<PartnerAccountRow?> findAccountByMobileNumber(
    String mobileNumber,
  ) async {
    final result = await _client.pool.execute(
      Sql.named(
        'SELECT $_accountColumns FROM accounts a '
        'LEFT JOIN markets m ON m.id = a.market_id '
        'WHERE a.mobile_number = @mobileNumber',
      ),
      parameters: {'mobileNumber': normaliseMobile(mobileNumber)},
    );
    if (result.isEmpty) return null;
    return _accountFromRow(result.first.toColumnMap());
  }

  @override
  Future<PartnerAccountRow?> findAccountByCnic(String cnicNumber) async {
    final result = await _client.pool.execute(
      Sql.named(
        'SELECT $_accountColumns FROM accounts a '
        'LEFT JOIN markets m ON m.id = a.market_id '
        'WHERE a.cnic_number = @cnic',
      ),
      parameters: {'cnic': cnicNumber.trim()},
    );
    if (result.isEmpty) return null;
    return _accountFromRow(result.first.toColumnMap());
  }

  @override
  Future<ApplicationRow?> openApplicationForNumber(String mobileNumber) =>
      _application(mobileNumber, openOnly: true);

  @override
  Future<ApplicationRow?> latestApplicationForNumber(String mobileNumber) =>
      _application(mobileNumber, openOnly: false);

  Future<ApplicationRow?> _application(
    String mobileNumber, {
    required bool openOnly,
  }) async {
    final result = await _client.pool.execute(
      Sql.named('''
        SELECT app.id, app.reference, app.mobile_number, app.status,
               app.submitted_at, app.business_name, app.full_name, app.role,
               m.name AS market_name,
               (SELECT bs.matched_name
                  FROM registration_buying_sources bs
                 WHERE bs.application_id = app.id
                 ORDER BY bs.position
                 LIMIT 1) AS verifying_source_name
          FROM registration_applications app
          LEFT JOIN markets m ON m.id = app.market_id
         WHERE app.mobile_number = @mobileNumber
           ${openOnly ? "AND app.status = 'submitted'" : ''}
         ORDER BY app.submitted_at DESC
         LIMIT 1
      '''),
      parameters: {'mobileNumber': normaliseMobile(mobileNumber)},
    );
    if (result.isEmpty) return null;

    final row = result.first.toColumnMap();
    final id = '${row['id']}';
    return ApplicationRow(
      id: id,
      reference: row['reference'] as String,
      mobileNumber: row['mobile_number'] as String,
      status: row['status'] as String,
      submittedAt: row['submitted_at'] as DateTime,
      verifyingSourceName: row['verifying_source_name'] as String?,
      businessName: row['business_name'] as String?,
      contactName: row['full_name'] as String?,
      role: row['role'] as String?,
      marketName: row['market_name'] as String?,
      approvals: await _approvals(id),
    );
  }

  Future<List<ApprovalRow>> _approvals(String applicationId) async {
    final result = await _client.pool.execute(
      Sql.named(
        'SELECT approver, state, decided_by_name, decided_at '
        'FROM registration_approvals WHERE application_id = @id '
        'ORDER BY approver',
      ),
      parameters: {'id': applicationId},
    );
    return [
      for (final row in result)
        ApprovalRow(
          approver: row.toColumnMap()['approver'] as String,
          state: row.toColumnMap()['state'] as String,
          decidedByName: row.toColumnMap()['decided_by_name'] as String?,
          decidedAt: row.toColumnMap()['decided_at'] as DateTime?,
        ),
    ];
  }

  // --- Registration OTP ---

  @override
  Future<String> issueWizardOtp(String mobileNumber) async {
    final code = generateOtpCode();
    await _client.pool.execute(
      Sql.named(
        'INSERT INTO otp_challenges (mobile_number, context, code) '
        "VALUES (@mobileNumber, 'registration_wizard', @code)",
      ),
      parameters: {'mobileNumber': normaliseMobile(mobileNumber), 'code': code},
    );
    return code;
  }

  @override
  Future<bool> verifyWizardOtp({
    required String mobileNumber,
    required String code,
  }) async {
    // Only the newest unverified challenge counts, so an older code that was
    // superseded by "Resend" cannot be used.
    final result = await _client.pool.execute(
      Sql.named('''
        UPDATE otp_challenges SET verified = true, verified_at = now()
         WHERE id = (
           SELECT id FROM otp_challenges
            WHERE mobile_number = @mobileNumber
              AND context = 'registration_wizard'
              AND verified = false
            ORDER BY created_at DESC
            LIMIT 1
         )
           AND code = @code
        RETURNING id
      '''),
      parameters: {'mobileNumber': normaliseMobile(mobileNumber), 'code': code},
    );
    return result.isNotEmpty;
  }

  // --- Home ---

  @override
  Future<DashboardRow?> dashboardFor(String mobileNumber) async {
    final account = await findAccountByMobileNumber(mobileNumber);
    if (account == null) return null;

    // The balance is derived, never stored, so Home and the ledger cannot
    // disagree. Held money has left the available balance; a rejected line
    // never moved at all.
    final totals = await _client.pool.execute(
      Sql.named('''
        SELECT
          -- SUM over bigint yields numeric, which arrives as a string. Cast
          -- back so paisa stays a whole number the whole way.
          COALESCE(SUM(CASE
            WHEN state = 'cleared' AND direction = 'credit' THEN amount_paisa
            WHEN state <> 'rejected' AND direction = 'debit' THEN -amount_paisa
            ELSE 0
          END), 0)::bigint AS available_paisa,
          COALESCE(SUM(CASE
            WHEN state = 'held' AND direction = 'debit' THEN amount_paisa
            ELSE 0
          END), 0)::bigint AS held_paisa
        FROM wallet_entries
       WHERE account_id = @accountId
      '''),
      parameters: {'accountId': account.id},
    );
    final totalsRow = totals.first.toColumnMap();

    final slides = await _client.pool.execute(
      Sql.named('''
        SELECT id, image_url, eyebrow, headline
          FROM promo_slides
         WHERE active
           AND audience IN ('all', @role)
           AND starts_at <= now()
           AND (ends_at IS NULL OR ends_at > now())
         ORDER BY position, created_at
      '''),
      parameters: {'role': account.userType},
    );

    final ticker = await _client.pool.execute(
      Sql.named('''
        SELECT message, text_colour, background_colour
          FROM ticker_messages
         WHERE active
           AND audience IN ('all', @role)
           AND starts_at <= now()
           AND (ends_at IS NULL OR ends_at > now())
         ORDER BY position, created_at
      '''),
      parameters: {'role': account.userType},
    );

    return DashboardRow(
      availablePaisa: (totalsRow['available_paisa'] as num).toInt(),
      heldPaisa: (totalsRow['held_paisa'] as num).toInt(),
      slides: [
        for (final row in slides)
          PromoSlideRow(
            id: '${row.toColumnMap()['id']}',
            imageUrl: row.toColumnMap()['image_url'] as String?,
            eyebrow: row.toColumnMap()['eyebrow'] as String?,
            headline: row.toColumnMap()['headline'] as String?,
          ),
      ],
      ticker: [
        for (final row in ticker)
          TickerMessageRow(
            message: row.toColumnMap()['message'] as String,
            textColour: row.toColumnMap()['text_colour'] as String?,
            backgroundColour: row.toColumnMap()['background_colour'] as String?,
          ),
      ],
    );
  }

  // --- Submission ---

  @override
  Future<SubmitResult> submitApplication(ApplicationInput input) async {
    final mobileNumber = normaliseMobile(input.mobileNumber);
    final cnic = input.cnicNumber.trim();

    final taken = await findAccountByMobileNumber(mobileNumber);
    if (taken != null) {
      return SubmitResult.rejected(
        SubmitRejection.numberTaken,
        heldBy: taken.displayName,
      );
    }
    if (await findAccountByCnic(cnic) != null) {
      // Deliberately no heldBy: who holds a CNIC is not the applicant's
      // business.
      return const SubmitResult.rejected(SubmitRejection.cnicTaken);
    }
    if (await openApplicationForNumber(mobileNumber) != null) {
      return const SubmitResult.rejected(SubmitRejection.applicationOpen);
    }

    // The application, its sources, its media and its three outstanding
    // approvals land together or not at all.
    final applicationId = await _client.pool.runTx((session) async {
      final inserted = await session.execute(
        Sql.named('''
          INSERT INTO registration_applications (
            reference, device_id, mobile_number, country_code, mobile_verified,
            role, full_name, alternate_number, business_name, business_address,
            market_id, shop_latitude, shop_longitude, cnic_number
          ) VALUES (
            @reference,
            (SELECT id FROM devices WHERE installation_uuid = @installationUuid),
            @mobileNumber, @countryCode, @mobileVerified,
            @role, @fullName, @alternateNumber, @businessName, @businessAddress,
            (SELECT id FROM markets WHERE name = @marketName),
            @shopLatitude, @shopLongitude, @cnic
          )
          RETURNING id
        '''),
        parameters: {
          'reference': _referenceFor(mobileNumber),
          'installationUuid': input.installationUuid,
          'mobileNumber': mobileNumber,
          'countryCode': input.countryCode,
          'mobileVerified': input.mobileVerified,
          'role': input.role,
          'fullName': input.fullName,
          'alternateNumber': input.alternateNumber,
          'businessName': input.businessName,
          'businessAddress': input.businessAddress,
          'marketName': input.marketName,
          'shopLatitude': input.shopLatitude,
          'shopLongitude': input.shopLongitude,
          'cnic': cnic,
        },
      );
      final id = '${inserted.first.toColumnMap()['id']}';

      for (final source in input.buyingSources) {
        final number = normaliseMobile(source.mobileNumber);
        await session.execute(
          Sql.named('''
            INSERT INTO registration_buying_sources (
              application_id, position, mobile_number,
              matched_account_id, matched_name, matched_role, matched_market
            )
            SELECT @applicationId, @position, @mobileNumber,
                   a.id, a.display_name, a.user_type, m.name
              FROM (SELECT 1) AS one
              LEFT JOIN accounts a ON a.mobile_number = @mobileNumber
              LEFT JOIN markets m ON m.id = a.market_id
          '''),
          parameters: {
            'applicationId': id,
            'position': source.position,
            'mobileNumber': number,
          },
        );
      }

      for (final item in input.media) {
        await session.execute(
          Sql.named(
            'INSERT INTO registration_media '
            '(application_id, kind, slot, link_url, storage_path) '
            'VALUES (@applicationId, @kind, @slot, @linkUrl, @storagePath)',
          ),
          parameters: {
            'applicationId': id,
            'kind': item.kind,
            'slot': item.slot,
            'linkUrl': item.linkUrl,
            'storagePath': item.storagePath,
          },
        );
      }

      // All three start outstanding. Nothing is approved on submission.
      await session.execute(
        Sql.named('''
          INSERT INTO registration_approvals (application_id, approver)
          VALUES (@id, 'buying_source'), (@id, 'marketing_officer'), (@id, 'crm')
        '''),
        parameters: {'id': id},
      );

      return id;
    });

    final application = await latestApplicationForNumber(mobileNumber);
    return SubmitResult.accepted(
      application ??
          ApplicationRow(
            id: applicationId,
            reference: _referenceFor(mobileNumber),
            mobileNumber: mobileNumber,
            status: 'submitted',
            submittedAt: DateTime.now(),
            verifyingSourceName: null,
            approvals: const [],
          ),
    );
  }

  /// 'CSE-4821190' — the last seven digits, which is what a partner can read
  /// back over the phone without spelling out a UUID.
  static String _referenceFor(String mobileNumber) =>
      'CSE-${mobileNumber.substring(mobileNumber.length - 7)}';

  PartnerAccountRow _accountFromRow(Map<String, dynamic> row) =>
      PartnerAccountRow(
        id: '${row['id']}',
        mobileNumber: row['mobile_number'] as String,
        userType: row['user_type'] as String,
        displayName: row['display_name'] as String?,
        contactName: row['contact_name'] as String?,
        marketName: row['market_name'] as String?,
        cnicNumber: row['cnic_number'] as String?,
      );
}
