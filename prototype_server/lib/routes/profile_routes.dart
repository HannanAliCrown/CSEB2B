import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../data/profile_data_store.dart';
import 'json_helpers.dart';

/// Profile: language, theme, the app PIN, support numbers and About.
///
/// No response here ever carries a PIN. It travels one way only — in, to be
/// hashed or checked — and is never echoed back or logged.
Router profileRoutes(ProfileDataStore store) {
  final router = Router();

  /// `GET /profile/settings?mobileNumber=`
  router.get('/profile/settings', (Request request) async {
    final mobileNumber = request.url.queryParameters['mobileNumber'];
    if (mobileNumber == null || mobileNumber.isEmpty) {
      return jsonResponse(400, {'error': 'mobileNumber is required'});
    }
    final settings = await store.settings(mobileNumber);
    if (settings == null) {
      return jsonResponse(404, {'error': 'unknown_account'});
    }
    return jsonResponse(200, settings.toJson());
  });

  /// `PUT /profile/settings` — applies only the fields given.
  router.put('/profile/settings', (Request request) async {
    final body = await readJsonBody(request);
    final mobileNumber = body['mobileNumber'] as String?;
    if (mobileNumber == null) {
      return jsonResponse(400, {'error': 'mobileNumber is required'});
    }

    final settings = await store.updateSettings(
      mobileNumber: mobileNumber,
      languageCode: body['languageCode'] as String?,
      languageRemembered: body['languageRemembered'] as bool?,
      theme: body['theme'] as String?,
    );
    if (settings == null) {
      return jsonResponse(404, {'error': 'unknown_account'});
    }
    return jsonResponse(200, settings.toJson());
  });

  /// `POST /profile/pin` — sets a PIN, or changes one. Changing needs the
  /// current PIN in `currentPin`.
  router.post('/profile/pin', (Request request) async {
    final body = await readJsonBody(request);
    final mobileNumber = body['mobileNumber'] as String?;
    final pin = body['pin'] as String?;
    if (mobileNumber == null || pin == null) {
      return jsonResponse(400, {'error': 'mobileNumber and pin are required'});
    }

    final refusal = await store.setPin(
      mobileNumber: mobileNumber,
      pin: pin,
      currentPin: body['currentPin'] as String?,
    );
    return _refusalResponse(refusal, store, mobileNumber);
  });

  /// `POST /profile/pin/verify` — what the unlock screen asks.
  router.post('/profile/pin/verify', (Request request) async {
    final body = await readJsonBody(request);
    final mobileNumber = body['mobileNumber'] as String?;
    final pin = body['pin'] as String?;
    if (mobileNumber == null || pin == null) {
      return jsonResponse(400, {'error': 'mobileNumber and pin are required'});
    }
    final verified = await store.verifyPin(
      mobileNumber: mobileNumber,
      pin: pin,
    );
    // 200 either way: a wrong PIN is an answer, not a failure.
    return jsonResponse(200, {'verified': verified});
  });

  /// `POST /profile/pin/disable` — turning the PIN off needs the PIN.
  router.post('/profile/pin/disable', (Request request) async {
    final body = await readJsonBody(request);
    final mobileNumber = body['mobileNumber'] as String?;
    final pin = body['pin'] as String?;
    if (mobileNumber == null || pin == null) {
      return jsonResponse(400, {'error': 'mobileNumber and pin are required'});
    }

    final refusal = await store.disablePin(
      mobileNumber: mobileNumber,
      pin: pin,
    );
    return _refusalResponse(refusal, store, mobileNumber);
  });

  /// `GET /support/contacts?mobileNumber=` — the numbers Call Support offers.
  router.get('/support/contacts', (Request request) async {
    final mobileNumber = request.url.queryParameters['mobileNumber'];
    if (mobileNumber == null || mobileNumber.isEmpty) {
      return jsonResponse(400, {'error': 'mobileNumber is required'});
    }
    final contacts = await store.supportContacts(mobileNumber);
    return jsonResponse(200, {
      'contacts': [for (final contact in contacts) contact.toJson()],
    });
  });

  /// `GET /app/about` — the copy About App shows. Not the version: the
  /// installed binary knows that, and a row here could disagree with it.
  router.get('/app/about', (Request request) async {
    return jsonResponse(200, {'info': await store.appInfo()});
  });

  return router;
}

/// The settings after a PIN change, or why it was refused.
Future<Response> _refusalResponse(
  PinRefusal? refusal,
  ProfileDataStore store,
  String mobileNumber,
) async {
  if (refusal == null) {
    final settings = await store.settings(mobileNumber);
    return jsonResponse(200, settings?.toJson() ?? const {});
  }

  return switch (refusal) {
    PinRefusal.wrongPin => jsonResponse(403, {'error': 'wrong_pin'}),
    PinRefusal.malformed => jsonResponse(400, {
      'error': 'pin_must_be_4_digits',
    }),
    PinRefusal.unknownAccount => jsonResponse(404, {
      'error': 'unknown_account',
    }),
  };
}
