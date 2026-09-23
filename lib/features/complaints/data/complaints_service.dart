// Constructor parameters are named for their public API rather than the
// private fields they populate, so the initializing-formal shorthand the
// linter suggests is not available here.
// ignore_for_file: prefer_initializing_formals

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/mock/partner_directory.dart';
import '../../../core/mock/pending_registrations.dart';

/// How urgent a complaint is.
enum ComplaintPriority { low, medium, high }

extension ComplaintPriorityX on ComplaintPriority {
  /// What the database stores.
  String get code => name;

  /// As the segmented control lists it.
  String get label => switch (this) {
    ComplaintPriority.low => 'Low',
    ComplaintPriority.medium => 'Medium',
    ComplaintPriority.high => 'High',
  };

  static ComplaintPriority fromCode(String? code) => switch (code) {
    'high' => ComplaintPriority.high,
    'low' => ComplaintPriority.low,
    _ => ComplaintPriority.medium,
  };
}

/// How long Crown Solar has to answer, and to finish.
class ComplaintTarget {
  const ComplaintTarget({
    required this.responseMinutes,
    required this.resolutionWorkingDays,
  });

  final int responseMinutes;
  final int resolutionWorkingDays;

  static ComplaintTarget fromJson(Map<String, dynamic> json) => ComplaintTarget(
    responseMinutes: json['responseMinutes'] as int,
    resolutionWorkingDays: json['resolutionWorkingDays'] as int,
  );
}

/// One of the chips on step 1 of the wizard, and what is promised for it at
/// each priority.
///
/// There is no narrower choice under it. The partner writes the complaint
/// themselves; the category is what routes the ticket.
class ComplaintCategory {
  const ComplaintCategory({
    required this.id,
    required this.code,
    required this.label,
    required this.targets,
  });

  final String id;

  /// Stable across renames. The screen maps this to the design's icon —
  /// the one thing about a category the database does not hold, because an
  /// icon belongs to the drawing rather than to the data.
  final String code;

  final String label;
  final Map<ComplaintPriority, ComplaintTarget> targets;

  ComplaintTarget? targetFor(ComplaintPriority priority) => targets[priority];

  static ComplaintCategory fromJson(Map<String, dynamic> json) =>
      ComplaintCategory(
        id: json['id'] as String,
        code: json['code'] as String,
        label: json['label'] as String,
        targets: {
          for (final entry in (json['targets'] as Map? ?? const {}).entries)
            ComplaintPriorityX.fromCode('${entry.key}'):
                ComplaintTarget.fromJson(entry.value as Map<String, dynamic>),
        },
      );
}

/// One thing that happened to a ticket.
class ComplaintEvent {
  const ComplaintEvent({
    required this.title,
    required this.state,
    this.meta,
    this.note,
    this.occurredAt,
  });

  final String title;

  /// The narrative, with no date in it — [occurredAt] carries the time.
  final String? meta;

  /// A trailing clause after the time, e.g. 'response target met'.
  final String? note;

  /// 'done' | 'active' | 'pending'.
  final String state;

  final DateTime? occurredAt;

  bool get done => state == 'done';
  bool get active => state == 'active';

  /// The line under the step title: narrative, then when it happened, then
  /// the verdict. Whichever parts there are.
  String? get line {
    final parts = [
      if (meta != null && meta!.isNotEmpty) meta!,
      if (occurredAt != null) formatWhen(occurredAt!),
      if (note != null && note!.isNotEmpty) note!,
    ];
    return parts.isEmpty ? null : parts.join(' · ');
  }

  static ComplaintEvent fromJson(Map<String, dynamic> json) => ComplaintEvent(
    title: json['title'] as String,
    meta: json['meta'] as String?,
    note: json['note'] as String?,
    state: json['state'] as String,
    occurredAt: _dateOrNull(json['occurredAt']),
  );
}

