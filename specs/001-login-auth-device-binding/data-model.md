# Phase 1 Data Model: Login, Authentication, and Device Binding

**Input**: [spec.md](./spec.md) Key Entities section | **Research**: [research.md](./research.md)

This document translates the spec's Key Entities into a concrete logical
model. Five entities are authoritative in PostgreSQL (per FR-036); the
sixth, Session, is local-only (per FR-036's "session-specific local
information may use appropriate Flutter local storage").

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
FR-038:

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
| `mobile_number` | `text`, **unique**, not null | The sole account identifier (FR-007). Format validation happens in the application layer before any query. |
| `user_type` | `text`, not null, `CHECK (user_type IN ('installer','retailer','wholesaler','distributor'))` | One of the four supported types (Actors & User Types). No other logic branches on this value in this feature (FR-004, FR-022). |
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
| `installation_uuid` | `text`, **unique**, not null | The locally generated identifier from `research.md` ("Decision: `uuid` package"). A row is created the first time a given installation presents itself, whether during registration or a New/Untrusted login attempt. |
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
| `context` | `text`, not null, `CHECK (context IN ('initial_registration','rebinding'))` | Why this row was created — supports the "binding history" the spec's entity description calls for, without inventing new states. |

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
above is sufficient, and `prototype_server`'s `evaluateLogin` handler
(`contracts/auth-service.md`) is the only place this count is computed —
never the Flutter client (FR-046).

### `otp_challenges`

Represents one simulated OTP challenge (spec: **OTP Challenge**).

| Column | Type | Notes |
|---|---|---|
| `id` | `uuid` (PK, default `gen_random_uuid()`) | |
| `account_id` | `uuid`, FK → `accounts.id`, not null | |
| `device_id` | `uuid`, FK → `devices.id`, not null | The device attempting registration or login (FR-020). |
| `context` | `text`, not null, `CHECK (context IN ('registration','new_device_login'))` | Distinguishes the two authentication events per FR-005/FR-021 — never conflated. |
| `code` | `text`, not null | The simulated challenge value. Returned to the caller for prototype testability only (`research.md`); never treated as a delivered "real SMS." |
| `verified` | `boolean`, not null, default `false` | Flips to `true` on the first successful verification. |
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
| `resolved_at` | `timestamptz`, nullable | Set when `status` leaves `pending`. |
| `source` | `text`, not null, default `'prototype_simulated_crm'` | Documents that this is a stand-in for the real external/CRM system (FR-024), never a value a partner can set themselves (FR-025). |

A new rebinding attempt always creates a new row (never reuses/edits a
resolved one for a different attempt), so history of prior authorization
decisions is preserved.

## Local-only entity

### `Session` (not a PostgreSQL table)

Represents the prototype's authenticated session on the current device
(spec: **Session**), stored via `flutter_secure_storage`
(`research.md`) as a single serialized record, never in PostgreSQL.

| Field | Type | Notes |
|---|---|---|
| `accountId` | `String` | The signed-in account's `accounts.id`. |
| `deviceInstallationUuid` | `String` | This installation's local device identifier. |
| `keepSignedIn` | `bool` | Whether the session should survive an app restart (FR-027–FR-029). |
| `createdAt` | `DateTime` (ISO-8601 string) | |

On app start, if `keepSignedIn` is `true` and a `Session` record exists,
the Repository calls `AuthService.getDeviceBindingStatus` (see
`contracts/auth-service.md`) to confirm the referenced device is **still**
that account's Active device before restoring authenticated state
(FR-030) — the local `Session` record is never, by itself, sufficient
evidence of continued access. Signing out (FR-032/FR-033) deletes only
this local record; it never touches `account_device_bindings`.

No `expiresAt` field exists, matching the session-expiration Open
Question — the same "we don't invent it, we just don't add the column"
principle as `otp_challenges`.

## Validation rules carried over from the spec (not re-derived here)

- Mobile number format validation happens before any registration/login
  attempt reaches the data layer (Edge Cases: "Invalid mobile number
  format").
- A device is classified New/Untrusted purely by the *absence* of a
  matching `active` `account_device_bindings` row for the current
  `(account_id, device_id)` pair — there is no separate "untrusted" flag
  to keep in sync.
- Every state transition described in User Stories 4–7 maps to exactly
  one `INSERT`/`UPDATE` sequence against `account_device_bindings` and
  `rebinding_authorizations`, executed inside one database transaction
  (see `contracts/auth-service.md` → `completeRebinding`).
