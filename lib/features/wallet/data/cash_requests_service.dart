// Constructor parameters are named for their public API rather than the
// private fields they populate, so the initializing-formal shorthand the
// linter suggests is not available here.
// ignore_for_file: prefer_initializing_formals

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/mock/partner_directory.dart';
import '../../../core/mock/pending_registrations.dart';
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

/// The Cash Request inbox.
///
/// [HttpCashRequestsService] reads the database behind `prototype_server`.
/// [MockCashRequestsService] holds the same transfers in memory, so a build
/// with no server running opens on the inbox the database shows.
abstract interface class CashRequestsService {
  /// Null when the inbox could not be read, which the screen says rather
  /// than showing an empty inbox.
  Future<List<CashRequest>?> requests(String mobileNumber);

  /// How many are waiting, for the badge on Home.
  Future<int> waitingCount(String mobileNumber);

  /// Records the verdict. False when nothing was recorded.
  Future<bool> decide({
    required String mobileNumber,
    required String reference,
    required bool approved,
  });
}

/// The Cash Request inbox, backed by the database behind `prototype_server`.
class HttpCashRequestsService implements CashRequestsService {
  HttpCashRequestsService({required String baseUrl, http.Client? client})
    : _baseUrl = baseUrl,
      _client = client ?? http.Client();

  final String _baseUrl;
  final http.Client _client;

  @override
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

  @override
  Future<int> waitingCount(String mobileNumber) async => [
    for (final request in await requests(mobileNumber) ?? const <CashRequest>[])
      if (request.waiting) request,
  ].length;

  @override
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

/// One transfer as `db/seed/008_profile_requests_and_cash_requests.sql`
/// writes it: an interval before and after the moment the row was seeded.
class _SeededTransfer {
  const _SeededTransfer({
    required this.reference,
    required this.fromNumber,
    required this.amountPaisa,
    required this.ago,
    required this.expiresIn,
    this.note,
  });

  final String reference;
  final String fromNumber;
  final int amountPaisa;
  final Duration ago;
  final Duration expiresIn;
  final String? note;
}

/// The Cash Request inbox, held in memory.
///
/// The same three transfers the seed writes, sent to the same receiver, so a
/// server-less build opens on the inbox the database shows. A verdict lasts
/// as long as the process does, which is what a build with no database can
/// offer.
class MockCashRequestsService implements CashRequestsService {
  MockCashRequestsService({required MockWalletRepository wallet})
    : _wallet = wallet,
      _seededAt = DateTime.now();

  /// Where the real transfers live. A transfer is one record — the sender's
  /// held ledger line — so the inbox reads it from there rather than keeping
  /// a second copy that could disagree with the wallet.
  final MockWalletRepository _wallet;

  /// The seed writes its intervals against `now()`. Holding the moment the
  /// rows were built keeps `sentAt` still while the app runs, as a row in a
  /// table would be.
  final DateTime _seededAt;

  /// Verdicts recorded this run, by reference.
  final Map<String, CashRequestState> _decisions = {};
  final Map<String, DateTime> _decidedAt = {};

  /// Every seeded transfer is sent to this partner.
  static const _receiverNumber = '3007781204';

  static const _seeded = <_SeededTransfer>[
    _SeededTransfer(
      reference: 'TX-0101',
      fromNumber: '3004821190',
      amountPaisa: 850000,
      note: 'Panels invoice 8841',
      ago: Duration(hours: 5),
      expiresIn: Duration(days: 2),
    ),
    _SeededTransfer(
      reference: 'TX-0102',
      fromNumber: '3335560071',
      amountPaisa: 1420000,
      note: 'Inverter part payment',
      ago: Duration(days: 1, hours: 6),
      expiresIn: Duration(days: 1),
    ),
    _SeededTransfer(
      reference: 'TX-0103',
      fromNumber: '3217745002',
      amountPaisa: 680000,
      ago: Duration(days: 6),
      expiresIn: Duration(hours: 20),
    ),
  ];

  CashRequest _build(_SeededTransfer row) {
    final sender = PartnerDirectory.find(row.fromNumber);
    final expiresAt = _seededAt.add(row.expiresIn);
    final decided = _decisions[row.reference];
    return CashRequest(
      reference: row.reference,
      fromName: sender?.displayName ?? 'A partner',
      fromRole: sender?.role ?? 'Partner',
      amount: Money(row.amountPaisa),
      state:
          decided ??
          (expiresAt.isBefore(DateTime.now())
              ? CashRequestState.expired
              : CashRequestState.waiting),
      note: row.note,
      sentAt: _seededAt.subtract(row.ago),
      expiresAt: expiresAt,
      decidedAt: _decidedAt[row.reference],
    );
  }

  /// A transfer actually sent in the app, as the partner it was sent to sees
  /// it. It never expires: the sender's money stays held until this partner
  /// answers, and a deadline nobody enforces would be a lie.
  CashRequest _fromTransfer(IncomingTransfer transfer) {
    // The directory first, then a partner who registered on this phone —
    // otherwise everyone who joined after the directory was written would
    // arrive in the inbox as "A partner".
    final account = PartnerDirectory.find(transfer.fromNumber);
    final pending = PendingRegistrations.find(transfer.fromNumber);
    return CashRequest(
      reference: transfer.entry.id,
      fromName: account?.displayName ?? pending?.businessName ?? 'A partner',
      fromRole: account?.role ?? pending?.role ?? 'Partner',
      amount: transfer.entry.amount,
      state: switch (transfer.entry.state) {
        LedgerState.held => CashRequestState.waiting,
        LedgerState.rejected => CashRequestState.rejected,
        LedgerState.cleared => CashRequestState.approved,
      },
      note: transfer.entry.subtitle,
      sentAt: transfer.entry.postedAt,
    );
  }

  @override
  Future<List<CashRequest>?> requests(String mobileNumber) async {
    // Transfers sent to this partner in the app, newest first, then the
    // seeded ones the one seeded receiver also has.
    final sent = [
      for (final transfer in _wallet.incomingTransfers(mobileNumber))
        _fromTransfer(transfer),
    ];

    if (PartnerDirectory.normalise(mobileNumber) != _receiverNumber) {
      return sent;
    }
    return [...sent, for (final row in _seeded) _build(row)];
  }

  @override
  Future<int> waitingCount(String mobileNumber) async => [
    for (final request in await requests(mobileNumber) ?? const <CashRequest>[])
      if (request.waiting) request,
  ].length;

  @override
  Future<bool> decide({
    required String mobileNumber,
    required String reference,
    required bool approved,
  }) async {
    // A transfer actually sent in the app: the wallet moves the money, so
    // the hold is released and the receiver credited in one step rather than
    // this service keeping a verdict the balances know nothing about.
    final sent = _wallet
        .incomingTransfers(mobileNumber)
        .any((transfer) => transfer.entry.id == reference);
    if (sent) {
      return _wallet.settleTransfer(id: reference, approved: approved);
    }

    if (PartnerDirectory.normalise(mobileNumber) != _receiverNumber) {
      return false;
    }
    if (!_seeded.any((row) => row.reference == reference)) return false;
    if (_decisions.containsKey(reference)) return false;

    _decisions[reference] = approved
        ? CashRequestState.approved
        : CashRequestState.rejected;
    _decidedAt[reference] = DateTime.now();
    return true;
  }
}