/// A ticket.
///
/// Everything here is a fact. The wording — "Met · 1 h 12 m", "Target 4 h" —
/// is worked out by the screens from these, so the same facts can be said
/// differently in another language.
class Complaint {
  const Complaint({
    required this.reference,
    required this.typeLabel,
    required this.categoryLabel,
    required this.priority,
    required this.title,
    required this.detail,
    required this.resolved,
    required this.responseTarget,
    required this.resolutionTargetWorkingDays,
    required this.raisedAt,
    required this.resolutionDueAt,
    this.evidenceNote,
    this.firstResponseAt,
    this.resolvedAt,
    this.events = const [],
  });

  final String reference;

  /// The full category name, as the wizard's chip says it.
  final String typeLabel;

  /// The short one, as the list and the detail header say it.
  final String categoryLabel;

  final ComplaintPriority priority;
  final String title;
  final String detail;
  final bool resolved;
  final String? evidenceNote;

  /// As promised when the ticket was raised, not as promised today.
  final Duration responseTarget;
  final int resolutionTargetWorkingDays;

  final DateTime raisedAt;
  final DateTime resolutionDueAt;
  final DateTime? firstResponseAt;
  final DateTime? resolvedAt;

  /// Empty on the list; filled on the detail.
  final List<ComplaintEvent> events;

  /// How long Crown Solar took to answer, once it has.
  Duration? get responseTook => firstResponseAt?.difference(raisedAt);

  /// Whether the answer came inside the promised window.
  bool get responseMet =>
      responseTook != null && responseTook! <= responseTarget;

  /// Whether the answer is late, which is only knowable once it is overdue.
  bool get responseOverdue =>
      firstResponseAt == null &&
      DateTime.now().difference(raisedAt) > responseTarget;

  bool get resolutionOverdue =>
      resolvedAt == null && DateTime.now().isAfter(resolutionDueAt);

  static Complaint fromJson(Map<String, dynamic> json) => Complaint(
    reference: json['reference'] as String,
    typeLabel: json['typeLabel'] as String,
    categoryLabel: json['categoryLabel'] as String,
    priority: ComplaintPriorityX.fromCode(json['priority'] as String?),
    title: json['title'] as String,
    detail: json['detail'] as String,
    resolved: json['status'] == 'resolved',
    evidenceNote: json['evidenceNote'] as String?,
    responseTarget: Duration(minutes: json['responseTargetMinutes'] as int),
    resolutionTargetWorkingDays: json['resolutionTargetWorkingDays'] as int,
    raisedAt: DateTime.parse(json['raisedAt'] as String).toLocal(),
    resolutionDueAt: DateTime.parse(json['resolutionDueAt'] as String)
        .toLocal(),
    firstResponseAt: _dateOrNull(json['firstResponseAt']),
    resolvedAt: _dateOrNull(json['resolvedAt']),
    events: [
      for (final entry in json['events'] as List? ?? const [])
        ComplaintEvent.fromJson(entry as Map<String, dynamic>),
    ],
  );
}

/// The ticket list, with the counts the two tabs are labelled with.
class ComplaintList {
  const ComplaintList({
    required this.complaints,
    required this.inProgress,
    required this.resolved,
  });

  final List<Complaint> complaints;
  final int inProgress;
  final int resolved;

  static const empty = ComplaintList(
    complaints: [],
    inProgress: 0,
    resolved: 0,
  );
}

