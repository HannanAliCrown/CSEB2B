---
description: "Tasks for Space and Chat"
---

# Tasks: Space and Chat

## Phase 1: Existing Foundation
- [x] T001 [P] Retain Space/chat entities and repositories in `lib/features/space/data/` and `lib/features/chat/data/`.
- [x] T002 [P] Retain social schema in `db/migrations/003_space_and_chat.sql` and seed in `db/seed/003_space_and_chat.sql`.

## Phase 2: User Story 1 - Space
- [x] T003 [US1] Filter Space feed by audience and published state in `prototype_server/lib/data/postgres_social_data_store.dart`.
- [x] T004 [US1] Support hearts, comments, one-level replies, and share text in `lib/features/space/`.
- [x] T005 [US1] Keep Space post creation absent from mobile routes; Teams remains publisher in `prototype_server/lib/routes/social_routes.dart`.
- [x] T006 [US1] Test feed visibility and one-level reply rules in `prototype_server/test/routes/social_test.dart`.
- [x] T012 [US1] Test audience filtering, hearts, comments, replies, and share text in `test/features/space/space_repository_test.dart`.

## Phase 3: User Story 2 - Chat
- [x] T007 [US2] Support partner and department party resolution in `lib/features/chat/data/`.
- [x] T008 [US2] Support thread open, message send, read marking, and filters in `lib/features/chat/ui/`.
- [x] T009 [US2] Test chat thread/message routes in `prototype_server/test/routes/social_test.dart`.
- [x] T013 [US2] Test thread ordering, party resolution, and read marking in `test/features/chat/chat_repository_test.dart`.

## Phase 4: Polish
- [ ] T010 Verify contacts and QR discovery against real device integrations in `lib/features/chat/data/http_chat_repository.dart` and `lib/features/profile/data/contacts_repository.dart`.
- [ ] T011 Run Space/chat scenarios from `specs/006-space-chat/quickstart.md`.

## Dependencies
- US1 and US2 can proceed after shared social schema; they are otherwise independent.

## MVP
US1 Space feed and reactions.
