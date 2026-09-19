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

  /// Claims, held per code and then per role.
  ///
  /// One box is sold on and installed, so the same code is worth one claim to
  /// an installer and one to a retailer. A second installer on a code an
  /// installer has already taken is turned away; a retailer on that same code
  /// is not.
  final Map<String, Map<PartnerRole, ScanClaim>> _claims = _seedClaims();

  /// The deterministic starting state: one code already claimed in both
  /// roles, so the already-scanned result can be seen without scanning twice.
  static Map<String, Map<PartnerRole, ScanClaim>> _seedClaims() => {
    'CS-INV-0001': {
      PartnerRole.retailer: ScanClaim(
        name: 'Bilal Traders',
        role: 'Retailer',
        claimedAt: DateTime.now().subtract(const Duration(days: 4)),
      ),
      PartnerRole.installer: ScanClaim(
        name: 'Shahdara Solar Services',
        role: 'Installer',
        claimedAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
    },
  };

  /// Development support: forgets every claim taken in this session and
  /// restores the seeded ones, so the winning journey can be walked again
  /// without restarting the app.
  ///
  /// Prizes already paid are left alone — the wallet and the ledger keep what
  /// they were credited, because that money really was won.
  void reset() {
    _claims
      ..clear()
      ..addAll(_seedClaims());
  }

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

    // Only this role's claim can stand in the way: what an installer took
    // says nothing about what a retailer may take.
    final claim = _claims[normalised]?[user.role];
    if (claim != null) {
      return ScanOutcome(
        code: normalised,
        mode: mode,
        verdict: ScanVerdict.alreadyScanned,
        product: product,
        claim: claim,
      );
    }

    // The trade roles have no Scan to Win tab; this only guards against a
    // caller asking for one anyway. They take no claim either, so they can
    // never use up a code an installer or a retailer is owed.
    final prize = prizeFor(user.role);
    if (prize == null) {
      return ScanOutcome(
        code: normalised,
        mode: mode,
        verdict: ScanVerdict.genuine,
        product: product,
      );
    }

    // The entry is spent whether or not this code was a winning one.
    (_claims[normalised] ??= {})[user.role] = ScanClaim(
      name: user.businessName,
      role: user.role.label,
      claimedAt: DateTime.now(),
    );

    if (!normalised.endsWith('1')) {
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
