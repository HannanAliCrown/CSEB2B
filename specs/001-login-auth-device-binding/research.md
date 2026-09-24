# Phase 0 Research: Login, Authentication, and Device Binding

**Input**: [spec.md](./spec.md) | **Constitution**: `.specify/memory/constitution.md`

This research resolves every technical unknown needed to fill the plan's
Technical Context. It does not revisit business rules already decided (or
deliberately left open) in `spec.md` — the two Open Questions there (OTP
expiry duration, session-expiration duration) are business decisions, not
research tasks, and remain unresolved here as well.

## Existing project inspection (prerequisite for all decisions below)

Per the spec's "Existing Flutter Architecture" section, the actual project
was inspected before making any technology choice:

- **State management**: `provider` (`^6.1.5+1`, confirmed in `pubspec.yaml`)
  + `ChangeNotifier`, constructor injection. ViewModels are provided at the
  route that uses them (`lib/app/router/app_router.dart`), not in a global
  container.
- **Navigation**: `go_router` (`^18.0.1`, confirmed in `pubspec.yaml`), with
  route paths as constants on `AppRoutes`.
- **Architecture**: `View → ViewModel → Repository → Service`
  (`docs/ARCHITECTURE.md`), feature-first under `lib/features/<feature>/`
  with `data/{models,repositories,services}` and `ui/{views,view_models,
  widgets}`. No domain/use-case layer, no service locator, no `BaseX`
  classes, no networking stack yet (`dio`/`retrofit` deliberately absent —
  "belong to the first feature that has an API contract").
- **Design system**: `lib/core/theme/` is the token authority; values are
  currently **provisional** pending a Claude Design MCP sync
  (`docs/DESIGN_SYSTEM.md`). `/design-login` must be run and the real
  tokens pulled from the `cse-design-system` bundle before this feature's
  screens are built — this is an implementation-time task, not a planning
  artifact, and is captured as such in `quickstart.md`.
- **Localization**: ARB files under `lib/core/localization/arb/`
  (`app_en.arb`, `app_ur.arb`, `app_ur_Latn.arb`) generate
  `AppLocalizations` via `flutter gen-l10n`. Every new user-visible string
  in this feature must be added there.
- **Existing auth code**: none. `lib/features/bootstrap/` is a temporary
  shell (README: "should be deleted once the first real feature ships").
- **Testing**: `flutter_test` only; `test/` mirrors `lib/` per feature.
- **Toolchain**: Flutter SDK `^3.13.3` (Dart), developed against Flutter
  3.47.4; Flutter is installed at `C:\src\flutter`, not on `PATH` (must be
  prefixed or added to `PATH` for the session, per `CLAUDE.md`).

No competing state-management, routing, DI, or UI framework is introduced
by this feature; the decisions below extend the existing architecture with
the smallest set of new dependencies the spec's persistence and security
requirements actually require.

## Decision: PostgreSQL is reached through a separate local prototype server process — never from inside the Flutter app

**Revised** (see plan.md "What changed" for why this superseded the
original decision below): a Postgres driver running *inside the Flutter
process* is still Flutter connecting directly to PostgreSQL, no matter
which class wraps it or what that class is named. FR-038 is a boundary
about the **process**, not just the code layer. Satisfying it requires an
actual network hop between the Flutter app and PostgreSQL.

**Decision**: Introduce a small standalone Dart HTTP server,
`prototype_server/` (its own package, own `pubspec.yaml`, sibling to
`lib/` at the repository root — not part of the Flutter app), built with
`shelf` + `shelf_router`. This server is the **only** place the `postgres`
package is used and the only process that ever opens a PostgreSQL
connection. It implements the REST endpoints listed in
`contracts/auth-service.md` and owns all business-rule enforcement
(device-trust evaluation, atomic rebinding, OTP verification) against
PostgreSQL — see plan.md "Prototype Business-Rule Enforcement Boundary."

On the Flutter side, `AuthService` (the interface `AuthRepository` depends
on) has exactly **one** implementation for this feature's entire life:
`HttpAuthService`, using the `http` package to call
`prototype_server`'s REST endpoints. Moving to production later means
pointing the same `HttpAuthService` at the real ASP.NET Core API's base
URL — a configuration change, not a code change, which satisfies FR-040
more strongly than an in-process swap would have.

```text
Prototype:
Flutter UI → ViewModel → AuthRepository → AuthService (HttpAuthService)
  → HTTP → prototype_server (shelf) → postgres package → PostgreSQL

Production (future, out of scope for this feature):
Flutter UI → ViewModel → AuthRepository → AuthService (HttpAuthService)
  → HTTP → ASP.NET Core API → SQL Server
```

