import 'package:prototype_server/data/complaints_data_store.dart';
import 'package:prototype_server/data/staff_models.dart';
import 'package:prototype_server/data/postgres_partner_data_store.dart'
    show normaliseMobile;

/// An in-memory [ComplaintsDataStore] enforcing the same rules the SQL does:
/// a ticket belongs to one partner, its targets are copied in at the moment
/// it is raised, and raising one writes both a history line and a
/// notification.
class FakeComplaintsDataStore implements ComplaintsDataStore {
  final Map<String, String> _accounts = {};
  final List<ComplaintTypeRow> _types = [];
  final Map<String, _Complaint> _complaints = {};
  final List<_Notification> _notifications = [];

  var _nextReference = 5515;
  var _nextId = 1;

  // --- Test setup ---

  /// Marks a ticket as raised by a Crown Solar Teams officer, as the Teams
  /// server's write would.
  void raisedByOfficer(String reference, RaisedByRow officer) =>
      _complaints[reference]!.raisedBy = officer;

  void addAccount(String mobileNumber) =>
      _accounts[normaliseMobile(mobileNumber)] = 'acc${_nextId++}';

  /// A category banded at every priority.
  ComplaintTypeRow addType({
    required String code,
    required String label,
    String? shortLabel,
    int responseMinutes = 240,
    int resolutionWorkingDays = 2,
  }) {
    final row = ComplaintTypeRow(
      id: 'typ${_nextId++}',
      code: code,
      label: label,
      shortLabel: shortLabel,
      targets: {
        for (final priority in const ['low', 'medium', 'high'])
          priority: ComplaintTargetRow(
            responseMinutes: responseMinutes,
            resolutionWorkingDays: resolutionWorkingDays,
          ),
      },
    );
    _types.add(row);
    return row;
  }

  void addNotification({
    required String mobileNumber,
    required String title,
    bool read = false,
  }) => _notifications.add(
    _Notification(
      id: 'ntf${_nextId++}',
      accountId: _accounts[normaliseMobile(mobileNumber)]!,
      title: title,
      readAt: read ? DateTime.now() : null,
    ),
  );

  // --- ComplaintsDataStore ---

  @override
  Future<List<ComplaintTypeRow>> catalogue() async => List.of(_types);

  @override
  Future<List<ComplaintRow>?> complaints(String mobileNumber) async {
    final accountId = _accounts[normaliseMobile(mobileNumber)];
    if (accountId == null) return null;
    return [
      for (final complaint in _complaints.values)
        if (complaint.accountId == accountId) complaint.toRow(),
    ]..sort((a, b) => b.raisedAt.compareTo(a.raisedAt));
  }

  @override
  Future<ComplaintRow?> complaint({
    required String mobileNumber,
    required String reference,
  }) async {
    final accountId = _accounts[normaliseMobile(mobileNumber)];
    final complaint = _complaints[reference];
    // Another partner's reference is not found, not forbidden.
    if (complaint == null || complaint.accountId != accountId) return null;

    return complaint.toRow(
      events: [
        const ComplaintEventRow(
          title: 'Complaint raised',
          meta: 'Submitted by you.',
          state: 'done',
        ),
        if (complaint.status == 'in_progress')
          const ComplaintEventRow(
            title: 'Awaiting resolution',
            state: 'active',
          ),
      ],
    );
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

    final accountId = _accounts[normaliseMobile(mobileNumber)];
    if (accountId == null) return (null, ComplaintRefusal.unknownAccount);

    for (final type in _types) {
      if (type.id != typeId) continue;
      final target = type.targets[priority];
      if (target == null) return (null, ComplaintRefusal.unknownType);

      final reference = 'CMP-2026-${_nextReference++}';
      _complaints[reference] = _Complaint(
        reference: reference,
        accountId: accountId,
        typeLabel: type.label,
        categoryLabel: type.shortLabel ?? type.label,
        priority: priority,
        title: title.trim(),
        detail: detail.trim(),
        // Copied in, not looked up later.
        responseTargetMinutes: target.responseMinutes,
        resolutionTargetWorkingDays: target.resolutionWorkingDays,
      );
      _notifications.add(
        _Notification(
          id: 'ntf${_nextId++}',
          accountId: accountId,
          title: 'Complaint $reference raised',
        ),
      );
      return (
        await complaint(mobileNumber: mobileNumber, reference: reference),
        null,
      );
    }
    return (null, ComplaintRefusal.unknownType);
  }

  @override
  Future<List<NotificationRow>?> notifications(String mobileNumber) async {
    final accountId = _accounts[normaliseMobile(mobileNumber)];
    if (accountId == null) return null;
    return [
      for (final item in _notifications.reversed)
        if (item.accountId == accountId)
          NotificationRow(
            id: item.id,
            level: 'info',
            title: item.title,
            body: 'body',
            createdAt: item.createdAt,
            readAt: item.readAt,
          ),
    ];
  }

  @override
  Future<int> markRead({required String mobileNumber, String? id}) async {
    final accountId = _accounts[normaliseMobile(mobileNumber)];
    var marked = 0;
    for (final item in _notifications) {
      if (item.accountId != accountId) continue;
      if (item.readAt != null) continue;
      if (id != null && item.id != id) continue;
      item.readAt = DateTime.now();
      marked++;
    }
    return marked;
  }
}

class _Complaint {
  _Complaint({
    required this.reference,
    required this.accountId,
    required this.typeLabel,
    required this.categoryLabel,
    required this.priority,
    required this.title,
    required this.detail,
    required this.responseTargetMinutes,
    required this.resolutionTargetWorkingDays,
  }) : raisedAt = DateTime.now();

  final String reference;
  final String accountId;
  final String typeLabel;
  final String categoryLabel;
  final String priority;
  final String title;
  final String detail;
  final int responseTargetMinutes;
  final int resolutionTargetWorkingDays;
  final DateTime raisedAt;
  final String status = 'in_progress';

  /// Set only for a ticket an officer raised through Crown Solar Teams.
  RaisedByRow? raisedBy;

  ComplaintRow toRow({List<ComplaintEventRow> events = const []}) =>
      ComplaintRow(
        reference: reference,
        typeLabel: typeLabel,
        categoryLabel: categoryLabel,
        priority: priority,
        title: title,
        detail: detail,
        status: status,
        responseTargetMinutes: responseTargetMinutes,
        resolutionTargetWorkingDays: resolutionTargetWorkingDays,
        raisedAt: raisedAt,
        resolutionDueAt: addWorkingDays(raisedAt, resolutionTargetWorkingDays),
        raisedBy: raisedBy,
        events: events,
      );
}

class _Notification {
  _Notification({
    required this.id,
    required this.accountId,
    required this.title,
    this.readAt,
  }) : createdAt = DateTime.now();

  final String id;
  final String accountId;
  final String title;
  final DateTime createdAt;
  DateTime? readAt;
}