/// One line in the notification centre.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.level,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.read,
    this.destinationLabel,
    this.destinationRoute,
  });

  final String id;

  /// 'info' | 'success' | 'warning' | 'critical'.
  final String level;

  final String title;
  final String body;

  /// What tapping does, in words, and where it goes. The route is null
  /// where that destination is not built yet.
  final String? destinationLabel;
  final String? destinationRoute;

  final DateTime createdAt;
  final bool read;

  /// "Today, 8:02 AM · opens Ledger entry".
  String get timestampLine =>
      [formatWhen(createdAt), ?destinationLabel].join(' · ');

  /// The destination on its own — "Claim detail" — for a sentence that
  /// supplies its own verb. The stored label reads as a phrase ("opens
  /// Claim detail") because that is how the list says it.
  String get destinationName {
    final label = destinationLabel;
    if (label == null || label.isEmpty) return 'That screen';
    return label.startsWith('opens ')
        ? label.substring('opens '.length)
        : label;
  }

  static AppNotification fromJson(Map<String, dynamic> json) => AppNotification(
    id: json['id'] as String,
    level: json['level'] as String,
    title: json['title'] as String,
    body: json['body'] as String,
    destinationLabel: json['destinationLabel'] as String?,
    destinationRoute: json['destinationRoute'] as String?,
    createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
    read: json['read'] == true,
  );
}

/// The notification list and its badge count.
class NotificationList {
  const NotificationList({required this.notifications, required this.unread});

  final List<AppNotification> notifications;
  final int unread;

  static const empty = NotificationList(notifications: [], unread: 0);
}

/// Complaints and notifications' data boundary.
///
/// [HttpComplaintsService] reads the database behind `prototype_server`.
/// [MockComplaintsService] holds the same tickets and notifications in
/// memory.
abstract interface class ComplaintsService {
  /// The categories, sub-types and targets the wizard offers.
  Future<List<ComplaintCategory>> catalogue();

  Future<ComplaintList?> list(String mobileNumber);

  Future<Complaint?> detail({
    required String mobileNumber,
    required String reference,
  });

  /// Raises a ticket. Null means it could not be raised — the screen says so
  /// rather than pretending it went through.
  Future<Complaint?> raise({
    required String mobileNumber,
    required String typeId,
    required ComplaintPriority priority,
    required String title,
    required String detail,
  });

  Future<NotificationList?> notifications(String mobileNumber);

  /// Marks one read, or every one when [id] is null.
  Future<void> markRead({required String mobileNumber, String? id});
}

/// Complaints and notifications' data boundary, backed by the database
/// behind `prototype_server`.
class HttpComplaintsService implements ComplaintsService {
  HttpComplaintsService({required String baseUrl, http.Client? client})
    : _baseUrl = baseUrl,
      _client = client ?? http.Client();

  final String _baseUrl;
  final http.Client _client;

  @override
  Future<List<ComplaintCategory>> catalogue() async {
    final body = await _get('/complaints/catalogue');
    if (body == null) return const [];
    return [
      for (final entry in body['types'] as List? ?? const [])
        ComplaintCategory.fromJson(entry as Map<String, dynamic>),
    ];
  }

  @override
  Future<ComplaintList?> list(String mobileNumber) async {
    final body = await _get('/complaints', {'mobileNumber': mobileNumber});
    if (body == null) return null;
    return ComplaintList(
      complaints: [
        for (final entry in body['complaints'] as List? ?? const [])
          Complaint.fromJson(entry as Map<String, dynamic>),
      ],
      inProgress: body['inProgress'] as int? ?? 0,
      resolved: body['resolved'] as int? ?? 0,
    );
  }

  @override
  Future<Complaint?> detail({
    required String mobileNumber,
    required String reference,
  }) async {
    final body = await _get('/complaints/$reference', {
      'mobileNumber': mobileNumber,
    });
    return body == null ? null : Complaint.fromJson(body);
  }

