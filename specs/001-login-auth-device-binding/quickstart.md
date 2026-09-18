# Quickstart: Validating Login, Authentication, and Device Binding

This guide runs and validates the feature end-to-end against a real local
PostgreSQL database, exercising the prototype exactly as `spec.md`
describes it — not a mocked or simulated backend. It does not restate
implementation details; see `data-model.md` and
`contracts/auth-service.md` for those.

The Flutter app never talks to PostgreSQL directly (`research.md`); it
calls `prototype_server`, a small local HTTP process, which is the only
thing that opens a database connection. Both must be running to validate
any scenario below.

**Device-move tiers, in brief** (spec.md "Device-Move Tiers" is
authoritative — this is only a recap so the scenarios below read clearly):
Device 1 is bound during Registration (out of this feature's scope).
Moving to **Device 2** — the account's *first* move — needs a
login-context OTP alone; no rebinding-authorization record is ever
consulted for it. Moving to **Device 3 and every device after that**
needs a rebinding-authorization outcome of `authorized` **before** any
OTP is requested — `pending`/`not_authorized` means no OTP is requested at
all. Independently of either tier, whenever the target device is
currently Active for a *different* account, a conflict-confirmation step
must occur before any OTP is requested.

## Prerequisites

1. **Flutter toolchain on `PATH` for the session** (per `CLAUDE.md`):

   ```powershell
   $env:PATH = "C:\src\flutter\bin;$env:PATH"
   ```

2. **A local PostgreSQL instance**, already installed per the project
   description. Create a database and apply the schema from
   `data-model.md` (table definitions + the two partial unique indexes).

3. **Seed the baseline accounts** (see "Seed data & test fixtures" below)
   before starting `prototype_server`.

4. **Start `prototype_server`**, configured with its own local,
   non-committed PostgreSQL connection details (per the constitution's
   "secrets... never invented or committed"):

   ```powershell
   cd prototype_server
   dart pub get
   $env:PG_HOST = "localhost"
   $env:PG_PORT = "5432"
   $env:PG_DATABASE = "cse_b2b_prototype"
   $env:PG_USER = "<local-dev-user>"
   $env:PG_PASSWORD = "<local-dev-password>"
   dart run bin/server.dart
   ```

   `prototype_server` and PostgreSQL run on the same machine, so
   `localhost` is correct here regardless of how the Flutter app itself
   will later reach `prototype_server` (see next step).

5. **Run the Flutter app pointed at `prototype_server`**, via
   `--dart-define`:

   ```powershell
   flutter pub get
   flutter gen-l10n
   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080
   ```

   `10.0.2.2` is how an Android emulator reaches the host machine; use
   `http://localhost:8080` on iOS Simulator, or the host's LAN IP on a
   physical device (`research.md`).

6. **Claude Design tokens synced** before judging any screen visually
   (`docs/DESIGN_SYSTEM.md`): run `/design-login` once, then pull the real
   `cse-design-system` tokens into `lib/core/theme/`. This guide validates
   *behavior*; visual conformance to Claude Design is validated separately
   per the spec's Design Requirements.

## Seed data & test fixtures

Account provisioning is out of this feature's scope (spec Assumptions), so
the baseline accounts this guide needs are inserted directly, not through
the app. `prototype_server/seed/seed.sql` (created in `/speckit-tasks`)
inserts one `accounts` row per user type with distinct mobile numbers:

```sql
INSERT INTO accounts (mobile_number, user_type) VALUES
  ('+92300...001', 'installer'),
  ('+92300...002', 'retailer'),
  ('+92300...003', 'wholesaler'),
  ('+92300...004', 'distributor');
```

Apply it once against the local database:

```bash
psql -h localhost -U <local-dev-user> -d cse_b2b_prototype -f prototype_server/seed/seed.sql
```

Every other fixture state this guide's scenarios need —
**no Active device**, **Active device**, **Revoked device**, **a device
Active for another account (conflict)**, an account's **device-move
count** (0 for the second-device tier, 1+ for the third-or-later tier —
never a value you set directly; it is always the number of prior
`rebinding`-context bindings an account has actually accumulated by
running the flows below), and **Pending / Authorized / Not Authorized
rebinding authorization** — is reached by *running the real flows*
(scenarios A–R below), not by hand-crafting rows that would bypass the
very integrity logic being validated. The one deliberate exception is
`rebinding_authorizations.status`: because the real external/CRM system
does not exist in this prototype, that one column is set directly in the
database (`UPDATE rebinding_authorizations SET status = 'authorized' ...`)
to simulate the external decision each scenario needs — this is called
out explicitly wherever it happens below, and it is the only fixture step
that touches the database directly rather than going through
`prototype_server`.

## How to read the scenarios below

Each scenario cites its **Acceptance Scenario letter** from
`spec.md` (§User Scenarios & Testing) so a tester can cross-reference the
exact `Given/When/Then` it proves. Steps describe *what to do in the running
app and what to check in the database*, not UI pixel detail.

---

### A–D. Registration + initial device binding (all four user types)

For each user type (Installer, Retailer, Wholesaler, Distributor):

1. Launch the app on a fresh install (or clear local secure storage) so no
   device UUID / session exists yet.
2. Enter that user type's seeded registered mobile number.
3. Confirm the app requests a registration OTP and does **not** yet show
   authenticated content.
4. Submit the OTP value surfaced by the prototype (`research.md` → "OTP
   simulation surfaced for prototype testability").
5. **Expect**: the app reaches authenticated content; in
   `account_device_bindings`, exactly one new row exists for that account
   with `status = 'active'`, `context = 'initial_registration'`.

Repeat for all four types to cover Acceptance Scenarios A, B, C, D.

### E. Trusted-device login (no OTP)

1. On the same device used in scenario A, sign out (see scenario P) or
   restart the app without "Keep Me Signed In."
2. Enter the same account's mobile number again.
3. **Expect**: authenticated content is reached with **no** OTP prompt.

### F. New/untrusted device is detected; conflict check and tier determination precede any OTP

1. On a second device (a second emulator, or clear the local device UUID
   to simulate one), enter the mobile number of an account already bound
   in scenario A — one that has never moved off its registration device.
2. **Expect**: the app shows a New/Untrusted-device state. Inspect the
   `POST /login` response (`contracts/auth-service.md`): `conflict` is
   `null` (this device is not Active for anyone else), and `tier` is
   `second_device` (this account's device-move count — prior
   `rebinding`-context bindings — is `0`). Neither is computed or assumed
   by the Flutter client; both come straight from `prototype_server`.
3. **Expect**: because the tier is `second_device`, the app requests a
   login-context OTP immediately — a **different** `otp_challenges` row
   (`context = 'new_device_login'`) from the one created during
   registration — and does **not** call `checkRebindingAuthorization` at
   any point for this device.

### R. Second-device tier: a login-context OTP alone completes the move (Acceptance Scenario R)

1. Continuing from scenario F, submit the correct login-context OTP.
2. **Expect (R, first half)**: the OTP was requested unconditionally, with
   no rebinding-authorization record ever created or consulted for this
   account/device pair — confirm no row for it exists in
   `rebinding_authorizations`.
3. **Expect (R, second half)**: once verified, the second device (now
   "Device 2" for this account) reaches authenticated content
   immediately; in `account_device_bindings`, Device 2's row is now
   `status = 'active'`, `context = 'rebinding'`, and Device 1's row is
   now `status = 'revoked'` with `revoked_at` set — both changes
   committed together in one transaction, never an intermediate state
   with two `active` rows for the account. The account's device-move
   count is now `1`, so its *next* move will be evaluated at the
   third-or-later tier (scenarios G–I below).

### G. Third-or-later tier: rebinding refused when authorization is not available (Acceptance Scenario G)

1. Continuing from scenario R (the account now has a device-move count of
   `1`), on a **third** device, enter the same account's mobile number.
2. **Expect**: `POST /login` reports `tier = third_or_later` for this
   account. Because of that, the app calls `checkRebindingAuthorization`
   **before** requesting any OTP — confirm no `otp_challenges` row
   (`context = 'new_device_login'`) exists yet for this device.
3. In `rebinding_authorizations`, leave the resulting row's `status` as
   `pending`, or set it to `not_authorized` directly in the database
   (simulating the external/CRM decision).
4. **Expect**: the app shows the refused/pending state and **never
   requests an OTP** for this attempt (`POST /login/otp` would itself
   return `403 not_authorized` if called directly — confirm via the
   route, not just the UI); in `account_device_bindings`, Device 2's row
   (the account's current Active device) is still `status = 'active'`
   and completely unchanged.

### H–I. Third-or-later tier: authorized rebinding activates the new device, revokes the old one (Acceptance Scenario H)

1. Continuing from scenario G, set the `rebinding_authorizations` row's
   `status` to `authorized` (simulating the external/CRM approval).
2. Trigger the app to re-check authorization (the same retry action shown
   on the refused state).
3. **Expect**: only now does the app request a login-context OTP. Submit
   the correct code.
4. **Expect**: the third device reaches authenticated content; in
   `account_device_bindings`, the third device's row is now
   `status = 'active'`, and Device 2's row is now `status = 'revoked'`
   with `revoked_at` set — both changes committed together (inspect that
   no intermediate state with two `active` rows for the account ever
   exists, by checking the transaction touches both rows in one
   statement/transaction).

### Q. Device conflict: the takeover confirmation occurs before any OTP is requested (Acceptance Scenario Q)

1. Using two of the seeded accounts of two *different* user types (e.g.,
   an Installer and a Retailer), each already registered on its own
   device (Device A for the Installer, Device B for the Retailer — per
   scenarios A–D; neither has moved yet, so both are still at the
   second-device tier).
2. On Device B, enter the Installer's mobile number.
3. **Expect**: `POST /login`'s response carries a non-null `conflict`
   naming the Retailer's account, **before** `tier` is acted on and
   before any OTP is requested. The app shows the takeover-confirmation
   step (Claude Design A4) naming both accounts — confirm no
   `otp_challenges` row exists yet for this device.
4. **Decline** the confirmation. **Expect**: nothing changes at all —
   `POST /login/confirm-takeover` is never called, no OTP is requested,
   and both accounts' bindings in `account_device_bindings` are exactly
   as they were before step 2.
5. Repeat steps 2–3, then **confirm** the takeover this time. **Expect**:
   `POST /login/confirm-takeover` is called (it writes nothing itself —
   confirm `account_device_bindings` is still unchanged immediately
   after), and only then does the flow proceed to the Installer's own
   tier-gated path (second-device tier here, per step 1 → scenario F/R's
   behavior applies next).

### J–K. Device conflict: transferring a device Active for another account (Acceptance Scenarios J, K)

1. Continuing directly from scenario Q's confirmed case: the Installer is
   now past the conflict gate and at the second-device tier for Device B,
   so the app requests a login-context OTP unconditionally (scenario
   F/R's behavior — no authorization involved, since this is the
   Installer's first move).
2. Submit the correct OTP. **Expect after completion**:
   `account_device_bindings` shows Device B `active` for the Installer,
   the Installer's prior device (Device A) `revoked`, and the Retailer's
   binding to Device B `revoked` — three consistent row states from one
   atomic operation, never a state with Device B `active` for two
   accounts at once.
3. Repeat with a different pair of user types (e.g., Wholesaler ↔
   Distributor) to confirm no special-casing (Acceptance Scenario K).
4. **Tier is orthogonal to this atomicity guarantee**: repeating this
   scenario with a requesting account that already has a device-move
   count of `1` or more (i.e., has already completed scenario R once)
   composes with scenarios G–I instead of F/R — the conflict
   confirmation (Q) still happens first, but authorization must then be
   `authorized` before any OTP is requested, and the same atomic 3-row
   transfer applies once it is.

### L. A previously revoked device cannot bypass revocation (Acceptance Scenario L)

1. Using the device revoked in scenario R, H/I, or J/K, attempt to sign in
   again with the account it used to belong to.
2. **Expect**: it is classified New/Untrusted (not trusted) and is
   re-evaluated at whichever tier now applies to the account — since a
   move has already happened, this will be the third-or-later tier, not
   the second-device tier the account may have started at. It must go
   through that tier's full gate (authorization before OTP, or OTP alone,
   whichever the account's *current* device-move count implies) to
   become Active again — it never silently regains access, and it is
   never re-evaluated against a stale, earlier tier.

### M–N. Keep Me Signed In on/off

1. Sign in with "Keep Me Signed In" enabled; restart the app.
   **Expect**: authenticated content is restored with no re-entry of the
   mobile number (Scenario M).
2. Sign in with "Keep Me Signed In" disabled; restart the app.
   **Expect**: the app returns to the sign-in screen (Scenario N).
3. **Expect throughout**: neither outcome depends in any way on which
   device-move tier last applied to this account, or on whether a device
   conflict was ever involved — session persistence and device-move
   tiering are completely independent.

### O. Persisted session on a device that was later revoked

1. Sign in on Device A with "Keep Me Signed In" enabled (do not restart
   yet).
2. From a different device, complete a rebinding that revokes Device A —
   either scenario R (second-device tier) or scenario H/I
   (third-or-later tier); the outcome below is identical either way.
3. Restart the app on Device A.
4. **Expect**: the persisted local session does **not** restore
   authenticated content — the app checks `getDeviceBindingStatus`
   (`contracts/auth-service.md`) and finds Device A `revoked`, so it
   returns to sign-in. Which tier caused the revocation is irrelevant to
   this check.

### P. Logout does not unbind the device

1. On an account's Active device, sign in, then explicitly sign out.
2. **Expect**: the app returns to sign-in; `account_device_bindings` is
   **unchanged** — the same row remains `status = 'active'`, and the
   account's device-move count is unaffected (logout never writes to
   `account_device_bindings` at all).
3. Sign in again from the same device with the same mobile number.
   **Expect**: trusted-device login (Scenario E behavior) — no OTP,
   regardless of the account's device-move tier.

---

## Automated coverage vs. this guide

`flutter test` (see `research.md` → "Testing approach") covers how
ViewModels/`AuthRepository` render each outcome `AuthService` can return,
against an in-memory fake `AuthService`, with **no** `prototype_server` or
PostgreSQL dependency, as part of the standard
`dart format . && flutter analyze && flutter test` gate. `prototype_server`
has its own `dart test` suite for its request-handling logic against a
fake data layer.

The scenarios in this document additionally validate the real
`prototype_server` implementation end-to-end and the database's own
integrity constraints (the partial unique indexes in `data-model.md`) —
they require both `prototype_server` and a live local PostgreSQL instance
running, and are run manually/locally, not as part of either package's
automated test suite, since no CI/CD infrastructure exists for this
project yet.
