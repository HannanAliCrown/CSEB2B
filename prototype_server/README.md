# prototype_server

Local prototype backend for the Crown Solar Energy Flutter app's
Login, Authentication, and Device Binding feature
(`specs/001-login-auth-device-binding/`).

## What this is

The **only** process in this repository that opens a PostgreSQL connection
or enforces the feature's device-binding/rebinding business rules. The
Flutter app never connects to PostgreSQL directly (FR-035) — it calls this
server over HTTP through `HttpAuthService`
(`lib/features/auth/data/services/http_auth_service.dart`), following the
contract in `specs/001-login-auth-device-binding/contracts/auth-service.md`.

```text
Flutter UI → ViewModel → AuthRepository → AuthService (HttpAuthService)
  → HTTP → prototype_server (this package) → PostgreSQL
```

## What this is NOT

**This is prototype business-rule enforcement, not a production security
boundary** (FR-045). This server:

- runs unauthenticated, over plain HTTP, on the developer's own machine
- reads PostgreSQL credentials from local environment variables, never
  committed
- has no rate limiting, no TLS, no real SMS/OTP delivery, no real CRM
  integration

In production, this server is replaced by a real ASP.NET Core API against
SQL Server, reachable through the exact same `AuthService` HTTP contract —
see `specs/001-login-auth-device-binding/spec.md` §Prototype vs. Production
Boundary.

## Running locally

```bash
dart pub get
$env:PG_HOST = "localhost"
$env:PG_PORT = "5432"
$env:PG_DATABASE = "cse_b2b_prototype"
$env:PG_USER = "<local-dev-user>"
$env:PG_PASSWORD = "<local-dev-password>"
$env:PORT = "8080"        # optional, defaults to 8080
dart run bin/server.dart
```

Apply `lib/db/schema.sql` and, for local testing, `seed/seed.sql` against
the target database before starting the server. See
`specs/001-login-auth-device-binding/quickstart.md` for the full
prerequisites and scenario walkthrough.

## Tests

```bash
dart test
```

Runs entirely against an in-memory fake data store (`test/support/`) — no
PostgreSQL connection required. See
`specs/001-login-auth-device-binding/quickstart.md` for the separate,
manually-run scenarios that validate this server against a real local
PostgreSQL instance.
