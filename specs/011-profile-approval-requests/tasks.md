---
description: "Tasks for profile approval requests"
---

# Tasks: Profile Approval Requests

## Phase 1: Existing Foundation
- [x] T001 [P] Retain request DTOs/service in `lib/features/profile_requests/data/profile_requests_service.dart`.
- [x] T002 [P] Retain expected-purchase constraints in `db/migrations/008_profile_requests_and_cash_requests.sql`.

## Phase 2: User Story 1 - Review Pending Requests
- [x] T003 [US1] Return only outstanding requests for the selected buying source in `prototype_server/lib/routes/partner_routes.dart`.
- [x] T004 [US1] Exclude CNIC number/images from request DTOs and responses in `lib/features/profile_requests/data/profile_requests_service.dart`.
- [x] T005 [US1] Render request list/detail and Home badge in `lib/features/profile_requests/ui/` and `lib/features/home/ui/views/dashboard_screen.dart`.

## Phase 3: User Story 2 - Decide Requests
- [x] T006 [US2] Require expected purchase for approval and reason for rejection in `prototype_server/lib/data/postgres_partner_data_store.dart`.
- [x] T007 [US2] Enforce single-use decisions and account isolation in `prototype_server/lib/routes/partner_routes.dart`.
- [x] T008 [US2] Render approve/reject flows and validation messages in `lib/features/profile_requests/ui/views/profile_requests_screen.dart`.
- [x] T009 [US2] Test request visibility and decisions in `prototype_server/test/routes/profile_requests_test.dart`.

## Phase 4: Polish
- [ ] T010 Verify calling pending approvers uses the phone dialer and stored number.
- [ ] T011 Run profile-request scenarios from `specs/011-profile-approval-requests/quickstart.md`.

## Dependencies
- US2 depends on the request list/detail from US1.

## MVP
US1 and US2: a buying source can review and decide a request safely.
