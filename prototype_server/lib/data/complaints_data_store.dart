/// One of the chips on step 1 of the complaint wizard, and what Crown Solar
/// promises for it at each priority.
///
/// There is no second, narrower choice. A partner describes their problem in
/// their own words; the category is only what routes the ticket.
class ComplaintTypeRow {
  const ComplaintTypeRow({
    required this.id,
    required this.code,
    required this.label,
    required this.targets,
    this.shortLabel,
  });

  final String id;

  /// Stable across renames. The app maps this to the design's icon, which is
  /// the one thing about a category the database does not hold: an icon is a
  /// property of the drawing, not of the data.
  final String code;

  /// What the chip says.
  final String label;

  /// What the ticket list says. Null means [label] does for both.
  final String? shortLabel;

  /// Keyed by priority: 'low' | 'medium' | 'high'.
  final Map<String, ComplaintTargetRow> targets;

  Map<String, Object?> toJson() => {
    'id': id,
    'code': code,
    'label': label,
    'shortLabel': shortLabel,
    'targets': {
      for (final entry in targets.entries) entry.key: entry.value.toJson(),
    },
  };
}

/// How long Crown Solar has to answer, and to finish.
class ComplaintTargetRow {
  const ComplaintTargetRow({
    required this.responseMinutes,
    required this.resolutionWorkingDays,
  });

  final int responseMinutes;
  final int resolutionWorkingDays;

  Map<String, Object?> toJson() => {
    'responseMinutes': responseMinutes,
    'resolutionWorkingDays': resolutionWorkingDays,
  };
}

/// One thing that happened to a ticket.
class ComplaintEventRow {
  const ComplaintEventRow({
    required this.title,
    required this.state,
    this.meta,
    this.note,
    this.occurredAt,
  });

  final String title;

  /// The narrative, with no date in it. [occurredAt] carries the time and
  /// the app formats it, so a September history does not still say "Today"
  /// in October.
  final String? meta;

  /// A trailing clause after the time, e.g. 'response target met'.
  final String? note;

  /// 'done' | 'active' | 'pending'.
  final String state;

  /// Null for a step that has not happened.
  final DateTime? occurredAt;

  Map<String, Object?> toJson() => {
    'title': title,
    'meta': meta,
    'note': note,
    'state': state,
    'occurredAt': occurredAt?.toUtc().toIso8601String(),
  };
}

/// A ticket.
///
/// The screens compute their own wording — "Met · 1 h 12 m", "Target 4 h" —
/// from these facts. Nothing here is a phrase.
class ComplaintRow {
  const ComplaintRow({
    required this.reference,
    required this.typeLabel,
    required this.categoryLabel,
    required this.priority,
    required this.title,
    required this.detail,
    required this.status,
    required this.responseTargetMinutes,
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

  /// 'low' | 'medium' | 'high'.
  final String priority;

  final String title;
  final String detail;

  /// 'in_progress' | 'resolved'.
  final String status;

  final String? evidenceNote;

  /// Copied onto the ticket when it was raised, not read through the join:
  /// a target that changes next month must not rewrite last month's promise.
  final int responseTargetMinutes;
  final int resolutionTargetWorkingDays;

  final DateTime raisedAt;

  /// [raisedAt] plus the resolution target, counted in working days.
  final DateTime resolutionDueAt;

  final DateTime? firstResponseAt;
  final DateTime? resolvedAt;

  /// Empty on the list; filled on the detail.
  final List<ComplaintEventRow> events;

  Map<String, Object?> toJson() => {
    'reference': reference,
    'typeLabel': typeLabel,
    'categoryLabel': categoryLabel,
    'priority': priority,
    'title': title,
    'detail': detail,
    'status': status,
    'evidenceNote': evidenceNote,
    'responseTargetMinutes': responseTargetMinutes,
    'resolutionTargetWorkingDays': resolutionTargetWorkingDays,
    'raisedAt': raisedAt.toUtc().toIso8601String(),
    'resolutionDueAt': resolutionDueAt.toUtc().toIso8601String(),
    'firstResponseAt': firstResponseAt?.toUtc().toIso8601String(),
    'resolvedAt': resolvedAt?.toUtc().toIso8601String(),
    'events': [for (final event in events) event.toJson()],
  };
}

/// One line in the notification centre.
class NotificationRow {
  const NotificationRow({
    required this.id,
    required this.level,
    required this.title,
    required this.body,
    required this.createdAt,
    this.destinationLabel,
    this.destinationRoute,
    this.readAt,
  });

  final String id;

  /// 'info' | 'success' | 'warning' | 'critical'.
  final String level;

  final String title;
  final String body;

  /// What tapping does, in words ('opens Ledger entry'), and where it goes.
  /// The route is null where that destination is not built: the row still
  /// says where it would lead rather than pretending to navigate.
  final String? destinationLabel;
  final String? destinationRoute;

  final DateTime createdAt;
  final DateTime? readAt;

  Map<String, Object?> toJson() => {
    'id': id,
    'level': level,
    'title': title,
    'body': body,
    'destinationLabel': destinationLabel,
    'destinationRoute': destinationRoute,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'read': readAt != null,
  };
}

/// Why a complaint could not be raised.
enum ComplaintRefusal {
  /// No account on that number.
  unknownAccount,

  /// No such category, or a priority outside low/medium/high.
  unknownType,

  /// A title or a detail that is empty.
  incomplete,
}

/// Complaints and notifications' persistence boundary.
abstract interface class ComplaintsDataStore {
  /// The categories and the targets the wizard offers.
  Future<List<ComplaintTypeRow>> catalogue();

  /// This partner's tickets, newest first. Both tabs in one call — the list
  /// screen needs the counts for its tab labels either way.
  Future<List<ComplaintRow>?> complaints(String mobileNumber);

  /// One ticket with its history. Scoped to the partner, so a reference
  /// guessed from another account's notification returns nothing.
  Future<ComplaintRow?> complaint({
    required String mobileNumber,
    required String reference,
  });

  /// Raises a ticket and returns it, or says why not.
  Future<(ComplaintRow?, ComplaintRefusal?)> raiseComplaint({
    required String mobileNumber,
    required String typeId,
    required String priority,
    required String title,
    required String detail,
  });

  /// This partner's notifications, newest first.
  Future<List<NotificationRow>?> notifications(String mobileNumber);

  /// Marks one read, or every one when [id] is null. Returns the number of
  /// rows that were still unread.
  Future<int> markRead({required String mobileNumber, String? id});
}

/// [from] plus [days] working days.
///
/// Sunday is the only day skipped: Crown Solar's own support hours are
/// Monday to Saturday, so counting Saturday as a working day is what the
/// partner is actually promised.
DateTime addWorkingDays(DateTime from, int days) {
  var result = from;
  var remaining = days;
  while (remaining > 0) {
    result = result.add(const Duration(days: 1));
    if (result.weekday != DateTime.sunday) remaining--;
  }
  return result;
}
