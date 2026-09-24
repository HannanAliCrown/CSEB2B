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
1. Given a post audience, when a partner opens Space, then only published posts intended for that role appear, newest first.
2. Given a visible post, when the partner hearts it, then the heart count and personal state toggle.
3. Given a visible post, when a partner adds a comment or a reply to a top-level comment, then it appears in the post once the server has stored it.
4. Given a post, when Share is selected, then the share sheet opens with the post's title, body, and "— Crown Solar Energy"; if no share sheet is available, the text is copied to the clipboard.

### User Story 2 - Use chat (Priority: P1)
A partner reads, filters, starts, and sends messages to other partners or Crown Solar departments.

**Independent Test**: Open a partner and department thread, send a message, and mark it read.

**Acceptance Scenarios**
1. Given threads, when filtered by All, Read, or Unread, then the list matches unread state.
2. Given a valid partner or department, when a thread is opened, then it is created if absent and its unread badge is cleared.
3. Given a non-empty message, when sent, then it appears in the conversation, the thread moves to the top of the list, and it counts as unread for the other party only.
4. Given a number, contact, or scanned profile QR that belongs to no registered account, when the partner tries to open a chat, then "No Crown Solar account uses this number." is shown and no thread is created.

## Edge Cases
- Empty comments/messages must be rejected (whitespace-only counts as empty).
- Replies remain one level deep; a reply to a reply is refused by the server (409) and the app offers Reply only on top-level comments.
- Space posts are not authored by this mobile app.
- A partner cannot open a conversation with themselves.
- An account registered after seeding starts with an empty chat list; accounts present at seed time start with CRM and Branding threads.

## Requirements
- **FR-001**: Space MUST filter posts by audience and published state: `all` reaches everyone, `installer` installers, `retailer` retailers, and `trade` wholesalers and distributors.
- **FR-002**: Space MUST support hearts, comments, one-level replies, and share text.
- **FR-003**: The mobile app MUST NOT create Space posts; Teams/Crown Solar publishing remains authoritative.
- **FR-004**: Chat MUST support partner and department conversations.
- **FR-005**: Chat MUST support All, Read, and Unread views.
- **FR-006**: Chat MUST reject empty messages.
- **FR-007**: Heart counts and "hearted by me" MUST be derived from one heart row per partner per post.
- **FR-008**: Comments and replies MUST record the author's business name and show an "Admin" tag when written by Crown Solar.
- **FR-009**: A comment or reply MUST appear only after the server accepts it, and the post detail MUST re-read the stored post.
- **FR-010**: New conversations MUST be startable from synced contacts, a scanned profile QR, a typed mobile number, or the department list (CRM, Branding, Technical Support, Accounts).
- **FR-011**: A partner address MUST resolve only to a registered account; any `dept:<name>` address always resolves.
- **FR-012**: Opening a conversation MUST mark it read; unread MUST be the count of messages from the other party after the partner's read mark.
- **FR-013**: The thread list MUST be ordered by latest message, newest first, and show a "You:" prefix when the partner spoke last.
- **FR-014**: The partner's own messages MUST show their status (Sending, Sent, Delivered, Read).

## Key Entities
- **SpacePost**, **PostComment**, **PostReply**, **ChatThread**, **ChatMessage**, **ChatParty**, **Department**.

## Success Criteria
- **SC-001**: Every role sees only permitted Space content.
- **SC-002**: A reaction or comment is reflected when the post is reloaded.
- **SC-003**: A sent chat message is visible in its thread after refresh.

## Assumptions
- Team publishing is an external responsibility.
- Department replies are written into the chat store by Crown Solar outside this app; the app has no department-side interface.
- Contact sync itself belongs to the profile feature; this feature consumes the saved matched contacts and the shared QR scanner.
