# Feature Specification: Login, Authentication, and Device Binding

**Feature Branch**: `001-login-auth-device-binding`

**Created**: 2026-09-17

**Status**: Draft (Revised — tiered device-move model; reconciled with the implemented code 2026-09-24 — requirements with no implementation are marked "(Not implemented)")

**Input**: User description: "Crown Solar Energy — Login, Authentication and Device Binding" (full detailed requirements provided by user; revised per corrected business rules for registration, login, device states, and rebinding; further revised to the final tiered device-move model confirmed against the Claude Design Login journey and its functional spec)

## Feature Overview

This is the first feature implemented in the Crown Solar Energy Flutter
application. It defines two distinct authentication events — **Registration**
(first-time account setup, which establishes the account's initial trusted
device; a separate journey, out of scope for this feature's implementation
work) and **Login** (every subsequent sign-in) — and how the application
recognizes, trusts, and transfers the single physical device authorized to
access each account ("device binding"). Login itself distinguishes exactly
two device-move tiers after registration: an account's *first* device move
is gated by OTP alone, and every move after that is gated by external
(CRM) authorization as well as OTP — see "Registration vs. Login" and
"Device-Move Tiers" below. For this prototype phase, the authoritative
persistence for accounts, devices, bindings, and related state is a local
PostgreSQL database; a real backend API, real SMS delivery, and the real
CRM authorization system are all explicitly out of scope and are
simulated or represented as state only, so that the same business behavior
can later move to a production backend without redesigning the Flutter UI.

## Goals

- Let a partner register and sign in using only their registered mobile
  number — no password, email, username, or dealer code.
- Require OTP verification during registration, and use a successful
  registration OTP as the authorization for binding the current device as
  the account's initial Active device (**Device 1** — establishing this
  binding is not itself a "device move").
- On every subsequent login, recognize and trust an account's Active device
  without repeating OTP verification.
- Detect any device attempting to use the account that is not the account's
  current Active device, and gate its access according to exactly which
  **device-move tier** applies to that account (its first move after
  registration, gated by OTP alone; or any move after that, gated by
  external authorization as well as OTP) — see "Device-Move Tiers."
- Where the requested device is already Active for a *different* account,
  require an explicit user confirmation (mirroring the Claude Design
  takeover dialog) *before* any OTP is requested for it.
- Guarantee that an account has at most one Active device at any time, and
  that a device has at most one Active account, even when device bindings
  must be transferred or conflict with another account's binding.
- Keep session persistence ("Keep Me Signed In") and device-binding state
  fully independent, so a stale session can never bypass a device
  revocation, and so device-move tiering never influences session
  behavior or vice versa.
- Persist the business-relevant state (accounts, devices, bindings, OTP and
  authorization state, session state, history) in PostgreSQL for this
  prototype, behind an abstraction that lets a real backend API replace it
  later without UI changes.
- Reproduce the approved Crown Solar Energy Claude Design visual and
  interaction language for every screen and state this feature introduces.

## Scope

In scope:

- Mobile-number-only login for accounts that have already registered
  (registration itself — the flow that establishes Device 1 — is a
  separate journey and is explicitly **not** implemented by this feature;
  see "Out of Scope").
- Device recognition: Active, Revoked, and New/Untrusted device states —
  exactly these three, unchanged from prior revisions of this spec.
- Trusted-device login (no OTP) when the current device matches the
  account's Active device.
- New/untrusted-device handling during login, including:
  - An explicit device-conflict confirmation step, shown before any OTP is
    requested, whenever the requested device is currently Active for a
    different account.
  - Determining which of the two **device-move tiers** applies to the
    requesting account (see "Device-Move Tiers") and gating the rest of
    the flow accordingly.
- Device rebinding, including the case where the incoming device is already
  Active for a different account ("device conflict"), atomically
  transferring it regardless of which tier gated the requesting account's
  path to that point.
- "Keep Me Signed In" session persistence, independent of device binding
  and of device-move tiering.
- Explicit sign-out ("logout") that ends the session without changing
  device binding.
- A logical PostgreSQL data model sufficient to demonstrate all of the above
  business rules, with the integrity guarantee that an account has at most
  one Active device at a time and a device has at most one Active account.
- Repository/service-level abstraction boundaries that isolate the UI and
  application layer from the PostgreSQL-backed prototype implementation.

