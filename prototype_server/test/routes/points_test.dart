import 'package:prototype_server/data/points_data_store.dart';
import 'package:prototype_server/router.dart';
import 'package:test/test.dart';

import '../support/fake_auth_data_store.dart';
import '../support/fake_points_data_store.dart';
import '../support/request_helpers.dart';

void main() {
  late FakePointsDataStore points;
  late FakeAuthDataStore auth;

  /// A retailer, a wholesaler and a distributor — the three roles that hold
  /// points. And an installer, who holds none.
  const alNoor = '3007781204';
  const hamza = '3014429911';
  const ravi = '3028890143';
  const adnan = '3004821190';

  setUp(() {
    points = FakePointsDataStore();
    auth = FakeAuthDataStore();

    points
      ..addAccount(
        mobileNumber: alNoor,
        role: 'retailer',
        name: 'Al-Noor Electric Store',
      )
      ..addAccount(
        mobileNumber: hamza,
        role: 'wholesaler',
        name: 'Hamza Solar House',
      )
      ..addAccount(
        mobileNumber: ravi,
        role: 'distributor',
        name: 'Ravi Distribution Co.',
      )
      ..addAccount(
        mobileNumber: adnan,
        role: 'installer',
        name: 'Adnan Solar Works',
      );

    // The trading roles may exchange points. Installers appear in no rule,
    // which is the whole reason they are kept out.
    for (final from in const ['retailer', 'wholesaler', 'distributor']) {
      for (final to in const ['retailer', 'wholesaler', 'distributor']) {
        points.allow(from: from, to: to);
      }
    }

    points.accrue(mobileNumber: alNoor, amount: 182400);
  });

  dynamic router() => buildRouter(auth, points: points);

  Future<Map<String, dynamic>> send({
    String from = alNoor,
    String to = hamza,
    int amount = 12000,
  }) => postJson(router(), '/points/transfers', {
    'fromMobileNumber': from,
    'toMobileNumber': to,
    'amount': amount,
  });

  group('the ledger', () {
    test('carries the balance it is derived from', () async {
      final body =
          (await getJson(
                router(),
                '/points/ledger?mobileNumber=$alNoor',
              ))['body']
              as Map;

      expect(body['balance'], 182400);
      expect((body['entries'] as List).length, 1);
      expect(body['canSend'], isTrue);
    });

    test('every line says the balance it left behind', () async {
      await send(amount: 12000);

      final entries =
          ((await getJson(
                    router(),
                    '/points/ledger?mobileNumber=$alNoor',
                  ))['body']
                  as Map)['entries']
              as List;

      expect((entries.first as Map)['balanceAfter'], 170400);
      expect((entries.last as Map)['balanceAfter'], 182400);
    });

    test('an unknown number has no ledger', () async {
      final result = await getJson(
        router(),
        '/points/ledger?mobileNumber=3001112222',
      );
      expect(result['statusCode'], 404);
    });
  });

  group('who may be sent points', () {
    test('installers never appear — they hold no points', () async {
      final body =
          (await getJson(
                router(),
                '/points/recipients?mobileNumber=$alNoor',
              ))['body']
              as Map;
      final numbers = (body['recipients'] as List)
          .map((r) => (r as Map)['mobileNumber'])
          .toList();

      expect(numbers, containsAll([hamza, ravi]));
      expect(numbers, isNot(contains(adnan)));
    });

    test('someone who cannot receive is not offered', () async {
      points.restrict(mobileNumber: hamza, canReceive: false);

      final body =
          (await getJson(
                router(),
                '/points/recipients?mobileNumber=$alNoor',
              ))['body']
              as Map;
      final numbers = (body['recipients'] as List)
          .map((r) => (r as Map)['mobileNumber'])
          .toList();

      expect(
        numbers,
        isNot(contains(hamza)),
        reason: 'offering someone and then refusing them wastes the attempt',
      );
    });

    test('a lookup answers only about a permitted recipient', () async {
      final permitted = await getJson(
        router(),
        '/points/recipients/lookup?mobileNumber=$alNoor&number=$hamza',
      );
      final installer = await getJson(
        router(),
        '/points/recipients/lookup?mobileNumber=$alNoor&number=$adnan',
      );

      expect(permitted['statusCode'], 200);
      expect(installer['statusCode'], 404);
    });
  });

  group('sending points', () {
    test('arrives at once, with no approval step', () async {
      final result = await send(amount: 12000);
      expect(result['statusCode'], 201);

      final theirs =
          (await getJson(
                router(),
                '/points/ledger?mobileNumber=$hamza',
              ))['body']
              as Map;

      expect(
        theirs['balance'],
        12000,
        reason: 'points are with the receiver immediately, unlike cash',
      );
      expect(((theirs['entries'] as List).first as Map)['type'], 'transfer_in');
    });

    test('both legs share one reference', () async {
      final sent = (await send())['body'] as Map;
      final reference = (sent['entry'] as Map)['reference'];

      final theirs =
          ((await getJson(
                    router(),
                    '/points/ledger?mobileNumber=$hamza',
                  ))['body']
                  as Map)['entries']
              as List;

      expect((theirs.first as Map)['reference'], reference);
    });

    test('refuses more than the balance, and says what is held', () async {
      final result = await send(amount: 200000);

      expect(result['statusCode'], 400);
      expect((result['body'] as Map)['error'], 'not_enough_points');
      expect((result['body'] as Map)['balance'], 182400);
    });

    test('refuses a pair the team has not permitted', () async {
      final result = await send(to: adnan);

      expect(result['statusCode'], 403);
      expect((result['body'] as Map)['error'], 'pair_not_permitted');
    });

    test('refuses a restricted sender', () async {
      points.restrict(mobileNumber: alNoor, canSend: false);

      final result = await send();
      expect((result['body'] as Map)['error'], 'sender_restricted');
    });

    test('refuses a restricted recipient', () async {
      points.restrict(mobileNumber: hamza, canReceive: false);

      final result = await send();
      expect((result['body'] as Map)['error'], 'recipient_restricted');
    });

    test('refuses sending to yourself', () async {
      final result = await send(to: alNoor);
      expect((result['body'] as Map)['error'], 'self');
    });

    test('refuses zero and negative amounts', () async {
      expect(
        ((await send(amount: 0))['body'] as Map)['error'],
        'amount_not_positive',
      );
      expect(
        ((await send(amount: -5))['body'] as Map)['error'],
        'amount_not_positive',
      );
    });

    test('a restricted sender still sees their balance', () async {
      points.restrict(
        mobileNumber: alNoor,
        canSend: false,
        reason: 'Under review',
      );

      final body =
          (await getJson(
                router(),
                '/points/ledger?mobileNumber=$alNoor',
              ))['body']
              as Map;

      expect(body['canSend'], isFalse);
      expect(body['restrictionReason'], 'Under review');
      expect(
        body['balance'],
        182400,
        reason: 'a partner is always entitled to see their own record',
      );
    });
  });

  group('targets', () {
    test(
      'a partner with no scheme has none, and that is its own state',
      () async {
        final body =
            (await getJson(
                  router(),
                  '/points/targets?mobileNumber=$ravi',
                ))['body']
                as Map;

        expect(body['schemeName'], isNull);
        expect((body['periods'] as List), isEmpty);
        expect(body['annual'], isNull);
      },
    );

    test('the breakdown adds up to what was scored', () async {
      points.addScheme(
        mobileNumber: alNoor,
        name: 'Retailer Scheme 2026',
        periods: [
          PointTargetRow(
            kind: 'period',
            label: 'Sep — Dec 2026',
            targetPoints: 400000,
            scoredPoints: 182400,
            startsOn: DateTime(2026, 9),
            endsOn: DateTime(2026, 12, 31),
          ),
        ],
      );
      await send(amount: 12000);

      final body =
          (await getJson(
                router(),
                '/points/targets?mobileNumber=$alNoor',
              ))['body']
              as Map;
      final breakdown = body['breakdown'] as Map;

      expect(breakdown['purchases'], 182400);
      expect(
        breakdown['transferredIn'],
        0,
        reason: 'points sent out are not points that arrived',
      );
    });

    test('points sent out do not count toward the receiver twice', () async {
      points.addScheme(
        mobileNumber: hamza,
        name: 'Wholesaler Scheme 2026',
        periods: const [],
      );
      await send(amount: 12000);

      final body =
          (await getJson(
                router(),
                '/points/targets?mobileNumber=$hamza',
              ))['body']
              as Map;
      final breakdown = body['breakdown'] as Map;

      expect(breakdown['transferredIn'], 12000);
      expect(
        breakdown['purchases'],
        0,
        reason: 'a transfer in is not a purchase of their own',
      );
    });
  });
}
