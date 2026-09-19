// Constructor parameters are named for their public API rather than the
// private fields they populate, so the initializing-formal shorthand the
// linter suggests is not available here.
// ignore_for_file: prefer_initializing_formals

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/mock/partner_directory.dart';
import '../../../core/mock/pending_registrations.dart';
import 'signed_in_user.dart';

/// Who a mobile number belongs to.
///
/// This is the seam under [SessionRepository]: the repository owns the
/// session record on the phone, this owns the question "is this number
/// anybody". Swapping the implementation is what moves sign-in from the
/// bundled directory to the database, and later to the real API.
abstract interface class SessionService {
  /// The partner this number signs in as, or null when it is nobody.
  ///
  /// A returned user may be unapproved: an application still waiting on its
  /// approvals signs in to watch them, not to use the app.
  Future<SignedInUser?> findPartner(String mobileNumber);
}

/// Sign-in against the bundled directory and the applications submitted on
/// this phone. What the app used before there was a database.
class MockSessionService implements SessionService {
  const MockSessionService();

  @override
  Future<SignedInUser?> findPartner(String mobileNumber) async {
    final pending = PendingRegistrations.find(mobileNumber);
    final account = PartnerDirectory.find(mobileNumber);
    if (pending == null && account == null) return null;

    return switch ((pending, account)) {
      // A submitted application, still waiting: signed in, but unapproved.
      (final p?, _) when !p.isApproved => SignedInUser.fromPending(p),
      // Approved, or an account that already existed.
      (_, final a?) => SignedInUser.fromAccount(a),
      (final p?, _) => SignedInUser.fromPending(p).copyWith(approved: true),
      _ => null,
    };
  }
}

/// Sign-in against `prototype_server`, which owns the PostgreSQL connection.
///
/// One call answers both cases the sign-in screen cares about — an open
/// account, and an application still waiting — because the app has to know
/// which before it can decide between Home and the approval screen.
class HttpSessionService implements SessionService {
  HttpSessionService({required String baseUrl, http.Client? client})
    : _baseUrl = baseUrl,
      _client = client ?? http.Client();

  final String _baseUrl;
  final http.Client _client;

  @override
  Future<SignedInUser?> findPartner(String mobileNumber) async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/session/lookup')
          .replace(queryParameters: {'mobileNumber': mobileNumber}),
    );
    if (response.statusCode != 200) return null;

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final role = PartnerRole.values
        .where((value) => value.name == body['role'])
        .firstOrNull;
    if (role == null) return null;

    return SignedInUser(
      mobileNumber: _display(body['mobileNumber'] as String? ?? mobileNumber),
      businessName: body['businessName'] as String? ?? '',
      contactName: body['contactName'] as String? ?? '',
      role: role,
      market: body['market'] as String? ?? '',
      approved: body['approved'] == true,
    );
  }

  /// '+92 300 4821190' from the ten digits the database holds. Every screen
  /// shows a number this way, so it is put back together here rather than in
  /// each of them.
  static String _display(String nationalDigits) {
    if (nationalDigits.length != 10) return nationalDigits;
    return '+92 ${nationalDigits.substring(0, 3)} '
        '${nationalDigits.substring(3)}';
  }
}
