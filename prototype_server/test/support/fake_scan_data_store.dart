import 'package:prototype_server/data/postgres_partner_data_store.dart'
    show normaliseMobile;
import 'package:prototype_server/data/scan_data_store.dart';

/// An in-memory [ScanDataStore] enforcing the same rules the SQL does: one
/// claim per code per role, an authenticity check that changes nothing, and
/// no prize band meaning no prize.
class FakeScanDataStore implements ScanDataStore {
  final Map<String, ({String role, String name})> _accounts = {};
  final Map<
    String,
    ({String name, bool blocked, bool unassigned, bool winsPrize})
  >
  _products = {};
  final Map<String, int> _prizeByRole = {};

  /// Keyed 'code/role', as the unique key is.
  final Map<String, ScanClaimRow> _claims = {};

  // --- Test setup ---

  void addAccount({
    required String mobileNumber,
    required String role,
    String name = 'Adnan Solar Works',
  }) => _accounts[normaliseMobile(mobileNumber)] = (role: role, name: name);

  void addProduct({
    required String code,
    String name = 'Crown Solar 8kW Hybrid Inverter',
    bool blocked = false,
    bool unassigned = false,
    bool winsPrize = false,
  }) => _products[code] = (
    name: name,
    blocked: blocked,
    unassigned: unassigned,
    winsPrize: winsPrize,
  );

  void addPrizeBand({required String role, required int amountPaisa}) =>
      _prizeByRole[role] = amountPaisa;

  void addClaim({
    required String code,
    required String role,
    required String name,
  }) => _claims['$code/$role'] = ScanClaimRow(
    name: name,
    role: role[0].toUpperCase() + role.substring(1),
    claimedAt: DateTime.now().subtract(const Duration(days: 2)),
  );

  /// What the store is holding, so a test can prove a check took no claim.
  bool hasClaim({required String code, required String role}) =>
      _claims.containsKey('$code/$role');

  // --- ScanDataStore ---

  @override
  Future<ScanIntroRow?> intro(String mobileNumber) async {
    final account = _accounts[normaliseMobile(mobileNumber)];
    if (account == null) return null;

    final band = _prizeByRole[account.role];
    return ScanIntroRow(
      prizePaisa: band,
      samples: [
        for (final entry in _products.entries)
          ScanSampleRow(
            code: entry.key,
            meaning: _meaningFor(
              entry.value,
              taken: _claims.containsKey('${entry.key}/${account.role}'),
              canWin: band != null,
            ),
          ),
      ],
    );
  }

  static String _meaningFor(
    ({String name, bool blocked, bool unassigned, bool winsPrize}) product, {
    required bool taken,
    required bool canWin,
  }) {
    if (product.unassigned) return 'Not yet assigned';
    if (product.blocked) return 'Blocked batch';
    if (!canWin) return 'Genuine product';
    if (taken) return 'Already scanned';
    return product.winsPrize
        ? 'Genuine · wins a prize'
        : 'Genuine · no prize this time';
  }

  @override
  Future<ScanOutcomeRow?> check({
    required String code,
    required String mobileNumber,
    required bool claim,
  }) async {
    final account = _accounts[normaliseMobile(mobileNumber)];
    if (account == null) return null;

    final normalised = code.trim().toUpperCase();
    final product = _products[normalised];
    if (product == null) {
      return ScanOutcomeRow(code: normalised, verdict: 'not_recognised');
    }

    if (product.unassigned) {
      return ScanOutcomeRow(code: normalised, verdict: 'unassigned');
    }

    final row = ScannedProductRow(
      name: product.name,
      batch: normalised,
      madeOn: 'Lahore plant',
    );

    if (product.blocked) {
      return ScanOutcomeRow(code: normalised, verdict: 'blocked', product: row);
    }
    if (!claim) {
      return ScanOutcomeRow(code: normalised, verdict: 'genuine', product: row);
    }

    final existing = _claims['$normalised/${account.role}'];
    if (existing != null) {
      return ScanOutcomeRow(
        code: normalised,
        verdict: 'already_scanned',
        product: row,
        claim: existing,
      );
    }

    final band = _prizeByRole[account.role];
    if (band == null) {
      return ScanOutcomeRow(code: normalised, verdict: 'genuine', product: row);
    }

    // The entry is spent whether or not this code was a winning one.
    _claims['$normalised/${account.role}'] = ScanClaimRow(
      name: account.name,
      role: account.role[0].toUpperCase() + account.role.substring(1),
      claimedAt: DateTime.now(),
    );

    return ScanOutcomeRow(
      code: normalised,
      verdict: 'genuine',
      product: row,
      prizePaisa: product.winsPrize ? band : null,
    );
  }
}
