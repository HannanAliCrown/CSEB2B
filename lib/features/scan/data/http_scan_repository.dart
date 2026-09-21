// Constructor parameters are named for their public API rather than the
// private fields they populate, so the initializing-formal shorthand the
// linter suggests is not available here.
// ignore_for_file: prefer_initializing_formals

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../session/data/signed_in_user.dart';
import '../../wallet/data/wallet_repository.dart';
import 'scan_repository.dart';

/// The scanner, backed by Crown Solar's product records in the database.
///
/// The rule that one code is worth one claim to an installer and one to a
/// retailer lives in `scan_claims`' unique key, not here: two phones on the
/// same box cannot both win, because the second insert is refused by the
/// database rather than by a check the app could race.
class HttpScanRepository implements ScanRepository {
  HttpScanRepository({
    required String baseUrl,
    required WalletRepository wallet,
    http.Client? client,
  }) : _baseUrl = baseUrl,
       _wallet = wallet,
       _client = client ?? http.Client();

  final String _baseUrl;
  final WalletRepository _wallet;
  final http.Client _client;

  /// Against the database a claim is a row, so there is nothing a button
  /// here could put back. `db/README.md` has the SQL.
  @override
  bool get canResetClaims => false;

  @override
  void resetClaims() {}

  @override
  Future<ScanIntro> intro(SignedInUser user) async {
    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/scan/intro')
            .replace(queryParameters: {'mobileNumber': user.mobileNumber}),
      );
      if (response.statusCode != 200) return ScanIntro.empty;

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final prize = (body['prizePaisa'] as num?)?.toInt();
      return ScanIntro(
        prize: prize == null ? null : Money(prize),
        samples: [
          for (final entry in body['samples'] as List? ?? const [])
            ScanSample(
              code: (entry as Map<String, dynamic>)['code'] as String,
              meaning: entry['meaning'] as String,
            ),
        ],
      );
    } on Object {
      // No prize is claimed and no code is listed, rather than quoting an
      // amount nobody confirmed.
      return ScanIntro.empty;
    }
  }

  @override
  Future<ScanOutcome> check({
    required String code,
    required SignedInUser user,
    required ScanMode mode,
  }) async {
    final normalised = code.trim().toUpperCase();

    final http.Response response;
    try {
      response = await _client.post(
        Uri.parse('$_baseUrl/scan'),
        headers: const {'content-type': 'application/json'},
        body: jsonEncode({
          'code': normalised,
          'mobileNumber': user.mobileNumber,
          // An authenticity check answers one question and changes nothing,
          // so stock on a shelf can be checked without burning its prize.
          'claim': mode == ScanMode.win,
        }),
      );
    } on Object {
      // A code that could not be checked is not a code that failed: saying
      // "not recognised" would be a verdict nobody reached.
      return ScanOutcome(
        code: normalised,
        mode: mode,
        verdict: ScanVerdict.unchecked,
      );
    }

    if (response.statusCode != 200) {
      return ScanOutcome(
        code: normalised,
        mode: mode,
        verdict: ScanVerdict.unchecked,
      );
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final prize = (body['prizePaisa'] as num?)?.toInt();

    // The server credited the wallet inside the same transaction that took
    // the claim. This tells the screens behind this one to reload.
    if (prize != null) {
      await _wallet.creditScanPrize(
        user: user,
        amount: Money(prize),
        productName: (body['product'] as Map?)?['name'] as String? ?? 'product',
        code: normalised,
      );
    }

    return ScanOutcome(
      code: normalised,
      mode: mode,
      verdict: switch (body['verdict']) {
        'already_scanned' => ScanVerdict.alreadyScanned,
        'blocked' => ScanVerdict.blocked,
        'not_recognised' => ScanVerdict.notRecognised,
        _ => ScanVerdict.genuine,
      },
      product: _productFrom(body['product'] as Map<String, dynamic>?),
      prizeCredited: prize == null ? null : Money(prize),
      claim: _claimFrom(body['claim'] as Map<String, dynamic>?),
    );
  }

  ScannedProduct? _productFrom(Map<String, dynamic>? json) => json == null
      ? null
      : ScannedProduct(
          name: json['name'] as String,
          batch: json['batch'] as String? ?? '',
          madeOn: json['madeOn'] as String? ?? '',
        );

  ScanClaim? _claimFrom(Map<String, dynamic>? json) => json == null
      ? null
      : ScanClaim(
          name: json['name'] as String,
          role: json['role'] as String,
          claimedAt: DateTime.parse(json['claimedAt'] as String).toLocal(),
        );
}