  @override
  Future<Complaint?> raise({
    required String mobileNumber,
    required String typeId,
    required ComplaintPriority priority,
    required String title,
    required String detail,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl/complaints'),
        headers: const {'content-type': 'application/json'},
        body: jsonEncode({
          'mobileNumber': mobileNumber,
          'typeId': typeId,
          'priority': priority.code,
          'title': title,
          'detail': detail,
        }),
      );
      if (response.statusCode != 201) return null;
      return Complaint.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } on Object {
      return null;
    }
  }

  @override
  Future<NotificationList?> notifications(String mobileNumber) async {
    final body = await _get('/notifications', {'mobileNumber': mobileNumber});
    if (body == null) return null;
    return NotificationList(
      notifications: [
        for (final entry in body['notifications'] as List? ?? const [])
          AppNotification.fromJson(entry as Map<String, dynamic>),
      ],
      unread: body['unread'] as int? ?? 0,
    );
  }

  @override
  Future<void> markRead({required String mobileNumber, String? id}) async {
    try {
      await _client.post(
        Uri.parse('$_baseUrl/notifications/read'),
        headers: const {'content-type': 'application/json'},
        body: jsonEncode({'mobileNumber': mobileNumber, 'id': ?id}),
      );
    } on Object {
      // Nothing to tell the partner: the list reloads either way, and an
      // unread dot that lingers is not worth an error message.
    }
  }

  Future<Map<String, dynamic>?> _get(
    String path, [
    Map<String, String>? query,
  ]) async {
    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl$path').replace(queryParameters: query),
      );
      if (response.statusCode != 200) return null;
      return jsonDecode(response.body) as Map<String, dynamic>;
    } on Object {
      return null;
    }
  }
}

/// One row of `complaint_types`, with the label the list screen shortens to.
class _SeededType {
  const _SeededType({required this.code, required this.label, this.shortLabel});

  final String code;
  final String label;
  final String? shortLabel;

  /// `COALESCE(short_label, label)`, which is what the ticket list shows.
  String get categoryLabel => shortLabel ?? label;
}

/// One ticket, held as the seed writes it: an interval before `now()`.
class _SeededComplaint {
  _SeededComplaint({
    required this.reference,
    required this.number,
    required this.typeCode,
    required this.priority,
    required this.title,
    required this.detail,
    required this.resolved,
    required this.raisedAgo,
    required this.events,
    this.evidenceNote,
    this.respondedAgo,
    this.resolvedAgo,
  });

  final String reference;
  final String number;
  final String typeCode;
  final ComplaintPriority priority;
  final String title;
  final String detail;
  final bool resolved;
  final String? evidenceNote;
  final Duration raisedAgo;
  final Duration? respondedAgo;
  final Duration? resolvedAgo;
  final List<_SeededEvent> events;
}

/// One row of `complaint_events`, timed from the ticket it belongs to.
class _SeededEvent {
  const _SeededEvent({required this.title, this.meta, this.note, this.after});

  final String title;
  final String? meta;
  final String? note;

  /// How long after the ticket was raised. Null takes the ticket's own
  /// first-response or resolved time, as the seed's CASE does.
  final Duration? after;
}

/// One row of `notifications`.
class _SeededNotification {
  _SeededNotification({
    required this.id,
    required this.level,
    required this.title,
    required this.body,
    required this.ago,
    required this.unread,
    this.destinationLabel,
    this.destinationRoute,
  });

  final String id;
  final String level;
  final String title;
  final String body;
  final String? destinationLabel;
  final String? destinationRoute;
  final Duration ago;
  final bool unread;
}

/// Complaints and notifications' data boundary, held in memory.
///
/// The categories, targets, four tickets and five notifications
/// `db/seed/005_complaints_and_notifications.sql` writes. A ticket raised
/// here lasts as long as the process does, which is what a build with no
/// database can offer.
class MockComplaintsService implements ComplaintsService {
  MockComplaintsService() : _seededAt = DateTime.now() {
    _complaints.addAll(_seededComplaints());
    _notifications.addAll(_seededNotifications());
  }

  /// The seed writes every date relative to `now()`. Holding that moment
  /// keeps the tickets still while the app runs, as rows in a table would be.
  final DateTime _seededAt;

  final List<_SeededComplaint> _complaints = [];
  final List<_SeededNotification> _notifications = [];

  /// Which notifications have been marked read this run.
  final Set<String> _read = {};

  int _nextReference = 5515;

