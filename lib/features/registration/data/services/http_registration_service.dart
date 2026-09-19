import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/registration_draft.dart';
import 'registration_service.dart';

/// Where the prototype server lives. `10.0.2.2` is the host machine as the
/// Android emulator sees it; a device on the same network needs the machine's
/// LAN address passed in instead.
///
/// Supplied with `--dart-define=API_BASE_URL=...`, never hardcoded to
/// anything but the emulator default.
const String _apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://10.0.2.2:8080',
);

/// The [RegistrationService] backed by `prototype_server`, which owns the
/// PostgreSQL connection.
///
/// This is the seam the real API slots into: the endpoints below are the ones
/// the production service is expected to expose, so replacing it means
/// changing the base URL and, at most, the shape of a response — never the
/// ViewModel and never a screen.
class HttpRegistrationService implements RegistrationService {
  HttpRegistrationService({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      _baseUrl = baseUrl ?? _apiBaseUrl;

  final http.Client _client;
  final String _baseUrl;

  Uri _uri(String path, [Map<String, String>? query]) =>
      Uri.parse('$_baseUrl$path').replace(queryParameters: query);

  Future<Map<String, dynamic>> _get(
    String path, [
    Map<String, String>? query,
  ]) async {
    final response = await _client.get(_uri(path, query));
    return _decode(response);
  }

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, Object?> body,
  ) async {
    final response = await _client.post(
      _uri(path),
      headers: const {'content-type': 'application/json'},
      body: jsonEncode(body),
    );
    return _decode(response);
  }

  /// The body, with the status kept alongside it — several endpoints answer
  /// with a 4xx that is an outcome rather than a failure.
  Map<String, dynamic> _decode(http.Response response) {
    final body = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body) as Map<String, dynamic>;
    return {...body, '_status': response.statusCode};
  }

  @override
  Future<List<String>> markets() async {
    final body = await _get('/markets');
    return [
      for (final market in body['markets'] as List? ?? const [])
        (market as Map<String, dynamic>)['name'] as String,
    ];
  }

  @override
  Future<AccountLookupResult> lookupAccount(String mobileNumber) async {
    final body = await _get('/accounts/lookup', {'mobileNumber': mobileNumber});
    if (body['exists'] != true) return const AccountLookupResult.notFound();
    return AccountLookupResult.existing(
      role: _roleLabel(body['role'] as String?),
      displayName: body['displayName'] as String?,
    );
  }

  @override
  Future<OtpIssueResult> requestRegistrationOtp(String mobileNumber) async {
    final body = await _post('/registration/wizard/otp', {
      'mobileNumber': mobileNumber,
    });
    return OtpIssueResult(prototypeCode: body['code'] as String? ?? '');
  }

  @override
  Future<OtpVerifyOutcome> verifyRegistrationOtp({
    required String mobileNumber,
    required String code,
  }) async {
    final body = await _post('/registration/wizard/otp/verify', {
      'mobileNumber': mobileNumber,
      'code': code,
    });
    return body['outcome'] == 'verified'
        ? OtpVerifyOutcome.verified
        : OtpVerifyOutcome.invalidCode;
  }

  @override
  Future<BuyingSourceLookup> lookupBuyingSource(String mobileNumber) async {
    final body = await _get('/buying-sources/lookup', {
      'mobileNumber': mobileNumber,
    });
    if (body['found'] != true) return const BuyingSourceLookup.notFound();

    final name = body['name'] as String? ?? '';
    final role = _roleLabel(body['role'] as String?) ?? '';
    if (body['eligible'] != true) {
      return BuyingSourceLookup.ineligible(name: name, role: role);
    }
    return BuyingSourceLookup.found(
      name: name,
      role: role,
      market: body['market'] as String? ?? '',
    );
  }

  @override
  Future<bool> cnicAlreadyRegistered(String cnicNumber) async {
    final body = await _get('/accounts/cnic-holder', {
      'cnicNumber': cnicNumber,
    });
    return body['taken'] == true;
  }

