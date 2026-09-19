import 'package:flutter_test/flutter_test.dart';

import 'package:cse_b2b/core/mock/partner_directory.dart';
import 'package:cse_b2b/features/scan/data/scan_repository.dart';
import 'package:cse_b2b/features/session/data/signed_in_user.dart';
import 'package:cse_b2b/features/wallet/data/wallet_repository.dart';

final _installer = SignedInUser.fromAccount(
  PartnerDirectory.find('3004821190')!,
);
final _retailer = SignedInUser.fromAccount(
  PartnerDirectory.find('3217745002')!,
);
final _wholesaler = SignedInUser.fromAccount(
  PartnerDirectory.find('3014429911')!,
);

({MockScanRepository scanner, MockWalletRepository wallet}) _build() {
  final wallet = MockWalletRepository();
  return (scanner: MockScanRepository(wallet: wallet), wallet: wallet);
}

void main() {
  group('scanning to win', () {
    test('a Crown Solar code is genuine and names the product', () async {
      final outcome = await _build().scanner.check(
        code: 'CS-PNL-2207',
        user: _installer,
        mode: ScanMode.win,
      );

      expect(outcome.verdict, ScanVerdict.genuine);
      expect(outcome.product?.name, 'Crown Solar 560W Panel');
      expect(outcome.hasPrize, isFalse);
    });

    test('an unknown code is not recognised', () async {
      final outcome = await _build().scanner.check(
        code: 'hello',
        user: _installer,
        mode: ScanMode.win,
      );

      expect(outcome.verdict, ScanVerdict.notRecognised);
      expect(outcome.product, isNull);
    });

    test('a blocked batch is refused', () async {
      final outcome = await _build().scanner.check(
        code: 'CS-BAT-7788',
        user: _installer,
        mode: ScanMode.win,
      );

      expect(outcome.verdict, ScanVerdict.blocked);
    });

    test('a winning scan credits the wallet and the ledger', () async {
      final harness = _build();
      final before = await harness.wallet.balance(_installer);
      final prize = MockScanRepository.prizeFor(_installer.role)!;

      final outcome = await harness.scanner.check(
        code: 'CS-INV-8841',
        user: _installer,
        mode: ScanMode.win,
      );

      expect(outcome.hasPrize, isTrue);
      expect(outcome.prizeCredited, prize);

      final after = await harness.wallet.balance(_installer);
      expect(after, before + prize, reason: 'the prize is spendable at once');

      final ledger = await harness.wallet.ledger(_installer);
      expect(ledger.first.title, contains('Scan prize'));
      expect(ledger.first.amount, prize);
      expect(ledger.first.isCredit, isTrue);
      expect(ledger.first.state, LedgerState.cleared);
    });

    test('scanning again reports who claimed it, and pays nothing', () async {
      final harness = _build();

      await harness.scanner.check(
        code: 'CS-INV-8841',
        user: _installer,
        mode: ScanMode.win,
      );
      final balanceAfterWin = await harness.wallet.balance(_installer);

      final second = await harness.scanner.check(
        code: 'CS-INV-8841',
        user: _installer,
        mode: ScanMode.win,
      );

      expect(second.verdict, ScanVerdict.alreadyScanned);
      expect(second.claim?.name, 'Adnan Solar Works');
      expect(second.claim?.role, 'Installer');
      expect(second.claim?.claimedAt, isNotNull);
      expect(second.hasPrize, isFalse);
      expect(
        await harness.wallet.balance(_installer),
        balanceAfterWin,
        reason: 'a code pays out once',
      );
    });

    test(
      'the seeded claimed code names the partner in your own role',
      () async {
        final scanner = _build().scanner;

        final forInstaller = await scanner.check(
          code: 'CS-INV-0001',
          user: _installer,
          mode: ScanMode.win,
        );
        expect(forInstaller.verdict, ScanVerdict.alreadyScanned);
        expect(forInstaller.claim?.name, 'Shahdara Solar Services');
        expect(forInstaller.claim?.role, 'Installer');

        final forRetailer = await scanner.check(
          code: 'CS-INV-0001',
          user: _retailer,
          mode: ScanMode.win,
        );
        expect(forRetailer.verdict, ScanVerdict.alreadyScanned);
        expect(forRetailer.claim?.name, 'Bilal Traders');
        expect(forRetailer.claim?.role, 'Retailer');
      },
    );

    test('a retailer wins their own role\'s amount', () async {
      final harness = _build();
      final prize = MockScanRepository.prizeFor(_retailer.role)!;

      final outcome = await harness.scanner.check(
        code: 'CS-INV-8841',
        user: _retailer,
        mode: ScanMode.win,
      );

      expect(outcome.hasPrize, isTrue);
      expect(outcome.prizeCredited, prize);
      expect(
        prize,
        isNot(MockScanRepository.prizeFor(PartnerRole.installer)),
        reason: 'the prize depends on the role',
      );
    });

    test('a trade role wins nothing even if it asks', () async {
      final harness = _build();
      final before = await harness.wallet.balance(_wholesaler);

      final outcome = await harness.scanner.check(
        code: 'CS-INV-8841',
        user: _wholesaler,
        mode: ScanMode.win,
      );

      expect(outcome.verdict, ScanVerdict.genuine);
      expect(outcome.hasPrize, isFalse);
      expect(await harness.wallet.balance(_wholesaler), before);
    });
  });

  group('one code, one installer and one retailer', () {
    test('a retailer can still win a code an installer has taken', () async {
      final harness = _build();

      final first = await harness.scanner.check(
        code: 'CS-INV-8841',
        user: _installer,
        mode: ScanMode.win,
      );
      final second = await harness.scanner.check(
        code: 'CS-INV-8841',
        user: _retailer,
        mode: ScanMode.win,
      );

      expect(first.hasPrize, isTrue);
      expect(second.verdict, ScanVerdict.genuine);
      expect(second.hasPrize, isTrue);
      expect(
        second.prizeCredited,
        MockScanRepository.prizeFor(PartnerRole.retailer),
      );
    });

    test('a second installer is turned away', () async {
      final harness = _build();
      final otherInstaller = SignedInUser.fromAccount(
        PartnerDirectory.find('3335560071')!,
      );
      expect(otherInstaller.role, PartnerRole.installer);

      await harness.scanner.check(
        code: 'CS-INV-8841',
        user: _installer,
        mode: ScanMode.win,
      );
      final before = await harness.wallet.balance(otherInstaller);

      final second = await harness.scanner.check(
        code: 'CS-INV-8841',
        user: otherInstaller,
        mode: ScanMode.win,
      );

      expect(second.verdict, ScanVerdict.alreadyScanned);
      expect(second.claim?.name, 'Adnan Solar Works');
      expect(second.hasPrize, isFalse);
      expect(await harness.wallet.balance(otherInstaller), before);
    });

    test('and so is a second retailer', () async {
      final harness = _build();
      final otherRetailer = SignedInUser.fromAccount(
        PartnerDirectory.find('3007781204')!,
      );
      expect(otherRetailer.role, PartnerRole.retailer);

      await harness.scanner.check(
        code: 'CS-INV-8841',
        user: _retailer,
        mode: ScanMode.win,
      );
      final second = await harness.scanner.check(
        code: 'CS-INV-8841',
        user: otherRetailer,
        mode: ScanMode.win,
      );

      expect(second.verdict, ScanVerdict.alreadyScanned);
      expect(second.claim?.name, 'Bilal Traders');
    });

    test('a code that pays nothing still uses up the entry', () async {
      final harness = _build();

      final first = await harness.scanner.check(
        code: 'CS-PNL-2207',
        user: _installer,
        mode: ScanMode.win,
      );
      final second = await harness.scanner.check(
        code: 'CS-PNL-2207',
        user: _installer,
        mode: ScanMode.win,
      );

      expect(first.verdict, ScanVerdict.genuine);
      expect(first.hasPrize, isFalse);
      expect(second.verdict, ScanVerdict.alreadyScanned);
    });

    test('a trade role never uses up anyone\'s entry', () async {
      final harness = _build();

      await harness.scanner.check(
        code: 'CS-INV-8841',
        user: _wholesaler,
        mode: ScanMode.win,
      );
      final installer = await harness.scanner.check(
        code: 'CS-INV-8841',
        user: _installer,
        mode: ScanMode.win,
      );

      expect(installer.hasPrize, isTrue);
    });
  });

  group('checking authenticity', () {
    test('says a Crown Solar product is genuine', () async {
      final outcome = await _build().scanner.check(
        code: 'CS-INV-8841',
        user: _wholesaler,
        mode: ScanMode.authenticity,
      );

      expect(outcome.verdict, ScanVerdict.genuine);
      expect(outcome.product?.name, 'Crown Solar 8kW Hybrid Inverter');
      expect(outcome.mode, ScanMode.authenticity);
    });

    test('still refuses a blocked batch and an unknown code', () async {
      final scanner = _build().scanner;

      expect(
        (await scanner.check(
          code: 'CS-BAT-7788',
          user: _wholesaler,
          mode: ScanMode.authenticity,
        )).verdict,
        ScanVerdict.blocked,
      );
      expect(
        (await scanner.check(
          code: 'nope',
          user: _wholesaler,
          mode: ScanMode.authenticity,
        )).verdict,
        ScanVerdict.notRecognised,
      );
    });

    test('never pays, whatever the role', () async {
      final harness = _build();
      final before = await harness.wallet.balance(_installer);

      final outcome = await harness.scanner.check(
        code: 'CS-INV-8841',
        user: _installer,
        mode: ScanMode.authenticity,
      );

      expect(outcome.hasPrize, isFalse);
      expect(await harness.wallet.balance(_installer), before);
    });

    test('does not use up the code', () async {
      final harness = _build();

      await harness.scanner.check(
        code: 'CS-INV-8841',
        user: _retailer,
        mode: ScanMode.authenticity,
      );
      final claimed = await harness.scanner.check(
        code: 'CS-INV-8841',
        user: _installer,
        mode: ScanMode.win,
      );

      expect(
        claimed.hasPrize,
        isTrue,
        reason: 'checking a product must not burn the prize on it',
      );
    });

    test('says nothing about who claimed a code', () async {
      final outcome = await _build().scanner.check(
        code: 'CS-INV-0001',
        user: _installer,
        mode: ScanMode.authenticity,
      );

      expect(outcome.verdict, ScanVerdict.genuine);
      expect(outcome.claim, isNull);
    });
  });

  group('resetting for a demonstration', () {
    test('a claimed code can be won again', () async {
      final harness = _build();

      await harness.scanner.check(
        code: 'CS-INV-8841',
        user: _installer,
        mode: ScanMode.win,
      );
      harness.scanner.reset();

      final again = await harness.scanner.check(
        code: 'CS-INV-8841',
        user: _installer,
        mode: ScanMode.win,
      );

      expect(again.verdict, ScanVerdict.genuine);
      expect(again.hasPrize, isTrue);
    });

    test('prizes already paid are left in the wallet', () async {
      final harness = _build();

      await harness.scanner.check(
        code: 'CS-INV-8841',
        user: _installer,
        mode: ScanMode.win,
      );
      final won = await harness.wallet.balance(_installer);

      harness.scanner.reset();

      expect(await harness.wallet.balance(_installer), won);
    });

    test('the seeded claims come back', () async {
      final harness = _build();
      harness.scanner.reset();

      final outcome = await harness.scanner.check(
        code: 'CS-INV-0001',
        user: _installer,
        mode: ScanMode.win,
      );

      expect(outcome.verdict, ScanVerdict.alreadyScanned);
      expect(outcome.claim?.name, 'Shahdara Solar Services');
    });
  });

  group('who can win', () {
    test('installers and retailers have a prize, the trade roles do not', () {
      expect(MockScanRepository.prizeFor(PartnerRole.installer), isNotNull);
      expect(MockScanRepository.prizeFor(PartnerRole.retailer), isNotNull);
      expect(MockScanRepository.prizeFor(PartnerRole.wholesaler), isNull);
      expect(MockScanRepository.prizeFor(PartnerRole.distributor), isNull);
    });
  });
}