  /// The partner the seeded tickets and notifications belong to.
  static const _ownerNumber = '3004821190';

  static const _types = <_SeededType>[
    _SeededType(
      code: 'qr_and_prizes',
      label: 'QR and prizes',
      shortLabel: 'QR prize dispute',
    ),
    _SeededType(code: 'wallet_and_cash', label: 'Wallet and cash'),
    _SeededType(code: 'points', label: 'Points'),
    _SeededType(code: 'shop_branding', label: 'Shop branding'),
    _SeededType(code: 'account_and_access', label: 'Account and access'),
    _SeededType(code: 'something_else', label: 'Something else'),
  ];

  /// One band per priority, applied to every category.
  static const _targets = <ComplaintPriority, ComplaintTarget>{
    ComplaintPriority.high: ComplaintTarget(
      responseMinutes: 240,
      resolutionWorkingDays: 2,
    ),
    ComplaintPriority.medium: ComplaintTarget(
      responseMinutes: 480,
      resolutionWorkingDays: 3,
    ),
    ComplaintPriority.low: ComplaintTarget(
      responseMinutes: 1440,
      resolutionWorkingDays: 5,
    ),
  };

  static _SeededType _typeOf(String code) {
    for (final type in _types) {
      if (type.code == code) return type;
    }
    return _types.last;
  }

  static List<_SeededComplaint> _seededComplaints() => [
    _SeededComplaint(
      reference: 'CMP-2026-5514',
      number: _ownerNumber,
      typeCode: 'qr_and_prizes',
      priority: ComplaintPriority.high,
      title: 'Prize not credited for inverter scan',
      detail:
          'I scanned a Crown 8kW inverter on 8 September at about 3 pm. The '
          'app showed the prize screen but nothing came into my wallet.',
      resolved: false,
      evidenceNote:
          'QR code CS-6K-2026-338201 · previous claimant M. Zubair Solar · '
          'both timestamps · your location at the time of the scan.',
      raisedAgo: const Duration(hours: 3, minutes: 12),
      respondedAgo: const Duration(hours: 2),
      events: const [
        _SeededEvent(
          title: 'Complaint raised',
          meta: 'Submitted by you with attached scan evidence.',
          after: Duration.zero,
        ),
        _SeededEvent(
          title: 'Ticket assigned',
          meta: 'Assigned to CRM prize desk.',
          after: Duration(minutes: 12),
        ),
        _SeededEvent(
          title: 'First response',
          meta: '"We are checking both scans against the installation record."',
          note: 'response target met',
          after: Duration(hours: 1, minutes: 12),
        ),
      ],
    ),
    _SeededComplaint(
      reference: 'CMP-2026-5390',
      number: _ownerNumber,
      typeCode: 'shop_branding',
      priority: ComplaintPriority.medium,
      title: 'Board installed with wrong shop name',
      detail:
          'The frontlit board that went up yesterday reads "Adnan Solar '
          'Work". The shop name is Adnan Solar Works.',
      resolved: false,
      raisedAgo: const Duration(days: 17),
      respondedAgo: const Duration(days: 16, hours: 20),
      events: const [
        _SeededEvent(
          title: 'Complaint raised',
          meta: 'Submitted by you.',
          after: Duration.zero,
        ),
        _SeededEvent(
          title: 'First response',
          meta: 'Rehman Signs has been asked to reprint and refit the board.',
        ),
      ],
    ),
    _SeededComplaint(
      reference: 'CMP-2026-5102',
      number: _ownerNumber,
      typeCode: 'points',
      priority: ComplaintPriority.medium,
      title: 'Points missing for August purchase',
      detail:
          'I bought 12 panels on 18 August through Hamza Solar House. No '
          'points were posted against the invoice.',
      resolved: true,
      raisedAgo: const Duration(days: 30),
      respondedAgo: const Duration(days: 29, hours: 18),
      resolvedAgo: const Duration(days: 27),
      events: const [
        _SeededEvent(
          title: 'Complaint raised',
          meta: 'Submitted by you.',
          after: Duration.zero,
        ),
        _SeededEvent(
          title: 'First response',
          meta: 'Crown Solar acknowledged the complaint.',
        ),
        _SeededEvent(
          title: 'Resolved',
          meta:
              'Closed by CRM. Reopen it by raising a new complaint if the '
              'problem comes back.',
        ),
      ],
    ),
    _SeededComplaint(
      reference: 'CMP-2026-4977',
      number: _ownerNumber,
      typeCode: 'account_and_access',
      priority: ComplaintPriority.low,
      title: 'Cannot sign in on my new phone',
      detail:
          'My old handset broke. The app says my account is fixed to another '
          'device and will not let me in.',
      resolved: true,
      raisedAgo: const Duration(days: 38),
      respondedAgo: const Duration(days: 37),
      resolvedAgo: const Duration(days: 35),
      events: const [
        _SeededEvent(
          title: 'Complaint raised',
          meta: 'Submitted by you.',
          after: Duration.zero,
        ),
        _SeededEvent(
          title: 'First response',
          meta: 'Crown Solar acknowledged the complaint.',
        ),
        _SeededEvent(
          title: 'Resolved',
          meta:
              'Closed by CRM. Reopen it by raising a new complaint if the '
              'problem comes back.',
        ),
      ],
    ),
  ];

