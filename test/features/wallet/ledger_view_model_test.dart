import 'package:flutter_test/flutter_test.dart';

import 'package:cse_b2b/core/mock/partner_directory.dart';
import 'package:cse_b2b/features/session/data/signed_in_user.dart';
import 'package:cse_b2b/features/wallet/data/wallet_repository.dart';
import 'package:cse_b2b/features/wallet/ui/ledger_view_model.dart';

final _installer = SignedInUser.fromAccount(
  PartnerDirectory.find('3004821190')!,
);

LedgerViewModel _build() =>
    LedgerViewModel(repository: MockWalletRepository(), user: _installer);

void main() {
  group('ledger totals', () {
    test('balance is available plus held', () async {
      final ledger = _build();
      await ledger.load();

      expect(ledger.available, Money.rupees(16000));
      expect(ledger.held, Money.rupees(1500));
      expect(
        ledger.balance,
        Money.rupees(17500),
        reason: 'the header must add up: balance = available + held',
      );
    });
  });

  group('ledger filters', () {
    test('everything is shown by default within the month', () async {
      final ledger = _build();
      await ledger.load();

      ledger.setRange(LedgerRange.everything);
      expect(ledger.rows, hasLength(5));
      expect(ledger.isFiltered, isTrue);
    });

    test('credits and debits can be shown on their own', () async {
      final ledger = _build();
      await ledger.load();
      ledger.setRange(LedgerRange.everything);

      ledger.setDirection(LedgerDirectionFilter.credits);
      expect(ledger.rows.every((r) => r.entry.isCredit), isTrue);

      ledger.setDirection(LedgerDirectionFilter.debits);
      expect(ledger.rows.every((r) => !r.entry.isCredit), isTrue);
    });

    test('types narrow the list and combine', () async {
      final ledger = _build();
      await ledger.load();
      ledger.setRange(LedgerRange.everything);

      ledger.toggleType(LedgerType.scanPrize);
      expect(
        ledger.rows.every((r) => r.entry.type == LedgerType.scanPrize),
        isTrue,
      );

      ledger.toggleType(LedgerType.sendCash);
      expect(ledger.rows, hasLength(4));

      ledger.toggleType(LedgerType.scanPrize);
      expect(
        ledger.rows.every((r) => r.entry.type == LedgerType.sendCash),
        isTrue,
      );
    });

    test('resetting puts every filter back', () async {
      final ledger = _build();
      await ledger.load();

      ledger.setRange(LedgerRange.everything);
      ledger.setDirection(LedgerDirectionFilter.debits);
      ledger.toggleType(LedgerType.sendCash);

      ledger.resetFilters();

      expect(ledger.isFiltered, isFalse);
      expect(ledger.range, LedgerRange.thisMonth);
      expect(ledger.direction, LedgerDirectionFilter.all);
      expect(ledger.types, isEmpty);
    });
  });

  group('running balance', () {
    test('the newest line agrees with the available balance', () async {
      final ledger = _build();
      await ledger.load();
      ledger.setRange(LedgerRange.everything);

      final settled = ledger.rows.firstWhere((r) => r.balanceAfter != null);
      expect(
        settled.balanceAfter,
        ledger.available,
        reason: 'the top settled row is where the balance stands now',
      );
    });

    test('a held line carries no running balance', () async {
      final ledger = _build();
      await ledger.load();
      ledger.setRange(LedgerRange.everything);

      final heldRow = ledger.rows.firstWhere(
        (r) => r.entry.state == LedgerState.held,
      );
      expect(
        heldRow.balanceAfter,
        isNull,
        reason: 'it has settled nowhere, so there is no balance to print',
      );
    });
  });

  group('a custom date range', () {
    test('shows only the entries between the two dates', () async {
      final ledger = _build();
      await ledger.load();
      ledger.setRange(LedgerRange.everything);

      final all = ledger.rows.map((r) => r.entry).toList();
      final newest = all.first.postedAt;
      final oldest = all.last.postedAt;
      expect(
        oldest.isBefore(newest),
        isTrue,
        reason: 'the seed needs a spread of dates for this to mean anything',
      );

      ledger.setCustomRange(oldest, oldest);

      expect(ledger.rows, isNotEmpty);
      for (final row in ledger.rows) {
        final when = row.entry.postedAt;
        expect(when.year, oldest.year);
        expect(when.month, oldest.month);
        expect(when.day, oldest.day);
      }
    });

    test('includes entries posted on the closing day', () async {
      final ledger = _build();
      await ledger.load();
      ledger.setRange(LedgerRange.everything);

      final latest = ledger.rows.first.entry;
      // A range that ends on the day itself, not the moment before it.
      ledger.setCustomRange(latest.postedAt, latest.postedAt);

      expect(ledger.rows.map((r) => r.entry.id), contains(latest.id));
    });

    test('accepts the two dates the wrong way round', () async {
      final ledger = _build();
      final from = DateTime(2026, 9, 1);
      final to = DateTime(2026, 9, 30);

      ledger.setCustomRange(to, from);

      expect(ledger.customFrom, from);
      expect(ledger.customTo, to);
    });

    test('picking dates selects the range in one step', () async {
      final ledger = _build();
      expect(ledger.range, LedgerRange.thisMonth);

      ledger.setCustomRange(DateTime(2026, 9, 1), DateTime(2026, 9, 30));

      expect(ledger.range, LedgerRange.custom);
      expect(ledger.isFiltered, isTrue);
    });

    test('the chip names the dates, not the word "custom"', () async {
      final ledger = _build();
      ledger.setCustomRange(DateTime(2026, 9, 1), DateTime(2026, 9, 30));

      expect(ledger.rangeLabel, '1 Sep – 30 Sep');
      expect(ledger.rangeLabel, isNot(contains('Custom')));
    });

    test('resetting clears the dates as well as the range', () async {
      final ledger = _build();
      ledger.setCustomRange(DateTime(2026, 9, 1), DateTime(2026, 9, 30));

      ledger.resetFilters();

      expect(ledger.range, LedgerRange.thisMonth);
      expect(ledger.customFrom, isNull);
      expect(ledger.customTo, isNull);
      expect(ledger.rangeLabel, 'This month');
    });

    test('a range with nothing in it shows nothing', () async {
      final ledger = _build();
      await ledger.load();

      ledger.setCustomRange(DateTime(2020, 1, 1), DateTime(2020, 1, 31));

      expect(ledger.rows, isEmpty);
      expect(
        ledger.isEmpty,
        isFalse,
        reason: 'the ledger has movements, just none in this range',
      );
    });

    test('it leaves the running balance alone', () async {
      final ledger = _build();
      await ledger.load();
      ledger.setRange(LedgerRange.everything);

      final wholeHistory = {
        for (final row in ledger.rows) row.entry.id: row.balanceAfter,
      };
      final oldest = ledger.rows.last.entry;

      ledger.setCustomRange(oldest.postedAt, oldest.postedAt);

      for (final row in ledger.rows) {
        expect(
          row.balanceAfter,
          wholeHistory[row.entry.id],
          reason: 'a filtered row still shows the real balance at the time',
        );
      }
    });
  });

  group('grouping', () {
    test('a day with nothing in it is not shown as a heading', () async {
      final ledger = _build();
      await ledger.load();
      ledger.setRange(LedgerRange.everything);

      for (final group in ledger.groups) {
        expect(group.rows, isNotEmpty);
      }
      expect(ledger.groups.map((g) => g.label), contains('Earlier'));
    });
  });
}