  @override
  Future<RegistrationSubmission> submit(RegistrationDraft draft) async {
    final body = await _post(
      '/registration/applications',
      _applicationPayload(draft),
    );

    if (body['_status'] != 201) {
      throw RegistrationSubmitFailure(switch (body['error']) {
        'number_taken' => 'This number is already registered.',
        'cnic_taken' => 'A partner is already registered with this CNIC.',
        'application_open' =>
          'An application on this number is already waiting for approval.',
        _ => 'The application could not be submitted. Try again.',
      });
    }
    return _submissionFrom(body);
  }

  @override
  Future<RegistrationSubmission?> latestSubmission(String mobileNumber) async {
    final body = await _get('/registration/applications/latest', {
      'mobileNumber': mobileNumber,
    });
    if (body['_status'] != 200) return null;
    return _submissionFrom(body);
  }

  /// The wizard's draft as the application endpoint expects it. Media travels
  /// as rows rather than columns, so the three video slots and three image
  /// slots do not each need a field of their own.
  Map<String, Object?> _applicationPayload(RegistrationDraft draft) {
    final media = <Map<String, Object?>>[
      for (var i = 0; i < draft.videoLinks.length; i++)
        if (draft.videoLinks[i].trim().isNotEmpty)
          {
            'kind': 'video_link',
            'slot': '${i + 1}',
            'linkUrl': draft.videoLinks[i].trim(),
          },
      for (final entry in draft.shopImagePaths.entries)
        {'kind': 'shop_image', 'slot': entry.key, 'storagePath': entry.value},
      if (draft.cnicFrontPath != null)
        {'kind': 'cnic_front', 'storagePath': draft.cnicFrontPath},
      if (draft.cnicBackPath != null)
        {'kind': 'cnic_back', 'storagePath': draft.cnicBackPath},
      if (draft.selfiePath != null)
        {'kind': 'selfie', 'storagePath': draft.selfiePath},
    ];

    return {
      'mobileNumber': draft.nationalMobileNumber,
      'countryCode': draft.countryCode,
      'mobileVerified': draft.mobileVerified,
      'role': draft.role?.name ?? RegistrationRole.installer.name,
      'fullName': draft.fullName,
      'alternateNumber': draft.alternateNumber.isEmpty
          ? null
          : draft.alternateNumber,
      'businessName': draft.businessName,
      'businessAddress': draft.businessAddress,
      'marketName': draft.market,
      'shopLatitude': draft.shopLatitude,
      'shopLongitude': draft.shopLongitude,
      'cnicNumber': draft.cnicNumber,
      'buyingSources': [
        for (var i = 0; i < draft.buyingSources.length; i++)
          {'position': i, 'mobileNumber': draft.buyingSources[i].mobileNumber},
      ],
      'media': media,
    };
  }

  RegistrationSubmission _submissionFrom(Map<String, dynamic> body) {
    final states = <String, RegistrationApprovalState>{};
    for (final entry in body['approvals'] as List? ?? const []) {
      final approval = entry as Map<String, dynamic>;
      states[approval['approver'] as String] = switch (approval['state']) {
        'approved' => RegistrationApprovalState.approved,
        'rejected' => RegistrationApprovalState.rejected,
        _ => RegistrationApprovalState.outstanding,
      };
    }

    return RegistrationSubmission(
      reference: body['reference'] as String,
      submittedAt: DateTime.parse(body['submittedAt'] as String),
      verifyingSourceName: body['verifyingSourceName'] as String?,
      buyingSourceState:
          states['buying_source'] ?? RegistrationApprovalState.outstanding,
      marketingOfficerState:
          states['marketing_officer'] ?? RegistrationApprovalState.outstanding,
      crmState: states['crm'] ?? RegistrationApprovalState.outstanding,
    );
  }

  /// The database stores a role in lower case; every screen shows it in the
  /// form the design uses.
  static String? _roleLabel(String? userType) => switch (userType) {
    'installer' => 'Installer',
    'retailer' => 'Retailer',
    'wholesaler' => 'Wholesaler',
    'distributor' => 'Distributor',
    _ => null,
  };
}
