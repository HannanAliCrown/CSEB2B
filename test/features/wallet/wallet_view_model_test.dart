import 'package:flutter_test/flutter_test.dart';

import 'package:cse_b2b/core/mock/partner_directory.dart';
import 'package:cse_b2b/features/session/data/signed_in_user.dart';
import 'package:cse_b2b/features/wallet/data/wallet_repository.dart';
import 'package:cse_b2b/features/wallet/ui/wallet_view_model.dart';

final _installer = SignedInUser.fromAccount(
  PartnerDirectory.find('3004821190')!,
);

({WalletViewModel model, MockWalletRepository repository}) _build() {
  final repository = MockWalletRepository();
  return (
    model: WalletViewModel(repository: repository, user: _installer),
    repository: repository,
  );
}

void main() {
  group('money', () {
    test('formats with grouping and no stray decimals', () {
      expect(Money.rupees(18500).formatted, '18,500');
      expect(Money.rupees(1200).formatted, '1,200');
      expect(Money.rupees(0).formatted, '0');
      expect(const Money(150050).formatted, '1,500.50');
    });
  });

  group('wallet', () {
    test('the balance counts cleared credits and every debit', () async {
      final wallet = _build().model;
      await wallet.load();

      // Seeded credits 18,500 + 1,200 + 800, less a 3,000 cleared debit and
      // a 1,500 held one — held money has already left the balance.
      expect(wallet.balance, Money.rupees(16000));
      expect(wallet.entries, hasLength(5));
    });

    test('recipients never include the signed-in partner', () async {
      final wallet = _build().model;
      await wallet.load();

      expect(wallet.recipients, isNotEmpty);
      expect(
        wallet.recipients.every(
          (r) =>
              PartnerDirectory.normalise(r.mobileNumber) !=
              PartnerDirectory.normalise(_installer.mobileNumber),
        ),
        isTrue,
      );
    });

    test('a number resolves to a partner rather than being typed', () async {
      final wallet = _build().model;
      await wallet.load();

      await wallet.lookupRecipient('3007781204');

      expect(wallet.recipient?.name, 'Al-Noor Electric Store');
      expect(wallet.step, SendCashStep.amount);
    });

    test('an unknown number is refused', () async {
      final wallet = _build().model;
      await wallet.load();

      await wallet.lookupRecipient('3009990000');

      expect(wallet.recipient, isNull);
      expect(wallet.error, isNotNull);
      expect(wallet.step, SendCashStep.recipient);
    });

    test('an amount over the balance cannot be reviewed', () async {
      final wallet = _build().model;
      await wallet.load();
      await wallet.lookupRecipient('3007781204');

      wallet.setAmount('99999');

      expect(wallet.amountProblem, contains('more than your balance'));
      expect(wallet.canReview, isFalse);
    });

    test('an amount under the minimum cannot be reviewed', () async {
      final wallet = _build().model;
      await wallet.load();
      await wallet.lookupRecipient('3007781204');

      wallet.setAmount('50');

      expect(wallet.amountProblem, contains('smallest transfer'));
      expect(wallet.canReview, isFalse);
    });

    test('sending to a retailer is held and lowers the balance', () async {
      final wallet = _build().model;
      await wallet.load();
      final before = wallet.balance;

      await wallet.lookupRecipient('3007781204');
      wallet.setAmount('1000');
      wallet.review();
      await wallet.send();

      expect(wallet.step, SendCashStep.sent);
      expect(wallet.result?.held, isTrue);
      expect(wallet.balance, before - Money.rupees(1000));
      expect(wallet.entries.first.title, contains('Al-Noor Electric Store'));
    });

    test('every transfer waits on the receiver, whatever their role', () async {
      for (final number in ['3007781204', '3014429911', '3028890143']) {
        final wallet = _build().model;
        await wallet.load();

        await wallet.lookupRecipient(number);
        wallet.setAmount('1000');
        wallet.review();
        await wallet.send();

        expect(
          wallet.result?.held,
          isTrue,
          reason: 'the receiver approves, not the buying source ($number)',
        );
      }
    });

    test('an installer cannot receive cash', () async {
      final wallet = _build().model;
      await wallet.load();

      // Shahdara Solar Services is an installer: they buy, they do not sell.
      await wallet.lookupRecipient('3335560071');

      expect(wallet.recipient, isNull);
      expect(wallet.error, isNotNull);
      expect(
        wallet.recipients.every((r) => r.role != 'Installer'),
        isTrue,
        reason: 'installers are not offered as recipients either',
      );
    });

    test('the ledger and the balance come from the same movements', () async {
      final wallet = _build().model;
      await wallet.load();

      await wallet.lookupRecipient('3014429911');
      wallet.setAmount('500');
      wallet.review();
      await wallet.send();

      var recomputed = const Money(0);
      for (final entry in wallet.entries) {
        if (entry.state == LedgerState.rejected) continue;
        if (entry.isCredit) {
          if (entry.state == LedgerState.cleared) {
            recomputed = recomputed + entry.amount;
          }
        } else {
          recomputed = recomputed - entry.amount;
        }
      }
      expect(recomputed, wallet.balance);
    });
  });
}
