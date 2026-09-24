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
2. Given a request, when detail opens, then applicant/business details, shop pin, the other buying sources named, and non-CNIC media appear, but CNIC data does not.
3. Given no requests, when Home loads, then no pending badge appears.
4. Given an applicant named more than one buying source, when they submit, then only the first buying source is notified and sees the request; later sources see nothing.

### User Story 2 - Approve or reject (Priority: P1)
The buying source records an approval with expected purchasing or rejects with a reason.

**Independent Test**: Submit valid approval and rejection decisions and verify validation.

**Acceptance Scenarios**
1. Given an outstanding request, when approval includes an expected-purchase band, then the decision is recorded.
2. Given an outstanding request, when rejection includes a reason, then the decision is recorded and the application ends as rejected.
3. Given missing approval expectation or rejection reason, then no decision is recorded.
4. Given an already decided request, when another decision is attempted, then no state changes.
5. Given a buying source named after the first, when they attempt a decision, then no state changes.
6. Given the first buying source approves, when the applicant opens Approval Status, then the buying source row shows as approved.

## Edge Cases
- Installers cannot receive buying-source approval requests: the wizard lookup marks an installer number as not an eligible buying source, and Home shows installers no New Profile tile.
- Unknown account/request must not disclose another partner's data; deciding someone else's request answers `not_outstanding` (404), not forbidden.
- A request must not be decided twice.
- An unreachable server shows "Could not reach Crown Solar" rather than an empty inbox; the Home badge falls back to no badge.

## Requirements
- **FR-001**: The system MUST show outstanding requests only to the first buying source the applicant named. Later buying sources MUST NOT receive the request or its notification.
- **FR-002**: The system MUST exclude CNIC number and CNIC images from request details.
- **FR-003**: Approval MUST require an expected-purchase selection.
- **FR-004**: Rejection MUST require a reason.
- **FR-005**: A decision MUST be single-use and durable.
- **FR-006**: Pending request count MUST be available for Home badges.
- **FR-007**: Only the first buying source's decision is required and accepted. Once they approve, the buying source approval MUST show as approved on the applicant's Approval Status.
- **FR-008**: A buying-source rejection MUST end the application (status `rejected`). An approval MUST change only the buying-source approval; Marketing Officer and CRM remain outstanding.
- **FR-009**: Each outstanding approval on the applicant's Approval Status MUST offer a Call action that opens the phone dialer. The dialer currently receives placeholder `0000000000`; using a stored number per approver is (Not implemented).
- **FR-010**: On the registration Buying Source step, a source number MUST be looked up automatically once it is fully entered, with no search action: 11 digits starting with 0, 12 starting with 92, 13 starting with +92, or 10 without a prefix (0, 92, and +92 are equivalent). A partial number MUST NOT be looked up. A match shows the source's details; otherwise the existing not-found or ineligible message is shown.

## Key Entities
- **ProfileRequest**, **ProfileRequestMedia**, **ExpectedPurchaseBand**, **ProfileDecision**.

## Success Criteria
- **SC-001**: A buying source sees only its own outstanding requests.
- **SC-002**: Invalid approval/rejection inputs create no decisions.
- **SC-003**: Completed decisions disappear from the outstanding inbox.

## Assumptions
- MO and CRM approval steps remain part of the separate Team App workflow.
- Calling an approver opens the phone dialer with placeholder `0000000000` until Crown Solar supplies per-role numbers.
- Media photos are not viewable by the buying source: they remain on the applicant's phone until file upload exists, so only video links open.
