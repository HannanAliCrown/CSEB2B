# Implementation Plan: Space and Chat

**Branch**: `006-space-chat` | **Date**: 2026-09-21 | **Spec**: [spec.md](spec.md)

## Summary
Deliver role-filtered Crown Solar broadcasts and partner/department messaging through the existing SpaceRepository and ChatRepository boundaries.

## Technical Context
- **Language/Version**: Dart/Flutter and plain Dart
- **Dependencies**: Provider, HTTP, PostgreSQL prototype store
- **Storage**: Space posts/hearts/comments and chat threads/messages
- **Testing**: Flutter repository tests and prototype server social route tests
- **Target Platform**: Android/iOS portrait-first
- **Project Type**: Flutter mobile plus local prototype API
- **Constraints**: Teams app is the only Space publisher; replies are one level
- **Scale/Scope**: Space feed/detail and chat list/thread/new conversation

## Constitution Check
Pass: posting is explicitly external and no publishing service is added to the mobile app.

## Project Structure
```text
lib/features/{space,chat}/{data,ui}/
db/migrations/003_space_and_chat.sql
prototype_server/lib/{data, routes}/social_*
test/features/{space,chat}/
prototype_server/test/routes/social_test.dart
```

## Design Decisions
- Keep feed audience filtering in the data layer.
- Re-read posts/threads after writes so UI reflects persisted state.
- Keep partner and department parties under one chat abstraction.

## Complexity Tracking
None.
