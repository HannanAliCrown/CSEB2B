# Feature Specification: Space and Chat

**Feature Branch**: `006-space-chat`
**Created**: 2026-09-21
**Status**: Draft
**Input**: Crown Solar Space broadcasts and partner/department chat.

## User Scenarios & Testing

### User Story 1 - Read and react to Space (Priority: P1)
A partner reads role-targeted Crown Solar posts and can heart, comment, reply, and share them.

**Independent Test**: Load a feed for each role and exercise each reaction.

**Acceptance Scenarios**
1. Given a post audience, when a partner opens Space, then only posts intended for that role appear.
2. Given a visible post, when the partner hearts it, then the heart count and personal state toggle.
3. Given a visible post, when a partner adds a comment or one-level reply, then it appears in the post.
4. Given a post, when Share is selected, then share text is produced.

### User Story 2 - Use chat (Priority: P1)
A partner reads, filters, starts, and sends messages to other partners or Crown Solar departments.

**Independent Test**: Open a partner and department thread, send a message, and mark it read.

**Acceptance Scenarios**
1. Given threads, when filtered by All, Read, or Unread, then the list matches message state.
2. Given a valid partner or department, when a thread is opened, then it is created if absent.
3. Given a non-empty message, when sent, then it appears in the conversation and unread state updates appropriately.

## Edge Cases
- Empty comments/messages must be rejected.
- Replies remain one level deep.
- Space posts are not authored by this mobile app.

## Requirements
- **FR-001**: Space MUST filter posts by audience and active availability.
- **FR-002**: Space MUST support hearts, comments, one-level replies, and share text.
- **FR-003**: The mobile app MUST NOT create Space posts; Teams/Crown Solar publishing remains authoritative.
- **FR-004**: Chat MUST support partner and department conversations.
- **FR-005**: Chat MUST support All, Read, and Unread views.
- **FR-006**: Chat MUST reject empty messages.

## Key Entities
- **SpacePost**, **PostComment**, **PostReply**, **ChatThread**, **ChatMessage**, **ChatParty**.

## Success Criteria
- **SC-001**: Every role sees only permitted Space content.
- **SC-002**: A reaction or comment is reflected when the post is reloaded.
- **SC-003**: A sent chat message is visible in its thread after refresh.

## Assumptions
- Team publishing is an external responsibility.
- QR/contact discovery may use existing repository boundaries and is not redefined here.
