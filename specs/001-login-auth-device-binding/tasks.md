---

description: "Task list for Login, Authentication, and Device Binding"
---

# Tasks: Login, Authentication, and Device Binding

**Input**: Design documents from `specs/001-login-auth-device-binding/`
(`spec.md`, `plan.md`, `research.md`, `data-model.md`,
`contracts/auth-service.md`, `quickstart.md`)

**Prerequisites**: `plan.md` (architecture), `spec.md` (9 user stories,
priorities P1/P2/P3), `data-model.md` (6 entities), `contracts/auth-service.md`
(9 `AuthService` operations), `research.md` (technology decisions),
`quickstart.md` (acceptance scenarios A–R)

**Tests**: Explicitly requested by the user for this task breakdown — every
user-story phase includes tests, on both the Flutter side (fake `AuthService`)
and the `prototype_server` side (fake data layer), plus a final
manual-validation phase running `quickstart.md` scenarios A–R against the
real stack.

**Reconciliation with the code (2026-09-24)**: every checkbox below was
re-checked against the implementation; a box is `[x]` only where the code
or test actually exists. Changes from the earlier state: T003, T026,
T034, T035, T045, T052, T060, T064, T067, T068, T081, T085, T096, T108
checked (built by the later board-02 pass in `lib/features/login/`);
T075 and T080 unchecked (only partly built — see their notes). Phase 14
records the as-built work no task described, plus the gaps found (103/127 tasks now `[x]`). Current
automated results: `prototype_server` auth route tests 33/33 passing;
Flutter `test/features/auth` + `test/features/session` 36/36 passing. FR
numbers cited in Phases 1–12 predate the spec's renumbering (e.g. "FR-035"
there is today's FR-038, "FR-040" is FR-043, "FR-044" is FR-047) and are
left as written.

**Implementation status (2026-09-17)**: 70/97 tasks completed — all code and
both automated test suites (`prototype_server`: 22/22 passing; Flutter:
27/27 passing; `dart analyze`/`flutter analyze` clean). The 27 remaining
tasks are blocked by two environmental constraints that could not be
resolved in the implementing session, not by any unresolved design
question:
- **Claude Design MCP** requires an interactive `/design-login`, which
  cannot run in a non-interactive session (T003, T025, T026, T034, T035,
  T045, T052, T060, T067, T068, T079, T081, T085, T095). Screens were
  built functionally against the existing provisional `lib/core/theme/`
  tokens instead, clearly not final visual UI. **This blocker has since
  been resolved** (the Claude Design MCP connected in a later session and
  the real Login-journey screens A1–A4/B1–B4/C1–C2 were located and
  inspected — see `plan.md` §UI State Implementation) but none of the
  design-dependent tasks above have been re-attempted yet.
