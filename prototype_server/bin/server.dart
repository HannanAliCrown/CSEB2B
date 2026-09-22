import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

import 'package:prototype_server/data/postgres_auth_data_store.dart';
import 'package:prototype_server/data/postgres_branding_data_store.dart';
import 'package:prototype_server/data/postgres_complaints_data_store.dart';
import 'package:prototype_server/data/postgres_inaam_data_store.dart';
import 'package:prototype_server/data/postgres_partner_data_store.dart';
import 'package:prototype_server/data/postgres_points_data_store.dart';
import 'package:prototype_server/data/postgres_profile_data_store.dart';
import 'package:prototype_server/data/postgres_scan_data_store.dart';
import 'package:prototype_server/data/postgres_wallet_data_store.dart';
import 'package:prototype_server/data/postgres_social_data_store.dart';
import 'package:prototype_server/db/postgres_client.dart';
import 'package:prototype_server/router.dart';

Future<void> main() async {
  final client = PostgresClient.fromEnvironment();
  final store = PostgresAuthDataStore(client);
  final partners = PostgresPartnerDataStore(client);
  final social = PostgresSocialDataStore(client);
  final profile = PostgresProfileDataStore(client);
  final complaints = PostgresComplaintsDataStore(client);
  final wallet = PostgresWalletDataStore(client);
  final scan = PostgresScanDataStore(client);
  final points = PostgresPointsDataStore(client);
  final inaam = PostgresInaamDataStore(client);
  final branding = PostgresBrandingDataStore(client);
  final router = buildRouter(
    store,
    partners: partners,
    social: social,
    profile: profile,
    complaints: complaints,
    wallet: wallet,
    scan: scan,
    points: points,
    inaam: inaam,
    branding: branding,
  );

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
