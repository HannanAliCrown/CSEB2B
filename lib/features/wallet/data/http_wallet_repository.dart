// Constructor parameters are named for their public API rather than the
// private fields they populate, so the initializing-formal shorthand the
// linter suggests is not available here.
// ignore_for_file: prefer_initializing_formals

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../session/data/signed_in_user.dart';
import 'wallet_repository.dart';

/// The wallet, read from the database behind `prototype_server`.
///
/// No balance is held here either. Every figure comes from a sum the server
/// computes over `wallet_entries`, so the ledger and Home read the same rows
/// and cannot drift apart.
class HttpWalletRepository implements WalletRepository {
  HttpWalletRepository({required String baseUrl, http.Client? client})
    : _baseUrl = baseUrl,
      _client = client ?? http.Client();

  final String _baseUrl;
  final http.Client _client;

  final _changes = _Broadcast();

  @override
  Listenable get changes => _changes;

  @override
  void announceChange() => _changes.announce();

  @override
  Future<Money> balance(SignedInUser user) async =>
      Money((await _snapshot(user))?.availablePaisa ?? 0);

  @override
  Future<Money> heldTotal(SignedInUser user) async =>
      Money((await _snapshot(user))?.heldPaisa ?? 0);

  @override
  Future<List<LedgerEntry>> ledger(SignedInUser user) async =>
      (await _snapshot(user))?.entries ?? const [];

  /// Tells anything watching a balance that a scan prize landed.
  ///
  /// Nothing is written here: the server credited the wallet inside the same
  /// transaction that took the claim, so the row already exists. What comes
  /// back is that credit described, so the caller has something to show
  /// while the screens reload.
  @override
  Future<LedgerEntry> creditScanPrize({
    required SignedInUser user,
    required Money amount,
    required String productName,
    required String code,
  }) async {
    _changes.announce();
    return LedgerEntry(
      id: code,
      postedAt: DateTime.now(),
      title: 'Scan prize · $productName',
      subtitle: code,
      amount: amount,
      direction: LedgerDirection.credit,
      // A prize is Crown Solar's own money: nobody has to accept it.
      state: LedgerState.cleared,
      type: LedgerType.scanPrize,
    );
  }

  @override
  Future<List<CashRecipient>> recentRecipients(SignedInUser user) async {
    final body = await _get('/wallet/recipients', {
      'mobileNumber': user.mobileNumber,
    });
    if (body == null) return const [];
    return [
      for (final entry in body['recipients'] as List? ?? const [])
        _recipientFrom(entry as Map<String, dynamic>),
    ];
  }

  @override
  Future<CashRecipient?> lookupRecipient(String mobileNumber) async {
    final body = await _get('/wallet/recipients/lookup', {
      'mobileNumber': mobileNumber,
    });
    return body == null ? null : _recipientFrom(body);
  }

  @override
  Future<TransferResult> sendCash({
    required SignedInUser from,
    required String toMobileNumber,
    required Money amount,
    String? note,
  }) async {
    final http.Response response;
    try {
      response = await _client.post(
        Uri.parse('$_baseUrl/wallet/transfers'),
        headers: const {'content-type': 'application/json'},
        body: jsonEncode({
          'fromMobileNumber': from.mobileNumber,
          'toMobileNumber': toMobileNumber,
          'amountPaisa': amount.paisa,
          'note': ?note,
        }),
      );
    } on Object {
      // Unreachable is not the same as refused, but the partner needs an
      // answer either way and no money moved.
      return const TransferResult.failed(TransferFailure.unknownRecipient);
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 201) {
      return TransferResult.failed(switch (body['error']) {
        'amount_too_small' => TransferFailure.amountTooSmall,
        'not_enough_balance' => TransferFailure.notEnoughBalance,
        'self' => TransferFailure.self,
        _ => TransferFailure.unknownRecipient,
      });
    }

    _changes.announce();
    return TransferResult.success(
      _entryFrom(body['entry'] as Map<String, dynamic>),
      held: body['held'] == true,
    );
  }

  Future<({List<LedgerEntry> entries, int availablePaisa, int heldPaisa})?>
  _snapshot(SignedInUser user) async {
    final body = await _get('/wallet/ledger', {
      'mobileNumber': user.mobileNumber,
    });
    if (body == null) return null;
    return (
      entries: [
        for (final entry in body['entries'] as List? ?? const [])
          _entryFrom(entry as Map<String, dynamic>),
      ],
      availablePaisa: (body['availablePaisa'] as num?)?.toInt() ?? 0,
      heldPaisa: (body['heldPaisa'] as num?)?.toInt() ?? 0,
    );
  }

  Future<Map<String, dynamic>?> _get(
    String path,
    Map<String, String> query,
  ) async {
    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl$path').replace(queryParameters: query),
      );
      if (response.statusCode != 200) return null;
      return jsonDecode(response.body) as Map<String, dynamic>;
    } on Object {
      // Nothing is invented to fill the gap: an empty wallet is honest, a
      // fabricated balance is not.
      return null;
    }
  }

  LedgerEntry _entryFrom(Map<String, dynamic> json) => LedgerEntry(
    id: json['reference'] as String,
    postedAt: DateTime.parse(json['postedAt'] as String).toLocal(),
    title: json['title'] as String,
    subtitle: json['subtitle'] as String? ?? '',
    amount: Money((json['amountPaisa'] as num).toInt()),
    direction: json['direction'] == 'credit'
        ? LedgerDirection.credit
        : LedgerDirection.debit,
    state: switch (json['state']) {
      'held' => LedgerState.held,
      'rejected' => LedgerState.rejected,
      _ => LedgerState.cleared,
    },
    type: switch (json['type']) {
      'send_cash' => LedgerType.sendCash,
      'cash_request' => LedgerType.cashRequest,
      'scan_prize' => LedgerType.scanPrize,
      'spin_prize' => LedgerType.spinPrize,
      'returned' => LedgerType.returned,
      _ => LedgerType.adjustment,
    },
  );

  CashRecipient _recipientFrom(Map<String, dynamic> json) => CashRecipient(
    mobileNumber: json['mobileNumber'] as String,
    name: json['name'] as String,
    role: json['role'] as String,
  );
}

/// A [ChangeNotifier] its owner can fire, so the wallet can announce that a
/// balance moved without exposing the whole notifier API.
class _Broadcast extends ChangeNotifier {
  void announce() => notifyListeners();
}
