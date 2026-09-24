# Implementation Plan: Login, Authentication, and Device Binding

**Branch**: `001-login-auth-device-binding` | **Date**: 2026-09-17 (Revised) | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/001-login-auth-device-binding/spec.md`

**Note**: This template is filled in by the `/speckit-plan` command; its definition describes the execution workflow.

## What changed in this revision

**Revision 1** (carried forward): The first draft of this plan put a
`PostgresAuthService` — a class that imported the `postgres` driver —
**inside the Flutter app**, reasoning that it satisfied FR-038 ("Flutter
MUST NOT connect directly to PostgreSQL") because it was a `Service` class
one layer below the Repository. That was wrong: a PostgreSQL driver running
inside the Flutter process is Flutter connecting directly to PostgreSQL,
regardless of which Dart class wraps it. FR-038 is a boundary about the
**process**, not just the source-file layer. This revision moved all
PostgreSQL access into a genuinely separate local process,
`prototype_server/`, that the Flutter app talks to over HTTP.

**Revision 2** (this revision): `spec.md` was corrected to the final,
authoritative **device-move tiering** model — confirmed against the
Claude Design Login journey (screens A1–A4, B1–B2) and its functional
specification — replacing the earlier draft's "every New/Untrusted device
needs OTP, then CRM authorization" model with:

- **Second-device tier** (account's device-move count = 0): a login-context
  OTP alone is required; no rebinding-authorization outcome is ever
  consulted.
- **Third-or-later-device tier** (device-move count ≥ 1): a
  rebinding-authorization outcome of Authorized is required **before**
  any OTP is requested; Pending/Not Authorized means no OTP is ever
  requested for that attempt.
- A **device-conflict confirmation** (mirroring Claude Design's A4 dialog)
  is now required *before* any OTP is requested, whenever the target
  device is currently Active for a different account — independent of
  which tier gates the requesting account's own move.

This reverses the previously implemented ordering for the
third-or-later tier (which checked OTP before authorization) and adds a
pre-OTP conflict-confirmation gate that did not previously exist. Both
changes are reflected in "Prototype Business-Rule Enforcement &
Atomicity" and "UI State Implementation" below. **Registration (FR-001–
FR-005) is unaffected and is not re-planned here.**

**Reconciliation (2026-09-24)**: this plan was re-checked against the
code. Both revisions above are built. Two Flutter login flows now exist:

- **Live** — `/login` renders `LoginFlowScreen`
  (`lib/features/login/ui/views/login_flow_screen.dart`), the Claude
  Design board-02 screens. It is a `StatefulWidget` that calls
  `AuthRepository` directly (no ViewModel), then signs the partner in
  through `SessionController` (`lib/features/session/`), which loads the
  partner profile and owns the saved session. Its copy is hard-coded
  English.
- **Legacy** — `/login/legacy`, `/register/legacy`, `/home/legacy`
  render the earlier `LoginScreen` / `RegistrationScreen` / `HomeScreen`
  with `LoginViewModel` / `RegistrationViewModel` / `HomeViewModel`
  (`lib/features/auth/ui/`), localized via ARB.

Both use the same `AuthRepository` → `HttpAuthService` →
`prototype_server` path for every device-binding decision. Session
restoration differs: only the legacy route validates device binding
(see the "Persisted-session validation" row below).

## Summary

Partners sign in with only a registered mobile number. First contact with
an account is **registration** (out of scope for this feature — see
`spec.md` → "Out of Scope"): mobile number + OTP verification, and only on
success does the current device become that account's initial Active
device (Device 1; not itself a device move). Every later app open is
**login**: the current device is compared to the account's Active device —
a match skips OTP entirely (trusted device); a mismatch classifies the
device New/Untrusted, and, once any device-conflict confirmation is
resolved, gates the rest of the flow by the requesting account's
**device-move tier** — its *first* move (to "Device 2") needs only a
verified login-context OTP, while every move after that (to "Device 3"
and beyond) needs an externally sourced rebinding-authorization decision
of Authorized *before* any OTP is requested. Either path, once satisfied,
atomically revokes whatever the new device replaces (including a
conflicting binding on another account). "Keep Me Signed In" persists
only local session records — re-validated against current device-binding
state on the legacy route only, not on the live route (spec FR-033) — and
remains completely independent of device-move tiering in both directions.

Technically: the existing `View → ViewModel → Repository → Service`
architecture gains the Flutter feature module `lib/features/auth/`,
whose `AuthRepository` depends on an `AuthService` interface implemented
by `HttpAuthService` (plus the live screens in `lib/features/login/` —
see "Reconciliation" above). `HttpAuthService` calls a new, separate local
process — `prototype_server/`, a small Dart/`shelf` HTTP server — which is
the **only** thing that ever opens a PostgreSQL connection and the only
place device-binding/rebinding business rules are actually decided. Moving
to production later means pointing `HttpAuthService` at the real ASP.NET
Core API's URL; no Flutter code changes.

## Technical Context

**Language/Version**: Dart / Flutter SDK `^3.13.3` for the app (developed
against Flutter 3.47.4 — confirmed in `pubspec.yaml`/README; already the
project's toolchain). `prototype_server/` is a plain Dart package (no
Flutter dependency), using the same Dart SDK.

**Primary Dependencies**:

- *Flutter app* — existing: `flutter`, `flutter_localizations`, `go_router`
  `^18.0.1`, `provider` `^6.1.5+1`, `intl`. New (justified in
  `research.md`): `http` (calls `prototype_server`/future API via the sole
  `HttpAuthService` implementation of `AuthService`), `flutter_secure_storage`
  (local device-id + session persistence), `uuid` (local device-identifier
  generation). **`postgres` is never a Flutter dependency.**
- *`prototype_server/`* (separate package) — new: `postgres` (PostgreSQL
  driver), `shelf` + `shelf_router` (minimal HTTP server/routing).

**Storage**: PostgreSQL, local to the development environment, reached
**exclusively by `prototype_server/`**, as the prototype's sole
authoritative store for `accounts`, `devices`, `account_device_bindings`,
`otp_challenges`, and `rebinding_authorizations` (schema: `data-model.md`).
The local session records ("Keep Me Signed In") live only on the device,
never in PostgreSQL: the `Session` record in `flutter_secure_storage`, and
the live path's signed-in partner record in `shared_preferences`
(`data-model.md` → Local-only entities).

**Testing**: Two independent tiers (`research.md` → "Testing approach"):
(1) `flutter_test` for the Flutter app — ViewModels and `AuthRepository`
against a hand-written in-memory fake `AuthService`, no live server or
database required, part of the standard `flutter test` gate; (2) `dart
test` for `prototype_server` — its request-handling logic against a fake
data layer. `quickstart.md` additionally documents scenarios run manually
against a real `prototype_server` + local PostgreSQL instance, since that
is the only way to validate the actual atomic-transaction and
integrity-constraint behavior; no CI/CD infrastructure exists to automate
that tier yet.

**Target Platform**: Android 8+ (API 26+) and iOS 15+, portrait-first
mobile only, for the Flutter app (constitution's Technology Constraints;
README's iOS 15.0 floor note). `prototype_server` targets the developer's
own machine only — it is never built for or deployed to a mobile device.

**Project Type**: Mobile app (Flutter) plus one local-only prototype
backend process (`prototype_server/`, plain Dart). This is *not* a
traditional frontend/backend product split — `prototype_server` is never
deployed, ships to no user, and exists solely because FR-038 forbids the
Flutter client from reaching PostgreSQL itself. See Complexity Tracking
below for why this additional process is justified rather than avoided.

**Performance Goals**: No feature-specific numeric target beyond the
spec's own Success Criteria (e.g., SC-002/SC-003: a trusted sign-in or a
New/Untrusted classification each resolve as a direct consequence of one
sign-in submission). No new performance constraint introduced.

**Constraints**: Requires network reachability from the Flutter app to
`prototype_server`, and from `prototype_server` to PostgreSQL, to
authenticate at all — this prototype is not offline-capable for auth (a
production build's own offline/retry behavior is separately specified,
out of scope here). Localization (English / Urdu RTL / Roman Urdu LTR),
system text scaling, and accessible semantics apply to every new Flutter
screen (constitution Principle VIII). No production secrets, bundle
identifiers, or signing configuration are touched by this feature;
PostgreSQL connection details reach only `prototype_server`, via local,
non-committed environment configuration (`quickstart.md`).

**Scale/Scope**: One Flutter feature module (`lib/features/auth/`)
covering registration, login, OTP (both contexts), device-conflict/
rebinding, Keep Me Signed In, session restoration, and logout, across 4
identical-logic user types — plus one small local server package
(`prototype_server/`) exposing the 9 operations in
`contracts/auth-service.md` as REST endpoints. The exact number of Flutter
screens/dialogs/snackbars is not fixed here (see "UI State Implementation"
below); the Required UI States list in `spec.md` is a state inventory, not
a screen-count.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|---|---|---|
| I. Spec-Driven Development | **Pass** | `spec.md` exists, reviewed and twice revised; this plan (now itself revised once, for the FR-038 correction) derives from it, not from ad-hoc chat instructions. |
| II. Approved Design Is Authoritative | **Pass (deferred action noted)** | Claude Design tokens are currently provisional (`docs/DESIGN_SYSTEM.md`); a Claude Design MCP sync (`/design-login`) is required before screens are built in `/speckit-implement`, and the exact screen/dialog/state breakdown is determined then (see "UI State Implementation"), not invented here. |
| III. Simple MVVM | **Pass** | `View → ViewModel → Repository → Service`, no new Flutter-side layer. `AuthRepository` is now deliberately thin — it calls `AuthService` and translates the result for the ViewModel; it holds no independent copy of device-trust/rebinding logic, since that now lives in `prototype_server` (see "Prototype Business-Rule Enforcement Boundary" below). This is a *simplification* versus the original draft, not a new layer. **As built, the live `LoginFlowScreen` has no ViewModel** — the view holds the flow state and calls `AuthRepository` and `SessionController` itself; only the legacy route uses `LoginViewModel`. |
| IV. Centralized Design System | **Pass** | All new screens use `lib/core/theme/` tokens exclusively; `prototype_server` has no UI. |
| V. Minimum Necessary Dependencies | **Pass** | Flutter gains `http`, `flutter_secure_storage`, `uuid`, each tied to a specific FR. `postgres`/`shelf`/`shelf_router` belong only to `prototype_server`, never the Flutter app. No framework substitution. |
| VI. Scope Discipline | **Pass, with a flagged addition** | Touches `lib/features/auth/` (new), `app_router.dart` (add routes), and now also introduces `prototype_server/` as a sibling package — a larger footprint than a typical single-feature change, justified in Complexity Tracking below because FR-038 leaves no smaller option. `lib/features/bootstrap/` was superseded as the initial route and has been removed (T087). |
| VII. Testable Boundaries | **Pass** | Flutter: ViewModel/Repository response-mapping tested via a fake `AuthService`. `prototype_server`: its own request-handling logic tested via a fake data layer, independent of a live database. |
| VIII. Localization and Accessibility | **Pass (legacy screens) / Gap (live screens)** | The legacy auth screens use ARB strings; the live `LoginFlowScreen`/`SignInScreen` copy is hard-coded English. `prototype_server` has no UI and needs no localization. |
| IX. Verification | **Pass, two gates** | Flutter: `dart format .`, `flutter analyze`, `flutter test` (unchanged). `prototype_server`, being a separate Dart package, gets the equivalent `dart format .`, `dart analyze`, `dart test` run inside `prototype_server/` before a task touching it is complete — both are environment-appropriate, neither hidden. `quickstart.md`'s live-PostgreSQL scenarios remain a separate, explicitly-called-out manual tier. |
| X. No Overengineering | **Pass** | `prototype_server` is the smallest thing that makes FR-038 literally true: one HTTP server library (`shelf`), one router, one driver — no ORM, no auth framework, no `BaseController`/`BaseRepository`, no speculative endpoints beyond `contracts/auth-service.md`'s 9 operations. Still no `BaseViewModel`/`BaseRepository`/`BaseService`, no generic `Result<T>`, no service locator, no fake CRM UI, no multi-device Active state. |
| Technology Constraints | **Pass** | `provider` + `go_router` reused as confirmed present; Android 8+/iOS 15+ portrait-only. No secrets invented — all PostgreSQL connection details are local, non-committed configuration read by `prototype_server` only, never by the Flutter app. |

### Post-Phase-1 re-check

Re-evaluated after `research.md`, `data-model.md`,
`contracts/auth-service.md`, and `quickstart.md` were revised for the
FR-038 correction: no dependency, layer, or framework beyond what is
already justified above was introduced during design. Moving business-rule
enforcement into `prototype_server` *removed* logic from `AuthRepository`
rather than adding any — the net client-side complexity is lower than the
first draft, even though one new package exists. **All gates still Pass.
Complexity Tracking has exactly one entry (below), carried over from the
Scope Discipline row.**

## Prototype Business-Rule Enforcement & Atomicity

This section answers, explicitly, where each business rule from `spec.md`
is enforced in this architecture — all of it inside `prototype_server`,
against PostgreSQL, never in the Flutter app:

| Rule | Enforced by |
|---|---|
| At most one Active device per account | `account_device_bindings_one_active_per_account` partial unique index (`data-model.md`) — a second `INSERT` of an `active` row for the same account fails at the database level, not just in application logic. |
| At most one account owning a device as Active (no device-conflict double-Active) | `account_device_bindings_one_active_per_device` partial unique index (`data-model.md`) — same structural guarantee, keyed on `device_id`. |
| Atomic device rebinding / atomic device-conflict transfer, at either tier | `PostgresAuthDataStore.completeRebinding` (called by `POST /rebindings`) wraps the OTP/tier/authorization re-checks and the revoke-old / revoke-conflicting-binding / activate-new writes in **one PostgreSQL transaction**; if any write fails (including a unique-index violation), the whole transaction rolls back and the route returns `409`, so the two indexes above are never observed to be violated even transiently, and no step is left half-applied. This is identical regardless of which tier gated the requester's path to this operation. |
| Registration initial-binding atomicity (FR-043) | `prototype_server`'s `verifyRegistrationOtp` handler performs OTP verification and the initial `account_device_bindings` insert in one transaction: the OTP row is only marked `verified` and the binding row only committed together. If the insert fails, the transaction rolls back — including the OTP's `verified` flag — so the account never appears registered without a persisted Active device (see "Registration Transaction Semantics" below). **Unchanged by this revision — registration is out of scope for this feature.** |
| OTP verification required before initial binding | `verifyRegistrationOtp` is the only handler that can write an `initial_registration` binding row, and it only does so after checking `otp_challenges.verified` within the same transaction. |
| **Device-move tier determination (FR-015)** — *new in this revision* | `evaluateLogin` computes the requesting account's device-move count as `SELECT count(*) FROM account_device_bindings WHERE account_id = $1 AND context = 'rebinding'` (no new column; see `data-model.md`) and returns the resulting tier (`second_device` / `third_or_later`) to the client as part of its response. The Flutter client never computes or assumes this itself (FR-046) — it only branches its UI on the tier value the server returned. |
| **Device-conflict detection precedes tiering and OTP (FR-013/FR-014)** — *new in this revision* | `evaluateLogin` checks whether the target device currently has *any* `active` binding row for a **different** account before computing the tier. Its response carries both `conflict` (`{otherAccountId}` — the other account's id only, not its name) and `tier`; the Flutter client shows the confirmation step (Claude Design A4) first and calls `POST /login/confirm-takeover` before requesting any OTP. Declining performs no write at all. **The server does not record or require the confirmation** — `completeRebinding` transfers a conflicting device whether or not confirm-takeover was called. |
| **Second-device tier: OTP alone, no authorization check (FR-016)** — *revised* | For `tier = second_device`, the client goes `requestLoginOtp` → `verifyLoginOtp` → `completeRebinding`. `requestLoginOtp` and `completeRebinding` each re-derive the tier and, at this tier, never read or create a `rebinding_authorizations` row; the client never calls `checkRebindingAuthorization`. |
| **Third-or-later tier: authorization before OTP (FR-017/FR-018)** — *reversed from the prior implementation* | For `tier = third_or_later`, the client calls `checkRebindingAuthorization` first and shows B1 unless it is `authorized`. Independently, `requestLoginOtp` re-derives the tier and refuses (`403 not_authorized`, creating a `pending` row if none exists) unless the latest authorization for the pair is `authorized`, and `completeRebinding` re-checks it again inside its transaction. Built (Phase 13). |
| Pending / Authorized / Not Authorized rebinding state | `rebinding_authorizations.status` (`data-model.md`), written only by `prototype_server` (simulating the external/CRM decision — see `quickstart.md`'s seed-data note); never writable by the Flutter client (FR-028). Per FR-022/FR-016, this table is now conceptually scoped to the third-or-later tier only — a stray row for a second-device-tier account/device pair is never consulted. |
| Revoked-device behavior | `getDeviceBindingStatus`/`evaluateLogin` read `account_device_bindings` fresh on every call; a `revoked` row (or no `active` row at all) always classifies the device New/Untrusted — there is no cache or flag on the Flutter side that could let a revoked device "remember" trust. Re-attempting from a Revoked device is re-tiered against the account's *current* move count, never the count that applied when that device was first bound. |
| Persisted-session validation against current device binding | **Legacy route only.** `AuthRepository.restoreSession` calls `getDeviceBindingStatus` (via `HttpAuthService` → `prototype_server`) when `/login/legacy` is opened (FR-033); the local `Session` record carries no authority. **The live `/login` and signed-in routes restore through `SessionController.restore()`, which reads the saved partner record and does not check device binding — FR-033 is Not implemented there.** Independent of tiering in both directions (FR-030). |

**This is prototype business-rule enforcement, not a production security
boundary.** `prototype_server` runs unauthenticated, in plaintext HTTP, on
the developer's own machine, and PostgreSQL credentials live in local
environment configuration — none of that is acceptable for production.
What *does* carry forward unchanged to production is the **shape**: the
same `AuthService` operations, the same "the backend decides, the client
only renders" split, the same atomicity guarantees — now backed by the
ASP.NET Core API's own transactions/constraints against SQL Server instead
of `prototype_server`'s against PostgreSQL (`spec.md` → Prototype vs.
Production Boundary).

### Registration Transaction Semantics

The single logical operation is: **OTP verified → initial binding
persisted → registration succeeds.** Concretely, inside one PostgreSQL
transaction in `prototype_server`:

1. Look up the pending `otp_challenges` row for `(accountId, deviceId,
   context = 'registration')` and check the submitted code.
2. If it does not match: roll back (nothing to undo yet) and return an
   invalid-OTP outcome. No binding is created.
3. If it matches: within the *same* transaction, mark the OTP row
   `verified = true` **and** insert the `account_device_bindings` row
   (`status = 'active'`, `context = 'initial_registration'`).
4. Commit. Only after a successful commit does `verifyRegistrationOtp`
   return a success outcome to the Flutter app.
5. If the commit fails for any reason (including the partial unique index
   rejecting a concurrent duplicate), the transaction rolls back in full —
   the OTP row is **not** left `verified`, and no binding row exists. The
   caller sees a failure outcome and may retry from OTP submission.

This is exactly FR-043: successful OTP verification alone is never, by
itself, observable as "registration succeeded" — the two things are
committed together or not at all.

## UI State Implementation

The Claude Design MCP sync (`/design-login`) that this plan originally
deferred has since happened. The Login journey board in
`Crown Solar Energy.dc.html` defines these concrete screens/dialogs,
which now supersede the earlier placeholder grouping below wherever they
overlap:

| Claude Design screen | Required UI State it covers | Tier / gate it belongs to | As built (live `/login`) |
|---|---|---|---|
| **A1** Sign in | Login, login loading, authentication failure (no client-side validation state — see spec Edge Cases) | All | `SignInScreen` (`lib/features/login/ui/views/sign_in_screen.dart`) |
| **A2** New device SMS code | OTP entry for new-device login, 30-second resend countdown | Second-device tier (OTP-only), and third-or-later tier once Authorized | `LoginFlowScreen` verify step |
| **A3** Wrong code → lockout | Invalid OTP (plain error styling only — its lockout card is explicitly NOT implemented; see `spec.md` Design Note) | Both tiers | Verify step error row |
| **A4** Takeover/conflict dialog | Device-conflict confirmation, shown *before* OTP | Precedes both tiers | Inline dialog in `LoginFlowScreen`; generic copy, no before/after account naming |
| **B1** Refused/locked | Third-or-later-tier "locked, not yet authorized" state — shown *instead of* an OTP screen | Third-or-later tier, Pending/Not Authorized | `LoginFlowScreen` locked step, "Try Again" re-evaluates |
| **B2** CRM-authorized rebind | Third-or-later-tier "authorized, verify" state, OTP shown alongside a CRM-allowed banner | Third-or-later tier, Authorized | Verify step with "CRM has allowed one move" notice |
| **B3** Session expired | Invalid/expired session | Session (tier-independent) | **Not implemented** in the live flow (`SessionExpiredScreen` is design-preview only) |
| **B4** Account deactivated | Authentication failure (account-level) | All | **Not implemented** (`accounts.status` only allows `active`) |
| **C1** PIN unlock / **C2** valid-session-no-PIN | Session restoration | Session (tier-independent) | C1 is the app-PIN `PinGate` owned by the profile feature; C2 is the router redirect from `/login` to `/home` |

This table is the concrete realization of the Required UI States list in
`spec.md`; it replaces that list's earlier "not yet determined" framing
now that the design has actually been inspected. Two states from that
list have **no** dedicated screen because the design treats them as one
existing screen's states, not separate screens: "successful device move"
and "successful device-conflict transfer" are not their own screens —
both simply resolve to the same authenticated-content destination A1
already routes to on success, with no distinct confirmation screen of
their own. `/speckit-tasks` enumerates the concrete view/view-model files
against this table; `ui/views/` in the Project Structure below is
grouped by flow (Registration [out of scope], Login/Trusted, New-Device/
Conflict, Tier-Gated Rebinding, Session) to mirror it.

## Project Structure

### Documentation (this feature)

```text
specs/001-login-auth-device-binding/
├── plan.md              # This file (/speckit-plan command output)
├── research.md          # Phase 0 output (/speckit-plan command)
├── data-model.md         # Phase 1 output (/speckit-plan command)
├── quickstart.md         # Phase 1 output (/speckit-plan command)
├── contracts/
│   └── auth-service.md   # Phase 1 output (/speckit-plan command)
├── checklists/
│   └── requirements.md
└── tasks.md              # Phase 2 output (/speckit-tasks command - NOT created by /speckit-plan)
```

### Source Code (repository root)

Two Dart packages: the existing Flutter app (extended, no new top-level
structure) and one new, separate, non-Flutter package for the local
prototype server.

```text
lib/
├── main.dart
├── app/
│   └── router/
│       └── app_router.dart          # /login (live), /login/legacy,
│                                    # /register/legacy, /home/legacy; the
│                                    # session redirect
├── core/
│   ├── localization/                # ARB strings for the legacy auth screens
│   └── theme/                       # consumed, not extended
└── features/
    ├── auth/
    │   ├── data/
    │   │   ├── models/
    │   │   │   ├── account.dart      # UserType + Account (only DTOs built;
    │   │   │   └── session.dart      # the others in data-model.md are not)
    │   │   ├── repositories/
    │   │   │   └── auth_repository.dart      # thin: calls AuthService, maps
    │   │   │                                  # results; Session persist/
    │   │   │                                  # restore/logout
    │   │   └── services/
    │   │       ├── auth_service.dart          # interface + result types
    │   │       ├── http_auth_service.dart      # the one implementation
    │   │       ├── device_identity_store.dart # local UUID via flutter_secure_storage
    │   │       └── session_store.dart         # local Session record via flutter_secure_storage
    │   └── ui/                       # legacy routes only
    │       ├── views/                # login_screen, registration_screen, home_screen
    │       ├── view_models/          # login_, registration_, home_view_model
    │       └── widgets/              # auth_info_banner, auth_primary_button,
    │                                 # crown_solar_logo, device_conflict_dialog,
    │                                 # otp_code_input
    ├── login/
    │   └── ui/
    │       ├── views/
    │       │   ├── login_flow_screen.dart   # LIVE /login: A1→A4→A2/B2→B1, calls
    │       │   │                            # AuthRepository + SessionController
    │       │   ├── sign_in_screen.dart      # A1 (and B3 SessionExpiredScreen, preview only)
    │       │   └── takeover_, device_locked_, crm_authorised_, verify_phone_,
    │       │       pin_unlock_screen.dart   # static design-preview screens only
    │       └── widgets/crown_wordmark.dart
    └── session/                     # signed-in partner (live path)
        ├── data/                    # session_repository, session_service
        │                            # (/session/lookup or mock), signed_in_user
        └── ui/session_controller.dart

