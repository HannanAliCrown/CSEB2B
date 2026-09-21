# Feature Specification: Profile Approval Requests

**Feature Branch**: `011-profile-approval-requests`
**Created**: 2026-09-21
**Status**: Draft
**Input**: Buying-source inbox for new Installer/Retailer registrations.

## User Scenarios & Testing

### User Story 1 - Review pending requests (Priority: P1)
A Retailer, Wholesaler, or Distributor reviews registration requests that selected them as a buying source.

**Independent Test**: Seed a pending request and verify the inbox excludes CNIC number/images.

**Acceptance Scenarios**
1. Given pending requests, when the inbox opens, then only requests assigned to the signed-in buying source appear.
2. Given a request, when detail opens, then applicant/business/media details appear but CNIC data does not.
3. Given no requests, when Home loads, then no pending badge appears.

### User Story 2 - Approve or reject (Priority: P1)
The buying source records an approval with expected purchasing or rejects with a reason.

**Independent Test**: Submit valid approval and rejection decisions and verify validation.

**Acceptance Scenarios**
1. Given an outstanding request, when approval includes an expected-purchase band, then the decision is recorded.
2. Given an outstanding request, when rejection includes a reason, then the decision is recorded.
3. Given missing approval expectation or rejection reason, then no decision is recorded.
4. Given an already decided request, when another decision is attempted, then no state changes.

## Edge Cases
- Installers cannot receive buying-source approval requests.
- Unknown account/request must not disclose another partner's data.
- A request must not be decided twice.

## Requirements
- **FR-001**: The system MUST show outstanding requests only to the selected buying source.
- **FR-002**: The system MUST exclude CNIC number and CNIC images from request details.
- **FR-003**: Approval MUST require an expected-purchase selection.
- **FR-004**: Rejection MUST require a reason.
- **FR-005**: A decision MUST be single-use and durable.
- **FR-006**: Pending request count MUST be available for Home badges.

## Key Entities
- **ProfileRequest**, **ProfileRequestMedia**, **ExpectedPurchaseBand**, **ProfileDecision**.

## Success Criteria
- **SC-001**: A buying source sees only its own outstanding requests.
- **SC-002**: Invalid approval/rejection inputs create no decisions.
- **SC-003**: Completed decisions disappear from the outstanding inbox.

## Assumptions
- MO and CRM approval steps remain part of the separate Team App workflow.
- Calling an approver uses the phone dialer with the stored number.
