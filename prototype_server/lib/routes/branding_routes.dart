import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../data/branding_data_store.dart';
import 'json_helpers.dart';

/// Shop Branding: the request, its status, and the board types a partner is
/// offered.
///
/// The eligibility rules are enforced in the store, not here — a handler
/// that decided which board a partner may have would be a second place for
/// the rule to live, and the two would drift.
Router brandingRoutes(BrandingDataStore store) {
  final router = Router();

  /// `GET /branding?mobileNumber=` — the landing screen: eligibility, the
  /// live request and the history behind it.
  router.get('/branding', (Request request) async {
    final mobileNumber = request.url.queryParameters['mobileNumber'];
    if (mobileNumber == null || mobileNumber.isEmpty) {
      return jsonResponse(400, {'error': 'mobileNumber is required'});
    }

    final landing = await store.landing(mobileNumber);
    if (landing == null) return jsonResponse(404, {'error': 'unknown_account'});
    return jsonResponse(200, landing.toJson());
  });

  /// `GET /branding/board-types?mobileNumber=` — what this partner may pick
  /// from right now, already filtered by replacement detection, role,
  /// points, scheme and recent scanning.
  router.get('/branding/board-types', (Request request) async {
    final mobileNumber = request.url.queryParameters['mobileNumber'];
    if (mobileNumber == null || mobileNumber.isEmpty) {
      return jsonResponse(400, {'error': 'mobileNumber is required'});
    }

    final options = await store.options(mobileNumber);
    if (options == null) return jsonResponse(404, {'error': 'unknown_account'});
    return jsonResponse(200, options.toJson());
  });

  /// `POST /branding/requests` — files a request.
  router.post('/branding/requests', (Request request) async {
    final body = await readJsonBody(request);

    final mobileNumber = body['mobileNumber'] as String?;
    final shopPhoto = body['shopPhotoPath'] as String?;
    final cardPhoto = body['cardPhotoPath'] as String?;
    final height = (body['heightFt'] as num?)?.toDouble();
    final width = (body['widthFt'] as num?)?.toDouble();
    final count = (body['boardCount'] as num?)?.toInt();
    final codes = (body['boardTypeCodes'] as List?)?.cast<String>();

    if (mobileNumber == null ||
        shopPhoto == null ||
        cardPhoto == null ||
        height == null ||
        width == null ||
        count == null ||
        codes == null) {
      return jsonResponse(400, {
        'error':
            'mobileNumber, shopPhotoPath, cardPhotoPath, heightFt, widthFt, '
            'boardCount and boardTypeCodes are required',
      });
    }

    final (created, refusal) = await store.createRequest(
      mobileNumber: mobileNumber,
      shopPhotoPath: shopPhoto,
      cardPhotoPath: cardPhoto,
      heightFt: height,
      widthFt: width,
      boardCount: count,
      boardTypeCodes: codes,
      shopAddress: body['shopAddress'] as String?,
      contactNumber: body['contactNumber'] as String?,
      personName: body['personName'] as String?,
    );

    // Each refusal keeps its own name: one is fixed by scanning or earning,
    // one by finishing the request already open, one by asking again.
    return switch (refusal) {
      null => jsonResponse(201, created!.toJson()),
      BrandingRefusal.unknownAccount => jsonResponse(404, {
        'error': 'unknown_account',
      }),
      BrandingRefusal.optionNotAvailable => jsonResponse(409, {
        'error': 'option_not_available',
      }),
      BrandingRefusal.boardCountMismatch => jsonResponse(400, {
        'error': 'board_count_mismatch',
      }),
      BrandingRefusal.requestAlreadyOpen => jsonResponse(409, {
        'error': 'request_already_open',
      }),
    };
  });

  /// `GET /branding/requests/<reference>?mobileNumber=` — one request.
  router.get('/branding/requests/<reference>', (
    Request request,
    String reference,
  ) async {
    final mobileNumber = request.url.queryParameters['mobileNumber'];
    if (mobileNumber == null || mobileNumber.isEmpty) {
      return jsonResponse(400, {'error': 'mobileNumber is required'});
    }

    final found = await store.request(
      mobileNumber: mobileNumber,
      reference: reference,
    );
    if (found == null) return jsonResponse(404, {'error': 'unknown_request'});
    return jsonResponse(200, found.toJson());
  });

  return router;
}
