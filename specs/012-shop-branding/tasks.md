---
description: "Tasks for shop branding"
---

# Tasks: Shop Branding

## Phase 1: Foundation
- [x] T001 [P] Create branding config, board types, role conditions, installations, requests and request boards in `db/migrations/011_shop_branding.sql`.
- [x] T002 [P] Seed board types, role conditions and demo requests/installations in `db/seed/010_shop_branding.sql`.
- [x] T003 [P] Define row types, refusals and the store interface in `prototype_server/lib/data/branding_data_store.dart`.
- [x] T004 Mount branding routes in `prototype_server/lib/router.dart` and wire the Postgres store in `prototype_server/bin/server.dart`.
- [x] T005 [P] Add DTOs, failures and HTTP client in `lib/features/branding/data/branding_service.dart`; provide it in `lib/app/router/app_router.dart`.

## Phase 2: User Story 1 - Branding Position
- [x] T006 [US1] Return eligibility, current request and history from `GET /branding` in `prototype_server/lib/routes/branding_routes.dart` and `prototype_server/lib/data/postgres_branding_data_store.dart`.
- [x] T007 [US1] Route the Home tile to `/branding` in `lib/app/shell/app_shell.dart` and `lib/features/home/ui/views/dashboard_screen.dart`.
- [x] T008 [US1] Render landing, blocked New Request, current request, three past requests and eligibility in `lib/features/branding/ui/views/shop_branding_screen.dart`.
- [x] T009 [US1] Render full history in `lib/features/branding/ui/views/branding_requests_screen.dart`.

## Phase 3: User Story 3 - Eligibility-Filtered Board Types
- [x] T010 [US3] Filter by role, points, scheme and recent scan claim in `prototype_server/lib/data/postgres_branding_data_store.dart`.
- [x] T011 [US3] Apply replacement detection first and return the replacement notice in `prototype_server/lib/data/postgres_branding_data_store.dart`.
- [x] T012 [US3] Return condition and first unmet locked reason in `prototype_server/lib/data/postgres_branding_data_store.dart`.

## Phase 4: User Story 2 - File a Request
- [x] T013 [US2] Build step 1 (photos, measurements, optional fields) and step 2 (per-board slots, sheet, split, empty state with Open Scanner) in `lib/features/branding/ui/views/new_branding_request_screen.dart`.
- [x] T014 [US2] Re-check eligibility, enforce board count and one live request in a transaction, snapshot price/split in `prototype_server/lib/data/postgres_branding_data_store.dart`.
- [x] T015 [US2] Map refusals to HTTP errors in `prototype_server/lib/routes/branding_routes.dart` and to messages in `lib/features/branding/data/branding_service.dart`.

## Phase 5: User Story 4 - Track a Request
- [x] T016 [US4] Return one account-scoped request from `GET /branding/requests/<reference>` in `prototype_server/lib/routes/branding_routes.dart`.
- [x] T017 [US4] Render timeline, shares, per-board breakdown, completed banner and rejection reason in `lib/features/branding/ui/views/branding_status_screen.dart`.
- [x] T018 [P] Keep static design-preview boards A1–A9 in `lib/features/branding/ui/views/branding_screens.dart` and `branding_request_screens.dart` for `lib/features/design_preview/preview_catalog.dart`.

## Phase 6: Remaining Work
- [ ] T019 [P] Add prototype-server route tests for landing, board-type filtering, replacement, refusals and account isolation in `prototype_server/test/routes/branding_test.dart`.
- [ ] T020 [P] Add Flutter tests for `BrandingService` parsing/failure mapping and wizard gating in `test/features/branding/`.
- [ ] T021 Use each board's `companyPercent` for the share labels instead of the hardcoded 60%/40% in `ExpenseShareCard` in `lib/features/branding/ui/views/branding_screens.dart`.
- [ ] T022 Resolve the wizard subtitles "Step 1 of 3"/"Step 2 of 3" against the two implemented steps in `lib/features/branding/ui/views/new_branding_request_screen.dart`.
- [ ] T023 Localize branding strings (English / Urdu / Roman Urdu) across `lib/features/branding/`.
- [ ] T024 Make `_newReference` collision-safe against the unique `reference` constraint in `prototype_server/lib/data/postgres_branding_data_store.dart`.
- [ ] T025 Show an unreachable state (not "No requests yet") when history fails to load in `lib/features/branding/ui/views/branding_requests_screen.dart`.
- [ ] T026 Run scenarios from `specs/012-shop-branding/quickstart.md`.

## Dependencies
- US2 depends on US3 board types; US4 depends on requests from US2 or seed.

## MVP
US1–US3: a partner can see their position and file a request for a board they are eligible for.
