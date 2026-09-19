// Constructor parameters are named for their public API rather than the
// private fields they populate, so the initializing-formal shorthand the
// linter suggests is not available here.
// ignore_for_file: prefer_initializing_formals

import '../../session/data/signed_in_user.dart';
import '../../wallet/data/wallet_repository.dart';

/// What a scanned code turned out to be.
enum ScanVerdict {
  /// A Crown Solar product, scanned for the first time.
  genuine,

  /// Genuine, but this code has already been claimed.
  alreadyScanned,

  /// Not a Crown Solar code at all.
  notRecognised,

  /// A real code the factory has not released yet.
  notReleased,

  /// Withdrawn — a batch Crown Solar has blocked.
  blocked,
}

/// A Crown Solar product behind a code.
class ScannedProduct {
  const ScannedProduct({
    required this.name,
    required this.batch,
    required this.madeOn,
  });

  final String name;
  final String batch;
  final String madeOn;
}

/// What a scan produced: whether the product is genuine, and any prize.
class ScanOutcome {
  const ScanOutcome({
    required this.code,
    required this.verdict,
    this.product,
    this.prize,
    this.prizeCredited,
  });

  final String code;
  final ScanVerdict verdict;
  final ScannedProduct? product;

  /// What was won, when the scan earned something.
  final String? prize;

  /// Cash credited to the wallet by this scan.
  final Money? prizeCredited;

  bool get isGenuine => verdict == ScanVerdict.genuine;
  bool get hasPrize => prize != null;
}

/// The scanner's data boundary. A real service would verify the code against
/// Crown Solar's factory records; the mock below behaves the same way.
abstract interface class ScanRepository {
  Future<ScanOutcome> check({required String code, required SignedInUser user});
}

/// Deterministic scan results, so every verdict can be demonstrated.
///
/// The code decides the outcome, which keeps the prototype reproducible
/// without a camera: see [sampleCodes].
class MockScanRepository implements ScanRepository {
  MockScanRepository();

  static const _latency = Duration(milliseconds: 450);

  /// Codes that demonstrate each verdict, listed on the scan screen so the
  /// journey can be walked without a printed box.
  static const sampleCodes = <({String code, String meaning})>[
    (code: 'CS-INV-8841', meaning: 'Genuine · wins a prize'),
    (code: 'CS-PNL-2207', meaning: 'Genuine · no prize this time'),
    (code: 'CS-INV-0001', meaning: 'Already scanned'),
    (code: 'CS-BAT-7788', meaning: 'Blocked batch'),
    (code: 'CS-NEW-9000', meaning: 'Not released yet'),
  ];

  /// Codes already claimed in this session, so scanning twice behaves the way
  /// it would against a real ledger.
  final Set<String> _claimed = {'CS-INV-0001'};

  @override
  Future<ScanOutcome> check({
    required String code,
    required SignedInUser user,
  }) async {
    await Future<void>.delayed(_latency);

    final normalised = code.trim().toUpperCase();

    if (!normalised.startsWith('CS-') || normalised.length < 10) {
      return ScanOutcome(code: normalised, verdict: ScanVerdict.notRecognised);
    }
    if (normalised.startsWith('CS-BAT')) {
      return ScanOutcome(
        code: normalised,
        verdict: ScanVerdict.blocked,
        product: _productFor(normalised),
      );
    }
    if (normalised.startsWith('CS-NEW')) {
      return ScanOutcome(
        code: normalised,
        verdict: ScanVerdict.notReleased,
        product: _productFor(normalised),
      );
    }
    if (_claimed.contains(normalised)) {
      return ScanOutcome(
        code: normalised,
        verdict: ScanVerdict.alreadyScanned,
        product: _productFor(normalised),
      );
    }

    _claimed.add(normalised);

    // Only installers and retailers earn from a scan; the trade roles scan
    // to check a product is genuine.
    final wins = user.role.earnsPrizes && normalised.endsWith('1');

    return ScanOutcome(
      code: normalised,
      verdict: ScanVerdict.genuine,
      product: _productFor(normalised),
      prize: wins ? 'Cash prize' : null,
      prizeCredited: wins ? Money.rupees(500) : null,
    );
  }

  ScannedProduct _productFor(String code) {
    final kind = code.length >= 6 ? code.substring(3, 6) : 'INV';
    return ScannedProduct(
      name: switch (kind) {
        'PNL' => 'Crown Solar 560W Panel',
        'BAT' => 'Crown Solar 200Ah Battery',
        _ => 'Crown Solar 8kW Hybrid Inverter',
      },
      batch: code,
      madeOn: 'Lahore plant · batch verified',
    );
  }
}