Out of scope: see [Out of Scope](#out-of-scope) below.

## Actors & User Types

All Crown Solar Energy business-partner user types share identical
authentication and device-binding rules, including identical device-move
tiering. There is no per-user-type variation in this feature's logic:

- **Installer**
- **Retailer**
- **Wholesaler**
- **Distributor**

User type may influence dashboards, permissions, or other modules in future
features, but this feature does not implement or special-case any of that;
it only needs to demonstrate that login and device binding behave
identically regardless of user type.

## Registration vs. Login

Registration and Login remain two distinct authentication events, and
registration is **not implemented by this feature** (see "Out of Scope") —
it is documented here only to the extent needed to define where the
device-move count starts from.

**Registration** (separate journey, out of scope for this feature's
implementation) establishes **Device 1**: mobile number entry, a
registration OTP, and — solely as a consequence of that OTP verification
succeeding — the current device becomes the account's initial Active
device. Establishing Device 1 this way is **not** counted as a device
move; an account that has only ever had Device 1 has made **zero** device
moves.

**Normal login** happens on every subsequent app open, once an account
already has an Active device (Device 1, or whatever device it has since
moved to). It consists of entering the registered mobile number and
choosing "Keep Me Signed In," after which the system identifies the
current device and evaluates it against the account's Active device:

- If the current device **matches** the account's Active device, it is
  trusted and login proceeds without any OTP step.
- If the current device **does not match**, it is New/Untrusted, and the
  system determines — before requesting any OTP — whether the device is
  already Active for a different account (see "Device Conflict
  Confirmation") and which **device-move tier** applies to the requesting
  account (see "Device-Move Tiers"), then gates the rest of the flow
  accordingly.

At no point does entering the mobile number alone bypass whichever gate
the applicable tier requires. No password, username, email, dealer code,
or other additional authentication factor is introduced at either stage.

**Account with no Active device at login** (as implemented): an account
that has never had a Device 1 binding — e.g. the seeded demo accounts, or
an account opened by the separate registration wizard, neither of which
creates an `initial_registration` binding — is treated like any other
New/Untrusted login at the second-device tier. Its first OTP-verified
sign-in is recorded as a `rebinding`-context binding, so it counts as the
account's one OTP-only move (see FR-049).

## Device-Move Tiers

This is the final, authoritative device-move model for this feature —
confirmed against the Claude Design Login journey (screens A1–A4, B1–B2)
and its functional specification. It replaces any prior draft of this
spec that treated every device change identically.

An account's **device-move count** is the number of device moves it has
completed since Device 1 was established at registration. A "move" is a
completed transfer of the account's Active binding from one device to
another (each such transfer persists as one binding row with
`context = 'rebinding'`; establishing Device 1 at registration does not
count, per "Registration vs. Login"). This count is derived from the
account's existing binding history — it is not a new piece of state the
system must separately track (see `data-model.md` for the exact
derivation).

- **Second-device tier** (move count = 0): the account has never moved
  off its registration device. Moving to a new device at this tier
  requires **only** a successfully verified login-context OTP. No
  external (CRM) authorization is consulted at all.
- **Third-or-later-device tier** (move count ≥ 1): the account has
  already completed at least one device move. Moving to a new device at
  this tier requires an external (CRM) rebinding-authorization outcome of
  **Authorized** *before* any login-context OTP is requested; only once
  that is Authorized does the login-context OTP requirement apply, with
  identical mechanics to the second-device tier.

Do **not** describe this as "one free move including registration" —
registration's Device 1 is not a move at all; the free, OTP-only move is
specifically the account's *first* move (to what a human reading the
Claude Design calls "Device 2"). Every move after that (to "Device 3" and
beyond) requires external authorization, with no further free moves at
any point. The tier boundary is exactly this one-move/one-time threshold
— there is no third tier and no additional free-move allowance beyond it.

The tier applies to the **requesting account's own move history**,
independent of the target device's history — including independent of
whether the target device happens to be involved in a device conflict
(see below).

## Device Conflict Confirmation

Whenever a New/Untrusted device is detected during login, the system
first determines whether that device is currently Active for a
**different** account (a device conflict) — before requesting any OTP,
and before evaluating the requesting account's device-move tier.

- If there is **no** conflict (the device is unrecognized, or was
  previously Revoked and belongs to no one currently), the flow proceeds
  directly to the requesting account's tier-gated flow.
- If there **is** a conflict, the system MUST present an explicit
  confirmation step to the user — mirroring the Claude Design's takeover
  dialog (Claude Design screen A4) — stating that this phone is signed in
  to another account and that continuing will sign that account out of
  this phone. *(Naming both accounts affected — the design's before/after
  layout — is **Not implemented**: the server reports only the other
  account's opaque id, and the dialog shows generic copy.)* Only after the
  user explicitly confirms does the flow proceed to
  the requesting account's tier-gated flow (second-device tier or
  third-or-later-device tier, exactly as above). Declining leaves every
  account's binding state completely unchanged.

As implemented, the server *detects* the conflict, but the confirmation
itself is enforced by the Flutter client only: `POST /login/confirm-takeover`
records nothing, and the rebinding operation does not require it to have
been called (see Open Questions).

A device conflict can occur at either device-move tier — the confirmation
step is about the *device's* current ownership, not about which tier
gates the *requesting account's* own move.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Register and establish the initial trusted device (Priority: P1)

**Out of scope for this feature's implementation** — registration is a
separate journey (see "Out of Scope"). This story is retained here only so
later stories can refer to "an account that already has Device 1 Active"
as their starting precondition. *(As built: a minimal registration path
from an earlier revision still exists — `POST /registration/otp` and
`POST /registration/otp/verify`, `RegistrationViewModel`, and
`RegistrationScreen` at the `/register/legacy` route. The app's live
`/register` route is the separate registration wizard, which does not
create a device binding.)*

**Acceptance Scenarios**:

1. **Given** an account with no Active device, **When** registration (out
   of scope) completes successfully, **Then** the account has exactly one
   Active device (Device 1) and a device-move count of zero. *(Acceptance
   Scenarios A–D, unchanged from the prior revision — registration itself
   is not re-implemented or re-tested by this feature.)*

---

### User Story 2 - Sign in from the trusted device (Priority: P1)

A partner whose account already has an Active device opens the app on that
same device and enters their registered mobile number. Because the current
device matches the account's Active device, they are authenticated
immediately, with no OTP step, regardless of the account's device-move
count.

**Why this priority**: This is the everyday sign-in path for every partner;
it must work reliably and without friction on every visit, at any tier.

**Independent Test**: Can be fully tested by signing in on the account's
already-bound device and confirming authentication succeeds without any OTP
prompt appearing.

**Acceptance Scenarios**:

1. **Given** an account whose Active device is Device A, **When** the
   partner signs in from Device A with the correct registered mobile
   number, **Then** authentication succeeds without an OTP step.
   *(Acceptance Scenario E)*
2. **Given** an account whose Active device is Device A, **When** the
   partner repeats sign-in from Device A on separate occasions, **Then**
   every attempt succeeds the same way, without OTP.

---

### User Story 3 - New device is detected, conflict is checked, and the applicable tier gate begins (Priority: P1)

A partner's registered mobile number is entered, during login, on a device
that is not the account's current Active device. The app must not treat
the mobile number alone as sufficient. It first checks whether the device
is currently Active for a different account (see "Device Conflict
Confirmation") and, once that is resolved (no conflict, or the user has
confirmed a takeover), determines which device-move tier applies to the
requesting account before requesting any OTP.

**Why this priority**: This is the core protection the feature exists to
provide — without it, mobile-number-only login would let anyone with a
partner's phone number take over their account from any device, and
without the conflict-confirmation gate a partner could unknowingly
displace someone else's account without ever being told.

**Independent Test**: Can be fully tested by signing in with a valid
account's mobile number from a device that is not its Active device, and
confirming: (a) if that device is Active for another account, a
confirmation step appears before anything else; (b) once past that (or if
there was nothing to confirm), the flow proceeds according to the
requesting account's tier without ever granting access on the mobile
number alone.

**Acceptance Scenarios**:

1. **Given** an account whose Active device is Device A, **When** the same
   mobile number is submitted from Device B during login, **Then** Device B
   is classified New/Untrusted and does not receive authenticated access on
   the strength of the mobile number alone. *(Acceptance Scenario F)*
2. **Given** Device B is currently Active for a *different* account,
   **When** the requesting account's mobile number is submitted from
   Device B, **Then** a confirmation step stating that the phone is
   signed in to another account is shown *before* any OTP is requested,
   and no binding changes until the user explicitly confirms. *(Acceptance
   Scenario Q. Naming both accounts in that step is Not implemented — see
   "Device Conflict Confirmation".)*
3. **Given** that confirmation step, **When** the user declines/cancels,
   **Then** no account's binding state changes at all, and Device B
   remains exactly as it was.
4. **Given** Device B is not Active for any other account (or the
   confirmation in Scenario Q has just been accepted), **When** the flow
   proceeds, **Then** the system determines the requesting account's
   device-move tier (zero prior moves vs. one or more) before requesting
   any OTP — this determination is never made or trusted client-side.

---

### User Story 4 - Second-device tier: the account's first move is gated by OTP alone (Priority: P2)

An account that has never moved off its registration device (device-move
count = 0) attempts to log in from a new device. Only a login-context OTP
is required — no external authorization is consulted at all.

**Why this priority**: This is the Claude Design's "A2" flow and the
functional spec's explicit rule that the first device move needs no CRM
involvement; it must work exactly this simply, with nothing else gating
it.

**Independent Test**: Can be fully tested by taking an account that has
never moved (device-move count 0), attempting login from a new device,
verifying the login-context OTP, and confirming the move completes with no
authorization check ever occurring.

**Acceptance Scenarios**:

1. **Given** an account with a device-move count of zero, **When** it
   attempts login from a New/Untrusted device (no conflict, or a conflict
   just confirmed), **Then** the system requests a login-context OTP and
   requires nothing else. *(Acceptance Scenario R, first half)*
2. **Given** that OTP is successfully verified, **When** the operation
   completes, **Then** the new device becomes Active, the account's
   previous Active device becomes Revoked, atomically, and no
   rebinding-authorization record needed to exist or be consulted for this
   to happen. *(Acceptance Scenario R, second half)*
3. **Given** an incorrect OTP at this tier, **When** it is submitted,
   **Then** verification fails, no device state changes, and the partner
   may retry — still with no authorization step involved.

---

### User Story 5 - Third-or-later-device tier: every subsequent move is gated by authorization and OTP (Priority: P2)

An account that has already completed at least one device move
(device-move count ≥ 1) attempts to log in from another new device. This
move requires an external (CRM) rebinding-authorization outcome of
Authorized *before* any OTP is requested; if that outcome is Pending or
Not Authorized, no OTP is ever requested for this attempt.

**Why this priority**: This is what makes the "one free move" rule actually
mean something — without it, an account could move indefinitely without
ever involving CRM.

**Independent Test**: Can be fully tested by taking an account with a
device-move count of one or more, attempting login from a new device, and
confirming: with authorization Pending/Not Authorized, no OTP is ever
requested and the existing Active device is unaffected; with authorization
Authorized, an OTP is requested and, once verified, the move completes
atomically.

**Acceptance Scenarios**:

1. **Given** an account with a device-move count of one or more, **When**
   it attempts login from a New/Untrusted device (no conflict, or a
   conflict just confirmed), **Then** the system checks the
   rebinding-authorization outcome for that account/device pair *before*
   requesting any OTP.
2. **Given** that outcome is **Pending** or **Not Authorized**, **When**
   the check occurs, **Then** no OTP is requested, the device remains
   New/Untrusted, and the account's existing Active device is completely
   unaffected. Both outcomes show the same "account is fixed to another
   phone" refusal screen (Claude Design B1), whose "Try Again" action
   re-runs the whole login evaluation. *(Acceptance Scenario G)*
3. **Given** that outcome is **Authorized**, **When** the check occurs,
   **Then** the system requests a login-context OTP; **When** that OTP is
   successfully verified, **Then** the new device becomes Active and the
   account's previous Active device becomes Revoked, atomically.
   *(Acceptance Scenario H)*
4. **Given** a device-move operation (either tier) is in progress, **When**
   any required step fails partway through, **Then** the account/device
   relationships are left exactly as they were before the operation
   started — never with two devices simultaneously Active for the same
   account. *(Acceptance Scenario I, atomicity)*

---

### User Story 6 - Device conflict: transferring a device that is Active for another account (Priority: P2)

Once a device conflict has been confirmed (User Story 3) and the
requesting account's applicable tier gate has been satisfied (User Story
4 or 5), the device is transferred atomically: the requesting account's
new device becomes Active, its previous device becomes Revoked, and the
other account's binding to that device becomes Revoked — never leaving
the device Active for two accounts, even momentarily.