prototype_server/                     # separate Dart package — NOT part of
├── pubspec.yaml                      # the Flutter app; never imported by lib/
├── README.md
├── bin/
│   └── server.dart                   # entrypoint: dart run bin/server.dart
├── lib/
│   ├── router.dart                   # buildRouter(): mounts every route file
│   ├── routes/                       # registration_, login_, login_otp_,
│   │                                  # rebinding_authorization_, rebindings_,
│   │                                  # device_status_routes.dart, json_helpers.dart
│   ├── data/
│   │   ├── auth_data_store.dart      # AuthDataStore interface + result enums
│   │   ├── models.dart               # server-side models, DeviceMoveTier
│   │   └── postgres_auth_data_store.dart  # SQL + transactions (imports `postgres`)
│   ├── db/
│   │   ├── schema.sql                # the tables + partial unique indexes
│   │   └── postgres_client.dart      # pool from PG_* env vars
│   └── otp/otp_generator.dart        # simulated 6-digit code
├── seed/
│   └── seed.sql                      # four `+92…` baseline accounts
└── test/
    ├── routes/                       # login_, login_otp_, rebindings_,
    │                                  # rebinding_authorization_, registration_,
    │                                  # device_status_test.dart
    └── support/fake_auth_data_store.dart

test/
└── features/
    ├── auth/
    │   ├── data/repositories/auth_repository_test.dart
    │   ├── support/                  # fake_auth_service, fake_stores
    │   └── ui/
    │       ├── view_models/          # login_, registration_view_model_test
    │       └── views/login_screen_test.dart   # legacy LoginScreen only
    └── session/session_controller_test.dart
