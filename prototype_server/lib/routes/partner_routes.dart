import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../data/partner_data_store.dart';
import '../data/partner_models.dart';
import 'json_helpers.dart';

/// First launch and the partner registration wizard.
///
/// One endpoint per method on the Flutter side's `RegistrationService`, so
/// the HTTP implementation of that interface is a thin translation and the
/// real API can take these paths over unchanged.
Router partnerRoutes(PartnerDataStore store) {
  final router = Router();

  // --- First launch ---

  /// `POST /devices/launch` — what first launch settled about this phone.
  /// Called once per answer, so a partner who declines location still leaves
  /// the language behind.
  router.post('/devices/launch', (Request request) async {
    final body = await readJsonBody(request);
    if (body['installationUuid'] is! String) {
      return jsonResponse(400, {'error': 'installationUuid is required'});
    }
    await store.recordDeviceLaunch(DeviceLaunchInput.fromJson(body));
    return jsonResponse(200, {'status': 'recorded'});
  });

  // --- Reference data ---

  /// `GET /markets` — the list the details step offers.
  router.get('/markets', (Request request) async {
    final markets = await store.markets();
    return jsonResponse(200, {
      'markets': [for (final market in markets) market.toJson()],
    });
  });

  // --- Lookups ---

  /// `GET /accounts/lookup?mobileNumber=` — is this number already an
  /// account? Answers the wizard's first question.
  router.get('/accounts/lookup', (Request request) async {
    final mobileNumber = request.url.queryParameters['mobileNumber'];
    if (mobileNumber == null || mobileNumber.isEmpty) {
      return jsonResponse(400, {'error': 'mobileNumber is required'});
    }
    final account = await store.findAccountByMobileNumber(mobileNumber);
    return jsonResponse(200, {
      'exists': account != null,
      if (account != null) ...{
        'role': account.userType,
        'displayName': account.displayName,
      },
    });
  });

  /// `GET /accounts/cnic-holder?cnicNumber=` — whether this identity has
  /// already registered. Returns only whether it is taken: naming the holder
  /// would tell one applicant about another's business.
  router.get('/accounts/cnic-holder', (Request request) async {
    final cnic = request.url.queryParameters['cnicNumber'];
    if (cnic == null || cnic.isEmpty) {
      return jsonResponse(400, {'error': 'cnicNumber is required'});
    }
    final account = await store.findAccountByCnic(cnic);
    return jsonResponse(200, {'taken': account != null});
  });

  /// `GET /buying-sources/lookup?mobileNumber=` — the business a buying
  /// source number resolves to, and whether it is one a partner may buy
  /// from. An installer buys the same way the applicant does, so it is found
  /// but not eligible.
  router.get('/buying-sources/lookup', (Request request) async {
    final mobileNumber = request.url.queryParameters['mobileNumber'];
    if (mobileNumber == null || mobileNumber.isEmpty) {
      return jsonResponse(400, {'error': 'mobileNumber is required'});
    }

    final account = await store.findAccountByMobileNumber(mobileNumber);
    if (account == null) {
      return jsonResponse(200, {'found': false, 'eligible': false});
    }

    const sellingRoles = {'retailer', 'wholesaler', 'distributor'};
    final eligible = sellingRoles.contains(account.userType);
    return jsonResponse(200, {
      'found': true,
      'eligible': eligible,
      'name': account.displayName,
      'role': account.userType,
      if (eligible) 'market': account.marketName,
    });
  });

  // --- Sign in ---

  /// `GET /session/lookup?mobileNumber=` — who this number is, for sign-in.
  ///
  /// An open account signs in and uses the app. An application still waiting
  /// on its approvals signs in too, but only to watch them land — so it comes
  /// back with `approved: false` and the app sends it to the approval screen
  /// rather than Home. A number that is neither is refused.
  router.get('/session/lookup', (Request request) async {
    final mobileNumber = request.url.queryParameters['mobileNumber'];
    if (mobileNumber == null || mobileNumber.isEmpty) {
      return jsonResponse(400, {'error': 'mobileNumber is required'});
    }

    final account = await store.findAccountByMobileNumber(mobileNumber);
    if (account != null) {
      return jsonResponse(200, {
        'approved': true,
        'mobileNumber': account.mobileNumber,
        'businessName': account.displayName,
        'contactName': account.contactName,
        'role': account.userType,
        'market': account.marketName,
      });
    }

    final application = await store.latestApplicationForNumber(mobileNumber);
    if (application == null || application.status != 'submitted') {
      return jsonResponse(404, {'error': 'unknown_number'});
    }

    return jsonResponse(200, {
      'approved': application.fullyApproved,
      'mobileNumber': application.mobileNumber,
      'businessName': application.businessName,
      'contactName': application.contactName,
      'role': application.role,
      'market': application.marketName,
      'application': application.toJson(),
    });
  });

  // --- Home ---

  /// `GET /dashboard?mobileNumber=` — the wallet figure, the slider and the
  /// ticker.
  ///
  /// The partner's own name and role are not here: the app already has them
  /// from sign-in, and Home reads the signed-in partner rather than asking
  /// twice.
  router.get('/dashboard', (Request request) async {
    final mobileNumber = request.url.queryParameters['mobileNumber'];
    if (mobileNumber == null || mobileNumber.isEmpty) {
      return jsonResponse(400, {'error': 'mobileNumber is required'});
    }
    final dashboard = await store.dashboardFor(mobileNumber);
    if (dashboard == null) {
      return jsonResponse(404, {'error': 'unknown_number'});
    }
    return jsonResponse(200, dashboard.toJson());
  });

  // --- Registration OTP ---

  /// `POST /registration/wizard/otp` — issues a code against a number that
  /// has no account yet. Distinct from `/registration/otp`, which belongs to
  /// device binding and requires an existing account.
  router.post('/registration/wizard/otp', (Request request) async {
    final body = await readJsonBody(request);
    final mobileNumber = body['mobileNumber'] as String?;
    if (mobileNumber == null || mobileNumber.isEmpty) {
      return jsonResponse(400, {'error': 'mobileNumber is required'});
    }
    final code = await store.issueWizardOtp(mobileNumber);
    return jsonResponse(200, {
      // Prototype-only: there is no SMS gateway, so the code comes back for
      // the wizard to display. Never a production behaviour.
      'code': code,
    });
  });

  router.post('/registration/wizard/otp/verify', (Request request) async {
    final body = await readJsonBody(request);
    final mobileNumber = body['mobileNumber'] as String?;
    final code = body['code'] as String?;
    if (mobileNumber == null || code == null) {
      return jsonResponse(400, {'error': 'mobileNumber and code are required'});
    }
    final verified = await store.verifyWizardOtp(
      mobileNumber: mobileNumber,
      code: code,
    );
    return jsonResponse(verified ? 200 : 400, {
      'outcome': verified ? 'verified' : 'invalid_code',
    });
  });

  // --- Applications ---

  /// `POST /registration/applications` — submits the wizard.
  router.post('/registration/applications', (Request request) async {
    final body = await readJsonBody(request);
    final ApplicationInput input;
    try {
      input = ApplicationInput.fromJson(body);
    } on Object {
      return jsonResponse(400, {'error': 'malformed_application'});
    }

    final result = await store.submitApplication(input);
    final application = result.application;
    if (application != null) {
      return jsonResponse(201, application.toJson());
    }

    return switch (result.rejection!) {
      SubmitRejection.numberTaken => jsonResponse(409, {
        'error': 'number_taken',
        'heldBy': result.heldBy,
      }),
      SubmitRejection.cnicTaken => jsonResponse(409, {'error': 'cnic_taken'}),
      SubmitRejection.applicationOpen => jsonResponse(409, {
        'error': 'application_open',
      }),
    };
  });

  /// `GET /registration/applications/latest?mobileNumber=` — what the
  /// approval screen reads.
  router.get('/registration/applications/latest', (Request request) async {
    final mobileNumber = request.url.queryParameters['mobileNumber'];
    if (mobileNumber == null || mobileNumber.isEmpty) {
      return jsonResponse(400, {'error': 'mobileNumber is required'});
    }
    final application = await store.latestApplicationForNumber(mobileNumber);
    if (application == null) return jsonResponse(404, {'error': 'not_found'});
    return jsonResponse(200, application.toJson());
  });

  return router;
}
