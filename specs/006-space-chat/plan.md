# Implementation Plan: Space and Chat

**Branch**: `006-space-chat` | **Date**: 2026-09-21 | **Spec**: [spec.md](spec.md)

## Summary
Deliver role-filtered Crown Solar broadcasts and partner/department messaging through the existing SpaceRepository and ChatRepository boundaries.

## Technical Context
- **Language/Version**: Dart/Flutter and plain Dart
- **Dependencies**: Provider, HTTP, share_plus, PostgreSQL prototype store
- **Storage**: Space posts/hearts/comments and chat threads/messages/read marks
- **Testing**: Flutter repository tests and prototype server social route tests
- **Target Platform**: Android/iOS portrait-first
- **Project Type**: Flutter mobile plus local prototype API
- **Constraints**: Teams app is the only Space publisher; replies are one level
- **Scale/Scope**: Space feed/detail and chat list/thread/new conversation
- **Data source**: Chat is always server-backed (`HttpChatRepository`); Space uses `HttpSpaceRepository` only when `DATA_SOURCE=server`, otherwise `MockSpaceRepository`.

## Constitution Check
Pass: posting is explicitly external and no publishing service is added to the mobile app.

## Project Structure
```text
lib/features/space/{data,ui}/
lib/features/chat/{data,ui}/
db/migrations/003_space_and_chat.sql
db/seed/003_space_and_chat.sql
prototype_server/lib/data/{social_data_store,social_models,postgres_social_data_store}.dart
prototype_server/lib/routes/social_routes.dart
test/features/{space,chat}/
prototype_server/test/routes/social_test.dart
```

## Design Decisions
- Keep feed audience filtering in the data layer (server SQL; mock repository in the mock build).
- Re-read posts/threads after writes so UI reflects persisted state.
- Keep partner and department parties under one chat abstraction, addressed by national digits or `dept:<name>`.
- Store each conversation once per sorted party pair; derive unread from read marks rather than a counter.
- Enforce one-level replies with a database trigger.

## Complexity Tracking
None.