```

No test drives the live `LoginFlowScreen`.

**Structure Decision**: The Flutter app follows the `data/{models,
repositories,services}` + `ui/{views,view_models,widgets}` convention
documented in `docs/ARCHITECTURE.md`. The live board-02 screens were
later added under `lib/features/login/` and the signed-in-partner session
under `lib/features/session/`; both reuse `AuthRepository` rather than a
second device-binding path. `lib/features/bootstrap/` has been removed.
`prototype_server/` is a second, independent Dart package at the
repository root, sibling to `lib/`, `android/`, `ios/`, and `test/` — it
is not a Flutter module, is never built into the app, and exists solely
to satisfy FR-038 (see Complexity Tracking). Other features' routes and
data stores have since been added to it as well.

## Prototype Seed Data & Test Fixtures

See `quickstart.md` → "Seed data & test fixtures" for the concrete
mechanism: a `prototype_server/seed/seed.sql` script inserts the four
baseline accounts (one per user type, `+92…` numbers, none with an Active
device yet). The live sign-in screen can only submit ten digits, so live
testing uses the six demo partners in `db/seed/001_reference_and_partners.sql`
(ten-digit numbers, also no binding) — whose first sign-in is an OTP-only
second-device-tier move (spec FR-049).
Every other fixture state `spec.md`'s scenarios need — an account with an
Active device, a Revoked device, a device Active for a *different*
account (the conflict setup), and each `rebinding_authorizations` status
— is reached by driving the real registration/login/rebinding flows
through `prototype_server`'s actual endpoints (per `quickstart.md`
scenarios A–P), not by hand-inserting binding rows that would bypass the
integrity constraints being validated. The single documented exception is
setting `rebinding_authorizations.status` directly in PostgreSQL, since
simulating the external/CRM decision is the one input this prototype has
no real system to produce.

The device-conflict fixture specifically — Account A → Device A Active,
Account B → Device B Active, then an authorized rebinding of Account A
onto Device B — is walked step-by-step in `quickstart.md` scenarios
J–K, ending in the required end state (Device A Revoked for Account A,
Device B Active for Account A, Device B Revoked for Account B) produced
atomically by `prototype_server`'s `completeRebinding` handler. The same
end state is asserted automatically, against the fake data store, in
`prototype_server/test/routes/rebindings_test.dart`.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

| Violation | Why Needed | Simpler Alternative Rejected Because |
|---|---|---|
| A second Dart package (`prototype_server/`), beyond the single-Flutter-project norm this codebase otherwise follows | FR-038 requires that the Flutter application never connect directly to PostgreSQL; achieving a real process/network boundary is the only way to make that literally true | *A `Service` class inside the Flutter app wrapping the `postgres` driver* — tried first, rejected on review: it is still "Flutter connects to PostgreSQL" no matter which class or layer wraps the driver, so it does not actually satisfy FR-038. *A full ASP.NET Core Web API now, matching production exactly* — considered in `research.md`, not the default because it requires a second SDK/runtime (.NET) the project has none of yet, purely to run a local prototype loop; flagged there as a valid override if the team prefers it. |

No other entries — every other Constitution Check row above is a plain
**Pass** with no violation to justify.
