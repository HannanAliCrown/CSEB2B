import 'package:postgres/postgres.dart';

import '../db/postgres_client.dart';
import 'complaints_data_store.dart';
import 'postgres_partner_data_store.dart' show normaliseMobile;
import 'staff_models.dart';

/// The [ComplaintsDataStore] backed by PostgreSQL.
class PostgresComplaintsDataStore implements ComplaintsDataStore {
  PostgresComplaintsDataStore(this._client);

  final PostgresClient _client;

  static const _priorities = {'low', 'medium', 'high'};

  /// Every column the list and the detail read, with the two category names
  /// resolved. Written once so the two queries cannot drift apart.
  static const _complaintColumns = '''
    c.reference, c.priority, c.title, c.detail, c.status, c.evidence_note,
    c.response_target_minutes, c.resolution_target_working_days,
    c.raised_at, c.first_response_at, c.resolved_at,
    c.raised_by_staff_name, c.raised_by_staff_role,
    t.label AS type_label,
    COALESCE(t.short_label, t.label) AS category_label
  ''';

  static const _complaintJoins = '''
    FROM complaints c
    JOIN complaint_types t ON t.id = c.type_id
    JOIN accounts        a ON a.id = c.account_id
  ''';

  @override
  Future<List<ComplaintTypeRow>> catalogue() async {
    final result = await _client.pool.execute('''
      SELECT t.id, t.code, t.label, t.short_label,
             g.priority, g.response_minutes, g.resolution_working_days
        FROM complaint_types t
        LEFT JOIN complaint_targets g ON g.type_id = t.id
       WHERE t.active
       ORDER BY t.position, t.label
    ''');

    // One row per (category, priority), folded back into the shape the
    // wizard reads: a category with a target for each priority.
    final types = <String, ({String id, String label, String? shortLabel})>{};
    final targets = <String, Map<String, ComplaintTargetRow>>{};

    for (final record in result) {
      final row = record.toColumnMap();
      final code = row['code'] as String;

      types[code] ??= (
        id: '${row['id']}',
        label: row['label'] as String,
        shortLabel: row['short_label'] as String?,
      );

      final priority = row['priority'] as String?;
      if (priority != null) {
        targets.putIfAbsent(code, () => {})[priority] = ComplaintTargetRow(
          responseMinutes: row['response_minutes'] as int,
          resolutionWorkingDays: row['resolution_working_days'] as int,
        );
      }
    }

    return [
      for (final entry in types.entries)
        ComplaintTypeRow(
          id: entry.value.id,
          code: entry.key,
          label: entry.value.label,
          shortLabel: entry.value.shortLabel,
          targets: targets[entry.key] ?? const {},
        ),
    ];
  }

  @override
  Future<List<ComplaintRow>?> complaints(String mobileNumber) async {
    if (await _accountId(mobileNumber) == null) return null;

    final result = await _client.pool.execute(
      Sql.named('''
        SELECT $_complaintColumns
        $_complaintJoins
         WHERE a.mobile_number = @number
         ORDER BY c.raised_at DESC
      '''),
      parameters: {'number': normaliseMobile(mobileNumber)},
    );

    return [for (final record in result) _complaintFrom(record.toColumnMap())];
  }

  @override
  Future<ComplaintRow?> complaint({
    required String mobileNumber,
    required String reference,
  }) async {
    final result = await _client.pool.execute(
      Sql.named('''
        SELECT c.id, $_complaintColumns
        $_complaintJoins
         WHERE a.mobile_number = @number AND c.reference = @reference
      '''),
      parameters: {
        'number': normaliseMobile(mobileNumber),
        'reference': reference,
      },
    );
    if (result.isEmpty) return null;

    final row = result.first.toColumnMap();
    return _complaintFrom(
      row,
      events: await _events('${row['id']}', _complaintFrom(row)),
    );
  }

  /// The history, plus the step still being waited on.
  ///
  /// That last step is derived rather than stored: it quotes the resolution
  /// target, and a row holding that sentence would go stale the moment the
  /// ticket moved or the date passed.
  Future<List<ComplaintEventRow>> _events(
    String complaintId,
    ComplaintRow complaint,
  ) async {
    final result = await _client.pool.execute(
      Sql.named('''
        SELECT title, meta, note, state, occurred_at
          FROM complaint_events
         WHERE complaint_id = @id
         ORDER BY position, occurred_at
      '''),
      parameters: {'id': complaintId},
    );

    final events = [
      for (final record in result)
        ComplaintEventRow(
          title: record.toColumnMap()['title'] as String,
          meta: record.toColumnMap()['meta'] as String?,
          note: record.toColumnMap()['note'] as String?,
          state: record.toColumnMap()['state'] as String,
          occurredAt: record.toColumnMap()['occurred_at'] as DateTime?,
        ),
    ];

    if (complaint.status == 'in_progress') {
      events.add(
        const ComplaintEventRow(title: 'Awaiting resolution', state: 'active'),
      );
    }
    return events;
  }

