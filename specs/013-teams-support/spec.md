# Feature Specification: Crown Solar Teams Support

**Feature Branch**: `013-teams-support`
**Created**: 2026-09-24
**Status**: Draft
**Input**: The Crown Solar Energy changes CSE-1 … CSE-7 approved by the product owner for the Crown Solar Teams app (MO/ASM/RSM field staff sharing this database). Recorded in `C:\Projects\cse_teams\docs\decisions-log.md`. Business logic changes only, except where a partner must see something new: the officer who raised a request, an officer's name in chat, and the "not yet assigned" scan result.

## Clarified by the product owner

- **Raised by**: a complaint or branding request shows the MO's or ASM's name **only when an officer raised it**. A request the partner raised shows no such field at all (2026-09-24).
- **MO rejection** of a new profile does not end the application; CRM (Super Admin) sees the MO's rejection and reason and decides (OD-07d).
- **Offers per market**: Super Admin decides in which markets each scheme or offer is shown; business logic only, no UI change (OD-16).
- **Unassigned QR**: a code created by Crown Solar Super Admin but not yet assigned to a product serial (CD-03).

## User Scenarios & Testing

### User Story 1 - Marketing Officer decision on a registration (CSE-1, Priority: P1)
Crown Solar Teams records the Marketing Officer's decision on a registration in this database. The applicant's Approval Status shows it; a rejection carries its reason and does not end the application.

**Independent Test**: record an MO rejection on a submitted application; the Marketing Officer row reads Rejected, the application stays submitted, and a rejection with no remark is refused by the database.

**Acceptance Scenarios**
1. Given a Marketing Officer rejection with no remark, when it is written, then the database refuses it.
2. Given a Marketing Officer decision, when it is written, then the officer's staff id, role and name are stored with it.
3. Given a Marketing Officer rejection, when the applicant opens Approval Status, then the Marketing Officer row shows Rejected and the application is still waiting on CRM; nothing else changes.

### User Story 2 - Officer-raised complaints and branding requests (CSE-2, CSE-3, Priority: P1)
An MO or ASM raises a complaint or branding request for a partner through Crown Solar Teams. The partner sees it in their own lists and details, labelled with the officer who raised it.

**Independent Test**: seed one officer-raised and one partner-raised complaint and branding request; the officer-raised detail shows "Raised by <name> · Marketing Officer"; the partner-raised detail shows no Raised by row.

**Acceptance Scenarios**
1. Given a request raised by an officer, when its detail opens, then a "Raised by" row shows the officer's name and role (Marketing Officer or Area Sales Manager).
2. Given a request the partner raised, when its detail opens, then no Raised by row is shown.
3. Given an officer reference, when it is stored, then the staff id, name and role are all present or all absent.

### User Story 3 - Closed shops (CSE-4, Priority: P2)
An account can be marked closed, so a Shop Closure approved by Crown Solar can be recorded.

**Acceptance Scenarios**
1. Given an account, when its status is set to `closed`, then the database accepts it; any other value except `active` is refused.

### User Story 4 - Officer names in chat (CSE-5, Priority: P1)
An officer messages a partner from Crown Solar Teams. The partner's chat list and conversation show the officer's name and role instead of dropping the thread.

**Independent Test**: seed a thread between a partner and `staff:<id>` with a staff party row; the partner's chat list shows it titled with the officer's name, subtitle the role.

**Acceptance Scenarios**
1. Given a thread with a known staff party, when the partner's chat list loads, then the thread shows the officer's name and role.
2. Given a thread with a staff address that has no party row, when the list loads, then the thread is left out, as for any unknown party today.

### User Story 5 - Offers targeted to markets (CSE-6, Priority: P1)
Super Admin decides in which markets each item scheme, reward program and point scheme is shown. A partner sees only what is shown in their market.

**Independent Test**: target one item scheme to market A only; a partner in market A sees it, a partner in market B does not; an untargeted scheme is seen by both.

