# Feature Specification: Shop Branding

**Feature Branch**: `012-shop-branding`
**Created**: 2026-09-24
**Status**: Draft
**Input**: Documents the Shop Branding module as implemented (Board 07 · A1–A9): landing, request wizard, eligibility-filtered board types, request history and status. Supersedes the "Branding is deferred" assumption in `specs/003-dashboard`.

## User Scenarios & Testing

### User Story 1 - See branding position (Priority: P1)
A partner opens Shop Branding from the Home tile and sees any live request, recent history, and the eligibility facts (scheme, points, existing board) that decide which boards they are offered.

**Independent Test**: Seed a retailer with a live, a completed and a rejected request; open the landing.

**Acceptance Scenarios**
1. Given a live request, when the landing opens, then a Current Request Status card shows its board summary and stage, and Start a Request is disabled with an explanation.
2. Given past requests, when the landing opens, then up to three appear with reference and status tag, and See all appears when there is more than one.
3. Given the server is unreachable, when the landing opens, then a warning says the figures are not the partner's real position and pull-to-refresh retries.

### User Story 2 - File a request (Priority: P1)
A partner captures a shop photo and visiting card, enters height, width and board count, optionally overrides address/contact/person, then picks a board type for every board and submits.

**Independent Test**: As a signed-scheme retailer, submit two boards of different types and verify one `in_progress` request with two priced boards.

**Acceptance Scenarios**
1. Given either photo or any measurement is missing, then Choose Board Type stays disabled.
2. Given board types are loaded, then each board slot is chosen from a sheet that lists open options with price and locked options with the one condition that would open them.
3. Given a type is picked, then its company/partner split is shown per board and as a combined total before submit.
4. Given exactly one option is open, then every board slot is preselected with it.
5. Given submit succeeds, then a snackbar shows the new `BRD-YYYY-NNNN` reference and the wizard closes back to a reloaded landing.

### User Story 3 - Eligibility-filtered board types (Priority: P1)
The server decides which board types a partner is offered from their role, points balance, signed scheme, recent scanning and existing board.

**Independent Test**: Compare board-type responses for an installer with/without a recent scan, a retailer with/without a scheme, and a partner with a board installed under six months ago.

**Acceptance Scenarios**
1. Given an installer who scanned within the scan window, then Frontlit Board is open; otherwise it is locked and the empty state offers Open Scanner.
2. Given a board installed less than the replacement window ago, then only that board's replacement option is offered, with a notice naming the existing board.
3. Given nothing is open to a non-installer, then the empty state tells them to sign a scheme or earn points and lists the locked options.
4. Given an option closed between loading and submit, when the partner submits, then the request is refused and they are told to pull down for current options.

### User Story 4 - Track a request (Priority: P2)
A partner opens any request to see its three-stage progress (Approved, Board Installed, Call Confirmation) and agreed money split, or the rejection reason.

**Independent Test**: Open the seeded in-progress, completed and rejected requests.

**Acceptance Scenarios**
1. Given an in-progress request, then the timeline marks its current stage and shows total company and partner shares.
2. Given more than one board, then a per-board breakdown is shown.
3. Given a completed request, then a Completed banner appears and all stages read as done.
4. Given a rejected request, then the reason is shown instead of a timeline, with Start a New Request.
5. Given a reference belonging to another account, then Request not found is shown.

## Edge Cases
- Only one `in_progress` request per account; a second submit is refused inside the transaction.
- Board-type count must equal board count.
- Role is not a condition a partner can meet: types with no role row are never shown; types with unmet conditions are shown locked.
- Price and split are copied onto each request board at submit, so later configuration changes do not rewrite history.
- Authenticity checks without a claim do not count as recent scanning.

## Requirements
- **FR-001**: Home's Shop Branding tile MUST open the branding landing for every role.
- **FR-002**: The landing MUST show the live request (if any), the newest three requests, and scheme/points/existing-board eligibility.
- **FR-003**: Starting a request MUST be blocked in the UI while one is in progress, and the server MUST refuse a second live request.
- **FR-004**: Step 1 MUST require shop photo, visiting-card photo (camera), height > 0, width > 0 and board count > 0; address, contact and person are optional.
- **FR-005**: The server MUST filter board types by role, then apply points, signed-scheme and recent-scan conditions from configuration.
- **FR-006**: A board installed within the replacement window MUST collapse options to its replacement type and state why.
- **FR-007**: Locked options MUST show only the first unmet condition in the partner's terms.
- **FR-008**: Each board MAY be a different type; one type MUST be supplied per board.
- **FR-009**: The expense split MUST be shown per board and in total before submit.
- **FR-010**: The server MUST re-check eligibility on submit and refuse unavailable types.
- **FR-011**: Request status and stage MUST be read-only in the app; they are owned by Crown Solar (Teams app).
- **FR-012**: Requests MUST be readable only by the owning account.
- **FR-013**: Rejected requests MUST carry and display a reason.

## Key Entities
- **BrandingConfig**, **BoardType**, **BoardTypeRole**, **Installation**, **BrandingRequest**, **RequestBoard**, **Eligibility**.

## Success Criteria
- **SC-001**: A partner never submits a type the server would not offer at that moment.
- **SC-002**: At most one in-progress request exists per account.
- **SC-003**: Cost split for every board is visible before submit and preserved on the request.

## Assumptions
- Board types, prices, splits, role conditions and windows are configuration owned by the Teams app; the app only reads them.
- Status transitions, rejection and installation records are written by the Teams app.
- Photos are stored as device paths in the prototype; upload is out of scope.
- Default scan window 10 days, replacement window 6 months, company share 60%.