**Rationale**: This is the smallest change that makes "Flutter MUST NOT
connect directly to PostgreSQL" true in the literal, process-boundary
sense the correction requires, while reusing the project's existing
language/toolchain (Dart) rather than introducing a second runtime
(e.g., .NET) for the prototype phase. `shelf` is a minimal, dependency-
light HTTP server library — not a competing application framework — so it
does not conflict with `AGENTS.md`'s "do not add infrastructure before an
API feature exists": this feature *is* the first one with an API contract
(`contracts/auth-service.md`), which is precisely the condition
`docs/ARCHITECTURE.md` names as the trigger for finally adding an HTTP
client (`http`) to the Flutter app.

**Alternatives considered**:
- *Postgres driver inside a Flutter-side `Service` class* (the original
  decision) — rejected per the explicit correction: an in-process driver
  is still "Flutter connects to PostgreSQL," regardless of which
  architectural layer wraps it.
- *A minimal ASP.NET Core Web API as the prototype server, matching the
  production stack exactly now* — a legitimate alternative, explicitly
  flagged for override: it would mean the prototype and production
  servers are literally the same technology (only the database target
  differs, Postgres now vs. SQL Server later). It was not chosen as the
  default because it requires a .NET SDK in the dev environment for a
  project that currently has none, adding toolchain burden purely for the
  prototype loop. If the team already runs .NET tooling, or wants the
  prototype and production servers to share code, this is the better
  choice and can replace `prototype_server/` without any Flutter-side
  change (the HTTP contract stays identical).
- *`sqflite`/`drift` instead of PostgreSQL* — still rejected; the spec
  requires PostgreSQL specifically.
- *A hosted Postgres-over-REST layer (PostgREST/Supabase)* — still
  rejected; adds an external service dependency the spec never asks for.

**Local connectivity note (prototype-only, not a business rule)**: an
Android emulator reaches the host machine via `10.0.2.2`, not `localhost`;
iOS Simulator reaches it via `localhost` directly; a physical device needs
the host's LAN IP. This applies twice now: `prototype_server` → PostgreSQL
(same-host, so `localhost` is fine there), and the Flutter app →
`prototype_server` (needs the emulator-aware host above). Both are
`quickstart.md` prerequisites, read from local, non-committed run
configuration (`--dart-define` for Flutter, environment variables for
`prototype_server`), never hardcoded, per the constitution's "Secrets...
are never invented or committed."

## Decision: `flutter_secure_storage` for local session + device-identity persistence

**Decision**: Use `flutter_secure_storage` to persist the two pieces of
purely local, non-authoritative state this feature needs on-device: (a)
the generated device identifier, and (b) the "Keep Me Signed In" session
record (account reference, device reference, issued-at, and whether the
session was established with Keep Me Signed In on).

**Rationale**: FR-047 requires that sensitive authentication/session
information not be stored insecurely, and that production-equivalent
tokens use secure storage; applying the same standard now costs nothing
extra and avoids a later migration. It also satisfies FR-039 precisely:
per spec, "session-specific local information may use appropriate Flutter
local storage" — this *is* that appropriate local storage — while the
authoritative Account/Device/AccountDeviceBinding/OTP/RebindingAuthorization
state stays exclusively in PostgreSQL, reached only by `prototype_server`.

**As built (2026-09-24)**: the device identifier and the `Session` record
do use `flutter_secure_storage`. The live login path, however, also saves
the signed-in partner's profile through the app's `shared_preferences`-
backed `AppPreferences` (`lib/features/session/data/session_repository.dart`),
and that record — not the secure `Session` — is what the live restore
reads (see `data-model.md` → Local-only entities).

**Alternatives considered**:
- *`shared_preferences`* — rejected: plaintext storage, and the spec's
  security requirements plus the project's own "no SharedPreferences as
  primary store" instruction (interpreted here to extend to session/token
  data, the most sensitive local artifact this feature produces) argue for
  the secure option; the marginal cost of one additional package is
  justified by an explicit FR.

## Decision: `uuid` package for local device-identity generation

**Decision**: Generate a v4 UUID once per app installation (via the `uuid`
package), store it in secure storage, and treat it as "the current device"
for every FR/user story that compares "current device" against the
account's Active device.

**Rationale**: The spec (Assumptions) explicitly leaves the device-
identification mechanism undictated as an implementation detail. A
locally generated, installation-scoped UUID is the smallest mechanism that
satisfies every behavior the spec actually requires:
- It naturally reproduces the "reinstalled app = unbound device" edge case
  (FR-... / Edge Cases in `spec.md`): a reinstall has no persisted UUID, so
  a fresh one is generated, which will not match the account's stored
  Active-device identifier, correctly classifying it New/Untrusted.
