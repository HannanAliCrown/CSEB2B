---
description: "Tasks for role-based dashboard"
---

# Tasks: Role-Based Dashboard

## Phase 1: Existing Foundation
- [x] T001 [P] Create/retain dashboard models in `lib/features/home/data/dashboard_repository.dart`.
- [x] T002 [P] Create/retain dashboard endpoint wiring in `prototype_server/lib/routes/partner_routes.dart`.

## Phase 2: User Story 1 - View Role-Based Home
- [x] T003 [US1] Load wallet, held amount, slides, ticker, and scan subtitle in `lib/features/home/data/http_dashboard_repository.dart`.
- [x] T004 [US1] Filter role-specific Home tiles and request badges in `lib/features/home/ui/views/dashboard_screen.dart`.
- [x] T005 [US1] Render Installer versus seller-side bottom navigation in `lib/app/shell/app_shell.dart`.
- [x] T006 [US1] Test dashboard and role tile behavior in `test/app/app_test.dart` and feature tests.

## Phase 3: User Story 2 - Use Dashboard Actions
- [x] T007 [US2] Keep route callbacks for wallet, scanner, complaints, notifications, points, and requests in `lib/app/router/app_router.dart`.
- [ ] T008 [US2] Replace deferred Branding callback with an explicit unavailable state until branding is separately specified in `lib/app/shell/app_shell.dart`.

## Phase 4: Polish
- [ ] T009 [P] Add focused dashboard contract tests under `prototype_server/test/routes/partner_test.dart`.
- [ ] T010 Run role-by-role dashboard scenarios from `specs/003-dashboard/quickstart.md`.

## Dependencies
- Foundation precedes both stories.
- US2 depends on role data from US1.

## MVP
US1: each role sees a valid Home dashboard.
