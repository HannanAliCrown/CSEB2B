import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../data/points_data_store.dart';
import 'json_helpers.dart';

/// Points, schemes and targets.
///
/// Points are not money. Nothing here reads or writes the wallet, and no
/// response carries a currency figure, so the two can never be added
/// together by accident downstream.
Router pointsRoutes(PointsDataStore store) {
  final router = Router();

  /// `GET /points/ledger?mobileNumber=` — every movement with the balance it
  /// left behind, and the balance itself, from the same rows.
  router.get('/points/ledger', (Request request) async {
    final mobileNumber = request.url.queryParameters['mobileNumber'];
    if (mobileNumber == null || mobileNumber.isEmpty) {
      return jsonResponse(400, {'error': 'mobileNumber is required'});
    }

    final entries = await store.ledger(mobileNumber);
    if (entries == null) {
      return jsonResponse(404, {'error': 'unknown_account'});
    }
    final sending = await store.sendingStatus(mobileNumber);

    return jsonResponse(200, {
      'balance': await store.balance(mobileNumber) ?? 0,
      'entries': [for (final entry in entries) entry.toJson()],
      // The hub needs to know before offering Send Points, rather than
      // letting the partner fill a form that was never going to be accepted.
      'canSend': sending?.canSend ?? true,
      'restrictionReason': sending?.reason,
    });
  });

  /// `GET /points/targets?mobileNumber=` — the scheme, its targets, any
  /// extras Crown Solar set by hand, and what has been scored toward each.
  router.get('/points/targets', (Request request) async {
    final mobileNumber = request.url.queryParameters['mobileNumber'];
    if (mobileNumber == null || mobileNumber.isEmpty) {
      return jsonResponse(400, {'error': 'mobileNumber is required'});
    }

    final targets = await store.targets(mobileNumber);
    if (targets == null) {
      return jsonResponse(404, {'error': 'unknown_account'});
    }
    return jsonResponse(200, targets.toJson());
  });

  /// `GET /points/recipients?mobileNumber=` — who this partner is permitted
  /// to send to, those already paid first.
  router.get('/points/recipients', (Request request) async {
    final mobileNumber = request.url.queryParameters['mobileNumber'];
    if (mobileNumber == null || mobileNumber.isEmpty) {
      return jsonResponse(400, {'error': 'mobileNumber is required'});
    }

    final recipients = await store.recipients(mobileNumber);
    if (recipients == null) {
      return jsonResponse(404, {'error': 'unknown_account'});
    }
    return jsonResponse(200, {
      'recipients': [for (final one in recipients) one.toJson()],
    });
  });

  /// `GET /points/recipients/lookup?mobileNumber=&number=` — resolves one
  /// number from a contact or a scanned QR code.
  ///
  /// There is deliberately no search here: the app never offers a number
  /// field for points, because a transfer arrives instantly and cannot be
  /// recalled. This endpoint answers about a number the partner already has.
  router.get('/points/recipients/lookup', (Request request) async {
    final mobileNumber = request.url.queryParameters['mobileNumber'];
    final number = request.url.queryParameters['number'];
    if (mobileNumber == null || number == null) {
      return jsonResponse(400, {
        'error': 'mobileNumber and number are required',
      });
    }

    final recipient = await store.lookupRecipient(
      mobileNumber: mobileNumber,
      recipientNumber: number,
    );
    if (recipient == null) {
      return jsonResponse(404, {'error': 'not_a_permitted_recipient'});
    }
    return jsonResponse(200, recipient.toJson());
  });

  /// `POST /points/transfers` — sends points, which arrive at once.
  router.post('/points/transfers', (Request request) async {
    final body = await readJsonBody(request);
    final from = body['fromMobileNumber'] as String?;
    final to = body['toMobileNumber'] as String?;
    final amount = (body['amount'] as num?)?.toInt();

    if (from == null || to == null || amount == null) {
      return jsonResponse(400, {
        'error': 'fromMobileNumber, toMobileNumber and amount are required',
      });
    }

    final (entry, refusal) = await store.sendPoints(
      fromMobileNumber: from,
      toMobileNumber: to,
      amount: amount,
    );

    // Each refusal keeps its own name, because each has a different remedy.
    return switch (refusal) {
      null => jsonResponse(201, {
        'entry': entry!.toJson(),
        'balance': await store.balance(from) ?? 0,
      }),
      PointTransferRefusal.notEnoughPoints => jsonResponse(400, {
        'error': 'not_enough_points',
        'balance': await store.balance(from) ?? 0,
      }),
      PointTransferRefusal.pairNotPermitted => jsonResponse(403, {
        'error': 'pair_not_permitted',
      }),
      PointTransferRefusal.senderRestricted => jsonResponse(403, {
        'error': 'sender_restricted',
      }),
      PointTransferRefusal.recipientRestricted => jsonResponse(403, {
        'error': 'recipient_restricted',
      }),
      PointTransferRefusal.amountNotPositive => jsonResponse(400, {
        'error': 'amount_not_positive',
      }),
      PointTransferRefusal.self => jsonResponse(400, {'error': 'self'}),
      PointTransferRefusal.unknownRecipient => jsonResponse(404, {
        'error': 'unknown_recipient',
      }),
      PointTransferRefusal.unknownSender => jsonResponse(404, {
        'error': 'unknown_account',
      }),
    };
  });

  return router;
}
