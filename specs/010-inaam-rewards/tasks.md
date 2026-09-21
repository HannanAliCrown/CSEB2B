---
description: "Tasks for Inaam rewards"
---

# Tasks: Inaam Rewards

## Phase 1: Existing Foundation
- [x] T001 [P] Retain Inaam models/service in `lib/features/inaam_baazar/data/inaam_service.dart`.
- [x] T002 [P] Retain rewards schema in `db/migrations/009_inaam_baazar.sql`.

## Phase 2: User Story 1 - Spin and Win
- [x] T003 [US1] Load scan-derived spin state in `prototype_server/lib/routes/inaam_routes.dart`.
- [x] T004 [US1] Atomically choose/pay a spin prize in `prototype_server/lib/data/postgres_inaam_data_store.dart`.
- [x] T005 [US1] Render unavailable, no-spins, success, and history states in `lib/features/inaam_baazar/ui/views/spin_screens.dart`.
- [x] T006 [US1] Test entitlement and wallet credit behavior in `prototype_server/test/routes/inaam_test.dart`.

## Phase 3: User Story 2 - Item Schemes
- [x] T007 [US2] Load scheme progress and tiers in `prototype_server/lib/data/postgres_inaam_data_store.dart`.
- [x] T008 [US2] Enforce reached, expiry, unknown, and one-claim rules in the data store.
- [x] T009 [US2] Render item scheme progress and claim outcomes in `lib/features/inaam_baazar/ui/views/scheme_screens.dart`.

## Phase 4: User Story 3 - Reward Program
- [x] T010 [US3] Display configured current program and prior award in `lib/features/inaam_baazar/ui/views/scheme_screens.dart`.
- [ ] T011 [US3] Add a separately specified background evaluation process for monthly winners; not part of current mobile implementation.

## Phase 5: Polish
- [ ] T012 Run all Inaam scenarios from `specs/010-inaam-rewards/quickstart.md` and verify role restrictions in `lib/features/inaam_baazar/ui/`.

## Dependencies
- US2 depends on product scan/progress data.
- US3 depends on externally supplied program configuration.

## MVP
US1: one correct spin and wallet credit.
