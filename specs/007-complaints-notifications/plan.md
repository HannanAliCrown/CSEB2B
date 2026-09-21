# Implementation Plan: Complaints and Notifications

**Branch**: `007-complaints-notifications` | **Date**: 2026-09-21 | **Spec**: [spec.md](spec.md)

## Summary
Use server-owned complaint catalogues, ticket histories, SLA timestamps, and notification records behind the existing ComplaintsService.

## Technical Context
- **Language/Version**: Dart/Flutter and plain Dart
- **Dependencies**: HTTP, PostgreSQL prototype store, Provider
- **Storage**: complaint types/targets/tickets/events and notifications
- **Testing**: Flutter service/view tests and prototype server complaint tests
- **Target Platform**: Android/iOS portrait-first
- **Project Type**: Flutter mobile plus local prototype API
- **Constraints**: account isolation, timestamp-derived SLA states, no fake success
- **Scale/Scope**: complaints list/detail/create and notifications

## Constitution Check
Pass: existing service boundary is retained and all user-visible text remains localizable at UI level.

## Project Structure
```text
lib/features/complaints/{data,ui}/
db/migrations/005_complaints_and_notifications.sql
prototype_server/lib/{data,routes}/complaints_*
test/features/complaints/
prototype_server/test/routes/complaints_test.dart
```

## Design Decisions
- Return null/error states on unreachable server rather than empty successful data where persistence matters.
- Keep SLA promises copied to each complaint at creation.
- Restrict notification navigation to existing routes.

## Complexity Tracking
None.
