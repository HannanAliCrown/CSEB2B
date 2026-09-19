import 'package:flutter_test/flutter_test.dart';

import 'package:cse_b2b/core/mock/partner_directory.dart';
import 'package:cse_b2b/features/scan/data/scan_repository.dart';
import 'package:cse_b2b/features/session/data/signed_in_user.dart';

final _installer = SignedInUser.fromAccount(
  PartnerDirectory.find('3004821190')!,
);
final _wholesaler = SignedInUser.fromAccount(
  PartnerDirectory.find('3014429911')!,
);

void main() {
  group('scanning', () {
    test('a Crown Solar code is genuine and names the product', () async {
      final outcome = await MockScanRepository().check(
        code: 'CS-PNL-2207',
        user: _installer,
      );

      expect(outcome.verdict, ScanVerdict.genuine);
      expect(outcome.product?.name, 'Crown Solar 560W Panel');
    });

    test('an unknown code is not recognised', () async {
      final outcome = await MockScanRepository().check(
        code: 'hello',
        user: _installer,
      );

      expect(outcome.verdict, ScanVerdict.notRecognised);
      expect(outcome.product, isNull);
    });

    test('a blocked batch is refused', () async {
      final outcome = await MockScanRepository().check(
        code: 'CS-BAT-7788',
        user: _installer,
      );

      expect(outcome.verdict, ScanVerdict.blocked);
    });

    test('an unreleased batch says so', () async {
      final outcome = await MockScanRepository().check(
        code: 'CS-NEW-9000',
        user: _installer,
      );

      expect(outcome.verdict, ScanVerdict.notReleased);
    });

    test('the same code cannot be claimed twice', () async {
      final scanner = MockScanRepository();

      final first = await scanner.check(code: 'CS-INV-8841', user: _installer);
      final second = await scanner.check(code: 'CS-INV-8841', user: _installer);

      expect(first.verdict, ScanVerdict.genuine);
      expect(second.verdict, ScanVerdict.alreadyScanned);
    });

    test('an installer can win a prize', () async {
      final outcome = await MockScanRepository().check(
        code: 'CS-INV-8841',
        user: _installer,
      );

      expect(outcome.hasPrize, isTrue);
      expect(outcome.prizeCredited, isNotNull);
    });

    test('a wholesaler scans for authenticity, never a prize', () async {
      final outcome = await MockScanRepository().check(
        code: 'CS-INV-8841',
        user: _wholesaler,
      );

      expect(outcome.verdict, ScanVerdict.genuine);
      expect(
        outcome.hasPrize,
        isFalse,
        reason: 'only installers and retailers earn from a scan',
      );
    });
  });
}