  /// These stand in for what the backend would have written when each thing
  /// happened. A null route is a destination that is not built yet — the row
  /// still says where it would go.
  static List<_SeededNotification> _seededNotifications() => [
    _SeededNotification(
      id: 'ntf-1',
      level: 'info',
      title: 'Cash request expired and returned',
      body:
          'PKR 4,000 you sent to Sitara Electronics came back to your wallet.',
      destinationLabel: 'opens Ledger entry',
      destinationRoute: '/wallet/ledger',
      ago: const Duration(hours: 5),
      unread: true,
    ),
    _SeededNotification(
      id: 'ntf-2',
      level: 'info',
      title: 'Prize held for review',
      body: 'Your claim on CS-6K-2026-338201 is with CRM.',
      destinationLabel: 'opens Claim detail',
      ago: const Duration(days: 1, hours: 6),
      unread: true,
    ),
    _SeededNotification(
      id: 'ntf-3',
      level: 'info',
      title: 'Spin entitlement earned',
      body: 'You scanned 10 products today. One spin is waiting.',
      destinationLabel: 'opens Inaam Baazar · Spin and Win',
      ago: const Duration(days: 1, hours: 9),
      unread: false,
    ),
    _SeededNotification(
      id: 'ntf-4',
      level: 'success',
      title: 'Complaint CMP-2026-5102 resolved',
      body: 'Points for your August purchase have been posted.',
      destinationLabel: 'opens Complaint detail',
      destinationRoute: '/complaints/CMP-2026-5102',
      ago: const Duration(days: 27),
      unread: false,
    ),
    _SeededNotification(
      id: 'ntf-5',
      level: 'info',
      title: 'New post in Space',
      body: 'Crown Solar shared: Eid scheme for retailers.',
      destinationLabel: 'opens Post detail',
      ago: const Duration(days: 32),
      unread: false,
    ),
  ];

