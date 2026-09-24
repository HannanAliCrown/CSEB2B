import 'package:prototype_server/data/complaints_data_store.dart';
import 'package:prototype_server/data/staff_models.dart';
import 'package:prototype_server/router.dart';
import 'package:test/test.dart';

import '../support/fake_auth_data_store.dart';
import '../support/fake_complaints_data_store.dart';
import '../support/request_helpers.dart';

void main() {
  late FakeComplaintsDataStore complaints;
  late FakeAuthDataStore auth;
  late ComplaintTypeRow prizeType;

  const adnan = '3004821190';
  const someoneElse = '3009990000';

  setUp(() {
    complaints = FakeComplaintsDataStore();
    auth = FakeAuthDataStore();
    complaints.addAccount(adnan);
    complaints.addAccount(someoneElse);
    prizeType = complaints.addType(
      code: 'qr_and_prizes',
      label: 'QR and prizes',
      shortLabel: 'QR prize dispute',
    );
  });

  dynamic router() => buildRouter(auth, complaints: complaints);

  Future<Map<String, dynamic>> raise({
    String mobileNumber = adnan,
    String? typeId,
    String priority = 'high',
    String title = 'Prize not credited for inverter scan',
    String detail = 'The app showed the prize screen but nothing arrived.',
  }) => postJson(router(), '/complaints', {
    'mobileNumber': mobileNumber,
    'typeId': typeId ?? prizeType.id,
    'priority': priority,
    'title': title,
    'detail': detail,
  });

  group('the catalogue', () {
    test('carries each category and its targets per priority', () async {
      final body =
          (await getJson(router(), '/complaints/catalogue'))['body'] as Map;
      final type = (body['types'] as List).single as Map;

      expect(type['label'], 'QR and prizes');
      expect(type['shortLabel'], 'QR prize dispute');

      final high = (type['targets'] as Map)['high'] as Map;
      expect(high['responseMinutes'], 240);
      expect(high['resolutionWorkingDays'], 2);
    });

    test('is not swallowed by the reference route', () async {
      final result = await getJson(router(), '/complaints/catalogue');
      expect(
        result['statusCode'],
        200,
        reason: '/complaints/<reference> must not match "catalogue"',
      );
    });
  });

  group('raising one', () {
    test('answers with the ticket, its reference and its targets', () async {
      final result = await raise();
      final body = result['body'] as Map;

      expect(result['statusCode'], 201);
      expect(body['reference'], startsWith('CMP-'));
      expect(body['status'], 'in_progress');
      expect(body['responseTargetMinutes'], 240);
      expect(body['resolutionTargetWorkingDays'], 2);
    });

    test('states a resolution date, not just a number of days', () async {
      final body = (await raise())['body'] as Map;
      final raised = DateTime.parse(body['raisedAt'] as String);
      final due = DateTime.parse(body['resolutionDueAt'] as String);

      expect(due.isAfter(raised), isTrue);
      expect(
        due.weekday,
        isNot(DateTime.sunday),
        reason: 'a working-day target must not land on a non-working day',
      );
    });

    test('opens the history with the step that just happened', () async {
      final body = (await raise())['body'] as Map;
      final events = body['events'] as List;

      expect((events.first as Map)['title'], 'Complaint raised');
      expect(
        (events.last as Map)['state'],
        'active',
        reason: 'the step being waited on is shown while it is open',
      );
    });

    test('tells the partner, because the review screen promised it', () async {
      await raise();

      final body =
          (await getJson(
                router(),
                '/notifications?mobileNumber=$adnan',
              ))['body']
              as Map;
      final titles = (body['notifications'] as List)
          .map((n) => (n as Map)['title'])
          .toList();

      expect(titles.first, startsWith('Complaint CMP-'));
      expect(body['unread'], 1);
    });

    test('refuses an empty title or detail', () async {
      expect((await raise(title: '   '))['statusCode'], 400);
      expect((await raise(detail: ''))['statusCode'], 400);
    });

    test('refuses a priority the category has no target for', () async {
      final result = await raise(priority: 'urgent');
      expect(result['statusCode'], 400);
      expect((result['body'] as Map)['error'], 'unknown_type');
    });

    test('refuses an unknown number', () async {
      expect((await raise(mobileNumber: '3001112222'))['statusCode'], 404);
    });
  });

  group('the list', () {
    test('counts each tab, and shows only your own tickets', () async {
      await raise();
      await raise(title: 'Second complaint');
      await raise(mobileNumber: someoneElse, title: 'Not yours');

      final body =
          (await getJson(router(), '/complaints?mobileNumber=$adnan'))['body']
              as Map;

      expect((body['complaints'] as List).length, 2);
      expect(body['inProgress'], 2);
      expect(body['resolved'], 0);
    });

    test('an unknown number has no list', () async {
      final result = await getJson(
        router(),
        '/complaints?mobileNumber=3001112222',
      );
      expect(result['statusCode'], 404);
    });
  });

  group('one ticket', () {
    test("another partner's reference is not found, not forbidden", () async {
      final reference = ((await raise())['body'] as Map)['reference'] as String;

      final mine = await getJson(
        router(),
        '/complaints/$reference?mobileNumber=$adnan',
      );
      final theirs = await getJson(
        router(),
        '/complaints/$reference?mobileNumber=$someoneElse',
      );

      expect(mine['statusCode'], 200);
      expect(
        theirs['statusCode'],
        404,
        reason: '403 would confirm the ticket exists',
      );
    });

    test('names the officer only when an officer raised it', () async {
      final reference = ((await raise())['body'] as Map)['reference'] as String;
      final path = '/complaints/$reference?mobileNumber=$adnan';

      final own = (await getJson(router(), path))['body'] as Map;
      expect(own['raisedBy'], isNull, reason: 'the partner raised it');

      complaints.raisedByOfficer(
        reference,
        const RaisedByRow(name: 'Imran Aslam', role: 'mo'),
      );
      final officer = (await getJson(router(), path))['body'] as Map;
      expect(officer['raisedBy'], {'name': 'Imran Aslam', 'role': 'mo'});

      final list =
          (await getJson(router(), '/complaints?mobileNumber=$adnan'))['body']
              as Map;
      expect((list['complaints'] as List).single['raisedBy'], isNotNull);
    });
  });

  group('notifications', () {
    test('mark one read without touching the rest', () async {
      complaints.addNotification(mobileNumber: adnan, title: 'First');
      complaints.addNotification(mobileNumber: adnan, title: 'Second');

      final list =
          (await getJson(
                router(),
                '/notifications?mobileNumber=$adnan',
              ))['body']
              as Map;
      final id = ((list['notifications'] as List).first as Map)['id'];

      final marked = await postJson(router(), '/notifications/read', {
        'mobileNumber': adnan,
        'id': id,
      });
      final after =
          (await getJson(
                router(),
                '/notifications?mobileNumber=$adnan',
              ))['body']
              as Map;

      expect((marked['body'] as Map)['marked'], 1);
      expect(after['unread'], 1);
    });

    test('mark every one read when no id is given', () async {
      complaints.addNotification(mobileNumber: adnan, title: 'First');
      complaints.addNotification(mobileNumber: adnan, title: 'Second');
      complaints.addNotification(mobileNumber: someoneElse, title: 'Theirs');

      await postJson(router(), '/notifications/read', {'mobileNumber': adnan});

      final mine =
          (await getJson(
                router(),
                '/notifications?mobileNumber=$adnan',
              ))['body']
              as Map;
      final theirs =
          (await getJson(
                router(),
                '/notifications?mobileNumber=$someoneElse',
              ))['body']
              as Map;

      expect(mine['unread'], 0);
      expect(
        theirs['unread'],
        1,
        reason: 'reading your own list must not read anyone else\'s',
      );
    });

    test('already-read rows are not marked twice', () async {
      complaints.addNotification(
        mobileNumber: adnan,
        title: 'Seen',
        read: true,
      );

      final result = await postJson(router(), '/notifications/read', {
        'mobileNumber': adnan,
      });
      expect((result['body'] as Map)['marked'], 0);
    });
  });

  group('working days', () {
    test('skip Sunday, because Crown Solar works Monday to Saturday', () {
      // A Friday plus two working days is the following Monday: Saturday
      // counts, Sunday does not.
      final friday = DateTime(2026, 9, 18);
      expect(friday.weekday, DateTime.friday);

      final due = addWorkingDays(friday, 2);
      expect(due, DateTime(2026, 9, 21));
      expect(due.weekday, DateTime.monday);
    });
  });
}
