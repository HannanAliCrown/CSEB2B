// Constructor parameters are named for their public API rather than the
// private fields they populate, so the initializing-formal shorthand the
// linter suggests is not available here.
// ignore_for_file: prefer_initializing_formals

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../session/data/signed_in_user.dart';
import '../../wallet/data/wallet_repository.dart';
import 'dashboard_repository.dart';

/// Home, read from the database behind `prototype_server`.
///
/// The slider and the ticker are content: rows with a window they run for,
/// filtered by role before they ever reach the phone. Adding a slide is a
/// row, not a release.
///
/// The partner's own name and role are not fetched here — they came with
/// sign-in, and Home reads the signed-in partner rather than asking twice.
class HttpDashboardRepository implements DashboardRepository {
  HttpDashboardRepository({required String baseUrl, http.Client? client})
    : _baseUrl = baseUrl,
      _client = client ?? http.Client();

  final String _baseUrl;
  final http.Client _client;

  @override
  Future<Dashboard> load(SignedInUser user) async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/dashboard')
          .replace(queryParameters: {'mobileNumber': user.mobileNumber}),
    );

    if (response.statusCode != 200) {
      // Nothing is invented to fill the gap: an empty Home is honest, a
      // fabricated balance is not.
      return Dashboard(
        balance: const Money(0),
        heldNote: null,
        slides: const [],
        tickerMessages: const [],
        scanSubtitle: _scanSubtitleFor(user),
      );
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final held = Money((body['heldPaisa'] as num?)?.toInt() ?? 0);

    return Dashboard(
      balance: Money((body['availablePaisa'] as num?)?.toInt() ?? 0),
      heldNote: held.paisa == 0
          ? null
          : '${held.formatted} held until the receiver accepts it',
      slides: [
        for (final entry in body['slides'] as List? ?? const [])
          _slideFrom(entry as Map<String, dynamic>),
      ],
      tickerMessages: [
        for (final entry in body['ticker'] as List? ?? const [])
          _tickerFrom(entry as Map<String, dynamic>),
      ],
      scanSubtitle: _scanSubtitleFor(user),
    );
  }

  PromoSlide _slideFrom(Map<String, dynamic> json) => PromoSlide(
    id: json['id'] as String? ?? '',
    eyebrow: json['eyebrow'] as String? ?? '',
    headline: json['headline'] as String? ?? '',
    imageUrl: json['imageUrl'] as String?,
  );

  TickerMessage _tickerFrom(Map<String, dynamic> json) => TickerMessage(
    text: json['message'] as String? ?? '',
    textColour: TickerMessage.parseColour(json['textColour'] as String?),
    backgroundColour: TickerMessage.parseColour(
      json['backgroundColour'] as String?,
    ),
  );

  /// Decided from the role rather than fetched: what the Scan card can do is
  /// a property of the partner, not content someone schedules.
  static String _scanSubtitleFor(SignedInUser user) => user.role.earnsPrizes
      ? 'Check a product or claim a prize'
      : 'Check a product is genuine';
}
