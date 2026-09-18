import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

Future<Map<String, dynamic>> postJson(
  Router router,
  String path,
  Map<String, Object?> body,
) async {
  final request = Request(
    'POST',
    Uri.parse('http://localhost$path'),
    body: jsonEncode(body),
    headers: {'content-type': 'application/json'},
  );
  final response = await router.call(request);
  return {
    'statusCode': response.statusCode,
    'body': jsonDecode(await response.readAsString()),
  };
}

Future<Map<String, dynamic>> getJson(Router router, String path) async {
  final request = Request('GET', Uri.parse('http://localhost$path'));
  final response = await router.call(request);
  return {
    'statusCode': response.statusCode,
    'body': jsonDecode(await response.readAsString()),
  };
}
