import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

import 'package:prototype_server/data/postgres_auth_data_store.dart';
import 'package:prototype_server/db/postgres_client.dart';
import 'package:prototype_server/router.dart';

Future<void> main() async {
  final client = PostgresClient.fromEnvironment();
  final store = PostgresAuthDataStore(client);
  final router = buildRouter(store);

  final pipeline = const Pipeline()
      .addMiddleware(logRequests())
      .addHandler(router.call);

  final port = int.tryParse(Platform.environment['PORT'] ?? '8080') ?? 8080;
  final server = await shelf_io.serve(pipeline, InternetAddress.anyIPv4, port);
  // ignore: avoid_print
  print(
    'prototype_server listening on http://${server.address.host}:${server.port}',
  );
  // ignore: avoid_print
  print(
    'This is a PROTOTYPE server — not a production security boundary (see README.md).',
  );
}