  @override
  Future<(ComplaintRow?, ComplaintRefusal?)> raiseComplaint({
    required String mobileNumber,
    required String typeId,
    required String priority,
    required String title,
    required String detail,
  }) async {
    if (title.trim().isEmpty || detail.trim().isEmpty) {
      return (null, ComplaintRefusal.incomplete);
    }
    if (!_priorities.contains(priority)) {
      return (null, ComplaintRefusal.unknownType);
    }

    final accountId = await _accountId(mobileNumber);
    if (accountId == null) return (null, ComplaintRefusal.unknownAccount);

    // The targets are copied in here, from the category's band for this
    // priority. A category with no band for it cannot be raised at it.
    final inserted = await _client.pool.execute(
      Sql.named('''
        INSERT INTO complaints (
          account_id, type_id, priority, title, detail,
          response_target_minutes, resolution_target_working_days
        )
        SELECT @accountId::uuid, g.type_id, g.priority, @title, @detail,
               g.response_minutes, g.resolution_working_days
          FROM complaint_targets g
          JOIN complaint_types t ON t.id = g.type_id AND t.active
         WHERE g.type_id = @typeId::uuid AND g.priority = @priority
        RETURNING id, reference
      '''),
      parameters: {
        'accountId': accountId,
        'typeId': typeId,
        'priority': priority,
        'title': title.trim(),
        'detail': detail.trim(),
      },
    );
    if (inserted.isEmpty) return (null, ComplaintRefusal.unknownType);

    final row = inserted.first.toColumnMap();
    final complaintId = '${row['id']}';
    final reference = row['reference'] as String;

    // The first line of the history, written by the thing that made it
    // happen — here, the app, on the partner's behalf.
    await _client.pool.execute(
      Sql.named('''
        INSERT INTO complaint_events (complaint_id, title, meta, state,
                                      occurred_at, position)
        SELECT @id::uuid, 'Complaint raised', 'Submitted by you.', 'done',
               raised_at, 0
          FROM complaints WHERE id = @id::uuid
      '''),
      parameters: {'id': complaintId},
    );

    // And the partner is told, because the review screen promised they would
    // be notified on every status change.
    await _client.pool.execute(
      Sql.named('''
        INSERT INTO notifications (account_id, level, title, body,
                                   destination_label, destination_route)
        VALUES (@accountId::uuid, 'info', @title, @body,
                'opens Complaint detail', @route)
      '''),
      parameters: {
        'accountId': accountId,
        'title': 'Complaint $reference raised',
        'body':
            'Crown Solar has your complaint. You will be told on every '
            'status change.',
        'route': '/complaints/$reference',
      },
    );

    return (
      await complaint(mobileNumber: mobileNumber, reference: reference),
      null,
    );
  }

  @override
  Future<List<NotificationRow>?> notifications(String mobileNumber) async {
    if (await _accountId(mobileNumber) == null) return null;

    final result = await _client.pool.execute(
      Sql.named('''
        SELECT n.id, n.level, n.title, n.body, n.destination_label,
               n.destination_route, n.created_at, n.read_at
          FROM notifications n
          JOIN accounts a ON a.id = n.account_id
         WHERE a.mobile_number = @number
         ORDER BY n.created_at DESC
      '''),
      parameters: {'number': normaliseMobile(mobileNumber)},
    );

    return [
      for (final record in result)
        NotificationRow(
          id: '${record.toColumnMap()['id']}',
          level: record.toColumnMap()['level'] as String,
          title: record.toColumnMap()['title'] as String,
          body: record.toColumnMap()['body'] as String,
          destinationLabel:
              record.toColumnMap()['destination_label'] as String?,
          destinationRoute:
              record.toColumnMap()['destination_route'] as String?,
          createdAt: record.toColumnMap()['created_at'] as DateTime,
          readAt: record.toColumnMap()['read_at'] as DateTime?,
        ),
    ];
  }

  @override
  Future<int> markRead({required String mobileNumber, String? id}) async {
    // Scoped by account in the statement itself, so an id from somewhere
    // else marks nothing.
    final result = await _client.pool.execute(
      Sql.named('''
        UPDATE notifications n SET read_at = now()
          FROM accounts a
         WHERE a.id = n.account_id
           AND a.mobile_number = @number
           AND n.read_at IS NULL
           AND (@id::uuid IS NULL OR n.id = @id::uuid)
        RETURNING n.id
      '''),
      parameters: {'number': normaliseMobile(mobileNumber), 'id': id},
    );
    return result.length;
  }

  Future<String?> _accountId(String mobileNumber) async {
    final result = await _client.pool.execute(
      Sql.named('SELECT id FROM accounts WHERE mobile_number = @number'),
      parameters: {'number': normaliseMobile(mobileNumber)},
    );
    if (result.isEmpty) return null;
    return '${result.first.toColumnMap()['id']}';
  }

  ComplaintRow _complaintFrom(
    Map<String, dynamic> row, {
    List<ComplaintEventRow> events = const [],
  }) {
    final raisedAt = row['raised_at'] as DateTime;
    final workingDays = row['resolution_target_working_days'] as int;
    return ComplaintRow(
      reference: row['reference'] as String,
      typeLabel: row['type_label'] as String,
      categoryLabel: row['category_label'] as String,
      priority: row['priority'] as String,
      title: row['title'] as String,
      detail: row['detail'] as String,
      status: row['status'] as String,
      evidenceNote: row['evidence_note'] as String?,
      responseTargetMinutes: row['response_target_minutes'] as int,
      resolutionTargetWorkingDays: workingDays,
      raisedAt: raisedAt,
      resolutionDueAt: addWorkingDays(raisedAt, workingDays),
      firstResponseAt: row['first_response_at'] as DateTime?,
      resolvedAt: row['resolved_at'] as DateTime?,
      raisedBy: RaisedByRow.fromColumns(row),
      events: events,
    );
  }
}
