// Constructor parameters are named for their public API rather than the
// private fields they populate, so the initializing-formal shorthand the
// linter suggests is not available here.
// ignore_for_file: prefer_initializing_formals

import 'dart:convert';

import 'package:http/http.dart' as http;

/// Someone who named this partner as their buying source, waiting to be
/// verified.
class ProfileRequest {
  const ProfileRequest({
    required this.applicationId,
    required this.reference,
    required this.mobileNumber,
    required this.contactName,
    required this.businessName,
    required this.role,
    required this.submittedAt,
    this.businessAddress,
    this.marketName,
    this.alternateNumber,
    this.shopLatitude,
    this.shopLongitude,
    this.otherBuyingSources = const [],
    this.media = const [],
  });

  final String applicationId;

  /// What the applicant quotes, e.g. 'CSE-4821190'.
  final String reference;

  final String mobileNumber;
  final String contactName;
  final String businessName;

  /// 'installer' or 'retailer' — the only two roles that can apply.
  final String role;

  final String? businessAddress;
  final String? marketName;
  final DateTime submittedAt;

  /// The rest of what they submitted. The CNIC number is deliberately not
  /// here: a buying source is confirming that someone buys from them, not
  /// identifying them, so it never leaves CRM.
  final String? alternateNumber;
  final String? shopLatitude;
  final String? shopLongitude;
  final List<String> otherBuyingSources;
  final List<ProfileRequestItem> media;

  /// 'Installer', as the screens print it.
  String get roleLabel =>
      role.isEmpty ? role : role[0].toUpperCase() + role.substring(1);

  static ProfileRequest fromJson(Map<String, dynamic> json) => ProfileRequest(
    applicationId: json['applicationId'] as String,
    reference: json['reference'] as String,
    mobileNumber: json['mobileNumber'] as String,
    contactName: json['contactName'] as String,
    businessName: json['businessName'] as String,
    role: json['role'] as String,
    businessAddress: json['businessAddress'] as String?,
    marketName: json['marketName'] as String?,
    submittedAt: DateTime.parse(json['submittedAt'] as String).toLocal(),
    alternateNumber: json['alternateNumber'] as String?,
    shopLatitude: json['shopLatitude'] as String?,
    shopLongitude: json['shopLongitude'] as String?,
    otherBuyingSources: [
      for (final name in json['otherBuyingSources'] as List? ?? const [])
        name as String,
    ],
    media: [
      for (final entry in json['media'] as List? ?? const [])
        ProfileRequestItem.fromJson(entry as Map<String, dynamic>),
    ],
  );
}

/// The buying source's side of a registration, backed by the database behind
/// `prototype_server`.
///
/// There is deliberately no in-memory implementation. A verdict on someone
/// else's livelihood that is forgotten when the app restarts is worse than
/// one that plainly fails to be recorded.
class ProfileRequestsService {
  ProfileRequestsService({required String baseUrl, http.Client? client})
    : _baseUrl = baseUrl,
      _client = client ?? http.Client();

  final String _baseUrl;
  final http.Client _client;