**Why this priority**: Device reassignment across partners (e.g., a device
handed from one field team to another) is a real operational scenario that
device binding must support correctly, and it must compose correctly with
whichever tier gate applied — a conflict does not change or bypass the
tier logic in User Stories 4/5, it only adds the confirmation step and the
extra revocation.

**Independent Test**: Can be fully tested by taking Account A (Active
device: Device A) and Account B (Active device: Device B), having Account A
confirm the takeover (User Story 3), satisfy whichever tier gate applies to
Account A (User Story 4 or 5), and confirming Device B becomes Active for
Account A, Device A becomes Revoked, and Account B's binding to Device B
becomes Revoked — all in one atomic update.

**Acceptance Scenarios**:

1. **Given** Device B is currently Active for Account B, **When** Account A
   completes the confirmation (User Story 3) and satisfies its own
   applicable tier gate (User Story 4 or 5) for Device B, **Then** the
   transfer completes as one atomic operation: Device B becomes Active for
   Account A, Account A's previous Active device becomes Revoked, and
   Account B's binding to Device B becomes Revoked — Device B is no longer
   Active for Account B. *(Acceptance Scenario J)*
2. **Given** this conflict-resolution logic, **When** exercised between any
   two of the four supported user types in any combination, **Then** it
   behaves identically, with no special-casing for any particular pair of
   user types, and with the tier gate applied strictly per Account A's own
   move history, never Account B's. *(Acceptance Scenario K)*
3. **Given** a device-conflict transfer, **When** it is applied, **Then**
   the database is never left, even temporarily, with the transferred
   device Active for more than one account at once.

---

### User Story 7 - A previously revoked device cannot bypass revocation (Priority: P2)

A device that was Revoked by a prior move attempts to authenticate again
using the account's registered mobile number. It must be treated as
New/Untrusted, not as trusted, regardless of its prior Active history —
and, if the account tries to move back to it, that attempt is itself
gated by whichever tier now applies to the account (its move count only
ever increases).

**Why this priority**: Without this, revocation would be meaningless — a
displaced device could simply sign in again and reclaim trust, or an
account could cycle between two devices forever without ever reaching the
third-or-later tier.

**Independent Test**: Can be fully tested by revoking a device (via a
prior move), then attempting to sign in again from that revoked device
with the account's mobile number, and confirming it is classified
New/Untrusted and subject to the account's *current* tier — not the tier
that applied when it was first bound.

**Acceptance Scenarios**:

1. **Given** a device that is currently Revoked for an account, **When** it
   attempts to sign in again using that account's registered mobile
   number, **Then** it is classified New/Untrusted, not trusted, and its
   reactivation is gated by whichever device-move tier currently applies
   to the account (never automatically reactivated, and never re-evaluated
   against a stale/lower tier). *(Acceptance Scenario L)*

---

### User Story 8 - Session persists safely across app restarts (Priority: P2)

A partner enables "Keep Me Signed In" during sign-in. Reopening the app
restores their session without requiring sign-in again, as long as the
session is valid and their device's binding has not since been revoked.
This is completely independent of device-move tiering — the tier that
gated how a device became Active has no bearing on whether a session on
that device can later be restored, and vice versa.

**Why this priority**: Session convenience matters for daily use, but the
app is already secure and functional without it; its most important
property — never let a stale session bypass revocation — is a direct
consequence of Stories 5–7, not of any tier-specific logic.

