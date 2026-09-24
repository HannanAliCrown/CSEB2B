# Implementation Plan: Profile Approval Requests

**Branch**: `011-profile-approval-requests` | **Date**: 2026-09-21 | **Spec**: [spec.md](spec.md)

## Summary
Provide the buying-source inbox and durable approve/reject decisions while leaving MO and CRM approvals to the separate Team App.

## Technical Context
- **Language/Version**: Dart/Flutter and plain Dart
- **Dependencies**: HTTP, PostgreSQL prototype store, Provider, url_launcher
- **Storage**: registration applications, buying sources, approval decisions, expected purchase bands
- **Testing**: prototype server route tests against the fake partner store (`prototype_server/test/routes/profile_requests_test.dart`); no Flutter profile-request tests
- **Target Platform**: Android/iOS portrait-first
- **Project Type**: Flutter mobile plus local prototype API
- **Constraints**: exclude CNIC data; decisions are single-use; pending badge counts the server's outstanding list (zero when unreachable)
- **Scale/Scope**: request inbox, request detail, expected purchase, approve/reject, applicant Approval Status call action

## Constitution Check
Pass with one deviation: reuses existing registration/partner data stores and does not duplicate the Team App approval system. The profile-request screens and Home read `ProfileRequestsService` directly from Provider; there is no ViewModel or repository for this feature.

## Project Structure
```text
lib/features/profile_requests/data/profile_requests_service.dart
lib/features/profile_requests/ui/views/{profile_requests_screen,profile_request_detail_screen}.dart
lib/features/home/ui/views/dashboard_screen.dart
lib/features/registration/ui/views/approval_status_flow_screen.dart
db/migrations/001_first_launch_and_registration.sql
db/migrations/008_profile_requests_and_cash_requests.sql
db/seed/{006_cash_and_scan,008_profile_requests_and_cash_requests}.sql
prototype_server/lib/data/{partner_data_store,partner_models,postgres_partner_data_store}.dart
prototype_server/lib/routes/partner_routes.dart   (profileRequestRoutes)
prototype_server/test/routes/profile_requests_test.dart
prototype_server/test/support/fake_partner_data_store.dart
```

## Design Decisions
- Return only outstanding requests from the inbox.
- Only the buying source at `position = 0` is notified, sees the request, and may decide it; the SQL join/WHERE clause is the authorisation.
- Enforce approval expectation and rejection reason in the server data layer and by migration 008 check constraints.
- A buying-source rejection sets the application `rejected`; an approval touches only the buying-source approval.
- Keep CNIC number/images out of request DTOs and responses; excluded in the query, not filtered afterwards.
- Approver calls use `tel:` with placeholder `0000000000`.

## Complexity Tracking
None.
