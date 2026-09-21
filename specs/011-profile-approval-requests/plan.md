# Implementation Plan: Profile Approval Requests

**Branch**: `011-profile-approval-requests` | **Date**: 2026-09-21 | **Spec**: [spec.md](spec.md)

## Summary
Provide the buying-source inbox and durable approve/reject decisions while leaving MO and CRM approvals to the separate Team App.

## Technical Context
- **Language/Version**: Dart/Flutter and plain Dart
- **Dependencies**: HTTP, PostgreSQL prototype store, Provider, url_launcher
- **Storage**: registration applications, buying sources, approval decisions, expected purchase bands
- **Testing**: Flutter profile-request tests and prototype server partner-route tests
- **Target Platform**: Android/iOS portrait-first
- **Project Type**: Flutter mobile plus local prototype API
- **Constraints**: exclude CNIC data; decisions are single-use; pending badge is server-derived
- **Scale/Scope**: request inbox, request detail, expected purchase, approve/reject

## Constitution Check
Pass: reuses existing registration/partner data stores and does not duplicate the Team App approval system.

## Project Structure
```text
lib/features/profile_requests/{data,ui}/
db/migrations/001_first_launch_and_registration.sql
db/migrations/008_profile_requests_and_cash_requests.sql
prototype_server/lib/{data,routes}/partner_*
test/features/profile_requests/
prototype_server/test/routes/profile_requests_test.dart
```

## Design Decisions
- Return only outstanding requests from the inbox.
- Enforce approval expectation and rejection reason in the server data layer.
- Keep CNIC number/images out of request DTOs and responses.

## Complexity Tracking
None.
