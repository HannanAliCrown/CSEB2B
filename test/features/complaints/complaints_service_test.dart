import 'package:cse_b2b/features/complaints/data/complaints_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// A ticket built from the shape the server actually sends, so a change to
/// either side shows up here.
Complaint complaintJson({
  required DateTime raisedAt,
  DateTime? firstResponseAt,
  DateTime? resolvedAt,
  String status = 'in_progress',
  int responseTargetMinutes = 240,
  int resolutionWorkingDays = 2,
  Map<String, dynamic>? raisedBy,
}) => Complaint.fromJson({
  'reference': 'CMP-2026-5514',
  'typeLabel': 'QR and prizes',
  'categoryLabel': 'QR prize dispute',
  'priority': 'high',
  'title': 'Prize not credited for inverter scan',
  'detail': 'The app showed the prize screen but nothing arrived.',
  'status': status,
  'evidenceNote': null,
  'responseTargetMinutes': responseTargetMinutes,
  'resolutionTargetWorkingDays': resolutionWorkingDays,
  'raisedAt': raisedAt.toUtc().toIso8601String(),
  'resolutionDueAt': raisedAt
      .add(Duration(days: resolutionWorkingDays))
      .toUtc()
      .toIso8601String(),
  'firstResponseAt': firstResponseAt?.toUtc().toIso8601String(),
  'resolvedAt': resolvedAt?.toUtc().toIso8601String(),
  'events': const [],
  'raisedBy': raisedBy,
});

void main() {
  group('response targets', () {
    test('an answer inside the window is met', () {
      final raised = DateTime.now().subtract(const Duration(hours: 3));
      final complaint = complaintJson(
        raisedAt: raised,
        firstResponseAt: raised.add(const Duration(hours: 1, minutes: 12)),
      );

      expect(complaint.responseMet, isTrue);
      expect(formatDuration(complaint.responseTook!), '1 h 12 m');
    });

    test('an answer outside it is not, however late the screen is read', () {
      final raised = DateTime.now().subtract(const Duration(days: 2));
      final complaint = complaintJson(
        raisedAt: raised,
        firstResponseAt: raised.add(const Duration(hours: 9)),
      );

      expect(
        complaint.responseMet,
        isFalse,
        reason: 'the verdict is fixed by when the answer came, not by now',
      );
    });

    test('an unanswered ticket is only overdue once the window passes', () {
      final fresh = complaintJson(
        raisedAt: DateTime.now().subtract(const Duration(hours: 1)),
      );
      final stale = complaintJson(
        raisedAt: DateTime.now().subtract(const Duration(hours: 9)),
      );

      expect(fresh.responseOverdue, isFalse);
      expect(stale.responseOverdue, isTrue);
    });
  });

  group('resolution', () {
    test('a resolved ticket is never overdue', () {
      final raised = DateTime.now().subtract(const Duration(days: 30));
      final complaint = complaintJson(
        raisedAt: raised,
        status: 'resolved',
        resolvedAt: raised.add(const Duration(days: 1)),
      );

      expect(complaint.resolved, isTrue);
      expect(
        complaint.resolutionOverdue,
        isFalse,
        reason: 'a closed ticket cannot go on being late',
      );
    });
  });

  group('the history line', () {
    test('joins narrative, time and verdict, skipping what is absent', () {
      final at = DateTime.now().subtract(const Duration(hours: 2));
      final full = ComplaintEvent(
        title: 'First response',
        meta: '"We are checking both scans."',
        note: 'response target met',
        state: 'done',
        occurredAt: at,
      );
      const bare = ComplaintEvent(
        title: 'Awaiting resolution',
        state: 'active',
      );

      expect(
        full.line,
        '"We are checking both scans." · ${formatWhen(at)} · '
        'response target met',
      );
      expect(bare.line, isNull);
      expect(bare.active, isTrue);
    });

    test('a time is never stored as a word', () {
      // The same instant read on the day and read later must not both say
      // "Today" — which is why the line is composed here and not in SQL.
      final today = DateTime.now().subtract(const Duration(hours: 1));
      final older = DateTime.now().subtract(const Duration(days: 9));

      expect(formatWhen(today), startsWith('Today, '));
      expect(formatWhen(older), isNot(contains('Today')));
      expect(
        formatWhen(DateTime.now().subtract(const Duration(days: 1))),
        'Yesterday',
      );
    });
  });

  group('durations', () {
    test('read short on a card and long in a sentence', () {
      expect(formatDuration(const Duration(hours: 4)), '4 h');
      expect(formatDuration(const Duration(minutes: 45)), '45 m');
      expect(formatDurationWords(const Duration(hours: 4)), '4 hours');
      expect(formatDurationWords(const Duration(hours: 1)), '1 hour');
      expect(formatDurationWords(const Duration(minutes: 45)), '45 minutes');
    });
  });

  group('raised by', () {
    test('names the officer and role when an officer raised it', () {
      final complaint = complaintJson(
        raisedAt: DateTime(2026, 9, 24, 9),
        raisedBy: {'name': 'Imran Aslam', 'role': 'mo'},
      );

      expect(complaint.raisedBy?.name, 'Imran Aslam');
      expect(complaint.raisedBy?.roleLabel, 'Marketing Officer');
    });

    test('is absent when the partner raised it', () {
      final complaint = complaintJson(raisedAt: DateTime(2026, 9, 24, 9));

      expect(complaint.raisedBy, isNull);
    });
  });

  group('the notification line', () {
    test('says when it happened and where it goes', () {
      final notification = AppNotification.fromJson({
        'id': 'n1',
        'level': 'info',
        'title': 'Cash request expired and returned',
        'body': 'PKR 4,000 came back to your wallet.',
        'destinationLabel': 'opens Ledger entry',
        'destinationRoute': '/wallet/ledger',
        'createdAt': DateTime.now()
            .subtract(const Duration(days: 9))
            .toUtc()
            .toIso8601String(),
        'read': false,
      });

      expect(notification.timestampLine, endsWith(' · opens Ledger entry'));
      expect(
        notification.destinationName,
        'Ledger entry',
        reason:
            'a sentence with its own verb must not read "opens Ledger '
            'entry is not built yet"',
      );
      expect(notification.read, isFalse);
    });

    test('one with nowhere to go still reads correctly', () {
      final notification = AppNotification.fromJson({
        'id': 'n2',
        'level': 'info',
        'title': 'Prize held for review',
        'body': 'Your claim is with CRM.',
        'destinationLabel': null,
        'destinationRoute': null,
        'createdAt': DateTime.now()
            .subtract(const Duration(days: 1))
            .toUtc()
            .toIso8601String(),
        'read': true,
      });

      expect(notification.timestampLine, 'Yesterday');
      expect(notification.destinationRoute, isNull);
      expect(notification.destinationName, 'That screen');
    });
  });
}
