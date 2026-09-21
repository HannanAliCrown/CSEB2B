// Constructor parameters are named for their public API rather than the
// private fields they populate, so the initializing-formal shorthand the
// linter suggests is not available here.
// ignore_for_file: prefer_initializing_formals

import 'dart:convert';

import 'package:http/http.dart' as http;

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
/// The server implementation remains available for the backend-backed
/// prototype. The mock implementation uses the same contract and rules with
/// bundled fixtures, so the complete journey can be viewed without a server.
class ComplaintsService {
  ComplaintsService({required String baseUrl, http.Client? client})
    : _baseUrl = baseUrl,
      _client = client ?? http.Client(),
      _mock = false,
      _mockComplaints = {},
      _mockNotifications = {};

  ComplaintsService.mock()
    : _baseUrl = '',
      _client = http.Client(),
      _mock = true,
      _mockComplaints = _demoComplaints(),
      _mockNotifications = _demoNotifications();

  final String _baseUrl;
  final http.Client _client;
  final bool _mock;
  final Map<String, List<Complaint>> _mockComplaints;
  final Map<String, List<AppNotification>> _mockNotifications;

  var _nextMockReference = 5515;
  var _nextMockNotification = 6;

  static const _mockAccounts = {
    '3217745002',
    '3004821190',
    '3007781204',
    '3014429911',
    '3335560071',
    '3028890143',
  };

  /// The categories, sub-types and targets the wizard offers.
  Future<List<ComplaintCategory>> catalogue() async {
    if (_mock) return _mockCatalogue();
    final body = await _get('/complaints/catalogue');
    if (body == null) return const [];
    return [
      for (final entry in body['types'] as List? ?? const [])
        ComplaintCategory.fromJson(entry as Map<String, dynamic>),
    ];
  }

