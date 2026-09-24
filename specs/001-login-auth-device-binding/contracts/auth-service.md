# Contract: `AuthService`

**Input**: [spec.md](../spec.md) Functional Requirements | **Data model**: [data-model.md](../data-model.md)

This is the interface boundary the `AuthRepository` depends on (per
`research.md` → "PostgreSQL is reached through a separate local prototype
server process"). It has exactly **one** Flutter-side implementation for
this feature's entire lifetime — `HttpAuthService`
(`lib/features/auth/data/services/http_auth_service.dart`) — which calls
these operations as real HTTP requests. Two different servers answer that
same HTTP contract at different times, never the Flutter app itself:

- **`prototype_server`** (this feature): a local Dart/`shelf` process that
  implements every endpoint below against the local PostgreSQL database
  described in `data-model.md` (routes in `prototype_server/lib/routes/`,
  mounted by `prototype_server/lib/router.dart`).
- **The production ASP.NET Core API** (future, out of scope for this
  feature): implements the identical endpoints against SQL Server.

Because both are reached the same way — `HttpAuthService` calling a
configured base URL (`API_BASE_URL`, default `http://10.0.2.2:8080`) —
moving to production is a configuration change (which base URL), not a
Repository or UI code change (FR-040).

**Reconciled with the implementation (2026-09-24)**: the table and the
wire shapes below describe the routes as built. The device-move-tiering
revision (`tier`, `conflict`, `confirmTakeover`) is implemented.

| Operation (`AuthService` method) | Purpose | Spec traceability | REST endpoint (implemented by `prototype_server`) |
|---|---|---|---|
| `requestRegistrationOtp(mobileNumber, deviceId)` | Issue an OTP challenge for a mobile number whose account has no Active device yet. Legacy registration path only. | FR-001, FR-002 | `POST /registration/otp` |
| `verifyRegistrationOtp(accountId, deviceId, code)` | Verify the registration OTP and, only on success, atomically create the account's initial `active` binding (`initial_registration` — Device 1, not a device move). | FR-001–FR-003, FR-043 (atomicity) | `POST /registration/otp/verify` |
| `evaluateLogin(mobileNumber, deviceId)` | Given a mobile number and the current device, report whether the device is the account's Active device (trusted) or not. For a New/Untrusted device the one response carries both the **conflict** (Active for a different account, else `null`) and the requesting account's device-move **tier** (`second_device` if it has zero `rebinding`-context bindings, else `third_or_later`). The client acts on `conflict` first. Grants no access itself. | FR-011–FR-015 | `POST /login` |
| `confirmTakeover(mobileNumber, deviceId)` | Acknowledge a reported conflict so the client may proceed to the tier-gated path. Writes nothing; declining means never calling it. The server does not require it before `completeRebinding`. | FR-014 | `POST /login/confirm-takeover` |
| `requestLoginOtp(accountId, deviceId)` | Issue a login-context OTP challenge (`new_device_login`). At `second_device`, issued unconditionally; at `third_or_later`, the server reads (creating as `pending` if absent) the latest authorization for the pair and refuses unless it is `authorized`. | FR-016, FR-017, FR-050 | `POST /login/otp` |
| `verifyLoginOtp(accountId, deviceId, code)` | Verify against the pair's most recent unverified login challenge. Verification alone does **not** grant Active status. | FR-016, FR-018, FR-021 | `POST /login/otp/verify` |
| `checkRebindingAuthorization(accountId, deviceId)` | Read the latest `pending` / `authorized` / `not_authorized` state for the pair, creating a `pending` record if none exists. Only called by the client at `third_or_later`; nothing server-side rejects a call at `second_device`. | FR-017, FR-022 | `GET /rebinding-authorizations?accountId=&deviceId=` |
| `completeRebinding(accountId, deviceId)` | In one transaction: require any verified `new_device_login` OTP for the pair; re-derive the tier and, at `third_or_later`, require the latest authorization to be `authorized`; then revoke the account's current Active binding, revoke any *other* account's Active binding to `deviceId`, and insert an `active` / `rebinding` row. | FR-023, FR-024, FR-025, FR-041, FR-042 | `POST /rebindings` |
| `getDeviceBindingStatus(accountId, deviceId)` | Read-only: the status of the most recent binding row for the pair — `active`, `revoked`, or `new_untrusted` when none exists. Here `deviceId` is the installation UUID (cold start), not the server's internal id. Used by `AuthRepository.restoreSession` (legacy path only). | FR-008, FR-033 | `GET /accounts/{accountId}/devices/{installationUuid}/status` |

All device-trust evaluation, conflict detection, tier determination, and
rebinding-eligibility decisions are made **inside `prototype_server`'s
handlers and its `AuthDataStore`**, against PostgreSQL — never by
`AuthRepository`. The Repository's job is limited to calling the right
operation and translating its result into something the UI can render; it
holds no independent copy of the business rules (FR-046). The takeover
*confirmation* is the one gate enforced only by the client (see spec.md
Open Questions).

Logout (FR-035/FR-036) and Keep-Me-Signed-In persistence (FR-030–FR-034)
are **not** `AuthService` operations — they only ever touch local records
(`data-model.md` → Local-only entities), never PostgreSQL. Signing out
never calls into device-binding state.

## Wire shapes (as implemented)

Request bodies are JSON. `deviceId` in `POST /registration/otp`,
`POST /login`, and `POST /login/confirm-takeover` is the app's
installation UUID; the server resolves it (creating a `devices` row if
new) and returns its internal `deviceId`, which the client passes to every
later call in the same flow. Missing required fields return
`400 {"error": "... are required"}` on every route below.

| Endpoint | Request | Success | Business-outcome responses |
|---|---|---|---|
| `POST /registration/otp` | `mobileNumber`, `deviceId` | `200 {accountId, deviceId, challengeId, code}` | `404 {error: account_not_found}`; `409 {error: already_registered}` |
| `POST /registration/otp/verify` | `accountId`, `deviceId`, `code` | `200 {status: active}` | `400 invalid_code`; `404 challenge_not_found`; `409 binding_failed` (rolled back) |
| `POST /login` | `mobileNumber`, `deviceId` | `200 {accountId, deviceId, outcome: trusted}` or `200 {accountId, deviceId, outcome: new_untrusted, conflict: {otherAccountId} \| null, tier: second_device \| third_or_later}` | `404 account_not_found` |
| `POST /login/confirm-takeover` | `mobileNumber`, `deviceId` | `200 {accountId, deviceId, acknowledged: true}` | `404 account_not_found` |
| `POST /login/otp` | `accountId`, `deviceId` | `200 {challengeId, code}` | `403 {error: not_authorized, authorizationStatus}` (third-or-later tier only) |
| `POST /login/otp/verify` | `accountId`, `deviceId`, `code` | `200 {verified: true}` | `400 invalid_code`; `404 challenge_not_found` |
| `GET /rebinding-authorizations` | query `accountId`, `deviceId` | `200 {status: pending \| authorized \| not_authorized}` | — |
| `POST /rebindings` | `accountId`, `deviceId` | `200 {status: active}` | `400 otp_not_verified`; `403 not_authorized`; `409 rebinding_failed` (rolled back) |
| `GET /accounts/{accountId}/devices/{installationUuid}/status` | path only | `200 {status: active \| revoked \| new_untrusted}` | — |

`code` is returned for prototype testability only (FR-052). Client-side
mapping in `HttpAuthService`: any non-200 from `POST /login` is treated as
account-not-found; `POST /login/otp/verify` maps 400 to invalid code and
anything else non-200 to not-found; `POST /rebindings` maps 400/403 as
above and anything else non-200 to failed.

## Error / outcome shape (behavioral, not literal Dart types)

Every operation that can fail for a business reason (invalid OTP, unknown
mobile number, authorization not yet resolved) returns a specific HTTP
status code + JSON body (above) that `HttpAuthService` turns into a
**result value** the UI can render — it never throws for an expected
business outcome. Only genuine infrastructure failure (the local server
or PostgreSQL is unreachable) is an exception. Per FR-041–FR-043, a
PostgreSQL error inside `verifyRegistrationOtp` or `completeRebinding`
rolls the whole transaction back and is reported as `409`; the Flutter
app never participates in that transaction. This is unaffected by which
tier gated the call.

## What this contract deliberately does not define

- OTP expiry/retry/lockout behavior (Open Question in `spec.md`).
- Session-expiration duration (Open Question in `spec.md`).
- Any CRM UI or a way for a caller to set `rebinding_authorizations.status`
  itself — `checkRebindingAuthorization` only ever *reads* (and, if
  absent, creates as `pending`) that state; no route accepts a status
  (FR-028).
- A third device-move tier, or any additional free move beyond the
  account's first — `tier` is exhaustively `second_device` |
  `third_or_later`; there is no third value.
- The other account's name or role for the A4 dialog — `conflict` carries
  only `otherAccountId` (the account-naming part of FR-014 is Not
  implemented).
