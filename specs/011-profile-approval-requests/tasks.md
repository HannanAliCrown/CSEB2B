---
description: "Tasks for profile approval requests"
---

# Tasks: Profile Approval Requests

## Phase 1: Existing Foundation
- [x] T001 [P] Retain request DTOs/service in `lib/features/profile_requests/data/profile_requests_service.dart`.
- [x] T002 [P] Retain expected-purchase constraints in `db/migrations/008_profile_requests_and_cash_requests.sql`.

## Phase 2: User Story 1 - Review Pending Requests
- [x] T003 [US1] Return only outstanding requests for the selected buying source in `prototype_server/lib/data/postgres_partner_data_store.dart`, served by `prototype_server/lib/routes/partner_routes.dart`.
- [x] T004 [US1] Exclude CNIC number/images from request queries and DTOs in `prototype_server/lib/data/postgres_partner_data_store.dart` and `lib/features/profile_requests/data/profile_requests_service.dart`.
- [x] T005 [US1] Render request list/detail and Home badge in `lib/features/profile_requests/ui/` and `lib/features/home/ui/views/dashboard_screen.dart`.

## Phase 3: User Story 2 - Decide Requests
- [x] T006 [US2] Require expected purchase for approval and reason for rejection in `prototype_server/lib/data/postgres_partner_data_store.dart`.
- [x] T007 [US2] Enforce single-use decisions and account isolation in `prototype_server/lib/data/postgres_partner_data_store.dart`, mapped to 404 responses in `prototype_server/lib/routes/partner_routes.dart`.
- [x] T008 [US2] Render approve/reject flows and validation messages in `lib/features/profile_requests/ui/views/profile_request_detail_screen.dart`.
- [x] T009 [US2] Test request visibility and decisions in `prototype_server/test/routes/profile_requests_test.dart`.
- [x] T016 [US2] End the application on a buying-source rejection in `prototype_server/lib/data/postgres_partner_data_store.dart`.

## Phase 4: First Buying Source Only (FR-001, FR-007)
- [x] T012 [US1] Notify only the first buying source on submission in `prototype_server/lib/data/postgres_partner_data_store.dart`.
- [x] T013 [US1] Return requests only to the first buying source in `prototype_server/lib/data/postgres_partner_data_store.dart`.
- [x] T014 [US2] Accept a decision only from the first buying source in `prototype_server/lib/data/postgres_partner_data_store.dart`.
- [x] T015 [US2] Test that a later buying source neither sees nor decides the request, and that approval marks the buying source approved, in `prototype_server/test/routes/profile_requests_test.dart`.

## Phase 5: Polish
- [ ] T010 Verify calling an outstanding approver opens the phone dialer (placeholder `0000000000`) in `lib/features/registration/ui/views/approval_status_flow_screen.dart`.
- [ ] T011 Run profile-request scenarios from `specs/011-profile-approval-requests/quickstart.md`.
- [ ] T017 Replace the placeholder with each approver's stored number in `lib/features/registration/ui/views/approval_status_flow_screen.dart` (FR-009, Not implemented; numbers not yet supplied).

## Dependencies
- US2 depends on the request list/detail from US1.

## MVP
US1 and US2: a buying source can review and decide a request safely.
