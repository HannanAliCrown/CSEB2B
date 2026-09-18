# Contract: `AuthService`

**Input**: [spec.md](../spec.md) Functional Requirements | **Data model**: [data-model.md](../data-model.md)

This is the interface boundary the `AuthRepository` depends on (per
`research.md` → "PostgreSQL is reached through a separate local prototype
server process"). It has exactly **one** Flutter-side implementation for
this feature's entire lifetime — `HttpAuthService` — which calls these
operations as real HTTP requests. Two different servers answer that same
HTTP contract at different times, never the Flutter app itself:

- **`prototype_server`** (this feature): a local Dart/`shelf` process that
  implements every endpoint below against the local PostgreSQL database
  described in `data-model.md`.
- **The production ASP.NET Core API** (future, out of scope for this
  feature): implements the identical endpoints against SQL Server.

Because both are reached the same way — `HttpAuthService` calling a
configured base URL — moving to production is a configuration change
(which base URL), not a Repository or UI code change (FR-037).

Every operation below is a **behavioral responsibility**; exact endpoint
request/response payload shapes are an implementation detail for
`/speckit-tasks`, not fixed here.

**Revised for the final device-move-tiering business rule** (`spec.md`
§Device-Move Tiers): `evaluateLogin`'s response now also carries a
`conflict` outcome (checked *before* anything else) and, once any conflict
is resolved, a `tier` value (`second_device` | `third_or_later`) that
governs whether the client is ever expected to call
`checkRebindingAuthorization` at all, and whether that call happens before
or is irrelevant to `requestLoginOtp`. A new `confirmTakeover` operation
is added for the conflict-confirmation step. **Not yet implemented** —
see `tasks.md` Phase 13.

| Operation (`AuthService` method) | Purpose | Spec traceability | REST endpoint (implemented by `prototype_server` now; identical shape in production later) |
|---|---|---|---|
| `requestRegistrationOtp(mobileNumber, deviceId)` | Issue an OTP challenge for a mobile number with no Active device yet. | FR-001, FR-002 | `POST /registration/otp` |
| `verifyRegistrationOtp(mobileNumber, deviceId, code)` | Verify the registration OTP and, only on success, atomically create the account's initial `active` binding for `deviceId` (Device 1 — not a device move). | FR-001–FR-003, FR-043 (atomicity) | `POST /registration/otp/verify` |
| `evaluateLogin(mobileNumber, deviceId)` | Given a mobile number and the current device, determine whether the device is the account's Active device (trusted) or not. For a New/Untrusted device, first reports whether `deviceId` is a **conflict** (Active for a different account); once resolved (no conflict, or `confirmTakeover` called), reports the requesting account's device-move **tier** (`second_device` if it has zero prior `rebinding`-context bindings, else `third_or_later`) — without granting access itself. | FR-011–FR-015 | `POST /login` |
| `confirmTakeover(mobileNumber, deviceId)` | *(New.)* Acknowledge a reported conflict so the flow may proceed to the requesting account's tier-gated path. Writes nothing itself; declining (never calling this) leaves every account's binding state unchanged. | FR-014 | `POST /login/confirm-takeover` |
| `requestLoginOtp(accountId, deviceId)` | Issue a login-context OTP challenge for a New/Untrusted device. Distinct challenge record from any registration OTP (FR-005). At the `second_device` tier, issued unconditionally; at the `third_or_later` tier, the server refuses to issue one unless `checkRebindingAuthorization` has already resolved to `Authorized` for this pair (FR-016, FR-017). | FR-016, FR-017 | `POST /login/otp` |
| `verifyLoginOtp(accountId, deviceId, code)` | Verify the login-context OTP. Verification alone does **not** grant Active status — `completeRebinding` still re-checks the tier's full precondition. | FR-016, FR-018 | `POST /login/otp/verify` |
| `checkRebindingAuthorization(accountId, deviceId)` | Read the current `Pending` / `Authorized` / `Not Authorized` state for this account/device pair, requesting one if none exists yet. **Only ever called by the client at the `third_or_later` tier** — at the `second_device` tier this operation is simply never invoked, and any stray record for that pair is not consulted. | FR-017, FR-022 | `GET /rebinding-authorizations?accountId=&deviceId=` |
| `completeRebinding(accountId, deviceId)` | Callable once the requesting account's tier precondition is satisfied: a verified OTP alone at the `second_device` tier; a verified OTP **and** `Authorized` status at the `third_or_later` tier. Atomically: activates `deviceId` for `accountId`, revokes `accountId`'s previous Active device, and — if `deviceId` was Active for a *different* account — revokes that binding too, regardless of tier. | FR-023, FR-024, FR-025, FR-041, FR-042 | `POST /rebindings` |
| `getDeviceBindingStatus(accountId, deviceId)` | Read-only: is `deviceId` currently `active`, `revoked`, or unrecorded (New/Untrusted) for `accountId`? Used both by `evaluateLogin` internally and by the Repository when restoring a persisted local session (FR-033). | FR-008, FR-033 | `GET /accounts/{accountId}/devices/{deviceId}/status` |

All device-trust evaluation, conflict detection, tier determination, and
rebinding-eligibility decisions are made **inside `prototype_server`'s
handlers**, against PostgreSQL — never by `AuthRepository`. The
Repository's job is limited to calling the right operation and
translating its result into something the ViewModel can render; it holds
no independent copy of the business rules, including the tier and
conflict determinations above (see plan.md "Prototype Business-Rule
Enforcement & Atomicity" and FR-046: client-side state is never the final
authority for authorization or tier/conflict decisions).

Logout (FR-035/FR-036) and Keep-Me-Signed-In persistence (FR-030–FR-034)
are **not** `AuthService` operations — they only ever touch the local
`Session` record (`data-model.md`), never PostgreSQL, so they are handled
entirely by `AuthRepository` + local secure storage. This matches the
spec: "Keep Me Signed In" controls session persistence only, independent
of device-move tiering in both directions, and signing out never calls
into device-binding state.

## Error / outcome shape (behavioral, not literal Dart types)

Every operation that can fail for a business reason (invalid OTP, unknown
mobile number, authorization not yet resolved) returns a well-defined HTTP
response (e.g., a specific status code + body shape) that `HttpAuthService`
turns into a **result value** the ViewModel can render as one of the
Required UI States in `spec.md` — it never throws for an expected business
outcome. Only genuine infrastructure failure (the local server or
PostgreSQL is unreachable) is an exception. Per the spec's transactional
requirements (FR-041–FR-043), any such failure inside `prototype_server`'s
`verifyRegistrationOtp` or `completeRebinding` handler MUST leave
PostgreSQL exactly as it was before the call — enforced structurally by
the partial unique indexes in `data-model.md` plus wrapping each
operation's writes in one database transaction, entirely within
`prototype_server`; the Flutter app never participates in that
transaction and only ever sees its final success/failure outcome. This is
unaffected by which tier gated the call.

## What this contract deliberately does not define

- OTP expiry/retry/lockout behavior (Open Question in `spec.md`).
- Session-expiration duration (Open Question in `spec.md`).
- Any CRM UI or a way for a caller to set `rebinding_authorizations.status`
  itself — `checkRebindingAuthorization` only ever *reads* (and, if
  absent, requests) that state; nothing in this contract lets a partner
  author their own authorization (FR-028).
- A third device-move tier, or any additional free move beyond the
  account's first — `tier` is exhaustively `second_device` |
  `third_or_later`; there is no third value.
