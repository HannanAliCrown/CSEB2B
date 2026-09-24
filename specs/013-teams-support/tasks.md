---
description: "Tasks for Crown Solar Teams Support"
---

# Tasks: Crown Solar Teams Support

**Input**: [spec.md](spec.md), [plan.md](plan.md)

## Phase 1: Foundation

- [X] T001 Write `db/migrations/012_teams_support.sql` (plan Data Model) and `db/seed/011_teams_support.sql` (one officer-raised complaint and branding request, one staff chat party and thread, one market-targeted item scheme, one unassigned code); list both in `db/README.md`

## Phase 2: User Story 1 - Marketing Officer decision (CSE-1)

- [X] T002 Verified: only the buying-source decision ends an application (`postgres_partner_data_store.dart` decideProfileRequest); Crown Solar Energy writes no Marketing Officer decision itself. Verify the Approval Status path leaves the application `submitted` after a Marketing Officer rejection (no code change expected; only the buying-source rejection ends it)

## Phase 3: User Story 2 - Raised by (CSE-2, CSE-3)

- [X] T003 Server: select the raised-by columns in complaints and branding stores; `raisedBy` in `ComplaintRow` / `BrandingRequestRow` JSON (null when not officer-raised); fakes updated
- [X] T004 [P] Server tests: officer-raised complaint returns `raisedBy`; partner-raised returns null
- [X] T005 App: `Complaint.raisedBy` and `BrandingRequest.raisedBy`; "Raised by" `DsSettingRow` on complaint detail and branding status only when present
- [X] T006 [P] App tests: complaint parsing with and without `raisedBy`

## Phase 4: User Story 4 - Staff chat parties (CSE-5)

- [X] T007 Server: `resolveParty` handles `staff:` from `chat_staff_parties`; fake store likewise; test
- [X] T008 App: `_roleLabel` covers `mo`/`asm`/`rsm` through `staffRoleLabel` (tested via the complaint raised-by test)

## Phase 5: User Story 5 - Market targeting (CSE-6)

- [X] T009 Server: item scheme list, detail and claim, and current reward program filtered by the partner's market (plan D2)

## Phase 6: User Story 6 - Unassigned codes (CSE-7)

- [X] T010 Server: verdict `unassigned` in `check()` and intro meaning; fake store and test
- [X] T011 App: `ScanVerdict.unassigned`, HTTP parsing, mock sample, result copy; test

## Phase 7: Verification

- [X] T012 `dart format .`, `flutter analyze`, `flutter test`; in `prototype_server/`: `dart analyze`, `dart test` — done; 14 design-preview golden failures pre-date this feature. Applying migration 012 and seed 011 to the local database is left to the operator (needs the database password)
