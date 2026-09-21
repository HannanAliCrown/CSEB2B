import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../data/inaam_data_store.dart';
import 'json_helpers.dart';

/// Inaam Baazar: Spin and Win, Item Schemes, and the Reward Program.
///
/// Every prize is paid into the cash wallet, so no response here carries a
/// balance of its own — the wallet is the one place a partner checks what
/// they were paid.
Router inaamRoutes(InaamDataStore store) {
  final router = Router();

  /// `GET /inaam/spin?mobileNumber=` — the wheel, the entitlement earned by
  /// today's scans, and the history.
  router.get('/inaam/spin', (Request request) async {
    final mobileNumber = request.url.queryParameters['mobileNumber'];
    if (mobileNumber == null || mobileNumber.isEmpty) {
      return jsonResponse(400, {'error': 'mobileNumber is required'});
    }

    final state = await store.spinState(mobileNumber);
    if (state == null) {
      return jsonResponse(404, {'error': 'unknown_account'});
    }
    return jsonResponse(200, state.toJson());
  });

  /// `POST /inaam/spin` — takes one spin.
  router.post('/inaam/spin', (Request request) async {
    final body = await readJsonBody(request);
    final mobileNumber = body['mobileNumber'] as String?;
    if (mobileNumber == null) {
      return jsonResponse(400, {'error': 'mobileNumber is required'});
    }

    final (spin, refusal) = await store.spin(mobileNumber);

    return switch (refusal) {
      null => jsonResponse(201, spin!.toJson()),
      SpinRefusal.noSpinsAvailable => jsonResponse(409, {
        'error': 'no_spins_available',
      }),
      SpinRefusal.notConfigured => jsonResponse(409, {
        'error': 'not_configured',
      }),
      SpinRefusal.unknownAccount => jsonResponse(404, {
        'error': 'unknown_account',
      }),
    };
  });

  /// `GET /inaam/item-schemes?mobileNumber=` — every active scheme with this
  /// partner's progress and whether they have taken their one claim.
  router.get('/inaam/item-schemes', (Request request) async {
    final mobileNumber = request.url.queryParameters['mobileNumber'];
    if (mobileNumber == null || mobileNumber.isEmpty) {
      return jsonResponse(400, {'error': 'mobileNumber is required'});
    }

    final schemes = await store.itemSchemes(mobileNumber);
    if (schemes == null) {
      return jsonResponse(404, {'error': 'unknown_account'});
    }
    return jsonResponse(200, {
      'schemes': [for (final scheme in schemes) scheme.toJson()],
    });
  });

  /// `POST /inaam/item-schemes/claim` — takes the one claim a scheme allows.
  router.post('/inaam/item-schemes/claim', (Request request) async {
    final body = await readJsonBody(request);
    final mobileNumber = body['mobileNumber'] as String?;
    final schemeId = body['schemeId'] as String?;
    final tierId = body['tierId'] as String?;

    if (mobileNumber == null || schemeId == null || tierId == null) {
      return jsonResponse(400, {
        'error': 'mobileNumber, schemeId and tierId are required',
      });
    }

    final (scheme, refusal) = await store.claimTier(
      mobileNumber: mobileNumber,
      schemeId: schemeId,
      tierId: tierId,
    );

    // Each refusal keeps its own name: one is fixed by scanning more, one
    // cannot be fixed at all, and the partner is owed the difference.
    return switch (refusal) {
      null => jsonResponse(201, scheme!.toJson()),
      ClaimRefusal.notReached => jsonResponse(409, {'error': 'not_reached'}),
      ClaimRefusal.alreadyClaimed => jsonResponse(409, {
        'error': 'already_claimed',
      }),
      ClaimRefusal.unknownTier => jsonResponse(404, {'error': 'unknown_tier'}),
      ClaimRefusal.unknownAccount => jsonResponse(404, {
        'error': 'unknown_account',
      }),
    };
  });

  /// `GET /inaam/reward-program?mobileNumber=` — this month's programme and
  /// the award last month earned.
  router.get('/inaam/reward-program', (Request request) async {
    final mobileNumber = request.url.queryParameters['mobileNumber'];
    if (mobileNumber == null || mobileNumber.isEmpty) {
      return jsonResponse(400, {'error': 'mobileNumber is required'});
    }

    final program = await store.rewardProgram(mobileNumber);
    if (program == null) {
      return jsonResponse(404, {'error': 'unknown_account'});
    }
    return jsonResponse(200, program.toJson());
  });

  return router;
}
