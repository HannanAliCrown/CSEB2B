import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../data/scan_data_store.dart';
import '../data/wallet_data_store.dart';
import 'json_helpers.dart';

/// The wallet: the ledger, who can be paid, transfers — and the scanner,
/// because a winning scan is a movement of the same money.
Router walletRoutes(WalletDataStore wallet, {ScanDataStore? scan}) {
  final router = Router();

  /// `GET /wallet/ledger?mobileNumber=` — every movement, with the two
  /// totals derived from the same rows so they cannot disagree.
  router.get('/wallet/ledger', (Request request) async {
    final mobileNumber = request.url.queryParameters['mobileNumber'];
    if (mobileNumber == null || mobileNumber.isEmpty) {
      return jsonResponse(400, {'error': 'mobileNumber is required'});
    }

    final entries = await wallet.ledger(mobileNumber);
    if (entries == null) {
      return jsonResponse(404, {'error': 'unknown_account'});
    }
    final totals = await wallet.totals(mobileNumber);

    return jsonResponse(200, {
      'entries': [for (final entry in entries) entry.toJson()],
      'availablePaisa': totals?.availablePaisa ?? 0,
      'heldPaisa': totals?.heldPaisa ?? 0,
    });
  });

  /// `GET /wallet/recipients?mobileNumber=` — partners who can be paid.
  router.get('/wallet/recipients', (Request request) async {
    final mobileNumber = request.url.queryParameters['mobileNumber'];
    if (mobileNumber == null || mobileNumber.isEmpty) {
      return jsonResponse(400, {'error': 'mobileNumber is required'});
    }

    final recipients = await wallet.recipients(mobileNumber);
    if (recipients == null) {
      return jsonResponse(404, {'error': 'unknown_account'});
    }
    return jsonResponse(200, {
      'recipients': [for (final one in recipients) one.toJson()],
    });
  });

  /// `GET /wallet/recipients/lookup?mobileNumber=` — one typed number.
  router.get('/wallet/recipients/lookup', (Request request) async {
    final mobileNumber = request.url.queryParameters['mobileNumber'];
    if (mobileNumber == null || mobileNumber.isEmpty) {
      return jsonResponse(400, {'error': 'mobileNumber is required'});
    }

    final recipient = await wallet.lookupRecipient(mobileNumber);
    if (recipient == null) {
      return jsonResponse(404, {'error': 'unknown_recipient'});
    }
    return jsonResponse(200, recipient.toJson());
  });

  /// `GET /wallet/cash-requests?mobileNumber=` — transfers sent to this
  /// partner, waiting and decided.
  router.get('/wallet/cash-requests', (Request request) async {
    final mobileNumber = request.url.queryParameters['mobileNumber'];
    if (mobileNumber == null || mobileNumber.isEmpty) {
      return jsonResponse(400, {'error': 'mobileNumber is required'});
    }

    final requests = await wallet.cashRequests(mobileNumber);
    if (requests == null) {
      return jsonResponse(404, {'error': 'unknown_account'});
    }
    return jsonResponse(200, {
      'requests': [for (final one in requests) one.toJson()],
      'waiting': requests.where((one) => one.state == 'held').length,
    });
  });

  /// `POST /wallet/cash-requests/decision` — approve or reject one.
  router.post('/wallet/cash-requests/decision', (Request request) async {
    final body = await readJsonBody(request);
    final mobileNumber = body['mobileNumber'] as String?;
    final reference = body['reference'] as String?;
    final approved = body['approved'] as bool?;

    if (mobileNumber == null || reference == null || approved == null) {
      return jsonResponse(400, {
        'error': 'mobileNumber, reference and approved are required',
      });
    }

    final refusal = await wallet.decideCashRequest(
      mobileNumber: mobileNumber,
      reference: reference,
      approved: approved,
    );

    return switch (refusal) {
      null => jsonResponse(200, {'decided': true}),
      CashRequestRefusal.unknownAccount => jsonResponse(404, {
        'error': 'unknown_account',
      }),
      // Not found rather than forbidden: the answer must not confirm that
      // someone else's transfer exists.
      CashRequestRefusal.notWaiting => jsonResponse(404, {
        'error': 'not_waiting',
      }),
    };
  });

  /// `POST /wallet/transfers` — sends cash.
  router.post('/wallet/transfers', (Request request) async {
    final body = await readJsonBody(request);
    final from = body['fromMobileNumber'] as String?;
    final to = body['toMobileNumber'] as String?;
    final amount = (body['amountPaisa'] as num?)?.toInt();

    if (from == null || to == null || amount == null) {
      return jsonResponse(400, {
        'error':
            'fromMobileNumber, toMobileNumber and amountPaisa are '
            'required',
      });
    }

    final (entry, refusal) = await wallet.sendCash(
      fromMobileNumber: from,
      toMobileNumber: to,
      amountPaisa: amount,
      note: body['note'] as String?,
    );

    return switch (refusal) {
      // Every transfer waits on the receiver, so `held` is always true. It
      // is stated rather than assumed, because the screen promises it.
      null => jsonResponse(201, {'entry': entry!.toJson(), 'held': true}),
      TransferRefusal.amountTooSmall => jsonResponse(400, {
        'error': 'amount_too_small',
        'minimumPaisa': minimumTransferPaisa,
      }),
      TransferRefusal.self => jsonResponse(400, {'error': 'self'}),
      TransferRefusal.notEnoughBalance => jsonResponse(400, {
        'error': 'not_enough_balance',
      }),
      TransferRefusal.unknownRecipient => jsonResponse(404, {
        'error': 'unknown_recipient',
      }),
      TransferRefusal.unknownSender => jsonResponse(404, {
        'error': 'unknown_account',
      }),
    };
  });

  /// `POST /scan` — checks a code, and claims it when asked to.
  ///
  /// An authenticity check and a claim are the same request with `claim`
  /// false or true; they are one endpoint because they ask the same question
  /// of the same record, and differ only in whether the answer costs the
  /// code its prize.
  if (scan != null) {
    /// `GET /scan/intro?mobileNumber=` — what this partner can win, and the
    /// codes a demonstration can use. Registered before `/scan`, which is a
    /// POST and so could not collide, but kept first for the reader.
    router.get('/scan/intro', (Request request) async {
      final mobileNumber = request.url.queryParameters['mobileNumber'];
      if (mobileNumber == null || mobileNumber.isEmpty) {
        return jsonResponse(400, {'error': 'mobileNumber is required'});
      }
      final intro = await scan.intro(mobileNumber);
      if (intro == null) {
        return jsonResponse(404, {'error': 'unknown_account'});
      }
      return jsonResponse(200, intro.toJson());
    });

    router.post('/scan', (Request request) async {
      final body = await readJsonBody(request);
      final code = body['code'] as String?;
      final mobileNumber = body['mobileNumber'] as String?;
      if (code == null || mobileNumber == null) {
        return jsonResponse(400, {
          'error': 'code and mobileNumber are required',
        });
      }

      final outcome = await scan.check(
        code: code,
        mobileNumber: mobileNumber,
        claim: body['claim'] == true,
      );
      if (outcome == null) {
        return jsonResponse(404, {'error': 'unknown_account'});
      }
      return jsonResponse(200, outcome.toJson());
    });
  }

  return router;
}