  /// The requests waiting on this partner. Null when the server could not be
  /// reached — which the screen says, rather than showing an empty inbox.
  Future<List<ProfileRequest>?> pending(String mobileNumber) async {
    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/profile-requests')
            .replace(queryParameters: {'mobileNumber': mobileNumber}),
      );
      if (response.statusCode != 200) return null;

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return [
        for (final entry in body['requests'] as List? ?? const [])
          ProfileRequest.fromJson(entry as Map<String, dynamic>),
      ];
    } on Object {
      return null;
    }
  }

  /// How many are waiting, for the badge on Home. Zero when unreachable: a
  /// badge is a nudge, not a fact worth an error.
  Future<int> outstandingCount(String mobileNumber) async =>
      (await pending(mobileNumber))?.length ?? 0;

  /// The bands to choose from before approving anyone. Reference data, so
  /// the figures are Crown Solar's rather than the screen's.
  Future<List<ExpectedPurchase>> expectedPurchases() async {
    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/profile-requests/expected-purchase'),
      );
      if (response.statusCode != 200) return const [];

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return [
        for (final entry in body['bands'] as List? ?? const [])
          ExpectedPurchase.fromJson(entry as Map<String, dynamic>),
      ];
    } on Object {
      return const [];
    }
  }

  /// Records this partner's verdict. Approving needs an expected purchase;
  /// rejecting needs a reason. Null means it was recorded.
  Future<ProfileDecisionFailure?> decide({
    required String mobileNumber,
    required String applicationId,
    required bool approved,
    String? expectedPurchaseId,
    String? note,
  }) async {
    final http.Response response;
    try {
      response = await _client.post(
        Uri.parse('$_baseUrl/profile-requests/decision'),
        headers: const {'content-type': 'application/json'},
        body: jsonEncode({
          'mobileNumber': mobileNumber,
          'applicationId': applicationId,
          'approved': approved,
          'expectedPurchaseBandId': ?expectedPurchaseId,
          'note': ?note,
        }),
      );
    } on Object {
      return ProfileDecisionFailure.unreachable;
    }

    if (response.statusCode == 200) return null;

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return switch (body['error']) {
      'expected_purchase_required' => ProfileDecisionFailure.expectationMissing,
      'reason_required' => ProfileDecisionFailure.reasonMissing,
      'not_outstanding' => ProfileDecisionFailure.notOutstanding,
      _ => ProfileDecisionFailure.unreachable,
    };
  }
}

/// One thing the applicant submitted.
///
/// CNIC images never reach this type, and the server never selects them for
/// this screen. The buying source is confirming that someone buys from them,
/// not identifying them.
class ProfileRequestItem {
  const ProfileRequestItem({required this.kind, this.slot, this.linkUrl});

  /// 'video_link' | 'shop_image' | 'selfie'.
  final String kind;
  final String? slot;

  /// Set for a video the applicant typed a link to.
  final String? linkUrl;

  /// 'Installation video 1', 'Shop Board', 'Photo of the applicant'.
  String get label => switch (kind) {
    'video_link' => 'Installation video${slot == null ? '' : ' $slot'}',
    'shop_image' => slot ?? 'Shop photo',
    _ => 'Photo of the applicant',
  };

  /// Whether there is anything to open. An image lives on the applicant's
  /// own phone until file upload is built, so there is nothing to fetch.
  bool get openable => linkUrl != null;

  static ProfileRequestItem fromJson(Map<String, dynamic> json) =>
      ProfileRequestItem(
        kind: json['kind'] as String,
        slot: json['slot'] as String?,
        linkUrl: json['linkUrl'] as String?,
      );
}

/// One band of expected monthly purchasing, which a buying source has to
/// pick before they can approve anyone.
class ExpectedPurchase {
  const ExpectedPurchase({required this.id, required this.label});

  final String id;
  final String label;

  static ExpectedPurchase fromJson(Map<String, dynamic> json) =>
      ExpectedPurchase(
        id: json['id'] as String,
        label: json['label'] as String,
      );
}

/// Why a verdict was not recorded, in the words the screen shows.
enum ProfileDecisionFailure {
  expectationMissing,
  reasonMissing,
  notOutstanding,
  unreachable,
}

extension ProfileDecisionFailureX on ProfileDecisionFailure {
  String get message => switch (this) {
    ProfileDecisionFailure.expectationMissing =>
      'Choose what you expect them to buy before approving.',
    ProfileDecisionFailure.reasonMissing =>
      'Say why you are rejecting them. They are told the reason.',
    ProfileDecisionFailure.notOutstanding =>
      'This request is no longer waiting on you. Pull down to refresh.',
    ProfileDecisionFailure.unreachable =>
      'Could not record that. Nothing has changed — try again.',
  };
}