- **PostgreSQL credentials**: a local PostgreSQL 17 server is installed
  and running, but its credentials are unknown and were not guessed
  (T090–T094, and the live-DB half of T009/T096/T097's verification).
  `prototype_server`'s own logic is fully implemented and tested against
  an in-memory fake instead. **This blocker has since been resolved** (a
  live integration test ran successfully against the real database in a
  later session) but T090–T094 above were exercised only informally
  during that pass, not by checking these exact task IDs off.

See the implementation's final report (delivered in the assisting session)
for the full per-task breakdown, including a small number of tasks
completed via a deliberately simpler approach than originally scoped
(T009, T044, T079/T080).

**Business-rule revision (2026-09-17, same day, later pass)**: `spec.md`
was corrected to the final device-move-tiering model (see its "Device-Move
Tiers" section) — the flat "every New/Untrusted device needs OTP, then
authorization" model that US3–US6 above were *implemented* against is
superseded. **The following already-`[x]`-marked tasks implement
behavior that is now incorrect and must be reworked** (their checkmarks
are left as a historical record of what was built, not as confirmation
that current behavior is correct — see the new Phase 13 below for the
rework tasks, and the implementing session's final report for the full
test-impact list):
- **T038, T041, T042** (`login_otp_routes.dart`): currently issue a
  login-context OTP for *any* New/Untrusted device unconditionally. Per
  the revised FR-016/FR-017, this must branch: unconditional only for the
  second-device tier; gated behind an `authorized` outcome for the
  third-or-later tier.
- **T047, T049** (`rebinding_authorization_routes.dart`): currently
  reachable, and expected to be checked, only *after* OTP verification.
  Per FR-017, this check must move to *before* OTP is requested, and must
  never be invoked at all for the second-device tier.
- **T054, T055, T057, T062, T063, T065, T066** (`rebindings_routes.dart`
  `completeRebinding` and its tests): currently assume a single
  universal precondition (verified OTP + authorized status). Per
  FR-016/FR-023, the precondition is now tier-dependent — a
  second-device-tier move requires only the verified OTP.
- **T039, T044, T048, T051, T059** (Flutter `LoginViewModel`/rebinding
  ViewModel and their tests): assume one universal
  OTP-then-authorization sequence with no tier branch and no
  pre-OTP device-conflict confirmation step; both are now required.
- No existing task implements the A4 conflict-confirmation-before-OTP
  gate (FR-013/FR-014) at all — this is wholly new work, not a rework.

See Phase 13 (below Phase 12) for the concrete rework/addition tasks.
**Phase 13 has since been implemented** (2026-09-17, later pass) — the
superseded tasks listed above no longer describe current behavior; see
Phase 13's own status note for exactly what changed and what remains
deferred (now only T107 — see the 2026-09-24 reconciliation note at the top).

**Architecture enforced throughout**: `Flutter UI → ViewModel →
AuthRepository → AuthService/HttpAuthService → HTTP → prototype_server →
PostgreSQL`. Flutter never imports `postgres` and never holds PostgreSQL
credentials; only `prototype_server` does (`lib/db/postgres_client.dart` and `lib/data/postgres_*_data_store.dart`). The live `/login` screen (`lib/features/login/`) calls `AuthRepository` directly, without a ViewModel.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependency on an
  incomplete task in the same phase)
- **[Story]**: Maps the task to its user story (US1–US9) from `spec.md`
- Every task names its exact file path and cites the FR(s)/scenario
  letter(s) it satisfies, for traceability back to `spec.md`/`quickstart.md`

## Path Conventions

- Flutter app: `lib/features/auth/{data/{models,repositories,services},
  ui/{views,view_models,widgets}}`, extending the existing
  `lib/features/<feature>/` convention (`docs/ARCHITECTURE.md`)
- `prototype_server/`: a separate Dart package at the repository root
  (`prototype_server/{bin,lib/{router.dart,routes,data,db,otp},seed,test/{routes,support}}`) — never imported
  by `lib/`, never a Flutter dependency
- Flutter tests: `test/features/auth/...` (mirrors `lib/features/auth/...`)
- `prototype_server` tests: `prototype_server/test/...`

---

## Phase 1: Setup

**Purpose**: Stand up both packages so later phases have somewhere to add code.

- [x] T001 Create `prototype_server/` package: `prototype_server/pubspec.yaml`
      (dependencies: `postgres`, `shelf`, `shelf_router`; dev dependency:
      `test`), `prototype_server/bin/server.dart` stub entrypoint, and
      `prototype_server/README.md` stating explicitly that this server is a
      **prototype-only** persistence/business-rule boundary, not the
      production security boundary (FR-045)
- [x] T002 [P] Add Flutter dependencies to `pubspec.yaml`: `http`,
      `flutter_secure_storage`, `uuid` (per `research.md` §Summary of new
      dependencies — `postgres` is never added here, FR-035)
- [x] T003 [P] Sync Claude Design tokens: run `/design-login`, pull the real
      `cse-design-system` tokens into `lib/core/theme/`, remove the
      `PROVISIONAL` headers per `docs/DESIGN_SYSTEM.md` (blocks every later
      UI task — Constitution Principle II) *(done: `docs/DESIGN_SYSTEM.md`
      records tokens synced 2026-09-17; brand font still outstanding)*
- [x] T004 [P] Configure `prototype_server` formatting/lints: add
      `prototype_server/analysis_options.yaml` (plain-Dart lint set,
      consistent with the root project's `flutter_lints` intent)

**Checkpoint**: Both packages exist and resolve their dependencies
(`flutter pub get`, `dart pub get` in `prototype_server/`).

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Shared plumbing every user story depends on. No user-story work
starts before this phase is done.

**⚠️ CRITICAL**: Blocks all of Phase 3 onward.

- [x] T005 Create `prototype_server/lib/db/schema.sql` implementing exactly
      the five tables from `data-model.md`: `accounts` (`mobile_number`
      unique not null; `user_type CHECK (user_type IN
      ('installer','retailer','wholesaler','distributor'))`; `status
      CHECK (status = 'active')` default `'active'`), `devices`
      (`installation_uuid` unique not null), `account_device_bindings`
      (`status CHECK (status IN ('active','revoked'))`; `context CHECK
      (context IN ('initial_registration','rebinding'))`), `otp_challenges`
      (`context CHECK (context IN ('registration','new_device_login'))`;
      `verified boolean not null default false`), `rebinding_authorizations`
      (`status CHECK (status IN ('pending','authorized','not_authorized'))
      default 'pending'`) — plus the two partial unique indexes verbatim
      from `data-model.md`:
      `CREATE UNIQUE INDEX account_device_bindings_one_active_per_account ON account_device_bindings (account_id) WHERE status = 'active';`
      and
      `CREATE UNIQUE INDEX account_device_bindings_one_active_per_device ON account_device_bindings (device_id) WHERE status = 'active';`
      (FR-008, FR-009, FR-018, FR-038)
- [x] T006 Implement `prototype_server/lib/db/postgres_client.dart` — the
      **only** file in the repository that imports the `postgres` package
      (FR-035); opens a connection/pool from `PG_HOST`/`PG_PORT`/
      `PG_DATABASE`/`PG_USER`/`PG_PASSWORD` environment variables (never
      hardcoded — constitution "secrets never invented or committed"); a
      helper to apply `schema.sql` on startup in dev *(not built — the
      schema is applied manually with `psql`; `postgres` is also imported
      by `prototype_server/lib/data/postgres_*_data_store.dart`)*
- [x] T007 Implement the `prototype_server` HTTP skeleton:
      `prototype_server/bin/server.dart` (shelf pipeline + port binding) and
      `prototype_server/lib/routes/` (mounted by one router in
      `prototype_server/lib/router.dart`) registering all 8
      operations from `contracts/auth-service.md` as stub `501 Not
      Implemented` handlers (`POST /registration/otp`, `POST
      /registration/otp/verify`, `POST /login`, `POST /login/otp`, `POST
      /login/otp/verify`, `GET /rebinding-authorizations`, `POST
      /rebindings`, `GET /accounts/{accountId}/devices/{deviceId}/status`)
- [x] T008 [P] Create `prototype_server/seed/seed.sql` inserting the four
      baseline `accounts` rows (one per `user_type`, distinct
      `mobile_number`, no binding yet) exactly as shown in `quickstart.md`
      §Seed data & test fixtures
- [ ] T009 [P] Create Flutter DTOs in `lib/features/auth/data/models/`:
      `account.dart`, `device.dart`, `account_device_binding.dart`
      (`status` ∈ `{active, revoked}`, `context` ∈
      `{initial_registration, rebinding}`), `otp_challenge.dart` (`context`
      ∈ `{registration, new_device_login}`, `verified: bool`),
      `rebinding_authorization.dart` (`status` ∈
      `{pending, authorized, not_authorized}`), `session.dart`
      (`accountId`, `deviceInstallationUuid`, `keepSignedIn`, `createdAt` —
      **no `expiresAt` field**, per the session-expiration Open Question) —
      mirroring `data-model.md` field-for-field *(partial: only
      `account.dart` and `session.dart` exist; the other DTOs were not
      needed because `auth_service.dart` defines result types directly)*
- [x] T010 Define the `AuthService` abstract interface in
      `lib/features/auth/data/services/auth_service.dart` with exactly the
      8 operations and signatures implied by `contracts/auth-service.md`'s
      table (`requestRegistrationOtp`, `verifyRegistrationOtp`,
      `evaluateLogin`, `requestLoginOtp`, `verifyLoginOtp`,
      `checkRebindingAuthorization`, `completeRebinding`,
      `getDeviceBindingStatus`) — result types represent business outcomes
      as values, never exceptions, per contracts' "Error / outcome shape"
      (FR-034, FR-037) *(now 9 operations — `confirmTakeover` added by
      T105)*
- [x] T011 [P] Implement
      `lib/features/auth/data/services/device_identity_store.dart`:
      generate a v4 UUID via the `uuid` package on first use, persist and
      re-read it via `flutter_secure_storage` (`research.md` §Decision:
      `uuid` package; reinstall ⇒ no persisted UUID ⇒ fresh UUID ⇒
      New/Untrusted, satisfying the reinstall edge case)
- [x] T012 [P] Implement `lib/features/auth/data/services/session_store.dart`:
      read/write/clear the local `Session` record (`accountId`,
      `deviceInstallationUuid`, `keepSignedIn`, `createdAt`) via
      `flutter_secure_storage` — no PostgreSQL access, no `expiresAt` field
      (FR-031 Open Question stays undefined; FR-044)
- [x] T013 Implement `lib/features/auth/data/services/http_auth_service.dart`
      — `HttpAuthService implements AuthService`; base URL read from the
      `API_BASE_URL` `--dart-define` (`research.md` local-connectivity
      note); uses the `http` package; implements all 8 methods as thin
      calls to the endpoints in `contracts/auth-service.md`'s table,
      turning each HTTP response into a result value (never throwing for an
      expected business outcome) — this is the **only** `AuthService`
      implementation the Flutter app will ever have (FR-035, FR-037)
- [x] T014 Create `lib/features/auth/data/repositories/auth_repository.dart`
      skeleton: `AuthRepository(AuthService authService, DeviceIdentityStore
      deviceIdentityStore, SessionStore sessionStore)` — no business logic
      yet; each user-story phase below adds exactly the method(s) it needs
      (FR-034: Repository never holds independent business rules, FR-043)
- [x] T015 Wire `lib/app/router/app_router.dart`: remove
      `lib/features/bootstrap/` as the app's `initialLocation` and point it
      at a placeholder auth-feature entry route (concrete destination
      screen added in US1/US8); add `AuthRoutes` constants following the
      existing `AppRoutes` pattern *(routes were added to `AppRoutes`
      itself; `initialLocation` is now first launch `/`, which leads to
      `/login`)*
- [x] T016 [P] Add the shared auth ARB string keys used across every story
      (e.g. app-wide error copy) to `lib/core/localization/arb/app_en.arb`,
      `app_ur.arb`, `app_ur_Latn.arb`; per-story strings are added in their
      own phase

**Checkpoint**: `prototype_server` starts and responds `501` on every
endpoint; the Flutter app compiles with the new packages, skeleton
Repository, and `HttpAuthService`.

---

## Phase 3: User Story 1 - Register and establish the initial trusted device (Priority: P1) 🎯 MVP

**Goal**: Mobile number + registration OTP → atomic initial Active binding,
identical for all four user types; no device becomes Active without a
successfully verified registration OTP.

**Independent Test**: Take an account with no binding, submit its mobile
number from a fresh device, verify the registration OTP, confirm the device
becomes Active only after verification succeeds — for each of the 4 user
types (`quickstart.md` scenarios A–D).

**Prerequisites**: Phase 2 complete.

**Relevant FRs**: FR-001–FR-005, FR-040, FR-042 (first half), FR-044.

### Tests for User Story 1

- [x] T017 [P] [US1] `prototype_server` test: `verifyRegistrationOtp`
      commits the OTP-verified flag and the initial `account_device_bindings`
      row together, and rolls back **both** if the binding insert fails
      (e.g. concurrent duplicate hitting the partial unique index) — no
      partial state either way — in
      `prototype_server/test/routes/registration_test.dart` (FR-002, FR-003,
      FR-040)
- [ ] T018 [P] [US1] Flutter test: `AuthRepository` registration flow
      (request OTP → verify → success/failure) against a hand-written fake
      `AuthService` in
      `test/features/auth/data/repositories/auth_repository_test.dart`
      *(partial: only "requestRegistrationOtp passes the current device id
      through" exists)*
- [x] T019 [P] [US1] Flutter test: `RegistrationViewModel` state machine
      (idle → otpRequested → verifying → success/failure) in
      `test/features/auth/ui/view_models/registration_view_model_test.dart`

### Implementation for User Story 1

- [x] T020 [US1] `prototype_server`: implement `POST /registration/otp` in
      `prototype_server/lib/routes/registration_routes.dart` — look up/
      create the `devices` row for the given `installation_uuid`, insert an
      `otp_challenges` row (`context = 'registration'`), return the
      generated code in the response for prototype testability
      (`research.md` §OTP simulation) (FR-001, FR-016)
- [x] T021 [US1] `prototype_server`: implement `POST
      /registration/otp/verify` in `registration_routes.dart` as **one
      PostgreSQL transaction**: validate the submitted code against the
      pending `otp_challenges` row; on match, set `verified = true` **and**
      insert `account_device_bindings` (`status = 'active'`, `context =
      'initial_registration'`) in the same transaction, then commit; on
      mismatch, return a failure outcome and leave `verified = false`, with
      no other writes. **Resolves the FR-017 OTP failed-attempt ambiguity**:
      a failed verification is represented solely by the `otp_challenges`
      row remaining `verified = false` — no separate per-attempt audit row
      is created, and no retry-limit/cooldown is enforced (explicitly out
      of scope per `spec.md` §Out of Scope); OTP expiry duration remains an
      undefined Open Question and is not implemented (FR-002, FR-003,
      FR-017, FR-040)
- [x] T022 [US1] `prototype_server`: confirm (via T017/T063-style
      parametrization) that `registration_routes.dart` contains no
      `user_type`-conditional branch — one code path for all four types
      (FR-004, FR-022)
- [x] T023 [US1] Flutter: implement
      `AuthRepository.requestRegistrationOtp`/`verifyRegistrationOtp` in
      `auth_repository.dart`, calling `AuthService` and mapping the result
- [x] T024 [US1] Flutter: implement `RegistrationViewModel` in
      `lib/features/auth/ui/view_models/registration_view_model.dart`
      (mobile-number entry, OTP entry, loading, success, failure states)
- [ ] T025 [US1] Flutter: inspect Claude Design MCP for the Registration
      states listed in `spec.md` §Design Requirements (mobile-number entry,
      OTP entry, OTP verification/loading, invalid OTP, registration
      success, initial device binding confirmation); record which are full
      screens vs. dialog/bottom sheet/inline/snackbar — do **not** assume
      one file per state (`plan.md` §UI State Implementation)
- [x] T026 [US1] Flutter: implement the Registration view(s) in
      `lib/features/auth/ui/views/` per T025's breakdown, using
      `lib/core/theme/` tokens exclusively, native Flutter widgets only
      *(`registration_screen.dart`, routed at `/register/legacy`; built
      without T025's inspection)*
- [x] T027 [US1] Flutter: add registration-flow strings (labels, OTP
      prompts, error/success copy) to `app_en.arb`/`app_ur.arb`/
      `app_ur_Latn.arb`
- [x] T028 [US1] Flutter: wire the registration route(s) into
      `app_router.dart` with `ChangeNotifierProvider(create: (_) =>
      RegistrationViewModel(...))`, following the existing bootstrap-route
      pattern

**Checkpoint**: Registration works end-to-end for a fresh device;
`quickstart.md` scenarios A–D are passable for all four user types via one
code path.

---

## Phase 4: User Story 2 - Sign in from the trusted device (Priority: P1)

**Goal**: The account's Active device signs in with no OTP step.

**Independent Test**: Sign in on the account's already-bound device; confirm
no OTP prompt appears (`quickstart.md` scenario E).

**Prerequisites**: Phase 2 complete. (Independent of US1's UI, but exercises
an account that already has a binding — US1 or seed-driven registration
supplies that.)

**Relevant FRs**: FR-006, FR-007, FR-011.

### Tests for User Story 2

- [x] T029 [P] [US2] `prototype_server` test: `POST /login` returns a
      trusted (no-OTP) outcome when the submitted device matches the
      account's active `account_device_bindings` row, in
      `prototype_server/test/routes/login_test.dart` (FR-011)
- [x] T030 [P] [US2] Flutter test: `LoginViewModel` trusted path reaches
      authenticated state without ever requesting OTP, in
      `test/features/auth/ui/view_models/login_view_model_test.dart`

### Implementation for User Story 2

- [x] T031 [US2] `prototype_server`: implement `POST /login`
      (`evaluateLogin`) in `prototype_server/lib/routes/login_routes.dart`
      — look up the account by `mobile_number` (FR-007), compare the
      submitted device against the account's active binding, return
      trusted/untrusted (untrusted case completed in US3) (FR-011, FR-012)
- [x] T032 [US2] Flutter: implement `AuthRepository.evaluateLogin` in
      `auth_repository.dart`, mapping a trusted outcome straight to
      authenticated state
- [x] T033 [US2] Flutter: implement `LoginViewModel` in
      `lib/features/auth/ui/view_models/login_view_model.dart` — mobile
      number entry + "Keep Me Signed In" choice only, no other field
      (FR-006)
- [x] T034 [US2] Flutter: Claude Design MCP inspection for Login states
      (layout, branding/logo, mobile-number input + validation feedback,
      Keep Me Signed In control, primary action, loading, empty-field,
      disabled/enabled, authentication failure) *(board 02 A1; no
      client-side validation/empty-field state was built)*
- [x] T035 [US2] Flutter: implement the Login view(s) per T034's breakdown
      in `lib/features/login/ui/views/sign_in_screen.dart` (live, `/login`)
      and `lib/features/auth/ui/views/login_screen.dart` (legacy,
      `/login/legacy`)
- [x] T036 [US2] Flutter: add login-flow ARB strings; register the Login
      view as the route `app_router.dart` falls back to when no session is
      restored (final wiring completed in US8)

**Checkpoint**: `quickstart.md` scenario E passable.

---

## Phase 5: User Story 3 - New device is detected during login and gated (Priority: P1)

**Goal**: A device that isn't the Active one is classified New/Untrusted and
gated behind a distinct login-context OTP.

**Independent Test**: Sign in with a valid account's mobile number from a
non-Active device; confirm New/Untrusted classification and a login-context
OTP requirement (`quickstart.md` scenario F).

**Prerequisites**: Phase 4 (extends `login_routes.dart`/`LoginViewModel`).

**Relevant FRs**: FR-005, FR-012, FR-013, FR-014, FR-015.

### Tests for User Story 3

- [x] T037 [P] [US3] `prototype_server` test: `evaluateLogin` classifies a
      mismatched device New/Untrusted and grants no access on the mobile
      number alone, in `login_test.dart` (FR-012, FR-015)
- [x] T038 [P] [US3] `prototype_server` test: `requestLoginOtp`/
      `verifyLoginOtp` create and verify a challenge with `context =
      'new_device_login'`, a distinct row from any registration-context
      challenge for the same account, in
      `prototype_server/test/routes/login_otp_test.dart` (FR-005, FR-013)
- [x] T039 [P] [US3] Flutter test: `LoginViewModel`/new-device flow routes
      to OTP entry when `evaluateLogin` reports untrusted, and shows
      invalid-OTP on a wrong code without changing any state

### Implementation for User Story 3

- [x] T040 [US3] `prototype_server`: complete the untrusted branch of `POST
      /login` in `login_routes.dart` — return New/Untrusted with no
      further access; device ID and mobile number together are still
      insufficient (FR-012, FR-015)
- [x] T041 [US3] `prototype_server`: implement `POST /login/otp`
      (`requestLoginOtp`) in
      `prototype_server/lib/routes/login_otp_routes.dart` — insert an
      `otp_challenges` row (`context = 'new_device_login'`), return the
      code for prototype testability (FR-013, FR-016)
- [x] T042 [US3] `prototype_server`: implement `POST /login/otp/verify`
      (`verifyLoginOtp`) in `login_otp_routes.dart` — validates the code
      against the `new_device_login` challenge; on success sets `verified =
      true` **only**; explicitly does **not** touch
      `account_device_bindings` or `rebinding_authorizations` (that's US4/
      US5) (FR-013, FR-014, FR-017's failed-attempt resolution applies here
      identically to T021)
- [x] T043 [US3] Flutter: implement
      `AuthRepository.requestLoginOtp`/`verifyLoginOtp` in
      `auth_repository.dart`
- [x] T044 [US3] Flutter: extend `LoginViewModel` (or add a
      `NewDeviceOtpViewModel` in
      `lib/features/auth/ui/view_models/new_device_otp_view_model.dart` if
      Claude Design treats it as a distinct flow) with OTP-entry and
      invalid-OTP states
- [x] T045 [US3] Flutter: Claude Design MCP inspection + implementation for
      the New/Untrusted-device OTP-entry state — confirm via MCP whether it
      reuses the OTP-entry component from US1 or is visually distinct;
      implement accordingly *(live: A2 verify step in
      `lib/features/login/ui/views/login_flow_screen.dart`, using the
      registration feature's `EditableOtpField`; legacy:
      `lib/features/auth/ui/widgets/otp_code_input.dart`)*
- [x] T046 [US3] Flutter: add related ARB strings

**Checkpoint**: `quickstart.md` scenario F passable.

---

## Phase 6: User Story 4 - New-device rebinding is refused when authorization is not available (Priority: P2)

**Goal**: A verified-OTP New/Untrusted device gains no access while
rebinding authorization is `Pending` or `Not Authorized`; the existing Active
device is unaffected.

**Independent Test**: Complete OTP verification for a New/Untrusted device,
leave authorization unresolved/refused, confirm the existing Active device
keeps working and the new device gains nothing (`quickstart.md` scenario G).

**Prerequisites**: Phase 5 complete (needs a verified login-context OTP).

**Relevant FRs**: FR-018, FR-019, FR-024, FR-025, FR-026.

### Tests for User Story 4

- [x] T047 [P] [US4] `prototype_server` test: `checkRebindingAuthorization`
      creates a `pending` row on first call and returns it unchanged on
      subsequent calls until something external resolves it; the
      account's active binding is never touched by this call, in
      `prototype_server/test/routes/rebinding_authorization_test.dart`
      (FR-018, FR-019)
- [x] T048 [P] [US4] Flutter test: rebinding ViewModel renders
      Pending/Not-Authorized outcomes without altering any authenticated
      state

### Implementation for User Story 4

- [x] T049 [US4] `prototype_server`: implement `GET
      /rebinding-authorizations` (`checkRebindingAuthorization`) in
      `prototype_server/lib/routes/rebinding_authorization_routes.dart` —
      look up or create (`status = 'pending'`, `source =
      'prototype_simulated_crm'`) a `rebinding_authorizations` row for
      `(accountId, deviceId)` (FR-018, FR-024)
- [x] T050 [US4] `prototype_server`: add a route-level test/assertion
      confirming **no endpoint** lets a caller set
      `rebinding_authorizations.status` to `authorized`/`not_authorized` —
      only direct database access (documented as the deliberate prototype
      exception in `quickstart.md`) can do that; confirms no CRM screens/
      approval UI exist anywhere in the Flutter app's route table (FR-025,
      FR-026)
- [x] T051 [US4] Flutter: implement
      `AuthRepository.checkRebindingAuthorization` and the
      Pending/Not-Authorized ViewModel states (extending the new-device flow
      from US3)
- [x] T052 [US4] Flutter: Claude Design MCP inspection + implementation for
      "rebinding pending" and "rebinding not authorized" states *(both
      render B1, the `LoginFlowScreen` locked step)*
- [x] T053 [US4] Flutter: add related ARB strings

**Checkpoint**: `quickstart.md` scenario G passable.

---

## Phase 7: User Story 5 - Authorized rebinding makes the new device Active and the old device Revoked (Priority: P2)

**Goal**: Once OTP is verified and authorization is `Authorized`, the new
device becomes Active and the old one Revoked, atomically.

**Independent Test**: Take an account with an Active device, complete OTP +
an Authorized outcome for a different device, confirm the swap happens
atomically (`quickstart.md` scenarios H–I).

**Prerequisites**: Phase 6 complete (needs `checkRebindingAuthorization`).

**Relevant FRs**: FR-020, FR-038, FR-039, FR-043.

### Tests for User Story 5

- [x] T054 [P] [US5] `prototype_server` test: `completeRebinding`, given a
      verified login-context OTP and `authorized` status, atomically
      activates the new device and revokes the account's previous Active
      device in one transaction, in
      `prototype_server/test/routes/rebindings_test.dart` (FR-020, FR-038,
      FR-039)
- [x] T055 [P] [US5] `prototype_server` test: `completeRebinding` refuses
      (no writes) if called with an unverified OTP or a non-`authorized`
      status — the server re-checks both conditions itself rather than
      trusting call order from the client (FR-043)
- [x] T056 [P] [US5] Flutter test: rebinding ViewModel transitions to
      authenticated state after a successful `completeRebinding` call

### Implementation for User Story 5

- [x] T057 [US5] `prototype_server`: implement `POST /rebindings`
      (`completeRebinding`) in
      `prototype_server/lib/routes/rebindings_routes.dart` as **one
      PostgreSQL transaction**: re-verify the login-context OTP is
      `verified` and `rebinding_authorizations.status = 'authorized'` for
      `(accountId, deviceId)`; insert a new `account_device_bindings` row
      (`status = 'active'`, `context = 'rebinding'`) for the requested
      device; update the account's previous active row to `status =
      'revoked'`, `revoked_at = now()`; commit (FR-020, FR-038, FR-039)
- [x] T058 [US5] Flutter: implement `AuthRepository.completeRebinding` in
      `auth_repository.dart`
- [x] T059 [US5] Flutter: implement the success path (→ authenticated
      state) in the rebinding ViewModel from US4
- [x] T060 [US5] Flutter: Claude Design MCP inspection + implementation for
      "rebinding authorized" / successful-rebinding state *(B2 "CRM has
      allowed one move" notice on the verify step; success goes straight to
      Home)*
- [x] T061 [US5] Flutter: add related ARB strings

**Checkpoint**: `quickstart.md` scenarios H–I passable (non-conflict case).

---

## Phase 8: User Story 6 - Device conflict: transferring a device that is Active for another account (Priority: P2)

**Goal**: Rebinding onto a device that is Active for a *different* account
atomically transfers it, revoking the other account's binding too — never
leaving it Active for two accounts — identically across any pair of the four
user types.

**Independent Test**: Account A (Active: Device A) and Account B (Active:
Device B); Account A completes an Authorized rebinding onto Device B;
confirm the three-row atomic outcome (`quickstart.md` scenarios J–K).

**Prerequisites**: Phase 7 complete (extends `completeRebinding`).

**Relevant FRs**: FR-021, FR-022, FR-038, FR-039.

### Tests for User Story 6

- [x] T062 [P] [US6] `prototype_server` test: `completeRebinding`, when the
      requested device is currently active for a *different* account,
      atomically activates it for the requesting account, revokes the
      requesting account's previous device, **and** revokes the other
      account's binding — one transaction, never a state with the device
      active for two accounts, in `rebindings_test.dart` (FR-021, FR-038,
      FR-039)
- [x] T063 [P] [US6] `prototype_server` test: the conflict-resolution
      behavior from T062 is identical across every pairing of the four
      user types (parametrized test: installer↔retailer,
      wholesaler↔distributor, etc.) — no special-cased branch for any pair
      (FR-022) *(covers 4 of the 6 pairings; the code has no user-type
      branch at all)*
- [x] T064 [P] [US6] Flutter test: the rebinding ViewModel handles a
      conflict outcome identically to the non-conflict authorized outcome
      from US5 — no client-side conflict-specific branching *(conflict
      group in `login_view_model_test.dart`: after confirmation the same
      tier path runs)*

### Implementation for User Story 6

- [x] T065 [US6] `prototype_server`: extend `completeRebinding`'s
      transaction (T057) to detect an existing `active`
      `account_device_bindings` row for the requested device under a
      *different* `account_id`, and revoke it within the same transaction
      (FR-021)
- [x] T066 [US6] `prototype_server`: add an end-to-end route test
      reproducing the exact `quickstart.md` J–K scenario and asserting the
      required final state: `Account A → Device A revoked`, `Account A →
      Device B active`, `Account B → Device B revoked`
- [x] T067 [US6] Flutter: Claude Design MCP inspection + implementation for
      a "device conflict" state, only if Claude Design represents it
      visually distinctly from the generic rebinding-authorized state from
      US5 (confirm via MCP before adding anything new) *(A4 dialog: inline
      in `LoginFlowScreen`, and `device_conflict_dialog.dart` for legacy)*
- [x] T068 [US6] Flutter: add related ARB strings (if T067 introduces new
      copy) *(`loginDeviceConflict*` keys; used by the legacy dialog only —
      the live dialog hard-codes English)*

**Checkpoint**: `quickstart.md` scenarios J–K passable.

---

## Phase 9: User Story 7 - A previously revoked device cannot bypass revocation (Priority: P2)

**Goal**: A Revoked device is always treated as New/Untrusted on any later
sign-in attempt — it never regains trust automatically.

**Independent Test**: Revoke a device (via US5/US6), then attempt sign-in
from it again; confirm New/Untrusted classification and the full OTP+
authorization flow is required again (`quickstart.md` scenario L).

**Prerequisites**: Phase 7 (a revocation must be possible first).

**Relevant FRs**: FR-023.

### Tests for User Story 7

- [x] T069 [P] [US7] `prototype_server` test: `evaluateLogin`/
      `getDeviceBindingStatus` classify a device whose only
      `account_device_bindings` row is `revoked` (or absent) as
      New/Untrusted — never trusted — in `login_test.dart` (FR-023)
- [ ] T070 [P] [US7] Flutter test: `LoginViewModel` routes a revoked device
      through the identical New/Untrusted path as a never-seen device

### Implementation for User Story 7

- [x] T071 [US7] `prototype_server`: confirm and lock in with an explicit
      regression test that `evaluateLogin`'s active-row lookup (T031)
      naturally treats revoked and absent rows identically — New/Untrusted
      is the *absence* of an active row (`data-model.md`), so no
      additional code path is needed (FR-023)
- [ ] T072 [US7] Flutter: no new UI state required beyond US3's
      New/Untrusted flow; add a code comment in the login ViewModel cross-
      referencing `quickstart.md` scenario L to document the reuse

**Checkpoint**: `quickstart.md` scenario L passable.

---

## Phase 10: User Story 8 - Session persists safely across app restarts (Priority: P2)

**Goal**: "Keep Me Signed In" persists a local session that is always
re-validated against current device-binding state before granting access; it
never itself grants access.

**Independent Test**: Sign in with Keep Me Signed In on/off and restart;
separately, revoke a device holding a persisted session and confirm it
cannot restore (`quickstart.md` scenarios M, N, O).

**Prerequisites**: Phase 4 (Login) and Phase 7 (a way to produce a Revoked
device to test against) complete.

**Relevant FRs**: FR-010, FR-027–FR-031.

### Tests for User Story 8

- [ ] T073 [P] [US8] Flutter test: `SessionStore` persists/clears the local
      `Session` record correctly; a session with `keepSignedIn = false`
      is never written for restoration (FR-027, FR-029)
- [x] T074 [P] [US8] Flutter test: `AuthRepository.restoreSession`, when
      `keepSignedIn = true`, calls `getDeviceBindingStatus` and restores
      authenticated state only on an `active` response, treating
      `revoked`/unknown as failure (FR-030)
- [ ] T075 [P] [US8] `prototype_server` test: `GET
      /accounts/{accountId}/devices/{deviceId}/status`
      (`getDeviceBindingStatus`) returns `active`/`revoked`/unrecorded
      correctly, in
      `prototype_server/test/routes/device_status_test.dart` (FR-008,
      FR-030) *(partial: only the unrecorded and `active` cases exist; no
      `revoked` case)*

### Implementation for User Story 8

- [x] T076 [US8] `prototype_server`: implement `GET
      /accounts/{accountId}/devices/{deviceId}/status`
      (`getDeviceBindingStatus`) in
      `prototype_server/lib/routes/device_status_routes.dart`
- [x] T077 [US8] Flutter: implement `AuthRepository.restoreSession()` in
      `auth_repository.dart` — on app start, if a `Session` record exists
      and `keepSignedIn = true`, call `getDeviceBindingStatus`; restore
      authenticated state only on `active`; on `revoked`/failure, clear the
      local session via `SessionStore` and route to sign-in (FR-030)
- [x] T078 [US8] Flutter: wire session persistence into the success paths
      of `RegistrationViewModel` (US1), `LoginViewModel` (US2), and the
      rebinding ViewModel (US5/US6) — write the `Session` record via
      `SessionStore` only when Keep Me Signed In was selected (FR-027,
      FR-028) *(done in `LoginViewModel` and the live `LoginFlowScreen`;
      `RegistrationViewModel` does not persist a session)*
- [ ] T079 [US8] Flutter: implement a startup/session-restoration step
      (e.g. `lib/features/auth/ui/view_models/session_restoration_view_model.dart`)
      invoked before routing to Login or authenticated home; Claude Design
      MCP inspection for "session restoration" (incl. loading state) and
      "invalid/expired session" states *(not built: restoration happens in
      the router redirect; B3 exists only as a design-preview screen)*
- [ ] T080 [US8] Flutter: wire session-restoration as the app's actual
      startup redirect in `app_router.dart`, replacing the placeholder from
      T015/T036 *(partial: `AuthRepository.restoreSession()` runs only in
      the `/login/legacy` redirect; the live `/login` and signed-in routes
      restore via `SessionController.restore()`, which does not check
      device binding — see T121)*
- [x] T081 [US8] Flutter: add related ARB strings *(`loginSessionExpiredNotice`)*

**Checkpoint**: `quickstart.md` scenarios M, N, O passable.

---

## Phase 11: User Story 9 - Sign out without losing the device's trust (Priority: P3)

**Goal**: Logout ends the local session only; the device stays trusted for
next sign-in.

**Independent Test**: Sign in, sign out, confirm the same device signs back
in as trusted with no OTP (`quickstart.md` scenario P).

**Prerequisites**: Phase 10 (needs a session to sign out of).

**Relevant FRs**: FR-032, FR-033.

### Tests for User Story 9

- [x] T082 [P] [US9] Flutter test: `AuthRepository.logout` clears only the
      local `Session` record and makes **no** `AuthService`/HTTP call —
      logout never touches device-binding state (FR-032, FR-033)

### Implementation for User Story 9

- [x] T083 [US9] Flutter: implement `AuthRepository.logout()` in
      `auth_repository.dart` — clears `SessionStore` only, no network call
      (FR-032, FR-033)
- [x] T084 [US9] Flutter: add a logout affordance in the authenticated UI
      (placement per Claude Design) that calls `logout()` and routes back
      to sign-in *(legacy `HomeScreen` calls `logout()`; the live Profile
      tab's Sign out calls `SessionController.signOut()` instead, which
      leaves the secure `Session` record in place — see T125)*
- [x] T085 [US9] Flutter: Claude Design MCP inspection + implementation for
      the "logout" state/transition *(Profile → Sign out confirmation, then
      `/login`)*
- [x] T086 [US9] Flutter: add related ARB strings

**Checkpoint**: `quickstart.md` scenario P passable. All 9 user stories are
now independently functional.

---

## Phase 12: Polish & Cross-Cutting Concerns

**Purpose**: Repo hygiene, both verification gates, and full manual
validation against the real stack.

- [x] T087 [P] Remove `lib/features/bootstrap/` and its route/tests — it is
      superseded as the app's initial route by this feature (README;
      `plan.md` §Scope Discipline)
- [x] T088 [P] Run `dart format .`, `flutter analyze`, `flutter test` for
      the Flutter app and fix any failures (constitution Principle IX)
- [x] T089 [P] Run `dart format .`, `dart analyze`, `dart test` inside
      `prototype_server/` and fix any failures (constitution Principle IX;
      `plan.md`'s parallel verification gate)
- [ ] T090 Apply `prototype_server/lib/db/schema.sql` and
      `prototype_server/seed/seed.sql` (T005, T008) against a local
      PostgreSQL instance per `quickstart.md` §Prerequisites
- [ ] T091 Start `prototype_server` and the Flutter app per
      `quickstart.md` §Prerequisites, then execute scenarios **A–D**
      end-to-end (all four user types) and record the result of each
- [ ] T092 Execute `quickstart.md` scenarios **E–G** end-to-end and record
      results
- [ ] T093 Execute `quickstart.md` scenarios **H–L** end-to-end, including
      the required repeat with a different user-type pair for scenario K,
      and record results
- [ ] T094 Execute `quickstart.md` scenarios **M–P** end-to-end and record
      results
- [ ] T095 Final Claude Design visual verification pass: compare every
      implemented screen/dialog/state against the Claude Design reference
      for layout, spacing, typography, colors, logo/branding, controls,
      icons, borders, radius, elevation, loading/validation/error states,
      and transitions, per `spec.md` §Design Requirements' Visual
      Validation checklist
- [x] T096 [P] Traceability check: re-read `spec.md` FR-001 through FR-045
      against the implementation and confirm each is satisfied by at least
      one completed task above; note any gap *(done 2026-09-24 against
      FR-001–FR-052; gaps are marked "(Not implemented)" in `spec.md` and
      listed as Phase 14's open tasks)*
- [ ] T097 [P] Confirm `prototype_server/README.md` (T001) and
      `spec.md` §Prototype vs. Production Boundary still accurately
      describe the shipped architecture; update if implementation deviated
      *(`spec.md` updated; the README still says to apply only
      `schema.sql` + `seed/seed.sql` and omits `db/migrations/` — not
      updated, outside this spec folder)*

**Checkpoint**: Full feature validated end-to-end; both automated gates
green; ready to consider `/speckit-implement` complete for this feature.

---

## Phase 13: Business-Rule Revision — Device-Move Tiering & Conflict-Confirmation Gate

**Purpose**: Bring the already-built US3–US6 code and tests in line with
the corrected `spec.md` (see "Business-rule revision" note above): the
account's first device move (to "Device 2") is gated by OTP alone; every
move after that (to "Device 3" and beyond) is gated by CRM authorization
*before* OTP; and any device conflict is confirmed by the user *before*
either gate. Registration (US1) is untouched.

**Implemented (2026-09-17, later pass)**: T098–T106, T109–T115, T117 are
complete — `prototype_server` (33/33 tests passing, `dart analyze` clean)
and the Flutter app (34/34 tests passing, `flutter analyze` clean), both
reformatted with `dart format .`. **T116 is now also complete**
(2026-09-17, following documentation-only pass): `quickstart.md`'s
scenarios G/H are rescoped to the third-or-later tier explicitly, and new
scenarios Q (conflict confirmation before OTP) and R (second-device-tier
OTP-only success) are added, without renumbering the existing A–P
letters. **T107 and T108 remain unimplemented by deliberate scope
choice**: both are Claude-Design-dependent visual work, explicitly
deferred per each pass's instructions ("Do NOT implement Claude Design
visual changes yet" / "Do not modify the UI"). *(2026-09-24: the later board-02 pass built both the A4 dialog and its copy, so T108 is now done; T107 stays open only for naming both accounts.)*

**Prerequisites**: Phases 3–9 (US1–US7) as already built; supersedes parts
of their route/ViewModel logic per the superseded-task list above.

**Relevant FRs**: FR-013 through FR-018, FR-022, FR-046 (new/revised).

### Backend (`prototype_server`) — reordering and new logic

- [x] T098 [P] Update `evaluateLogin` in
      `prototype_server/lib/routes/login_routes.dart` to detect, before
      any tier or OTP logic runs, whether the requested device currently
      has an `active` `account_device_bindings` row for a **different**
      account; if so, return a `conflict` outcome (naming the other
      account) instead of proceeding to tier evaluation (FR-013, FR-014)
- [x] T099 Implement `POST /login/confirm-takeover` in `login_routes.dart`
      — a new endpoint the client calls only after the user explicitly
      confirms a conflict; it performs no database write itself (it only
      unblocks the client to proceed to tier evaluation) and there is no
      corresponding "decline" endpoint because declining simply means the
      client never calls it (FR-014)
- [x] T100 Update `evaluateLogin` to compute the requesting account's
      device-move tier as `SELECT count(*) FROM account_device_bindings
      WHERE account_id = $1 AND context = 'rebinding'`; return `tier =
      second_device` when that count is `0`, else `tier =
      third_or_later`, as part of the New/Untrusted response (no new
      column — FR-015)
- [x] T101 Update `requestLoginOtp` in
      `prototype_server/lib/routes/login_otp_routes.dart` to branch on
      tier: for `second_device`, issue the OTP unconditionally exactly as
      it does today; for `third_or_later`, first check
      `rebinding_authorizations.status` for `(accountId, deviceId)` and
      refuse to issue an OTP (returning a distinct "not yet authorized"
      outcome) unless it is `authorized` — reversing the current
      always-issue behavior for this tier only (FR-016, FR-017)
- [x] T102 Update
      `prototype_server/lib/routes/rebinding_authorization_routes.dart`'s
      `checkRebindingAuthorization` so it is never called by the client
      for a `second_device`-tier account/device pair (document this as a
      client-side contract in `contracts/auth-service.md`, not a
      server-side rejection, since the check itself is harmless if called
      — but nothing in the second-device flow triggers it) (FR-016,
      FR-022)
- [x] T103 Update `completeRebinding` in
      `prototype_server/lib/routes/rebindings_routes.dart` to re-verify,
      server-side, the precondition matching the account's *current*
      tier: a verified `new_device_login` OTP alone for `second_device`;
      a verified OTP **and** `rebinding_authorizations.status =
      'authorized'` for `third_or_later` — rather than the single
      universal precondition it checks today (FR-016, FR-023, FR-042)

### Flutter — tier branching, conflict dialog

- [x] T104 Extend the `evaluateLogin` result type in
      `lib/features/auth/data/services/auth_service.dart` (and
      `http_auth_service.dart`'s mapping of it) to carry the new `tier`
      and optional `conflict` fields from T098/T100; `AuthRepository`
      passes both through without interpreting them (FR-015, FR-046 —
      tier/conflict determination stays server-owned)
- [x] T105 Add `AuthRepository.confirmTakeover()` (calls T099's endpoint)
      and a new `LoginViewModel` step shown whenever `evaluateLogin`
      reports a conflict, presented *before* any OTP request; declining
      returns the ViewModel to its initial state with no calls made
      (FR-014)
- [x] T106 Rework `LoginViewModel`'s `checkAuthorizationAndRebindIfPossible()`
      (or equivalent) into an explicit tier branch: for `tier ==
      second_device`, go straight from OTP verification to
      `completeRebinding`, skipping `checkRebindingAuthorization`
      entirely; for `tier == third_or_later`, call
      `checkRebindingAuthorization` **before** requesting any OTP, and
      only request/verify OTP once it resolves to Authorized (FR-016,
      FR-017, FR-018)
- [ ] T107 Flutter: Claude Design MCP inspection + implementation for the
      A4 takeover/conflict-confirmation dialog (`plan.md` §UI State
      Implementation) — naming both accounts affected, shown from the new
      step added in T105 *(partial: the dialog is built in both flows, but
      names neither account — `evaluateLogin` returns only
      `otherAccountId`; see T123)*
- [x] T108 Flutter: add ARB strings for the conflict-confirmation dialog
      and any second-device-tier-specific copy (e.g. a variant of the A2
      OTP screen with no "CRM has allowed this" banner, contrasted with
      B2's banner at the third-or-later tier) *(ARB keys
      `loginDeviceConflict*`, `loginSecondDeviceMoveNotice`,
      `loginCrmAuthorized*`; the live screens show the same variants in
      hard-coded English — see T122)*

### Tests to rewrite (superseding the tasks listed in the note above)

- [x] T109 [P] Rewrite `prototype_server/test/routes/login_otp_test.dart`:
      split the existing "any New/Untrusted device gets an OTP" case into
      a `second_device`-tier case (OTP issued unconditionally) and a
      `third_or_later`-tier case (OTP refused unless authorized)
- [x] T110 [P] Rewrite `prototype_server/test/routes/
      rebinding_authorization_test.dart` and `rebindings_test.dart`:
      reorder the existing "authorization checked, then OTP" assertions
      to "authorization checked before OTP is even requested" for
      `third_or_later`; add a case proving a `second_device`-tier move
      never creates or reads a `rebinding_authorizations` row, even if
      one happens to already exist for that pair
- [x] T111 [P] Add a `prototype_server` test: `evaluateLogin`'s conflict
      detection (T098) runs and is reported before tier evaluation runs,
      and `POST /login/confirm-takeover` (T099) never writes to any table
- [x] T112 [P] Rewrite `test/features/auth/ui/view_models/
      login_view_model_test.dart`'s `'an untrusted device is sent to OTP
      step'`, `'Not Authorized leaves flow without completing'`, and
      `'Authorized completes rebinding'` tests to be tier-parametrized
      (one variant per tier); add a new case proving the `second_device`
      tier reaches `rebindingSuccess` with zero calls to
      `checkRebindingAuthorization`
- [x] T113 [P] Add a Flutter test: `LoginViewModel` shows the
      conflict-confirmation step (T105) before requesting any OTP when
      `evaluateLogin` reports a conflict, and takes no action at all when
      the user declines it

### Documentation follow-through

- [x] T114 Update `contracts/auth-service.md`: document `evaluateLogin`'s
      new `tier`/`conflict` response fields and the new
      `confirmTakeover` operation and its `POST /login/confirm-takeover`
      mapping
- [x] T115 Update `data-model.md`: add the derived-tier note (device-move
      count = `COUNT(*)` of `context = 'rebinding'` rows per account; no
      new column) per `spec.md` §Device-Move Tiers and §Assumptions
- [x] T116 Update `quickstart.md`: rescope scenarios **G**/**H** to the
      third-or-later tier explicitly; add scenarios **Q** (conflict
      confirmation gate) and **R** (second-device-tier OTP-only success)
      matching `spec.md`'s new Acceptance Scenarios
- [x] T117 [P] Once T098–T113 are implemented, re-run `dart format .` /
      `flutter analyze` / `flutter test` and `prototype_server`'s
      equivalents, then update the "Implementation status" note at the
      top of this file to reflect the new pass/fail counts

**Checkpoint**: the business logic behind `quickstart.md` scenarios F, G,
H, Q, and R is implemented and covered by the automated test suites
(`prototype_server`: 33/33 passing; Flutter: 34/34 passing) — the
superseded tests listed in the note above no longer exist in their old
form. `quickstart.md` has since been rewritten (T116) to script F, R, G,
H–I, Q, and J–K as live-stack manual scenarios matching this behavior
exactly, including the conflict-decline and tier-composition cases; only
T107 (naming both accounts in A4) remains open.

---

## Phase 14: As-Built Reconciliation (2026-09-24)

**Purpose**: Record implemented work that no earlier task described, and
list the gaps between `spec.md` and the code found while reconciling. The
`[x]` tasks below describe code that exists; the `[ ]` tasks are the gaps
behind each "(Not implemented)" marker in `spec.md`.

### Built without a task

- [x] T118 Live board-02 login flow: `LoginFlowScreen` in
      `lib/features/login/ui/views/login_flow_screen.dart` (A1 via
      `sign_in_screen.dart`, A4 dialog, A2/A3 with 30-second resend
      countdown, B2 notice, B1 locked step), routed at `/login`; calls
      `AuthRepository` for every device decision (FR-011–FR-018, FR-050,
      FR-052)
- [x] T119 After the device policy passes, sign the partner in through
      `SessionController.signIn` (`lib/features/session/`), which loads the
      profile (`GET /session/lookup` or the mock directory) and saves it
      when Keep Me Signed In is on; then `persistSessionIfRequested`
      (FR-031, FR-032, FR-051)
- [x] T120 Keep the spec-era screens reachable at `/login/legacy`,
      `/register/legacy`, `/home/legacy` in `lib/app/router/app_router.dart`

### Gaps (spec requirements not implemented)

- [ ] T121 Validate device binding when restoring a session on the live
      path: `SessionController.restore()` / the `/login` and signed-in
      redirects in `app_router.dart` must check `getDeviceBindingStatus`
      and discard the session unless it is `active` (FR-033, SC-007,
      quickstart scenario O)
- [ ] T122 Localize the live `LoginFlowScreen` and `SignInScreen` copy
      through the ARB files (Constitution Principle VIII)
- [ ] T123 Name both accounts in the A4 dialog: extend `POST /login`'s
      `conflict` with display details and render the design's before/after
      layout (FR-014; completes T107)
- [ ] T124 Client-side mobile-number format validation before submitting
      A1 (Edge Cases: "Invalid mobile number format")
- [ ] T125 Clear the secure-storage `Session` record on the live sign-out,
      or stop writing it on the live path (FR-035)
- [ ] T126 Show the B3 "session ended" notice when a live session
      restore fails (Design Requirements B3)
- [ ] T127 Widget test driving the live `LoginFlowScreen` through trusted,
      second-device, third-or-later, and conflict paths against the fake
      `AuthService`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: no dependencies
- **Foundational (Phase 2)**: depends on Setup — **blocks every user story**
- **User Stories (Phases 3–11)**: all depend on Foundational. Unlike a
  typical spec-kit feature, these stories are **not fully parallelizable
  across a team** for *implementation*, because several stories extend the
  same `prototype_server` route file written by an earlier story:
  - US3 extends `login_routes.dart` (US2)
  - US4→US5→US6 extend `rebindings`/`rebinding_authorization` routes
    sequentially (US4 creates the authorization-check endpoint, US5 adds
    the authorized-activation transaction, US6 extends that same
    transaction for the conflict case)
  - US7 only adds a regression test over US2/US3's existing logic
  - US8 depends on both US2 (Login) and US7 (a way to produce a Revoked
    device to test session invalidation against)
  - US9 depends on US8 (needs a session to sign out of)

  Recommended order: **US1 → US2 → US3 → US4 → US5 → US6 → US7 → US8 →
  US9**, matching spec.md's priority order (P1s first, then P2s in their
  natural build-on-each-other sequence, then the P3). Each phase's
  Checkpoint is still independently verifiable via its own `quickstart.md`
  scenario(s), even though the phases were built in sequence.
- **Polish (Phase 12)**: depends on all nine user stories being complete.
- **Business-Rule Revision (Phase 13)**: depends on Phases 3–9 (US1–US7)
  as already built; its tasks supersede parts of US3–US6's route/ViewModel
  logic in place, rather than adding a parallel implementation.
  Implemented except T107 — see Phase 13's status note.
- **As-built reconciliation (Phase 14)**: records work done after Phase
  13; its open tasks depend on nothing else.

### Parallel Opportunities

- All Setup tasks marked `[P]` (T002–T004)
- Within Foundational: T008, T009, T011, T012 are `[P]` (distinct files, no
  cross-dependency)
- Within each user story's Tests subsection, all `[P]`-marked tests (distinct
  files) can run in parallel
- Within Polish: T087, T088, T089, T096, T097 are `[P]`

---

## Parallel Example: Foundational Phase

```bash
# After T001–T007 (sequential plumbing), these four can run together:
Task: "Create prototype_server/seed/seed.sql baseline accounts"
Task: "Create Flutter DTOs in lib/features/auth/data/models/"
Task: "Implement device_identity_store.dart"
Task: "Implement session_store.dart"
```

## Parallel Example: User Story 1 Tests

```bash
Task: "prototype_server test: verifyRegistrationOtp atomicity"
Task: "Flutter test: AuthRepository registration flow"
Task: "Flutter test: RegistrationViewModel state machine"
```

---

## Implementation Strategy

### MVP First (User Story 1 only)

1. Phase 1: Setup
2. Phase 2: Foundational (blocks everything)
3. Phase 3: User Story 1 (registration + initial binding)
4. **STOP and VALIDATE**: run `quickstart.md` scenarios A–D
5. Demo: an Installer/Retailer/Wholesaler/Distributor account can register
   and reach authenticated content

### Incremental Delivery

1. Setup + Foundational → foundation ready
2. US1 → validate (A–D) → MVP
3. US2 → validate (E) — everyday trusted sign-in now works
4. US3 → validate (F) — the core security protection now exists
5. US4 → validate (G) — unauthorized takeover is provably blocked
6. US5 → validate (H–I) — legitimate device replacement now works
7. US6 → validate (J–K) — cross-account device conflicts resolve correctly
8. US7 → validate (L) — revocation is provably permanent until re-authorized
9. US8 → validate (M–O) — convenience layer, safely bounded by device state
10. US9 → validate (P) — logout hygiene
11. Polish → both verification gates green, full manual pass, Claude Design
    sign-off

---

## Notes

- `[P]` tasks touch different files with no same-phase dependency.
- `[Story]` labels trace every task back to its `spec.md` user story.
- No task exists for anything outside `spec.md` — no password/username/
  email/dealer-code fields, no OTP retry/cooldown/expiry values, no fake
  CRM UI, no multi-device Active state, are implemented anywhere above.
- OTP expiry duration and session-expiration duration remain the two
  undefined Open Questions from `spec.md`; no task invents a value for
  either.
- Commit after each task or logical group; stop at any Checkpoint to
  validate that story independently before continuing.
