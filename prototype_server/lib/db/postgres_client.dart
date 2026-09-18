import 'dart:io';

import 'package:postgres/postgres.dart';

/// Owns the PostgreSQL connection pool. Configuration comes exclusively
/// from environment variables — never hardcoded, never committed
/// (constitution: "secrets... are never invented or committed").
class PostgresClient {
  PostgresClient._(this.pool);

  final Pool pool;

  /// Reads PG_HOST/PG_PORT/PG_DATABASE/PG_USER/PG_PASSWORD from the
  /// environment and opens a pool. Throws a [StateError] listing the
  /// missing variable(s) if any required one is absent, instead of
  /// silently falling back to a guessed value.
  static PostgresClient fromEnvironment() {
    final env = Platform.environment;
    final missing = <String>[
      for (final key in ['PG_HOST', 'PG_DATABASE', 'PG_USER', 'PG_PASSWORD'])
        if (!env.containsKey(key) || env[key]!.isEmpty) key,
    ];
    if (missing.isNotEmpty) {
      throw StateError(
        'Missing required PostgreSQL environment variable(s): '
        '${missing.join(', ')}. See prototype_server/README.md.',
      );
    }
    final endpoint = Endpoint(
      host: env['PG_HOST']!,
      port: int.tryParse(env['PG_PORT'] ?? '5432') ?? 5432,
      database: env['PG_DATABASE']!,
      username: env['PG_USER'],
      password: env['PG_PASSWORD'],
    );
    final pool = Pool.withEndpoints([
      endpoint,
    ], settings: const PoolSettings(sslMode: SslMode.disable));
    return PostgresClient._(pool);
  }

  Future<void> close() => pool.close();
}
