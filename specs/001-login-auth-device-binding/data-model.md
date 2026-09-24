# Phase 1 Data Model: Login, Authentication, and Device Binding

**Input**: [spec.md](./spec.md) Key Entities section | **Research**: [research.md](./research.md)

This document translates the spec's Key Entities into a concrete logical
model. Five entities are authoritative in PostgreSQL (per FR-039); the
sixth, Session, is local-only (per FR-039's "session-specific local
information may use appropriate Flutter local storage").

The base schema is `prototype_server/lib/db/schema.sql`. Later features'
migrations (`db/migrations/001_first_launch_and_registration.sql`) extend
some of these tables — extra `devices` and `accounts` columns, and on
`otp_challenges` nullable `account_id`/`device_id`, a `mobile_number`
column, and a third context `registration_wizard`. Those additions belong
to the first-launch and registration-wizard features; nothing in this
feature reads or writes them.

Every table below is owned exclusively by `prototype_server` (see
`research.md` → "PostgreSQL is reached through a separate local prototype
server process"). The Flutter app never opens a PostgreSQL connection and
never issues SQL; it only sees the outcomes `prototype_server` returns
over HTTP, per `contracts/auth-service.md`.

No field below encodes an undefined business rule (OTP expiry, session
expiry, retry/lockout counts). Where the spec left something open, the
corresponding column is simply absent — adding it now, unused, would imply
a decision nobody made.

## Entity-relationship overview

```text
Account (1) ──< AccountDeviceBinding >── (1) Device
   │                                          │
   │                                          │
   └──< OtpChallenge >───────────────────────┘   (each challenge ties one account to one device)
   │
   └──< RebindingAuthorization >───────────────┘  (each authorization ties one account to one requested device)

Session — local-only (flutter_secure_storage), references an Account and a
Device by their identifiers, not a foreign key in PostgreSQL.
```

Invariants enforced by the schema itself (not just application logic), per
FR-041:

- An account has **at most one** `AccountDeviceBinding` row with
  `status = 'active'` at any time.
- A device has **at most one** `AccountDeviceBinding` row with
  `status = 'active'` at any time (this is what makes a device conflict —
  User Story 6 — structurally impossible to leave half-applied).

## PostgreSQL entities

### `accounts`

Represents a Crown Solar Energy partner account (spec: **Account**).

| Column | Type | Notes |
|---|---|---|
| `id` | `uuid` (PK, default `gen_random_uuid()`) | |
| `mobile_number` | `text`, **unique**, not null | The sole account identifier (FR-007), matched exactly as sent. No format validation happens before the query (the live sign-in field only restricts input to 10 digits). The app's seed data (`db/seed/001_reference_and_partners.sql`) stores ten national digits; `prototype_server/seed/seed.sql` uses a `+92…` form. |
| `user_type` | `text`, not null, `CHECK (user_type IN ('installer','retailer','wholesaler','distributor'))` | One of the four supported types (Actors & User Types). No auth logic branches on this value (FR-004, FR-025). |
| `status` | `text`, not null, default `'active'`, `CHECK (status = 'active')` | This feature only ever produces/reads `'active'`; broader account lifecycle (suspension, etc.) is out of scope and intentionally not modeled beyond the single value the spec's "its status" attribute requires. |
| `created_at` | `timestamptz`, not null, default `now()` | |

Account provisioning (how a row first appears here) is out of scope
(spec Assumptions) — this feature only reads existing rows by
`mobile_number`.

### `devices`

Represents one physical app installation the system has ever seen (spec:
**Device**).

| Column | Type | Notes |
|---|---|---|
| `id` | `uuid` (PK, default `gen_random_uuid()`) | |
| `installation_uuid` | `text`, **unique**, not null | The locally generated identifier from `research.md` ("Decision: `uuid` package"). Upserted (bumping `updated_at`) whenever an installation presents itself: a registration OTP request, any `POST /login` or confirm-takeover for a known account, and every device-status check. |
| `platform` | `text`, nullable | Optional metadata (e.g., `android`/`ios`); not used by any business rule in this feature. |
| `created_at` | `timestamptz`, not null, default `now()` | |
| `updated_at` | `timestamptz`, not null, default `now()` | |

### `account_device_bindings`

Represents the relationship between one Account and one Device at a point
in time (spec: **AccountDeviceBinding**). Append-only history: a new
activation always inserts a new row; existing rows only ever transition
`active → revoked`, never back.

| Column | Type | Notes |
|---|---|---|
| `id` | `uuid` (PK, default `gen_random_uuid()`) | |
| `account_id` | `uuid`, FK → `accounts.id`, not null | |
| `device_id` | `uuid`, FK → `devices.id`, not null | |
| `status` | `text`, not null, `CHECK (status IN ('active','revoked'))` | Device-binding states per FR-008 — exactly these two persisted values; `New/Untrusted` is not a stored state, it is the *absence* of an active row matching the current device — determined by `prototype_server`'s `evaluateLogin` handler (see `contracts/auth-service.md`), never by the Flutter client. |
| `created_at` | `timestamptz`, not null, default `now()` | |
| `revoked_at` | `timestamptz`, nullable | Set when `status` transitions to `revoked`. |
| `context` | `text`, not null, `CHECK (context IN ('initial_registration','rebinding'))` | Why this row was created — supports the "binding history" the spec's entity description calls for, without inventing new states. `initial_registration` is written only by the legacy `/registration/otp/verify` route; every login-driven activation, including an account's very first binding when it had none (FR-049), is `rebinding`. |

**Integrity constraints** (enforce the invariants above at the database
level, not just in application code):

```sql
CREATE UNIQUE INDEX account_device_bindings_one_active_per_account
  ON account_device_bindings (account_id)
  WHERE status = 'active';

CREATE UNIQUE INDEX account_device_bindings_one_active_per_device
  ON account_device_bindings (device_id)
  WHERE status = 'active';
```

Together these two partial unique indexes are what make FR-041 ("an
account never has more than one Active device") and the device-conflict
invariant (a device never remains Active for two accounts) impossible to
violate, even under a bug in the transaction logic — the second `INSERT`
of a conflicting `active` row simply fails, which is exactly the "fail
atomically, change nothing" behavior FR-042/FR-043 require.

**Device-move tier is derived, not stored** (`spec.md` §Device-Move
Tiers): an account's device-move count — which determines whether
FR-016's second-device tier or FR-017/FR-018's third-or-later tier
applies to its next New/Untrusted-device login — is computed on demand as

```sql
SELECT count(*) FROM account_device_bindings
WHERE account_id = $1 AND context = 'rebinding';
```

`count = 0` ⇒ second-device tier; `count >= 1` ⇒ third-or-later tier. No
new column or table is introduced for this: the existing `context` column
above is sufficient. `prototype_server` computes this count in three
places — `POST /login`, `POST /login/otp`, and inside the
`POST /rebindings` transaction (before that move's own row is inserted) —
never the Flutter client (FR-046).

**Binding status for a pair** (`GET /accounts/{accountId}/devices/{installationUuid}/status`)
is the `status` of the *most recent* row for that `(account_id,
device_id)`; no row ⇒ `new_untrusted`.

### `otp_challenges`

Represents one simulated OTP challenge (spec: **OTP Challenge**).

| Column | Type | Notes |
|---|---|---|
| `id` | `uuid` (PK, default `gen_random_uuid()`) | |
| `account_id` | `uuid`, FK → `accounts.id`, not null | |
| `device_id` | `uuid`, FK → `devices.id`, not null | The device attempting registration or login (FR-020). |
| `context` | `text`, not null, `CHECK (context IN ('registration','new_device_login'))` | Distinguishes the two authentication events per FR-005/FR-021 — never conflated. (Migration 001 widens this check with `registration_wizard`, used by another feature.) |
| `code` | `text`, not null | The simulated 6-digit challenge value (`prototype_server/lib/otp/otp_generator.dart`). Returned to the caller for prototype testability only (FR-052); never treated as a delivered "real SMS." |
| `verified` | `boolean`, not null, default `false` | Flips to `true` on successful verification. Verification always checks the pair's most recent unverified challenge of that context (FR-050). A verified login challenge is never consumed: `POST /rebindings` accepts *any* verified `new_device_login` row for the pair. |
| `created_at` | `timestamptz`, not null, default `now()` | |
| `verified_at` | `timestamptz`, nullable | |

No `expires_at`, attempt-count, or lockout column exists — OTP expiry is
an [Open Question](./spec.md#open-questions--business-rules-required) and
retry/lockout limits are explicitly out of scope. When those business
rules are defined, this table gains the corresponding columns then, not
before.

### `rebinding_authorizations`

Represents one externally sourced (CRM-conceptual) authorization decision
for a specific account/device rebinding attempt (spec:
**RebindingAuthorization**). Per `spec.md` §Device-Move Tiers, this table
is only ever consulted by `prototype_server` for a **third-or-later-tier**
move (FR-017/FR-022) — a second-device-tier move (FR-016) never reads or
writes a row here, even if one happens to already exist for that account/
device pair.

| Column | Type | Notes |
|---|---|---|
| `id` | `uuid` (PK, default `gen_random_uuid()`) | |
| `account_id` | `uuid`, FK → `accounts.id`, not null | The account requesting the rebinding. |
| `device_id` | `uuid`, FK → `devices.id`, not null | The requested (New/Untrusted) device. |
| `status` | `text`, not null, default `'pending'`, `CHECK (status IN ('pending','authorized','not_authorized'))` | Never a device state — tracked entirely independently of `account_device_bindings` (FR-008, FR-022). |
| `requested_at` | `timestamptz`, not null, default `now()` | |
| `resolved_at` | `timestamptz`, nullable | Meant to be set when `status` leaves `pending`; `prototype_server` never writes it — whoever sets `status` directly in the database must. |
| `source` | `text`, not null, default `'prototype_simulated_crm'` | Documents that this is a stand-in for the real external/CRM system (FR-027), never a value a partner can set themselves (FR-028). |

As built, a row is created (as `pending`) only when none exists yet for
the `(account_id, device_id)` pair — by `GET /rebinding-authorizations`,
or by `POST /login/otp` at the third-or-later tier. After that, the most
recent row for the pair is read and reused on every later attempt; a
completed move does not consume it (see spec.md Open Questions).

## Local-only entity

### `Session` (not a PostgreSQL table)

Represents the prototype's authenticated session on the current device
(spec: **Session**), stored via `flutter_secure_storage`
(`research.md`) as a single serialized record, never in PostgreSQL.

| Field | Type | Notes |
|---|---|---|
| `accountId` | `String` | The signed-in account's `accounts.id`. |
| `deviceInstallationUuid` | `String` | This installation's local device identifier. |
| `keepSignedIn` | `bool` | Whether the session should survive an app restart (FR-030–FR-032). Only ever written as `true` — nothing is saved when it is off. |
| `createdAt` | `DateTime` (ISO-8601 string) | |

Written by `AuthRepository.persistSessionIfRequested` after a trusted
sign-in or completed move (both the live and legacy login flows). Read
only by `AuthRepository.restoreSession`, which calls
`AuthService.getDeviceBindingStatus` to confirm the device is **still**
that account's Active device before restoring, and clears the record
otherwise (FR-033). That restore runs only on the `/login/legacy` route.
The legacy logout deletes this record; the live sign-out does not. Neither
touches `account_device_bindings`.

No `expiresAt` field exists, matching the session-expiration Open
Question — the same "we don't invent it, we just don't add the column"
principle as `otp_challenges`.

### Signed-in partner record (not a PostgreSQL table)

The record the **live** restore path actually uses
(`lib/features/session/data/session_repository.dart`): the signed-in
partner's profile as JSON (`mobileNumber`, `businessName`, `contactName`,
`role`, `market`, `approved`), stored under `session.user` in the app's
preferences store (`shared_preferences`, not secure storage). Written on
sign-in when Keep Me Signed In is on, removed when it is off and on
sign-out. Restoring it does **not** consult device-binding state (FR-033
Not implemented on this path).

### Device identifier (not a PostgreSQL table)

`auth.device_installation_uuid` in `flutter_secure_storage`: a v4 UUID
generated on first use (`SecureDeviceIdentityStore`). A reinstall yields a
new one, so the reinstalled app is New/Untrusted.

## Validation rules carried over from the spec (not re-derived here)

- Mobile number format validation before any registration/login attempt
  reaches the data layer is **Not implemented** (Edge Cases: "Invalid
  mobile number format"); an unmatched number simply finds no account.
- A device is classified New/Untrusted purely by the *absence* of a
  matching `active` `account_device_bindings` row for the current
  `(account_id, device_id)` pair — there is no separate "untrusted" flag
  to keep in sync.
- Every binding transition described in User Stories 4–7 is one
  `UPDATE`/`UPDATE`/`INSERT` sequence against `account_device_bindings`,
  executed inside one database transaction (see
  `contracts/auth-service.md` → `completeRebinding`). `rebinding_authorizations`
  is only read inside that transaction; its `pending` row is created
  earlier, outside it.