  Complaint _complaintFrom(_SeededComplaint row) {
    final type = _typeOf(row.typeCode);
    final target = _targets[row.priority]!;
    final raisedAt = _seededAt.subtract(row.raisedAgo);
    final firstResponseAt = row.respondedAgo == null
        ? null
        : _seededAt.subtract(row.respondedAgo!);
    final resolvedAt = row.resolvedAgo == null
        ? null
        : _seededAt.subtract(row.resolvedAgo!);

    final events = <ComplaintEvent>[
      for (final event in row.events)
        ComplaintEvent(
          title: event.title,
          meta: event.meta,
          note: event.note,
          state: 'done',
          occurredAt: switch (event.title) {
            _ when event.after != null => raisedAt.add(event.after!),
            'Resolved' => resolvedAt,
            'First response' => firstResponseAt,
            _ => raisedAt,
          },
        ),
      // The step still being waited on is not a row: it is derived from the
      // ticket's status, so it can never quote a date that has gone stale.
      if (!row.resolved)
        const ComplaintEvent(title: 'Awaiting resolution', state: 'active'),
    ];

    return Complaint(
      reference: row.reference,
      typeLabel: type.label,
      categoryLabel: type.categoryLabel,
      priority: row.priority,
      title: row.title,
      detail: row.detail,
      resolved: row.resolved,
      evidenceNote: row.evidenceNote,
      responseTarget: Duration(minutes: target.responseMinutes),
      resolutionTargetWorkingDays: target.resolutionWorkingDays,
      raisedAt: raisedAt,
      resolutionDueAt: _addWorkingDays(raisedAt, target.resolutionWorkingDays),
      firstResponseAt: firstResponseAt,
      resolvedAt: resolvedAt,
      events: events,
    );
  }

  /// Working days skip Sunday, as the server counts them.
  static DateTime _addWorkingDays(DateTime from, int days) {
    var result = from;
    var remaining = days;
    while (remaining > 0) {
      result = result.add(const Duration(days: 1));
      if (result.weekday != DateTime.sunday) remaining--;
    }
    return result;
  }

  @override
  Future<List<ComplaintCategory>> catalogue() async => [
    for (final type in _types)
      ComplaintCategory(
        id: type.code,
        code: type.code,
        label: type.label,
        targets: _targets,
      ),
  ];

  List<_SeededComplaint> _mine(String mobileNumber) {
    final number = PartnerDirectory.normalise(mobileNumber);
    return [
      for (final row in _complaints)
        if (row.number == number) row,
    ]..sort((a, b) => a.raisedAgo.compareTo(b.raisedAgo));
  }

  @override
  Future<ComplaintList?> list(String mobileNumber) async {
    if (PartnerDirectory.find(mobileNumber) == null) return null;

    final mine = _mine(mobileNumber);
    return ComplaintList(
      complaints: [for (final row in mine) _complaintFrom(row)],
      inProgress: mine.where((row) => !row.resolved).length,
      resolved: mine.where((row) => row.resolved).length,
    );
  }

  @override
  Future<Complaint?> detail({
    required String mobileNumber,
    required String reference,
  }) async {
    for (final row in _mine(mobileNumber)) {
      if (row.reference == reference) return _complaintFrom(row);
    }
    return null;
  }

  @override
  Future<Complaint?> raise({
    required String mobileNumber,
    required String typeId,
    required ComplaintPriority priority,
    required String title,
    required String detail,
  }) async {
    if (PartnerDirectory.find(mobileNumber) == null) return null;
    if (title.trim().isEmpty || detail.trim().isEmpty) return null;

    final raised = _SeededComplaint(
      reference: 'CMP-${DateTime.now().year}-${_nextReference++}',
      number: PartnerDirectory.normalise(mobileNumber),
      typeCode: typeId,
      priority: priority,
      title: title,
      detail: detail,
      resolved: false,
      raisedAgo: _seededAt.difference(DateTime.now()),
      events: const [
        _SeededEvent(
          title: 'Complaint raised',
          meta: 'Submitted by you.',
          after: Duration.zero,
        ),
      ],
    );
    _complaints.add(raised);
    return _complaintFrom(raised);
  }

