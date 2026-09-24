/// The product behind a printed code.
class ScannedProductRow {
  const ScannedProductRow({
    required this.name,
    required this.batch,
    required this.madeOn,
  });

  final String name;
  final String batch;

  /// Where and when it was made, as one line.
  final String madeOn;

  Map<String, Object?> toJson() => {
    'name': name,
    'batch': batch,
    'madeOn': madeOn,
  };
}

/// Who already claimed a code, and when.
class ScanClaimRow {
  const ScanClaimRow({
    required this.name,
    required this.role,
    required this.claimedAt,
  });

  final String name;
  final String role;
  final DateTime claimedAt;

  Map<String, Object?> toJson() => {
    'name': name,
    'role': role,
    'claimedAt': claimedAt.toUtc().toIso8601String(),
  };
}

/// What a scan turned out to be.
class ScanOutcomeRow {
  const ScanOutcomeRow({
    required this.code,
    required this.verdict,
    this.product,
    this.prizePaisa,
    this.claim,
  });

  final String code;

  /// 'genuine' | 'already_scanned' | 'not_recognised' | 'blocked' |
  /// 'unassigned'.
  final String verdict;

  final ScannedProductRow? product;

  /// Credited to the wallet by this scan. Null when nothing was won.
  final int? prizePaisa;

  /// Who holds the claim, on an 'already_scanned'.
  final ScanClaimRow? claim;

  Map<String, Object?> toJson() => {
    'code': code,
    'verdict': verdict,
    'product': product?.toJson(),
    'prizePaisa': prizePaisa,
    'claim': claim?.toJson(),
  };
}

/// The scanner's persistence boundary.
abstract interface class ScanDataStore {
  /// What this partner can win, and the codes a demonstration can use.
  /// Null when the number has no account.
  Future<ScanIntroRow?> intro(String mobileNumber);

  /// Checks a code.
  ///
  /// [claim] false is an authenticity check: it answers one question and
  /// changes nothing, so stock on a shelf can be checked without burning the
  /// prize printed on it. [claim] true takes the code for this partner's
  /// role and pays whatever it is worth.
  Future<ScanOutcomeRow?> check({
    required String code,
    required String mobileNumber,
    required bool claim,
  });
}

/// One of the codes the scan screen lists, so the journey can be walked
/// without a printed box.
class ScanSampleRow {
  const ScanSampleRow({required this.code, required this.meaning});

  final String code;

  /// What scanning it will do for this partner — worked out from the
  /// product's own row and whether their role has already claimed it, so the
  /// list never describes a code as winnable when it is not.
  final String meaning;

  Map<String, Object?> toJson() => {'code': code, 'meaning': meaning};
}

/// What the scan screen needs before anything is scanned.
class ScanIntroRow {
  const ScanIntroRow({required this.prizePaisa, required this.samples});

  /// What a winning code pays this role, or null when it cannot win.
  final int? prizePaisa;

  final List<ScanSampleRow> samples;

  Map<String, Object?> toJson() => {
    'prizePaisa': prizePaisa,
    'samples': [for (final sample in samples) sample.toJson()],
  };
}