**Acceptance Scenarios**
1. Given an item scheme targeted to some markets, when a partner outside them opens Inaam Baazar, then it is not listed and cannot be claimed.
2. Given a reward program targeted to some markets, when a partner outside them opens it, then the latest program shown in their market (or none) is used. Awards already made to the partner keep paying their scan bonus.
3. Given a scheme, program or item scheme with no market targets, then it is shown in every market (today's behaviour, since Super Admin is not built).
4. Given a partner's signed point scheme, then it stays shown to that partner; targeting decides the markets where a point scheme is offered (read by Crown Solar Teams Focus › Offers).

### User Story 6 - Codes not yet assigned to a product (CSE-7, Priority: P1)
A QR code can exist before it is assigned to a product serial. Scanning it tells the partner so, and pays nothing.

**Independent Test**: seed an unassigned code; scanning it in either mode returns "not yet assigned"; no claim or wallet entry is written.

**Acceptance Scenarios**
1. Given an unassigned code, when it is scanned for authenticity or to win, then the result reads "Not yet assigned" with "This code is not yet assigned to a product." and no claim is taken.
2. Given the scan intro samples, then an unassigned code is described as "Not yet assigned".

### Edge Cases
- An officer reference on a request is never shown to the partner as an id; only name and role.
- A staff party's name may change; the chat shows the current row.
- Targeting a scheme to a market that has no partners changes nothing for anyone else.

## Requirements

- **FR-001**: A Marketing Officer rejection on `registration_approvals` MUST carry a non-empty note (database constraint).
- **FR-002**: `registration_approvals` MUST be able to record the deciding staff member (id, role, name); partner decisions are unchanged.
- **FR-003**: A Marketing Officer rejection MUST NOT change the application's status (only a buying-source rejection ends it, as today).
- **FR-004**: `complaints` and `branding_requests` MUST be able to record the officer who raised them (staff id, name, role `mo` or `asm`), all set or all null.
- **FR-005**: Complaint and branding request responses MUST include `raisedBy {name, role}` only when an officer raised the request, and the app MUST show a Raised by row only then.
- **FR-006**: `accounts.status` MUST accept `active` and `closed`. No sign-in or visibility effect of `closed` is specified here.
- **FR-007**: Chat MUST resolve `staff:<id>` parties from a staff-party record (name, role) and show them like a partner party: name as title, role as subtitle.
- **FR-008**: Item schemes, reward programs and point schemes MUST be targetable to markets; no targets means every market.
- **FR-009**: A partner MUST see and claim only item schemes shown in their market, and the current reward program MUST be the latest one shown in their market.
- **FR-010**: `products` MUST allow the state `unassigned`; scanning such a code MUST return the verdict `unassigned`, take no claim and write no wallet entry.
- **FR-011**: Every new user-visible string follows the existing screens' convention.

## Success Criteria
- **SC-001**: A Marketing Officer rejection without a remark is refused in 100% of attempts.
- **SC-002**: A Raised by row appears on 100% of officer-raised requests and on 0% of partner-raised ones.
- **SC-003**: Officer threads appear in the partner's chat list with the officer's name in 100% of seeded cases.
- **SC-004**: Partners outside a scheme's markets never see or claim it.
- **SC-005**: Scanning an unassigned code never produces a claim or wallet entry.

## Assumptions
- Staff (MO/ASM/RSM) live in Crown Solar Teams; this database stores their id, name and role as written by Teams, without a foreign key into Teams tables (Crown Solar Energy migrations run before Teams').
- Super Admin is not built: nothing in this project sets market targets, closes accounts or unassigns codes; seeds demonstrate each.
- A point scheme's targeting does not remove a scheme a partner has already signed.

## Out of Scope
- Super Admin screens; Crown Solar Teams itself; photo upload for officer-raised branding (CD-07, superseded).