**Independent Test**: Can be fully tested by signing in with "Keep Me Signed
In" on, restarting the app, and confirming the session restores; separately,
by signing in with it off and confirming the app returns to sign-in on
restart; and by revoking a device that held a persisted session (via
either tier's move) and confirming that session can no longer reach
authenticated content.

**Acceptance Scenarios**:

1. **Given** a partner signed in with "Keep Me Signed In" enabled, **When**
   the app is restarted while the session is still valid, **Then** the
   session is restored without requiring sign-in again. *(Acceptance
   Scenario M)*
2. **Given** a partner signed in with "Keep Me Signed In" disabled, **When**
   the app is restarted, **Then** the session is not automatically restored
   and the partner must sign in again. *(Acceptance Scenario N)*
3. **Given** a device with a persisted session that was later Revoked (via
   a move at either tier), **When** the app on the revoked device attempts
   to restore that session, **Then** access is denied and the
   device-binding state (Revoked) governs the outcome, not the stale
   session. *(Acceptance Scenario O. **Not implemented on the live
   `/login` → `/home` path**, which restores the saved partner record
   without asking the server; implemented only on the `/login/legacy`
   route via `AuthRepository.restoreSession` — see FR-033.)*

---

### User Story 9 - Sign out without losing the device's trust (Priority: P3)

A partner explicitly signs out. Their local session ends, but their
device's binding is untouched — signing back in on the same device does not
require going through OTP or any tier gate again, and does not change the
account's device-move count.

**Why this priority**: Useful for account hygiene and shared work devices,
but the app remains fully secure and functional without an explicit
sign-out action, since sessions already have their own lifecycle.

**Independent Test**: Can be fully tested by signing in, invoking sign-out,
confirming the session ends, and then confirming the same device can sign
in again as a trusted device without any OTP step.

**Acceptance Scenarios**:

1. **Given** an authenticated session, **When** the partner signs out,
   **Then** the local session ends and the device binding is left
   unchanged. *(Acceptance Scenario P)*
2. **Given** a partner who just signed out, **When** they sign in again from
   the same device, **Then** they are treated as the account's trusted
   device (per Story 2) with no OTP required — sign-out never revokes or
   unbinds the device, and never changes the account's device-move count.

---

### Edge Cases

- **Invalid mobile number format**: *(Not implemented as a separate
  check.)* The sign-in field accepts digits only, up to 10, with a fixed
  `+92` prefix, but nothing validates the number before submission; an
  empty, short, or otherwise malformed number is sent to the server and
  fails as "no account uses this number." No device-binding state
  changes.
- **Mobile number not associated with any account, submitted at login**:
  authentication fails ("No Crown Solar account uses this number.
  Register instead.") and no device-binding state is changed.
- **Account with no Active device at all** (never registered through
  Device 1): treated as New/Untrusted at the second-device tier; its first
  OTP-verified sign-in becomes its one OTP-only move (FR-049).
- **Account with an Active device, same device signs in**: handled by User
  Story 2 (trusted-device login).
- **Account with an Active device, a different device signs in, no
  conflict**: handled by User Story 3 → 4 or 5, depending on tier.
- **Device already Active for a different account (device conflict)**:
  handled by User Story 3's confirmation step, then User Story 6's atomic
  transfer — at whichever tier applies to the requesting account.
- **User declines the device-conflict confirmation**: no state changes at
  all; the requesting account's login attempt simply does not proceed.
- **Invalid login-context OTP submitted, at either tier**: verification
  fails; the device stays New/Untrusted; no binding or authorization state
  changes.
- **OTP lifecycle behavior when verification is attempted after the OTP's
  validity period has elapsed** (either tier) is an Open Question; see
  [Open Questions](#open-questions--business-rules-required). No expiry
  duration or expiration policy is defined by this specification, and
  none is enforced.
- **Resend**: requesting the code again issues a new challenge; only the
  most recent unverified challenge is checked, so an earlier code stops
  working (FR-050). The live A2 screen allows resend only after a
  30-second client-side countdown; the server enforces no cooldown.
- **No open challenge to verify** (e.g. it was already verified): the
  server returns "challenge not found"; the live screen words this as
  "That code has expired. Ask for a new one." although no expiry exists.
- **Device move committed, but the partner's profile then fails to load**:
  the binding change already stands; the sign-in screen shows "Signed in
  on this phone, but your profile could not be loaded," and signing in
  again succeeds as a trusted device.
- **Rebinding authorization state is Pending, at the third-or-later
  tier** (a decision has not yet been made by the external/CRM system): no
  OTP is requested; the requesting device remains New/Untrusted and the
  existing Active device is unaffected until the state resolves to
  Authorized or Not Authorized.
- **Rebinding authorization is Not Authorized, at the third-or-later
  tier**: handled by User Story 5.
- **Rebinding authorization is Authorized, at the third-or-later tier**:
  handled by User Story 5 (and User Story 6 for the conflict case).
- **An account at the second-device tier somehow has a stray
  rebinding-authorization record** (e.g., left over from a prior,
  unrelated conflict-confirmation check that was never completed): it MUST
  NOT be consulted — the second-device tier never checks authorization at
  all, regardless of what such a record contains.
- **A Revoked device attempts to sign in again**: handled by User Story 7;
  cannot bypass revocation, and is re-gated by the account's *current*
  tier, not the tier that applied when that device was originally bound.
- **A persisted "Keep Me Signed In" session exists on a device that has
  since been Revoked**: handled by User Story 8; the session must not grant
  access, regardless of which tier caused the revocation. *(Not
  implemented on the live `/login` path — see FR-033.)*
- **Session restoration fails** (session is invalid, expired, or its
  device is no longer Active): the partner is returned to the sign-in
  screen. As built, an unreadable saved record is discarded and the
  partner sees sign-in; the Claude Design B3 "session ended" notice exists
  only in the design preview and is not shown by the live flow.
- **An Authorized decision, or a verified login OTP, left over from an
  earlier attempt for the same account/device pair**: neither is consumed
  by a completed move, so both still count on a later attempt for that
  same pair (see Open Questions).
- **Sign-out**: handled by User Story 9; never changes device-binding
  state or the account's device-move count.
- **Persistence/transaction failure during a move at either tier**: the
  operation must not leave the system in a partially updated state (e.g.,
  new device Active while old device is also still Active, or a
  transferred device Active for two accounts at once); the pre-operation
  state is preserved until the whole operation can complete.
- **Duplicate concurrent attempts to make two different devices Active for
  the same account**: the one-Active-device-per-account rule must still
  hold after both attempts are resolved; only one can end up Active.

## Requirements *(mandatory)*

### Functional Requirements

**Registration** *(out of scope for this feature's implementation — retained for traceability only; see "Out of Scope". FR-001–FR-003 and FR-043 are implemented only by the legacy `/register/legacy` path and its two `/registration/otp` routes.)*

- **FR-001**: The system MUST provide a registration flow, used when an
  account has no Active device, consisting of: registered mobile-number
  entry, OTP verification, and — only upon successful OTP verification —
  binding of the current device as the account's Active device (Device 1).
- **FR-002**: The system MUST NOT bind any device as Active during
  registration unless the registration OTP has been successfully verified.
- **FR-003**: The system MUST NOT require any OTP step beyond the
  registration OTP itself in order to complete the initial device binding;
  successful registration OTP verification is sufficient authorization for
  that binding.
- **FR-004**: Registration MUST work identically for Installer, Retailer,
  Wholesaler, and Distributor accounts, with no user-type-specific logic.
- **FR-005**: The system MUST treat the registration OTP and any
  login-context OTP (used later for a New/Untrusted device, per FR-016/
  FR-018) as distinct authentication events, even though both use the same
  mobile-number-based delivery concept. Establishing Device 1 via the
  registration OTP is never counted as a device move (see "Device-Move
  Tiers").

**Login**

- **FR-006**: The sign-in form MUST collect only two things: the partner's
  registered mobile number, and a "Keep Me Signed In" choice. No password,
  email, username, dealer code, or other credential field is presented or
  required. As built, the live sign-in screen (A1) takes the ten national
  digits after a fixed `+92` prefix, has "Keep Me Signed In" checked by
  default, and offers a "Register" link to the registration wizard.
- **FR-007**: The registered mobile number MUST be the sole account
  identifier used to initiate login for all four user types.

**Device Recognition & States**

- **FR-008**: The system MUST recognize exactly three device-binding
  states for a given account/device relationship: **Active** (currently
  authorized and bound), **Revoked** (previously bound, no longer
  authorized), and **New/Untrusted** (attempting authentication, not the
  account's current Active device). No other device state is recognized;
  rebinding-authorization outcomes (Pending/Authorized/Not Authorized) are
  tracked separately (see FR-022) and are never a device state.
- **FR-009**: The system MUST allow an account to have at most one Active
  device, and a device to have at most one Active account, at any point in
  time — at every device-move tier.
- **FR-010**: Device-binding state and authenticated-session state MUST be
  tracked independently of one another (see Session Behavior), and both
  MUST be tracked independently of the account's device-move tier.

**Trusted-Device Login**

- **FR-011**: When the current device matches the account's Active device,
  the system MUST authenticate the partner without requiring any OTP step,
  regardless of the account's device-move count.

**New/Untrusted-Device Login & Device-Move Tiering**

- **FR-012**: When the current device does not match the account's Active
  device during login, the system MUST classify it as New/Untrusted and
  MUST NOT grant authenticated access based on the mobile number alone.
- **FR-013**: For a New/Untrusted device, the system MUST determine,
  before requesting any OTP, whether that device is currently Active for a
  *different* account (a device conflict).
- **FR-014**: Where a device conflict exists, the system MUST require an
  explicit user confirmation of the takeover before any OTP is requested
  for that device; declining MUST leave every account's binding state
  unchanged. This confirmation is independent of, and always precedes,
  acting on the device-move tier in FR-015. *(Naming both accounts
  affected is **Not implemented** — the conflict outcome carries only the
  other account's id. The confirmation is enforced by the client only; the
  server's confirm step writes nothing and the rebinding operation does
  not check for it.)*
- **FR-015**: For a New/Untrusted device with no conflict, or immediately
  after a conflict has been confirmed per FR-014, the system MUST
  determine the requesting account's device-move tier: **second-device
  tier** if the account's device-move count (per "Device-Move Tiers") is
  zero, or **third-or-later-device tier** if it is one or more. This
  determination MUST be made server-side and MUST NOT be computed or
  trusted client-side (see FR-046). As built, the server returns the
  conflict and the tier together in one login response; the client acts
  on the conflict first. The server re-derives the tier itself when an OTP
  is requested and when the move is completed.
- **FR-016**: At the **second-device tier**, the system MUST require only
  a successfully verified login-context OTP (simulated in this prototype,
  distinct from any registration OTP) before the device may become
  Active; the system MUST NOT consult or require any
  rebinding-authorization outcome at this tier.
- **FR-017**: At the **third-or-later-device tier**, the system MUST
  require a rebinding-authorization outcome of **Authorized** *before*
  requesting any login-context OTP for that device. Where the outcome is
  **Pending** or **Not Authorized**, the system MUST NOT request an OTP,
  MUST leave the device New/Untrusted, and MUST leave the account's
  existing Active device unaffected. The server enforces this itself: an
  OTP request at this tier is refused as not authorized (creating a
  Pending record if none exists) unless the latest record for the pair is
  Authorized.
- **FR-018**: At the **third-or-later-device tier**, once the
  rebinding-authorization outcome is Authorized per FR-017, the system
  MUST then require a successfully verified login-context OTP — identical
  mechanics to FR-016 — before the device may become Active.
- **FR-019**: The device identifier alone MUST NOT be treated as an
  authentication factor at any point in the registration or login flow, at
  either device-move tier.

**OTP Behavior (Prototype Simulation)**

- **FR-020**: The system MUST support requesting an OTP challenge and
  verifying a submitted OTP — for both the registration context and the
  login (New/Untrusted-device) context, at either device-move tier —
  simulating the challenge instead of sending a real SMS.
- **FR-021**: The system MUST persist each OTP challenge with its context
  (registration or login) and whether it has been successfully verified;
  a failed attempt is represented only by the challenge staying
  unverified — no separate failed-attempt record is kept. The server MUST
  NOT enforce any specific OTP expiry duration, attempt limit, or cooldown
  period that is not explicitly defined by the business; see
  [Open Questions](#open-questions--business-rules-required) for the
  OTP-expiry gap. *(The live A2 screen does apply a 30-second client-side
  resend countdown — see Open Questions.)*

**Device Rebinding & Conflicts**

- **FR-022**: Rebinding-authorization state MUST be tracked separately
  from device-binding state, with at least three possible values:
  **Pending**, **Authorized**, **Not Authorized**. Per FR-016, it MUST
  never be consulted at the second-device tier, regardless of whether a
  stray record happens to exist for that account/device pair. As built, a
  record is created as Pending the first time the pair is checked, and the
  most recent record for the pair is the one that applies.
- **FR-023**: Once all gates required by the applicable tier are satisfied
  (FR-016 alone, or FR-017 followed by FR-018), the system MUST, as a
  single atomic operation: activate the new device for the requesting
  account, and revoke the requesting account's previous Active device.
- **FR-024**: Where the device being activated was already Active for a
  *different* account (a device conflict, per FR-013/FR-014), the same
  atomic operation described in FR-023 MUST also update that other
  account's binding so the device is no longer Active for it (Revoked) —
  regardless of which tier gated the requesting account's path to this
  point.
- **FR-025**: This rebinding, tiering, and conflict-resolution logic MUST
  apply identically regardless of which user types are involved, in any
  combination; the system MUST NOT special-case any particular user type,
  pair of user types, or tier boundary beyond the single second/
  third-or-later distinction defined in "Device-Move Tiers."
- **FR-026**: A Revoked device MUST NOT be able to regain Active status
  automatically; it MUST go through the same New/Untrusted flow (conflict
  confirmation if applicable, then whichever tier currently applies to the
  account) as any other unrecognized device if it attempts to sign in
  again. The tier applied MUST always be the account's *current* tier, not
  the tier that applied when that device was previously bound.

**CRM Authorization Boundary**

- **FR-027**: Rebinding-authorization state (Pending / Authorized / Not
  Authorized) MUST be represented as data originating conceptually from an
  external/CRM system.
- **FR-028**: The application MUST NOT provide any in-app screen, control,
  or flow that lets a partner set or change their own rebinding-
  authorization state (no fake CRM approval UI, no self-authorization).
- **FR-029**: The application MUST NOT implement CRM screens, CRM
  administrator screens, CRM approval UI, CRM user management, or CRM
  roles; CRM authorization is out of scope for this Flutter feature and is
  only represented as state.

**Session Behavior**

- **FR-030**: "Keep Me Signed In" MUST control session persistence only;
  it MUST NOT influence device-binding state, the device-recognition
  rules above, or the account's device-move tier — and none of those MUST
  influence it in return.
- **FR-031**: When "Keep Me Signed In" is enabled, the system MUST persist
  session state and restore it after an app restart while the session
  remains valid. As built, two records are written: the signed-in
  partner's profile (live path, via the app's preferences store), and a
  `Session` record of account id + device identifier (secure storage).
- **FR-032**: When "Keep Me Signed In" is disabled, the system MUST NOT
  automatically restore the session after an app restart; the partner must
  sign in again. (Signing in with it disabled also clears any previously
  saved partner record.)
- **FR-033**: When restoring a persisted session, the system MUST validate
  the current device's binding state; a persisted session on a device that
  is no longer that account's Active device (e.g., because it was Revoked
  by a move at either tier) MUST NOT be allowed to reach authenticated
  content. *(**Not implemented on the live `/login` → `/home` path**: it
  restores the saved partner record without contacting the server.
  Implemented only on the `/login/legacy` route, where
  `AuthRepository.restoreSession` checks the device's binding status and
  clears the local `Session` record unless it is Active.)*
- **FR-034**: The system MUST NOT enforce any specific session-expiration
  duration that is not explicitly defined by the business; see
  [Open Questions](#open-questions--business-rules-required).

**Logout**

- **FR-035**: Signing out MUST end the local authenticated session and
  clear the associated session state. As built, the live sign-out (Profile
  → Sign out, after a confirmation) clears the saved partner record; it
  does not clear the secure-storage `Session` record, which only the
  legacy logout clears.
- **FR-036**: Signing out MUST NOT revoke or unbind the device, and MUST
  NOT change the account's device-move count; the account's device-binding
  state MUST remain exactly as it was before sign-out.

**Architecture & Persistence Boundary**

- **FR-037**: The UI and application/state layer MUST interact with
  registration, authentication, device, OTP, rebinding-authorization, and
  session data only through a repository/service-level abstraction; the UI
  MUST NOT communicate directly with the underlying persistence mechanism.
- **FR-038**: The Flutter application MUST NOT connect directly to
  PostgreSQL. A local prototype service/data-source layer MUST sit behind
  the repository/service abstraction and provide the same
  application-facing operations (e.g., authenticate, register, get active
  device, request/verify OTP, check rebinding authorization, bind/rebind
  device, restore session, logout) that the future REST API will provide.
- **FR-039**: For this prototype, the authoritative account, device,
  binding, OTP, and rebinding-authorization state MUST be persisted in a
  local PostgreSQL database, not in memory-only state, hardcoded state,
  JSON files, SQLite, Hive, or SharedPreferences. Session-specific local
  information may use appropriate Flutter local storage where suitable.
- **FR-040**: The repository/service abstraction MUST be defined so that
  replacing the local prototype service/data-source layer with a real REST
  API later does not require redesigning the UI or the application/state
  layer.
- **FR-041**: The system MUST guarantee, at the data-integrity level, that
  an account never has more than one Active device, and a device never has
  more than one Active account, at any time — including during and
  immediately after a move at either tier.
- **FR-042**: A device-move operation that changes multiple related
  records (revoking the old device, activating the new one, resolving a
  conflicting binding) MUST be applied as a single atomic operation,
  regardless of which tier gated it; if any required step cannot complete,
  none of the changes in that operation are persisted.
- **FR-043**: If registration OTP verification succeeds but persistence of
  the account's initial device binding fails, the registration operation
  MUST NOT leave a partially completed state — see FR-001–FR-003 (retained
  for traceability; registration itself is out of scope for this feature).

**Security**

- **FR-044**: The device identifier MUST NOT be treated as a sole
  authentication factor under any flow, at either device-move tier.
- **FR-045**: The registered mobile number alone MUST NOT be sufficient to
  authenticate a New/Untrusted device, at either device-move tier.
- **FR-046**: Client-side (Flutter-side) state MUST NOT be treated as the
  final authority for authorization decisions, device-conflict detection,
  or device-move-tier determination; the rebinding-authorization outcome
  is conceptually owned by an external/backend system, and the tier/
  conflict determination is conceptually owned by the same server-side
  logic that enforces device binding, even though this prototype
  represents that state locally.
- **FR-047**: Sensitive authentication and session information MUST NOT be
  stored insecurely on the device; where production-equivalent tokens or
  credentials are involved, secure storage mechanisms MUST be used. As
  built, the device identifier and the `Session` record use secure
  storage; the live path's saved partner profile (no token or credential)
  uses the plain preferences store. No tokens exist in this prototype.
- **FR-048**: This prototype's use of a local PostgreSQL database MUST be
  documented and treated as a prototype-only implementation detail, not as
  the intended production security boundary; the production security
  boundary is the future backend API.

**Implemented behavior not covered above** *(added 2026-09-24 from the
code)*

- **FR-049**: An account with no Active device at all MUST be treated as
  New/Untrusted on login, at the second-device tier; once its login OTP is
  verified, the resulting binding is recorded as a `rebinding`-context
  move, so the account's next device change is at the third-or-later
  tier.
- **FR-050**: Requesting a login OTP again ("Resend") MUST issue a new
  challenge; verification checks only the account/device pair's most
  recent unverified challenge, so earlier codes no longer verify.
- **FR-051**: Once the device policy is satisfied (trusted device, or a
  completed move), the app MUST load the partner's profile by mobile
  number before showing authenticated content. If that load fails, the
  partner stays on sign-in with an error; any binding change already
  committed stands.
- **FR-052**: Because no SMS is sent in this prototype, the server MUST
  return the generated 6-digit code with each OTP challenge, and the OTP
  screen shows it labelled as a prototype-only aid.

### Key Entities *(include if feature involves data)*

- **Account**: A Crown Solar Energy partner account. Represents one of the
  four user types (Installer, Retailer, Wholesaler, Distributor), its
  registered mobile number, its status, and — conceptually — which device is
  currently its Active device.
- **Device**: A physical application installation attempting or holding
  authentication. Represents an identifiable device the system can compare
  against an account's current binding.
- **AccountDeviceBinding**: The relationship between one Account and one
  Device at a point in time, carrying a state of Active or Revoked, plus
  enough history (when created, when revoked, why, and whether it was the
  registration binding or a later move) to demonstrate the registration,
  rebinding, and conflict-resolution flows. **An account's device-move
  count (see "Device-Move Tiers") is derived by counting this account's
  own `rebinding`-context rows — it is not a separate stored value.**
- **OTP Challenge**: A simulated one-time verification challenge tied to an
  account and, where applicable, the device attempting authentication, with
  a **context** (Registration or New/Untrusted-Device Login), a
  verification outcome (successful or failed), and the timestamps needed
  to reason about its lifecycle.
- **RebindingAuthorization**: The externally sourced (CRM-conceptual)
  authorization decision for a specific account/device rebinding attempt
  **at the third-or-later-device tier only**, with a state of Pending,
  Authorized, or Not Authorized, and the timestamps needed to reason about
  when it was requested and resolved. This is not a device state; it is
  tracked independently of AccountDeviceBinding, and it is never consulted
  for a second-device-tier move.
- **Session**: The prototype's representation of an authenticated session on
  a device, tracked separately from AccountDeviceBinding and from the
  account's device-move tier, including whether it was established with
  "Keep Me Signed In" enabled. As built it is two local records: the
  signed-in partner's profile (read on the live restore path) and a
  `Session` of account id + device identifier (read only by the legacy
  restore path).

## Design Requirements

Claude Design is the authoritative visual and interaction source of truth
for every screen and state this feature introduces. Claude Code MUST use
the Claude Design MCP during implementation to inspect and reference the
design — not by embedding, downloading, or rendering its HTML.

- Claude Design project: `https://claude.ai/design/p/9c58c1bd-3e56-42d5-b1a4-d34e613fd92f?file=Crown+Solar+Energy.dc.html`
- Primary design file: `Crown Solar Energy.dc.html`
- Claude Design MCP endpoint: `https://api.anthropic.com/v1/design/mcp`
- Authentication: use `/design-login` when authentication is required.

UI and interaction decisions follow this priority order:

1. Claude Design project.
2. Existing Flutter project's design system and architecture.
3. Explicit functional requirements in this specification.
4. Existing Flutter project conventions.

If a behavior required by this specification has no visual treatment
already defined in Claude Design, Claude Code MUST inspect the Claude
Design project through the MCP before inventing a new visual treatment;
an existing Claude Design decision is never replaced with a generic
Flutter UI merely because it is easier to implement.

During implementation planning and build, this design MUST be consulted
for at least the following states (matching the Claude Design's Login
journey board — screens A1–A4, B1–B3, and their annotations), before any
new visual treatment is invented:

- **Login (A1)**: layout, branding/logo placement, mobile-number input and
  its formatting/validation feedback, the "Keep Me Signed In" control, the
  persistent device-policy notice, the primary action, loading state,
  empty-field state, disabled/enabled control states, and authentication
  failure.
- **New/untrusted-device login, second-device tier (A2)**: OTP entry for
  this context, resend-countdown state, invalid-OTP state (A3's error
  styling only — see Design Note below), and successful verification.
- **Device conflict confirmation (A4)**: the takeover confirmation dialog
  shown *before* OTP entry whenever the target device is Active for a
  different account — including its before/after account-naming layout
  *(that layout is Not implemented; the dialog uses generic copy)*.
- **Third-or-later-device tier, not yet authorized (B1)**: the "locked to
  another device" refusal state, shown *instead of* an OTP screen.
- **Third-or-later-device tier, authorized (B2)**: the "CRM has allowed
  this move" state, shown alongside the OTP entry for this tier.
- **Session (B3, and the plain return-to-login case)**: session
  restoration, invalid/expired session, logout, and return-to-login.
  *(B3's "session ended" variant of A1 exists only in the design preview;
  the live flow never shows it.)*

**Design Note — OTP attempt-limiting/lockout (A3's "Verification paused"
card) is explicitly NOT implemented by this feature.** The Claude Design
itself annotates this card's specific numbers as "Sample durations," and
this spec's Open Questions leave OTP expiry/retry/lockout undefined,
per the constitution's prohibition on inventing such values. Only A3's
plain invalid-code error styling (red border, error caption) is in scope;
its lockout card is not.

Where this specification requires a behavior whose visual treatment is not
already represented in the design, the established Crown Solar Energy
visual language and component patterns take precedence over inventing an
unrelated UI. The feature MUST be implemented with native Flutter widgets,
navigation, and theming. Do NOT embed the Claude Design HTML, use a
WebView, render HTML inside Flutter, or build a separate web
implementation. The Claude Design system's tokens and component patterns
are translated into native Flutter widgets, themes, reusable components,
navigation, and design tokens — reusing the existing Flutter design-system
infrastructure rather than introducing a competing one.

## Required UI States

At minimum, this feature must present (using whatever combination of full
screens, dialogs, bottom sheets, inline states, or snackbars the Claude
Design reference specifies):

Login, login validation, login loading, authentication failure,
trusted-device sign-in, New/Untrusted device, device-conflict confirmation
(before OTP), OTP entry for new-device login (second-device tier and
third-or-later-device tier), invalid OTP, third-or-later-tier "locked,
not yet authorized" state, third-or-later-tier "authorized, verify" state,
successful device move (either tier), successful device-conflict transfer,
session restoration, invalid/expired session (if applicable), logout, and
successful authentication.

As built, the live flow (`/login`) renders A1, A2 (with the B2 banner at
the third-or-later tier), A3's error styling, A4, and B1; a successful
move or transfer goes straight to Home with no confirmation screen of its
own. The invalid/expired-session state is **Not implemented** in the live
flow. The live flow's copy is hard-coded English rather than localized
(the legacy `/login/legacy` screens use the ARB strings).

Do not invent new visual designs for any of these states where the Claude
Design reference already defines their treatment; do not create
unnecessary additional screens beyond what the design calls for. Do not
build the A3 lockout card or any OTP-expiry countdown tied to a specific
duration — those remain undefined (see Design Note above and Open
Questions).

## Prototype vs. Production Boundary

| Aspect | Prototype (this feature) | Production (future) |
|---|---|---|
| Backend | Local `prototype_server` (Dart/`shelf`) over local PostgreSQL | REST API (ASP.NET Core API) |
| Database | Local PostgreSQL | SQL Server |
| SMS/OTP delivery | Simulated | Real SMS/OTP provider |
| Rebinding authorization | Simulated as PostgreSQL state | Real CRM/backend authorization |
| Security boundary | Backend API (future) is authoritative; PostgreSQL here is a prototype-only persistence detail | Backend API and its database |
| Session/token storage | Local prototype session state | Backend-controlled, securely stored tokens |
| UI/business behavior | Same as production, to validate the flow | Same business behavior, real integrations |

Intended layering:

```text
Prototype:
Flutter UI → State/Application Layer → Repository/Service Abstraction → Local Prototype Service/Data Source → PostgreSQL

Production:
Flutter UI → State/Application Layer → Repository/Service Abstraction → REST API → ASP.NET Core API → SQL Server
```

The Flutter application MUST NOT connect directly to PostgreSQL. A local
prototype service/data-source layer sits behind the repository/service
abstraction and provides the same application-facing operations
(authenticate, get active device, request/verify OTP, check rebinding
authorization, bind/rebind device, restore session, logout, etc.) that the
future REST API will provide, so that the Flutter UI and application/state
layer do not need to be redesigned when the PostgreSQL prototype is
replaced by the real ASP.NET Core API. The prototype must demonstrate the
intended production business behavior end-to-end without presenting the
local PostgreSQL database, or any client-side state, as a
production-equivalent security architecture.

## Out of Scope

This feature explicitly does NOT include:

- **Registration** — the flow that establishes Device 1 (mobile-number
  entry, registration OTP, initial device binding) is a separate journey.
  This feature does not add to the registration journey; it only assumes
  an account with an established Device 1 as its starting precondition
  (the legacy registration path noted under User Story 1 remains from an
  earlier revision and is not extended).
- Real backend APIs, real SMS/OTP delivery, or real CRM integration.
- Any CRM screens, CRM administrator screens, CRM approval UI, CRM user
  management, CRM roles, or in-app CRM authorization controls of any kind.
- Password authentication, password recovery, email authentication,
  username authentication, dealer-code authentication, or any other
  additional authentication factor.
- Any specific OTP lockout, OTP retry limit, OTP cooldown, or
  login-attempt-lockout policy — none is defined by the business (see
  Open Questions), including the Claude Design's own "Sample durations"
  lockout card (A3).
- A third device-move tier, or any additional free move beyond the
  account's first — the tier boundary defined in "Device-Move Tiers" is
  exhaustive.
- Dashboard functionality, permissions, modules, or any other application
  area beyond what is minimally necessary to demonstrate successful
  authentication.
- A full production backend or its security implementation.
- Any Crown Solar Energy module unrelated to login, authentication, and
  device binding.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A valid sign-in from an account's current Active device
  proceeds directly to authenticated content without requiring an OTP
  step, regardless of the account's device-move count.
- **SC-002**: A sign-in attempt from a device other than an account's
  current Active device is classified New/Untrusted and, absent a device
  conflict, is gated by exactly one of the two device-move tiers with no
  other outcome possible.
- **SC-003**: An account with zero prior device moves completes a move to
  a new device using a login-context OTP alone, with no
  rebinding-authorization record ever required to exist or be consulted.
- **SC-004**: An account with one or more prior device moves is never able
  to complete a further move without a rebinding-authorization outcome of
  Authorized, regardless of how many times it retries.
- **SC-005**: A device conflict is never resolved without an explicit user
  confirmation shown before any OTP is requested, and declining that
  confirmation never changes any account's binding state.
- **SC-006**: A rebinding attempt that resolves to Authorized (at the
  third-or-later tier) or that completes via OTP alone (at the
  second-device tier) results in exactly one Active device for the
  account afterward, with the previous device Revoked, and — when the
  transferred device was Active for a different account — that other
  account's binding to it resolved to Revoked as part of the same atomic
  operation, never left partially applied.
- **SC-007**: A persisted "Keep Me Signed In" session on a device that has
  since been Revoked (by a move at either tier) fails to reach
  authenticated content when session restoration is attempted. *(Not met
  on the live `/login` path — see FR-033.)*
- **SC-008**: Signing out ends the local session while leaving the device's
  binding state and the account's device-move count unchanged, as verified
  by a subsequent trusted-device sign-in that requires no OTP.
- **SC-009**: A device that was Revoked by a prior move is classified
  New/Untrusted (not trusted) on any subsequent sign-in attempt, and its
  reactivation is gated by the account's *current* device-move tier.

## Assumptions

- Accounts (mobile number, user type) already exist in the system, with
  an established Device 1 Active binding, before any scenario in this
  feature runs; both account provisioning and the registration flow that
  establishes Device 1 are out of this feature's scope. In practice the
  seeded demo accounts have no binding at all, which FR-049 covers.
  Mobile numbers are stored as ten national digits (no `+92`, no leading
  zero) in the app's seed data.
- "Device" is treated in this specification as an abstract, identifiable
  unit the system can compare against a stored binding; the concrete
  mechanism for identifying a device is an implementation detail for the
  planning phase, not a business rule, and is intentionally not dictated
  here.
- An account's device-move count is derived entirely from its existing
  `account_device_bindings` history (a count of `rebinding`-context rows);
  no new stored field is required to track it, and no separate "tier"
  value is persisted — the tier is computed fresh from that count on every
  login attempt.
- Claude Code will inspect the existing Flutter project's architecture,
  state management, routing, dependency injection, and design system
  before implementation planning, and will reuse what it finds rather than
  introducing competing frameworks.
- PostgreSQL is used strictly as this prototype's persistence mechanism
  behind a repository/service abstraction. The Flutter application must
  not connect directly to PostgreSQL. A local prototype service/data-source
  layer may be used to provide the same application-facing operations that
  the future REST API will provide, so the UI and application/state layer
  do not need to be redesigned when the PostgreSQL prototype is replaced
  by the real ASP.NET Core API; this layer, and PostgreSQL itself, are not
  the intended production security boundary.
- The rebinding-authorization system (conceptually CRM-owned) is
  represented only as Pending/Authorized/Not Authorized state in this
  prototype, and only ever comes into play at the third-or-later-device
  tier; no in-app mechanism exists to influence that state.
- The registration OTP and the login-context (New/Untrusted-device) OTP
  share the same simulated delivery concept in this prototype but are
  modeled as separate events/records.

## Open Questions / Business Rules Required

- **OTP expiry duration**: This specification requires that OTP
  verification be modeled — for both the registration context and the
  login (New/Untrusted-device) context, at either device-move tier —
  including the possibility of an expired OTP, but the business has not
  defined a specific expiry duration (the Claude Design's own A3 card
  labels its numbers "Sample durations," confirming these are not yet
  decided). **Open Question / Business Rule Required.**
- **Session-expiration duration**: This specification requires that
  sessions be restorable while "valid" and rejected once no longer valid,
  but the business has not defined a specific session-expiration duration
  or inactivity window. **Open Question / Business Rule Required.**
- **OTP retry/lockout policy**: The Claude Design's A3 screen depicts an
  attempt-limit-then-lockout treatment, but no specific attempt count,
  lockout duration, or retry-time policy is defined by the business. This
  specification does not implement any such limit. **Open Question /
  Business Rule Required** if the Claude Design's A3 lockout treatment is
  to be built in a future revision.
- **Resend countdown**: the live A2 screen waits 30 seconds before
  allowing "Resend". The value comes from the screen, not from a business
  rule, and the server enforces nothing. **Open Question** — confirm or
  remove.
- **Reuse of an Authorized decision or a verified OTP**: a completed move
  consumes neither. A later move back to the same device for the same
  account is satisfied by the old Authorized record (and the server-side
  OTP re-check by any earlier verified code for that pair). **Open
  Question** — should each move require a fresh decision and code?
- **Server-side takeover confirmation**: the server does not record or
  require the A4 confirmation before transferring a conflicting device.
  **Open Question** — acceptable for the prototype, or must the server
  enforce it?
