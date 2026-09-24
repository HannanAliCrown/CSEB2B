---
description: "Tasks for points and targets"
---

# Tasks: Points and Targets

## Phase 1: Existing Foundation
- [x] T001 [P] Retain points models/service in `lib/features/points/data/points_service.dart`.
- [x] T002 [P] Retain points schema in `db/migrations/007_points_and_targets.sql`.

## Phase 2: User Story 1 - View Points
- [x] T003 [US1] Load ledger, balance, restrictions, schemes, periods, extras, and breakdown in `prototype_server/lib/routes/points_routes.dart`.
- [x] T004 [US1] Render no-scheme, four-month period, annual, and extra-target states in `lib/features/points/ui/views/targets_screen.dart`.
- [x] T005 [US1] Compute target scoring from qualifying entry types in `prototype_server/lib/data/postgres_points_data_store.dart`.
- [x] T006 [US1] Test scheme/no-scheme and target progress behavior in `prototype_server/test/routes/points_test.dart`.
- [x] T012 [US1] Render balance, meters, and five recent entries with "See all" in `lib/features/points/ui/views/points_tab.dart`.
- [x] T013 [US1] Filter the full ledger by credit/debit and date range in `lib/features/points/ui/views/points_ledger_screen.dart`.

## Phase 3: User Story 2 - Manual Transfers
- [x] T007 [US2] Enforce role-pair, restriction, self, amount, recipient, and balance rules in `prototype_server/lib/data/postgres_points_data_store.dart`.
- [x] T008 [US2] Support manual send flow in `lib/features/points/ui/views/send_points_screen.dart`.
- [x] T009 [US2] Test successful and refused transfers in `prototype_server/test/routes/points_test.dart`.

## Phase 4: Polish
- [ ] T010 Verify contact/QR/history selection paths against real device services in `lib/features/points/ui/views/send_points_screen.dart`.
- [x] T011 Document automatic 1% accrual and SAP integration as out of scope in `specs/009-points/spec.md`.
- [ ] T014 Add Flutter tests for the points hub, ledger filters, and send flow in `test/features/points/` (Not implemented).

## Dependencies
- US2 depends on recipient and restriction data from US1.

## MVP
US1: accurate points visibility and target reporting.
