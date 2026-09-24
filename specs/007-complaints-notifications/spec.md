# Feature Specification: Complaints and Notifications

**Feature Branch**: `007-complaints-notifications`
**Created**: 2026-09-21
**Status**: Draft
**Input**: Complaint creation/status tracking and in-app notifications.

## User Scenarios & Testing

### User Story 1 - Raise and track a complaint (Priority: P1)
A partner selects a complaint category and priority, writes a title and detail in their own words, reviews, submits, then follows its status and history.

**Independent Test**: Create a complaint and open its detail timeline.

**Acceptance Scenarios**
1. Given a valid category and priority, when a complaint is submitted, then a ticket reference (`CMP-YYYY-NNNN`) and the SLA targets copied at creation are returned.
2. Given a complaint with a response or resolution event, when detail is opened, then the timeline shows the event state and time.
3. Given an unknown category, a priority with no target, or an empty title/detail, when submitted, then no ticket is created.
4. Given a raised complaint, when the notification list is loaded, then it contains a "Complaint <reference> raised" notification that opens the complaint detail.

### User Story 2 - Read notifications (Priority: P2)
A partner views notifications, unread count, and valid destinations.

**Independent Test**: Load notifications, open a supported destination, and mark one/all read.

**Acceptance Scenarios**
1. Given unread notifications, when the list opens, then the unread count is shown and Mark all read is offered.
2. Given an unread notification, when it is tapped, then it is marked read before any navigation.
3. Given a notification whose destination is not supported, when it is tapped, then the app stays put and says "<destination> is not built yet."

## Edge Cases
- A complaint reference belonging to another account must not be disclosed (not found, not forbidden).
- Notification destinations not implemented by the app must not navigate nowhere.
- SLA overdue state is based on stored timestamps.
- When the server is unreachable, the list, detail, and notifications say so instead of showing empty data, and a failed submission reports that nothing was sent.

## Requirements
- **FR-001**: The system MUST provide complaint categories, priorities (low, medium, high), and SLA targets per category and priority. There are no sub-types.
- **FR-002**: The system MUST require a title and detail for a complaint.
- **FR-003**: The system MUST retain complaint history and response/resolution timestamps.
- **FR-004**: Notifications MUST expose unread count and read state.
- **FR-005**: Notifications MUST navigate only to supported destinations: `/wallet/ledger` and `/complaints/<reference>`.
- **FR-006**: The wizard MUST state the response and resolution targets for the chosen category and priority before submission.
- **FR-007**: A complaint MUST copy its response and resolution targets at creation; the resolution due date MUST count working days, skipping Sundays.
- **FR-008**: Raising a complaint MUST write a "Complaint raised" history event and a notification linking to its detail.
- **FR-009**: While in progress, a complaint's timeline MUST end with a derived "Awaiting resolution" active step.
- **FR-010**: The complaints list MUST separate In Progress and Resolved tickets, with a count on each tab.
- **FR-011**: Complaint detail MUST show response and resolution target status (response: Met, Late, Overdue, or Waiting; resolution: Resolved, Resolved late, Overdue, or In progress) and offer a CRM chat.
- **FR-012**: Home MUST show the notification unread count on its bell.

## Key Entities
- **ComplaintCategory**, **ComplaintTarget**, **Complaint**, **ComplaintEvent**, **AppNotification**.

## Success Criteria
- **SC-001**: A valid complaint receives a stable reference and target timestamps.
- **SC-002**: Complaint list and detail expose consistent status counts.
- **SC-003**: Marking notifications read updates the unread count.

## Assumptions
- Native push delivery is deferred; this feature covers persisted/in-app notifications.
- Complaint responses, resolution, and later history events are written by Crown Solar (CRM) outside this app.