  Future<ComplaintList?> list(String mobileNumber) async {
    if (_mock) {
      final account = _normaliseMobile(mobileNumber);
      if (!_mockAccounts.contains(account)) return null;
      final complaints = List<Complaint>.of(_mockComplaints[account] ?? const [])
        ..sort((a, b) => b.raisedAt.compareTo(a.raisedAt));
      return ComplaintList(
        complaints: complaints,
        inProgress: complaints.where((complaint) => !complaint.resolved).length,
        resolved: complaints.where((complaint) => complaint.resolved).length,
      );
    }
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

  Future<Complaint?> detail({
    required String mobileNumber,
    required String reference,
  }) async {
    if (_mock) {
      final account = _normaliseMobile(mobileNumber);
      if (!_mockAccounts.contains(account)) return null;
      final complaints = _mockComplaints[account] ?? const <Complaint>[];
      for (final complaint in complaints) {
        if (complaint.reference == reference) return complaint;
      }
      return null;
    }
    final body = await _get('/complaints/$reference', {
      'mobileNumber': mobileNumber,
    });
    return body == null ? null : Complaint.fromJson(body);
  }

  /// Raises a ticket. Null means it could not be raised — the screen says so
  /// rather than pretending it went through.
  Future<Complaint?> raise({
    required String mobileNumber,
    required String typeId,
    required ComplaintPriority priority,
    required String title,
    required String detail,
  }) async {
    if (_mock) {
      final account = _normaliseMobile(mobileNumber);
      if (!_mockAccounts.contains(account) ||
          title.trim().isEmpty ||
          detail.trim().isEmpty) {
        return null;
      }

      final category = _mockCatalogue().where((item) => item.id == typeId);
      if (category.isEmpty || category.first.targetFor(priority) == null) {
        return null;
      }
      final target = category.first.targetFor(priority)!;
      final raisedAt = DateTime.now();
      final complaint = Complaint(
        reference: 'CMP-2026-${_nextMockReference++}',
        typeLabel: category.first.label,
        categoryLabel: category.first.code == 'qr_and_prizes'
            ? 'QR prize dispute'
            : category.first.label,
        priority: priority,
        title: title.trim(),
        detail: detail.trim(),
        resolved: false,
        responseTarget: Duration(minutes: target.responseMinutes),
        resolutionTargetWorkingDays: target.resolutionWorkingDays,
        raisedAt: raisedAt,
        resolutionDueAt: raisedAt.add(
          Duration(days: target.resolutionWorkingDays),
        ),
        events: [
          ComplaintEvent(
            title: 'Complaint raised',
            meta: 'Submitted by you.',
            state: 'done',
            occurredAt: raisedAt,
          ),
          const ComplaintEvent(title: 'Awaiting resolution', state: 'active'),
        ],
      );
      (_mockComplaints[account] ??= []).add(complaint);
      (_mockNotifications[account] ??= []).insert(
        0,
        AppNotification(
          id: 'mock-notification-${_nextMockNotification++}',
          level: 'info',
          title: 'Complaint ${complaint.reference} raised',
          body:
              'Crown Solar has your complaint. You will be told on every '
              'status change.',
          destinationLabel: 'opens Complaint detail',
          destinationRoute: '/complaints/${complaint.reference}',
          createdAt: raisedAt,
          read: false,
        ),
      );
      return complaint;
    }
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

  Future<NotificationList?> notifications(String mobileNumber) async {
    if (_mock) {
      final account = _normaliseMobile(mobileNumber);
      if (!_mockAccounts.contains(account)) return null;
      final notifications = List<AppNotification>.of(
        _mockNotifications[account] ?? const [],
      );
      return NotificationList(
        notifications: notifications,
        unread: notifications.where((notification) => !notification.read).length,
      );
    }
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

  /// Marks one read, or every one when [id] is null.
  Future<void> markRead({required String mobileNumber, String? id}) async {
    if (_mock) {
      final account = _normaliseMobile(mobileNumber);
      final notifications = _mockNotifications[account];
      if (notifications == null) return;
      for (var index = 0; index < notifications.length; index++) {
        final notification = notifications[index];
        if (notification.read || (id != null && notification.id != id)) {
          continue;
        }
        notifications[index] = AppNotification(
          id: notification.id,
          level: notification.level,
          title: notification.title,
          body: notification.body,
          destinationLabel: notification.destinationLabel,
          destinationRoute: notification.destinationRoute,
          createdAt: notification.createdAt,
          read: true,
        );
      }
      return;
    }
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

  static String _normaliseMobile(String mobileNumber) {
    final digits = mobileNumber.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('92')) return digits.substring(2);
    if (digits.startsWith('0')) return digits.substring(1);
    return digits;
  }

  static List<ComplaintCategory> _mockCatalogue() => [
    for (final entry in const [
      ('qr_and_prizes', 'QR and prizes', 'QR prize dispute'),
      ('wallet_and_cash', 'Wallet and cash', null),
      ('points', 'Points', null),
      ('shop_branding', 'Shop branding', null),
      ('account_and_access', 'Account and access', null),
      ('something_else', 'Something else', null),
    ])
      ComplaintCategory(
        id: 'mock-${entry.$1}',
        code: entry.$1,
        label: entry.$2,
        targets: {
          ComplaintPriority.high: const ComplaintTarget(
            responseMinutes: 240,
            resolutionWorkingDays: 2,
          ),
          ComplaintPriority.medium: const ComplaintTarget(
            responseMinutes: 480,
            resolutionWorkingDays: 3,
          ),
          ComplaintPriority.low: const ComplaintTarget(
            responseMinutes: 1440,
            resolutionWorkingDays: 5,
          ),
        },
      ),
  ];

  static Map<String, List<Complaint>> _demoComplaints() {
    final now = DateTime.now();
    Complaint eventComplaint({
      required String reference,
      required String category,
      required ComplaintPriority priority,
      required String title,
      required String detail,
      required bool resolved,
      required Duration age,
    }) {
      final raisedAt = now.subtract(age);
      final respondedAt = raisedAt.add(
        priority == ComplaintPriority.high
            ? const Duration(hours: 1, minutes: 12)
            : const Duration(hours: 3),
      );
      final resolvedAt = resolved
          ? respondedAt.add(const Duration(days: 1))
          : null;
      return Complaint(
        reference: reference,
        typeLabel: category,
        categoryLabel: category == 'QR and prizes'
            ? 'QR prize dispute'
            : category,
        priority: priority,
        title: title,
        detail: detail,
        resolved: resolved,
        evidenceNote: null,
        responseTarget: Duration(
          minutes: switch (priority) {
            ComplaintPriority.high => 240,
            ComplaintPriority.medium => 480,
            ComplaintPriority.low => 1440,
          },
        ),
        resolutionTargetWorkingDays: switch (priority) {
          ComplaintPriority.high => 2,
          ComplaintPriority.medium => 3,
          ComplaintPriority.low => 5,
        },
        raisedAt: raisedAt,
        resolutionDueAt: raisedAt.add(const Duration(days: 2)),
        firstResponseAt: respondedAt,
        resolvedAt: resolvedAt,
        events: [
          ComplaintEvent(
            title: 'Complaint raised',
            meta: 'Submitted by you.',
            state: 'done',
            occurredAt: raisedAt,
          ),
          ComplaintEvent(
            title: 'First response',
            meta: 'Crown Solar acknowledged the complaint.',
            note: 'response target met',
            state: 'done',
            occurredAt: respondedAt,
          ),
          if (resolved)
            ComplaintEvent(
              title: 'Resolved',
              meta: 'Closed by CRM.',
              state: 'done',
              occurredAt: resolvedAt,
            )
          else
            const ComplaintEvent(
              title: 'Awaiting resolution',
              state: 'active',
            ),
        ],
      );
    }

    return {
      '3004821190': [
        eventComplaint(
          reference: 'CMP-2026-5514',
          category: 'QR and prizes',
          priority: ComplaintPriority.high,
          title: 'Prize not credited for inverter scan',
          detail:
              'I scanned a Crown 8kW inverter at about 3 pm. The app showed '
              'the prize screen but nothing came into my wallet.',
          resolved: false,
          age: const Duration(hours: 3, minutes: 12),
        ),
        eventComplaint(
          reference: 'CMP-2026-5390',
          category: 'Shop branding',
          priority: ComplaintPriority.medium,
          title: 'Board installed with wrong shop name',
          detail: 'The shop name on the frontlit board is incorrect.',
          resolved: false,
          age: const Duration(days: 17),
        ),
        eventComplaint(
          reference: 'CMP-2026-5102',
          category: 'Points',
          priority: ComplaintPriority.medium,
          title: 'Points missing for August purchase',
          detail: 'No points were posted against the invoice.',
          resolved: true,
          age: const Duration(days: 30),
        ),
        eventComplaint(
          reference: 'CMP-2026-4977',
          category: 'Account and access',
          priority: ComplaintPriority.low,
          title: 'Cannot sign in on my new phone',
          detail: 'The app says my account is fixed to another device.',
          resolved: true,
          age: const Duration(days: 38),
        ),
      ],
    };
  }

  static Map<String, List<AppNotification>> _demoNotifications() {
    final now = DateTime.now();
    return {
      '3004821190': [
        AppNotification(
          id: 'mock-notification-1',
          level: 'info',
          title: 'Complaint CMP-2026-5514 raised',
          body: 'Crown Solar has your complaint.',
          destinationLabel: 'opens Complaint detail',
          destinationRoute: '/complaints/CMP-2026-5514',
          createdAt: now.subtract(const Duration(hours: 2)),
          read: false,
        ),
        AppNotification(
          id: 'mock-notification-2',
          level: 'success',
          title: 'Points complaint resolved',
          body: 'Your complaint was closed by CRM.',
          destinationLabel: 'opens Complaint detail',
          destinationRoute: '/complaints/CMP-2026-5102',
          createdAt: now.subtract(const Duration(days: 3)),
          read: true,
        ),
      ],
    };
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