- It needs no platform permission and no real hardware identifier, so it
  carries no privacy/permission complexity the spec never asked for.

**Alternatives considered**:
- *`device_info_plus` (real hardware identifiers)* — rejected: adds
  platform-channel complexity and permission surface for a capability the
  spec does not require (the spec only needs *an* identifiable unit, not a
  hardware-true one); it would also behave differently on the "reinstall"
  edge case (some hardware IDs survive a reinstall, which the spec's own
  edge-case wording treats as *should* be treated as unbound).

## Decision: OTP simulation surfaced for prototype testability

**Decision**: When an OTP challenge (registration or login-context) is
requested, `prototype_server` generates and persists the OTP value in the
`otp_challenges` table (see `data-model.md`) exactly as a real flow would,
but — because no real SMS provider exists — the generated code is
also returned to the caller (surfaced in the UI, e.g., a dev-only inline
hint or log) purely so the flow can be exercised end-to-end without a real
phone. No production OTP-delivery behavior is implied by this: it is
labeled a prototype-only testing convenience in the UI copy.

**Rationale**: This is a "how do we make the prototype runnable" decision,
not a business rule — it invents no expiry, retry, or lockout policy,
which the spec explicitly forbids inventing. The spec requires that OTP
verification be demonstrably exercised (`quickstart.md` scenarios need a
way to obtain the code); this is the minimal way to do that.

**Alternatives considered**:
- *Hardcode a fixed OTP value (e.g., always `123456`)* — rejected: less
  faithful to the real challenge/response shape the data model and FRs
  describe (each OTP challenge is a distinct persisted record), and it
  would make the "invalid OTP" scenario un-demonstrable without extra
  logic to special-case rejection.

## Decision: Testing approach (two independent tiers)

**Decision**:

1. **Flutter side** (`flutter_test`, run via `flutter test`): unit/widget
   tests cover ViewModels and `AuthRepository`'s response-mapping logic
   against a hand-written in-memory fake `AuthService` (no plugin/mocking
   framework added). These run without `prototype_server` or PostgreSQL
   and are part of the required `dart format . && flutter analyze &&
   flutter test` gate. Because device-trust and rebinding decisions now
   live server-side (see plan.md "Prototype Business-Rule Enforcement
   Boundary"), these tests validate that the Repository/ViewModel
   correctly *interpret and render* every outcome `AuthService` can
   return — not that they independently reimplement the business rules.
2. **`prototype_server` side** (`dart test`, its own package): unit tests
   for request-handling logic against a fake/in-memory data layer, plus a
   small number of scenarios run manually against a real local PostgreSQL
   instance to validate the actual atomic-transaction and integrity-
   constraint behavior described in `data-model.md` — this is normal for
   a prototype whose premise is "behaves like the real thing against a
   real local database," and is called out explicitly as an environment-
   dependent verification step, not hidden or skipped silently
   (constitution Principle IX). `quickstart.md` documents these.

**Alternatives considered**:
- *Mocking framework (`mocktail`/`mockito`)* — not added on either side; a
  single hand-written fake is enough for each package's test surface.
- *Dockerized/CI-run PostgreSQL for automated integration tests* — out of
  scope: no CI/CD infrastructure exists yet and none was requested
  (`AGENTS.md`: "CI/CD infrastructure unless explicitly requested").

## Summary of new dependencies introduced by this feature

**Flutter app** (`pubspec.yaml`):

| Package | Purpose | Justification |
|---|---|---|
| `http` | Calls `prototype_server` (and, later, the production API) through the one `HttpAuthService` implementation of `AuthService` | FR-037/FR-038/FR-040 — this is the feature that first has an API contract, the condition `docs/ARCHITECTURE.md` names for adding an HTTP client |
| `flutter_secure_storage` | Local device-id + session persistence | FR-047 (secure storage for sensitive local data), FR-039 (session-specific local storage) |
| `uuid` | Local device-identifier generation | Assumptions: device-identification mechanism is a planning decision; smallest option that satisfies every FR/edge case |

**`prototype_server`** (separate package, its own `pubspec.yaml` — never
added to the Flutter app's dependencies):

| Package | Purpose | Justification |
|---|---|---|
| `postgres` | PostgreSQL driver | FR-039 requires PostgreSQL as the prototype's authoritative store |
| `shelf`, `shelf_router` | Minimal HTTP server + routing | Smallest way to expose `contracts/auth-service.md`'s REST shape locally, per the corrected FR-038 boundary |

No state-management, routing, DI, or design-system package is added or
changed in the Flutter app; `dio`/retrofit/mocking frameworks remain
deliberately absent, matching the existing project's stated position.
`postgres` is never a Flutter dependency.
