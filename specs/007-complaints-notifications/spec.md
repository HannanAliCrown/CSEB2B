# Feature Specification: Complaints and Notifications

**Feature Branch**: `007-complaints-notifications`
**Created**: 2026-09-21
**Status**: Draft
**Input**: Complaint creation/status tracking and in-app notifications.

## User Scenarios & Testing

### User Story 1 - Raise and track a complaint (Priority: P1)
A partner selects a complaint type, subtype, priority, title, and detail, then follows its status and history.

**Independent Test**: Create a complaint and open its detail timeline.

**Acceptance Scenarios**
1. Given a valid catalogue choice, when a complaint is submitted, then a ticket reference and SLA targets are returned.
2. Given a complaint with a response or resolution event, when detail is opened, then the timeline shows the event state and time.
3. Given an invalid subtype or incomplete title/detail, when submitted, then no ticket is created.

### User Story 2 - Read notifications (Priority: P2)
A partner views notifications, unread count, and valid destinations.

**Independent Test**: Load notifications, open a supported destination, and mark one/all read.

## Edge Cases
- A complaint reference belonging to another account must not be disclosed.
- Notification destinations not implemented by the app must not navigate nowhere.
- SLA overdue state is based on stored timestamps.

## Requirements
- **FR-001**: The system MUST provide complaint categories, subtypes, priorities, and SLA targets.
- **FR-002**: The system MUST require a title and detail for a complaint.
- **FR-003**: The system MUST retain complaint history and response/resolution timestamps.
- **FR-004**: Notifications MUST expose unread count and read state.
- **FR-005**: Notifications MUST navigate only to supported destinations.

## Key Entities
- **ComplaintCategory**, **ComplaintSubtype**, **ComplaintTarget**, **Complaint**, **ComplaintEvent**, **AppNotification**.

## Success Criteria
- **SC-001**: A valid complaint receives a stable reference and target timestamps.
- **SC-002**: Complaint list and detail expose consistent status counts.
- **SC-003**: Marking notifications read updates the unread count.

## Assumptions
- Native push delivery is deferred; this feature covers persisted/in-app notifications.