  @override
  Future<NotificationList?> notifications(String mobileNumber) async {
    if (PartnerDirectory.find(mobileNumber) == null) return null;

    final all = [
      // A registration submitted on this phone that named this partner as
      // its buying source. It is told here as well as in New Profile: a
      // request nobody is told about is a request nobody answers.
      for (final registration in PendingRegistrations.awaitingVerificationBy(
        mobileNumber,
      ))
        _buyingSourceNotification(registration),
      if (PartnerDirectory.normalise(mobileNumber) == _ownerNumber)
        for (final row in _notifications)
          AppNotification(
            id: row.id,
            level: row.level,
            title: row.title,
            body: row.body,
            destinationLabel: row.destinationLabel,
            destinationRoute: row.destinationRoute,
            createdAt: _seededAt.subtract(row.ago),
            read: !row.unread || _read.contains(row.id),
          ),
    ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return NotificationList(
      notifications: all,
      unread: all.where((notification) => !notification.read).length,
    );
  }

  /// Told to the buying source the applicant named, and kept afterwards: it
  /// is the record that they were asked, so it changes its wording once they
  /// have answered rather than disappearing.
  AppNotification _buyingSourceNotification(PendingRegistration registration) {
    final outstanding =
        registration.approvals[Approver.receiver] == ApprovalState.outstanding;

    return AppNotification(
      id: _buyingSourceNotificationId(registration),
      level: outstanding ? 'warning' : 'success',
      title: outstanding ? 'New profile request' : 'Profile request answered',
      body: outstanding
          ? '${registration.contactName} of ${registration.businessName} '
                'registered and named you as their buying source. They cannot '
                'be approved until you confirm they buy from you.'
          : '${registration.contactName} of ${registration.businessName} '
                'named you as their buying source. You have answered this '
                'one — Crown Solar carries it on from here.',
      destinationLabel: outstanding ? 'opens New Profile' : null,
      destinationRoute: outstanding ? '/profile-requests' : null,
      createdAt: registration.submittedAt,
      read: _read.contains(_buyingSourceNotificationId(registration)),
    );
  }

  static String _buyingSourceNotificationId(PendingRegistration registration) =>
      'profile-request-${registration.reference}';

  @override
  Future<void> markRead({required String mobileNumber, String? id}) async {
    if (id == null) {
      for (final row in _notifications) {
        _read.add(row.id);
      }
      for (final registration in PendingRegistrations.awaitingVerificationBy(
        mobileNumber,
      )) {
        _read.add(_buyingSourceNotificationId(registration));
      }
      return;
    }
    _read.add(id);
  }
}

DateTime? _dateOrNull(Object? value) =>
    value == null ? null : DateTime.parse(value as String).toLocal();

const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// "Today, 4:08 PM", then "Yesterday", then "04 Sep".
///
/// Times are never stored as words. A history line written this afternoon
/// still reads correctly next month because the date travels as a date and
/// is turned into a phrase here, when it is drawn.
String formatWhen(DateTime at) {
  final now = DateTime.now();
  final days = DateTime(
    now.year,
    now.month,
    now.day,
  ).difference(DateTime(at.year, at.month, at.day)).inDays;

  if (days == 0) {
    final hour = at.hour % 12 == 0 ? 12 : at.hour % 12;
    final minute = at.minute.toString().padLeft(2, '0');
    return 'Today, $hour:$minute ${at.hour < 12 ? 'AM' : 'PM'}';
  }
  if (days == 1) return 'Yesterday';
  return '${at.day.toString().padLeft(2, '0')} ${_months[at.month - 1]}';
}

/// "4 h", "1 h 12 m", "45 m" — the short form the target cards use, where
/// the space is tight and the label beside it says what it measures.
String formatDuration(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes % 60;
  if (hours == 0) return '$minutes m';
  if (minutes == 0) return '$hours h';
  return '$hours h $minutes m';
}

/// "4 hours", "1 hour", "45 minutes" — the long form for a sentence.
String formatDurationWords(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes % 60;
  if (hours == 0) return '$minutes minutes';
  final hoursWord = hours == 1 ? '1 hour' : '$hours hours';
  return minutes == 0 ? hoursWord : '$hoursWord $minutes minutes';
}
