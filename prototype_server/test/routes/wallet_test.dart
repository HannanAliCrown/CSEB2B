import 'package:prototype_server/data/wallet_data_store.dart';
import 'package:prototype_server/router.dart';
import 'package:test/test.dart';

import '../support/fake_auth_data_store.dart';
import '../support/fake_scan_data_store.dart';
import '../support/fake_wallet_data_store.dart';
import '../support/request_helpers.dart';

void main() {
  late FakeWalletDataStore wallet;
  late FakeScanDataStore scan;
  late FakeAuthDataStore auth;

  /// An installer, who can send cash but never receive it.
  const adnan = '3004821190';

  /// A retailer and a wholesaler, both of whom can.
  const alNoor = '3007781204';
  const hamza = '3008890011';

  setUp(() {
    wallet = FakeWalletDataStore();
    scan = FakeScanDataStore();
    auth = FakeAuthDataStore();

    wallet.addAccount(
      mobileNumber: adnan,
      role: 'installer',
      name: 'Adnan Solar Works',
    );
    wallet.addAccount(
      mobileNumber: alNoor,
      role: 'retailer',
      name: 'Al-Noor Electric Store',
    );
    wallet.addAccount(
      mobileNumber: hamza,
      role: 'wholesaler',
      name: 'Hamza Solar House',
    );
    wallet.credit(mobileNumber: adnan, amountPaisa: 1850000);
  });

  dynamic router() => buildRouter(auth, wallet: wallet, scan: scan);

  Future<Map<String, dynamic>> send({
    String from = adnan,
    String to = alNoor,
    int amountPaisa = 300000,
  }) => postJson(router(), '/wallet/transfers', {
    'fromMobileNumber': from,
    'toMobileNumber': to,
    'amountPaisa': amountPaisa,
  });

  group('the ledger', () {
    test('carries the totals it is derived from', () async {
      final body =
          (await getJson(
                router(),
                '/wallet/ledger?mobileNumber=$adnan',
              ))['body']
              as Map;

      expect((body['entries'] as List).length, 1);
      expect(body['availablePaisa'], 1850000);
      expect(body['heldPaisa'], 0);
    });

    test('an unknown number has no ledger', () async {
      final result = await getJson(
        router(),
        '/wallet/ledger?mobileNumber=3001112222',
      );
      expect(result['statusCode'], 404);
    });
  });

  group('who can be paid', () {
    test('installers are never recipients — cash moves up the chain', () async {
      final body =
          (await getJson(
                router(),
                '/wallet/recipients?mobileNumber=$alNoor',
              ))['body']
              as Map;
      final numbers = (body['recipients'] as List)
          .map((r) => (r as Map)['mobileNumber'])
          .toList();

      expect(numbers, contains(hamza));
      expect(
        numbers,
        isNot(contains(adnan)),
        reason: 'a retailer cannot pay an installer',
      );
    });

    test('looking up an installer finds nobody to pay', () async {
      final result = await getJson(
        router(),
        '/wallet/recipients/lookup?mobileNumber=$adnan',
      );
      expect(result['statusCode'], 404);
    });
  });

  group('sending cash', () {
    test('leaves the available balance at once, and is held', () async {
      final sent = await send();
      expect(sent['statusCode'], 201);
      expect((sent['body'] as Map)['held'], isTrue);
      expect(((sent['body'] as Map)['entry'] as Map)['state'], 'held');

      final after =
          (await getJson(
                router(),
                '/wallet/ledger?mobileNumber=$adnan',
              ))['body']
              as Map;

      expect(
        after['availablePaisa'],
        1550000,
        reason: 'money sent is gone from what can be spent, not still there',
      );
      expect(after['heldPaisa'], 300000);
    });

    test('writes nothing to the receiver until they accept', () async {
      await send();

      final theirs =
          (await getJson(
                router(),
                '/wallet/ledger?mobileNumber=$alNoor',
              ))['body']
              as Map;

      expect((theirs['entries'] as List), isEmpty);
      expect(theirs['availablePaisa'], 0);
    });

    test('refuses more than the balance covers', () async {
      final result = await send(amountPaisa: 99000000);
      expect(result['statusCode'], 400);
      expect((result['body'] as Map)['error'], 'not_enough_balance');
    });

    test('refuses less than the minimum, and names it', () async {
      final result = await send(amountPaisa: 5000);
      expect(result['statusCode'], 400);
      expect((result['body'] as Map)['error'], 'amount_too_small');
      expect((result['body'] as Map)['minimumPaisa'], minimumTransferPaisa);
    });

    test('refuses sending to yourself', () async {
      final result = await send(from: alNoor, to: alNoor);
      expect((result['body'] as Map)['error'], 'self');
    });

    test('refuses a recipient who cannot receive cash', () async {
      final result = await send(from: alNoor, to: adnan);
      expect(result['statusCode'], 404);
      expect((result['body'] as Map)['error'], 'unknown_recipient');
    });

    test('a balance spent twice is only spendable once', () async {
      // 1,850,000 paisa in hand: the first goes through, the second cannot.
      final first = await send(amountPaisa: 1000000);
      final second = await send(amountPaisa: 1000000);

      expect(first['statusCode'], 201);
      expect(second['statusCode'], 400);
      expect((second['body'] as Map)['error'], 'not_enough_balance');
    });
  });

  group('the cash request inbox', () {
    /// The inbox as the receiver sees it.
    Future<Map<String, dynamic>> inbox([String number = alNoor]) async =>
        (await getJson(
              router(),
              '/wallet/cash-requests?mobileNumber=$number',
            ))['body']
            as Map<String, dynamic>;

    /// The reference of the single transfer waiting on them.
    Future<String> waitingReference() async =>
        ((await inbox())['requests'] as List).single['reference'] as String;

    Future<Map<String, dynamic>> decide({
      required String reference,
      required bool approved,
      String mobileNumber = alNoor,
    }) => postJson(router(), '/wallet/cash-requests/decision', {
      'mobileNumber': mobileNumber,
      'reference': reference,
      'approved': approved,
    });

    Future<Map<String, dynamic>> ledgerOf(String number) async =>
        (await getJson(router(), '/wallet/ledger?mobileNumber=$number'))['body']
            as Map<String, dynamic>;

    test('lists what is waiting on this partner', () async {
      await send(from: adnan, to: alNoor, amountPaisa: 250000);

      final body = await inbox();
      final request = (body['requests'] as List).single as Map;

      expect(body['waiting'], 1);
      expect(request['fromName'], 'Adnan Solar Works');
      expect(request['fromRole'], 'Installer');
      expect(request['state'], 'held');
    });

    test('approving moves the held money into this wallet', () async {
      await send(from: adnan, to: alNoor, amountPaisa: 250000);

      final decided = await decide(
        reference: await waitingReference(),
        approved: true,
      );
      expect(decided['statusCode'], 200);

      expect((await ledgerOf(alNoor))['availablePaisa'], 250000);
      expect(
        (await ledgerOf(adnan))['heldPaisa'],
        0,
        reason: 'settled money is no longer held',
      );
    });

    test('rejecting gives it back to the sender', () async {
      await send(from: adnan, to: alNoor, amountPaisa: 250000);
      await decide(reference: await waitingReference(), approved: false);

      expect(
        (await ledgerOf(alNoor))['availablePaisa'],
        0,
        reason: 'nothing arrived',
      );
      expect(
        (await ledgerOf(adnan))['availablePaisa'],
        1850000,
        reason: 'the money is back where it started',
      );
      expect((await ledgerOf(adnan))['heldPaisa'], 0);
    });

    test('deciding twice changes nothing the second time', () async {
      await send(from: adnan, to: alNoor, amountPaisa: 250000);
      final reference = await waitingReference();

      await decide(reference: reference, approved: true);
      final again = await decide(reference: reference, approved: false);

      expect(again['statusCode'], 404);
      expect(
        (await ledgerOf(alNoor))['availablePaisa'],
        250000,
        reason: 'a second verdict must not undo the first',
      );
    });

    test('nobody can decide a transfer that is not theirs', () async {
      await send(from: adnan, to: alNoor, amountPaisa: 250000);

      final result = await decide(
        reference: await waitingReference(),
        approved: true,
        mobileNumber: hamza,
      );

      expect(
        result['statusCode'],
        404,
        reason: '403 would confirm the transfer exists',
      );
    });
  });

  group('scanning', () {
    setUp(() {
      scan
        ..addAccount(mobileNumber: adnan, role: 'installer')
        ..addAccount(mobileNumber: hamza, role: 'wholesaler')
        ..addProduct(code: 'CS-INV-8841', winsPrize: true)
        ..addProduct(code: 'CS-PNL-2207')
        ..addProduct(code: 'CS-BAT-7788', blocked: true)
        ..addProduct(code: 'CS-NEW-0001', unassigned: true)
        ..addPrizeBand(role: 'installer', amountPaisa: 50000);
    });

    Future<Map<String, dynamic>> check({
      String code = 'CS-INV-8841',
      String mobileNumber = adnan,
      bool claim = false,
    }) => postJson(router(), '/scan', {
      'code': code,
      'mobileNumber': mobileNumber,
      'claim': claim,
    });

    test('an authenticity check takes no claim', () async {
      final body = (await check())['body'] as Map;

      expect(body['verdict'], 'genuine');
      expect(body['prizePaisa'], isNull);
      expect(
        scan.hasClaim(code: 'CS-INV-8841', role: 'installer'),
        isFalse,
        reason: 'checking stock on a shelf must not burn its prize',
      );
    });

    test('claiming pays the band for that role', () async {
      final body = (await check(claim: true))['body'] as Map;
      expect(body['prizePaisa'], 50000);
    });

    test('a genuine code that pays nothing still spends the claim', () async {
      final body =
          (await check(code: 'CS-PNL-2207', claim: true))['body'] as Map;

      expect(body['verdict'], 'genuine');
      expect(body['prizePaisa'], isNull);
      expect(scan.hasClaim(code: 'CS-PNL-2207', role: 'installer'), isTrue);
    });

    test('a code not yet assigned to a product pays nothing', () async {
      final body =
          (await check(code: 'CS-NEW-0001', claim: true))['body'] as Map;

      expect(body['verdict'], 'unassigned');
      expect(body['product'], isNull);
      expect(body['prizePaisa'], isNull);
      expect(scan.hasClaim(code: 'CS-NEW-0001', role: 'installer'), isFalse);
    });

    test('a second installer on the same code is turned away', () async {
      await check(claim: true);
      final again = (await check(claim: true))['body'] as Map;

      expect(again['verdict'], 'already_scanned');
      expect((again['claim'] as Map)['role'], 'Installer');
    });

    test('a role with no band cannot win, and takes no claim', () async {
      final body =
          (await check(mobileNumber: hamza, claim: true))['body'] as Map;

      expect(body['verdict'], 'genuine');
      expect(body['prizePaisa'], isNull);
      expect(
        scan.hasClaim(code: 'CS-INV-8841', role: 'wholesaler'),
        isFalse,
        reason: 'a wholesaler must never use up a code an installer is owed',
      );
    });

    test('a blocked batch is refused but still named', () async {
      final body = (await check(code: 'CS-BAT-7788'))['body'] as Map;
      expect(body['verdict'], 'blocked');
      expect(body['product'], isNotNull);
    });

    test('a code Crown Solar never printed is not recognised', () async {
      final body = (await check(code: 'XX-0000-0000'))['body'] as Map;
      expect(body['verdict'], 'not_recognised');
      expect(body['product'], isNull);
    });
  });
}
