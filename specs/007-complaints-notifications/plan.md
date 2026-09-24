# Implementation Plan: Complaints and Notifications

**Branch**: `007-complaints-notifications` | **Date**: 2026-09-21 | **Spec**: [spec.md](spec.md)

## Summary
Use server-owned complaint catalogues, ticket histories, SLA timestamps, and notification records behind the existing ComplaintsService.

## Technical Context
- **Language/Version**: Dart/Flutter and plain Dart
- **Dependencies**: HTTP, PostgreSQL prototype store, Provider
- **Storage**: complaint categories/targets/tickets/events and notifications
- **Testing**: Flutter service tests (`test/features/complaints/complaints_service_test.dart`) and prototype server complaint tests
- **Target Platform**: Android/iOS portrait-first
- **Project Type**: Flutter mobile plus local prototype API
- **Constraints**: account isolation, timestamp-derived SLA states, no fake success
- **Scale/Scope**: complaints list/detail/create and notifications
- **Data source**: `ComplaintsService` is always server-backed; there is no mock implementation.

## Constitution Check
Pass: existing service boundary is retained and all user-visible text remains localizable at UI level.

## Project Structure
```text
lib/features/complaints/{data,ui}/
db/migrations/005_complaints_and_notifications.sql
db/migrations/010_complaints_without_subtypes.sql
db/seed/005_complaints_and_notifications.sql
prototype_server/lib/data/{complaints_data_store,postgres_complaints_data_store}.dart
prototype_server/lib/routes/complaints_routes.dart
test/features/complaints/
prototype_server/test/routes/complaints_test.dart
```

## Design Decisions
- Return null/error states on unreachable server rather than empty successful data where persistence matters.
- Keep SLA promises copied to each complaint at creation.
- Restrict notification navigation to existing routes (`/wallet/ledger`, `/complaints/<reference>`).
- Drop complaint sub-types (migration 010); targets are keyed on category and priority.
- Derive the in-progress "Awaiting resolution" step at read time instead of storing it.

## Complexity Tracking
None.
