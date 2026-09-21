// Constructor parameters are named for their public API rather than the
// private fields they populate, so the initializing-formal shorthand the
// linter suggests is not available here.
// ignore_for_file: prefer_initializing_formals

import 'dart:convert';

import 'package:http/http.dart' as http;

import 'wallet_repository.dart';

/// Where a transfer sent to this partner has got to.
enum CashRequestState { waiting, approved, rejected, expired }

extension CashRequestStateX on CashRequestState {
  String get label => switch (this) {
    CashRequestState.waiting => 'Waiting',
    CashRequestState.approved => 'Approved',
    CashRequestState.rejected => 'Rejected',
    CashRequestState.expired => 'Expired',
  };
}

/// One transfer waiting on, or already decided by, this partner.
///
/// The money is already out of the sender's wallet. Approving moves it into
/// this one; rejecting puts it back. It is never in both places and never in
/// neither.
class CashRequest {
  const CashRequest({
    required this.reference,
    required this.fromName,
    required this.fromRole,
    required this.amount,
    required this.state,
    required this.sentAt,
    this.note,
    this.expiresAt,
    this.decidedAt,
  });

  final String reference;
  final String fromName;
  final String fromRole;
  final Money amount;
  final CashRequestState state;

  /// What the sender said it was for, when they said anything.
  final String? note;

  final DateTime sentAt;
  final DateTime? expiresAt;
  final DateTime? decidedAt;

  bool get waiting => state == CashRequestState.waiting;

  static CashRequest fromJson(Map<String, dynamic> json) => CashRequest(
    reference: json['reference'] as String,
    fromName: json['fromName'] as String,
    fromRole: json['fromRole'] as String,
    amount: Money((json['amountPaisa'] as num).toInt()),
    state: switch (json['state']) {
      'accepted' => CashRequestState.approved,
      'rejected' => CashRequestState.rejected,
      'expired' => CashRequestState.expired,
      _ => CashRequestState.waiting,
    },
    note: json['note'] as String?,
    sentAt: DateTime.parse(json['sentAt'] as String).toLocal(),
    expiresAt: json['expiresAt'] == null
        ? null
        : DateTime.parse(json['expiresAt'] as String).toLocal(),
    decidedAt: json['decidedAt'] == null
        ? null
        : DateTime.parse(json['decidedAt'] as String).toLocal(),
  );
}

/// The Cash Request inbox, backed by the database behind
/// `prototype_server`.
///
/// There is deliberately no in-memory implementation. A verdict that moves
/// someone else's money and is forgotten on restart is worse than one that
/// plainly fails to be recorded.
class CashRequestsService {
  CashRequestsService({required String baseUrl, http.Client? client})
    : _baseUrl = baseUrl,
      _client = client ?? http.Client();

  final String _baseUrl;
  final http.Client _client;

  /// Null when the server could not be reached, which the screen says rather
  /// than showing an empty inbox.
  Future<List<CashRequest>?> requests(String mobileNumber) async {
    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/wallet/cash-requests')
            .replace(queryParameters: {'mobileNumber': mobileNumber}),
      );
      if (response.statusCode != 200) return null;

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return [
        for (final entry in body['requests'] as List? ?? const [])
          CashRequest.fromJson(entry as Map<String, dynamic>),
      ];
    } on Object {
      return null;
    }
  }

  /// How many are waiting, for the badge on Home.
  Future<int> waitingCount(String mobileNumber) async => [
    for (final request in await requests(mobileNumber) ?? const <CashRequest>[])
      if (request.waiting) request,
  ].length;

  /// Records the verdict. False when nothing was recorded.
  Future<bool> decide({
    required String mobileNumber,
    required String reference,
    required bool approved,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl/wallet/cash-requests/decision'),
        headers: const {'content-type': 'application/json'},
        body: jsonEncode({
          'mobileNumber': mobileNumber,
          'reference': reference,
          'approved': approved,
        }),
      );
      return response.statusCode == 200;
    } on Object {
      return false;
    }
  }
}
