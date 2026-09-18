import 'dart:convert';

import 'package:shelf/shelf.dart';

Response jsonResponse(int statusCode, Map<String, Object?> body) {
  return Response(
    statusCode,
    body: jsonEncode(body),
    headers: {'content-type': 'application/json'},
  );
}

Future<Map<String, dynamic>> readJsonBody(Request request) async {
  final raw = await request.readAsString();
  if (raw.isEmpty) return const {};
  return jsonDecode(raw) as Map<String, dynamic>;
}
