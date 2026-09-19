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

  /// Withdrawn — a batch Crown Solar has blocked.
  blocked,
}

/// What the partner asked the scan to do.
///
/// The two are separate journeys, not two views of one result: an
/// authenticity check never claims a code and never pays, so stock on a shelf
/// can be checked without burning the prize printed on it.
enum ScanMode {
  /// Is this a genuine Crown Solar product?
  authenticity,

  /// Claim this code and take whatever it pays.
  win,
}

extension ScanModeX on ScanMode {
  String get label => switch (this) {
    ScanMode.authenticity => 'Authenticity Check',
    ScanMode.win => 'Scan to Win',
  };
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

/// Who claimed a code, and when.
class ScanClaim {
  const ScanClaim({
    required this.name,
    required this.role,
    required this.claimedAt,
  });

  final String name;
  final String role;
  final DateTime claimedAt;
}

/// What a scan produced: whether the product is genuine, and any prize.
class ScanOutcome {
  const ScanOutcome({
    required this.code,
    required this.mode,
    required this.verdict,
    this.product,
    this.prizeCredited,
    this.claim,
  });

  final String code;

  /// What the partner asked for, which decides how the result reads.
  final ScanMode mode;

  final ScanVerdict verdict;
  final ScannedProduct? product;

  /// Cash credited to the wallet by this scan. Null when nothing was won.
  final Money? prizeCredited;

  /// Who already claimed this code, on an [ScanVerdict.alreadyScanned].
  final ScanClaim? claim;

  bool get isGenuine => verdict == ScanVerdict.genuine;
  bool get hasPrize => prizeCredited != null;
}

/// The scanner's data boundary. A real service would verify the code against
/// Crown Solar's factory records; the mock below behaves the same way.
abstract interface class ScanRepository {
  Future<ScanOutcome> check({
    required String code,
    required SignedInUser user,
    required ScanMode mode,
  });
}

/// Deterministic scan results, so every verdict can be demonstrated.
///
/// The code decides the outcome, which keeps the prototype reproducible
/// without a printed box: see [sampleCodes]. A prize really is credited to
/// the wallet, so the balance and the ledger agree with what the screen says.
class MockScanRepository implements ScanRepository {
  MockScanRepository({required WalletRepository wallet}) : _wallet = wallet;

  final WalletRepository _wallet;

  static const _latency = Duration(milliseconds: 450);

  /// What a winning scan pays, by role. Prototype figures — the real amounts
  /// belong to whichever scheme Crown Solar is running.
  ///
  /// Null for the trade roles: they scan to check a product, never to win.
  static Money? prizeFor(PartnerRole role) => switch (role) {
    PartnerRole.installer => Money.rupees(500),
    PartnerRole.retailer => Money.rupees(300),
    PartnerRole.wholesaler || PartnerRole.distributor => null,
  };

  /// Codes that demonstrate each verdict, listed on the scan screen so the
  /// journey can be walked without a printed box.
  static const sampleCodes = <({String code, String meaning})>[
    (code: 'CS-INV-8841', meaning: 'Genuine · wins a prize'),
    (code: 'CS-PNL-2207', meaning: 'Genuine · no prize this time'),
    (code: 'CS-INV-0001', meaning: 'Already scanned'),
    (code: 'CS-BAT-7788', meaning: 'Blocked batch'),
  ];

  /// Codes already claimed, and by whom. One is seeded so the
  /// already-scanned state can be seen without scanning twice.
  final Map<String, ScanClaim> _claims = {
    'CS-INV-0001': ScanClaim(
      name: 'Bilal Traders',
      role: 'Retailer',
      claimedAt: DateTime.now().subtract(const Duration(days: 4)),
    ),
  };

  @override
  Future<ScanOutcome> check({
    required String code,
    required SignedInUser user,
    required ScanMode mode,
  }) async {
    await Future<void>.delayed(_latency);

    final normalised = code.trim().toUpperCase();

    if (!normalised.startsWith('CS-') || normalised.length < 10) {
      return ScanOutcome(
        code: normalised,
        mode: mode,
        verdict: ScanVerdict.notRecognised,
      );
    }
    if (normalised.startsWith('CS-BAT')) {
      return ScanOutcome(
        code: normalised,
        mode: mode,
        verdict: ScanVerdict.blocked,
        product: _productFor(normalised),
      );
    }

    final product = _productFor(normalised);

    // An authenticity check answers one question and changes nothing: the
    // code stays unclaimed and the wallet is untouched.
    if (mode == ScanMode.authenticity) {
      return ScanOutcome(
        code: normalised,
        mode: mode,
        verdict: ScanVerdict.genuine,
        product: product,
      );
    }

    final claim = _claims[normalised];
    if (claim != null) {
      return ScanOutcome(
        code: normalised,
        mode: mode,
        verdict: ScanVerdict.alreadyScanned,
        product: product,
        claim: claim,
      );
    }

    _claims[normalised] = ScanClaim(
      name: user.businessName,
      role: user.role.label,
      claimedAt: DateTime.now(),
    );

    // The trade roles have no Scan to Win tab; this only guards against a
    // caller asking for one anyway.
    final prize = prizeFor(user.role);
    final wins = prize != null && normalised.endsWith('1');
    if (!wins) {
      return ScanOutcome(
        code: normalised,
        mode: mode,
        verdict: ScanVerdict.genuine,
        product: product,
      );
    }

    await _wallet.creditScanPrize(
      user: user,
      amount: prize,
      productName: product.name,
      code: normalised,
    );

    return ScanOutcome(
      code: normalised,
      mode: mode,
      verdict: ScanVerdict.genuine,
      product: product,
      prizeCredited: prize,
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
