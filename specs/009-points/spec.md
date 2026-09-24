# Feature Specification: Points and Targets

**Feature Branch**: `009-points`
**Created**: 2026-09-21
**Status**: Draft
**Input**: Role-controlled points ledger, manual transfers, schemes, four-month/annual targets, and extras.

## User Scenarios & Testing

### User Story 1 - View points (Priority: P1)
A partner views a points balance, ledger, scheme state, targets, progress, and extra targets.

**Independent Test**: Load a user with and without a signed scheme and compare the target state.

**Acceptance Scenarios**
1. Given no signed scheme, when targets open, then a no-scheme state appears while points remain visible.
2. Given a signed scheme, when targets open, then four-month period and annual targets show progress and status.
3. Given an extra target, when targets open, then it is shown separately from the signed scheme, with or without a scheme.
4. Points received count toward targets; points sent do not count for the sender.
5. Given ledger entries, when "See all" is opened and filtered by credit/debit or an inclusive date range, then only matching rows display.

### User Story 2 - Send points manually (Priority: P1)
A partner sends a manually specified points amount to an allowed recipient chosen from contacts, history, or a scanned QR code.

**Independent Test**: Send valid and refused transfers using configured role rules.

**Acceptance Scenarios**
1. Given an allowed pair and sufficient points, when a transfer is sent, then sender and receiver entries sharing one reference are created immediately, with no approval step.
2. Given a restricted sender/receiver, disallowed pair, self-recipient, unknown recipient, non-positive amount, or insufficient balance, then no transfer occurs.
3. Given a send-restricted partner, when Send Points is opened, then the flow is blocked with the restriction reason while balance and ledger stay visible.

## Edge Cases
- Points are separate from cash and must never be combined.
- No automatic 1% purchase calculation is required.
- Scheme signing is external/manual and one scheme applies per user.
- Two transfers sent at once must not both pass a balance check only one could afford.

## Requirements
- **FR-001**: Points MUST remain separate from the cash wallet.
- **FR-002**: Transfer permissions MUST be role-pair and account restriction driven.
- **FR-003**: Users MUST be able to send points manually when permitted.
- **FR-004**: Users without a signed scheme MUST retain ledger visibility but have no scheme targets.
- **FR-005**: Targets MUST include four-month periods, annual target, and company-created extras where present.
- **FR-006**: Target progress MUST count purchases and received points, subtract reversals, and exclude sent points and CRM adjustments.
- **FR-007**: SAP/Teams administration is outside this mobile feature; no automatic 1% accrual is required.
- **FR-008**: The points balance and each entry's balance-after MUST be derived from point entries, never stored.
- **FR-009**: Only recipients in a permitted role pair who are not receive-restricted MUST be offered; there is no search-by-number, and contacts are limited to synced contacts who are permitted recipients.
- **FR-010**: The Points hub MUST show the balance, the running period and annual meters when a scheme exists, and the five most recent entries with "See all" opening the full ledger.
- **FR-011**: The Points tab MUST be shown to retailer, wholesaler, and distributor; installers see Inaam instead.
- **FR-012**: Each target MUST show a status (not started, running, achieved, not met) and the date it was first met; the running period (or the year, if none is running) shows a purchases / transferred-in / reversals breakdown.

## Key Entities
- **PointEntry**, **PointTransferRule**, **PointRestriction**, **PointScheme**, **SchemePeriod**, **ExtraTarget**.

## Success Criteria
- **SC-001**: Points ledger and cash ledger never share balances or units.
- **SC-002**: Valid manual transfers reconcile sender and receiver entries.
- **SC-003**: Target progress follows the specified inclusion/exclusion rules.

## Assumptions
- Scheme rows and transfer rules are supplied by company operations; the seed permits every pair among retailer, wholesaler, and distributor.
- Contact/QR selection resolves through the app's synced contacts and the profile QR scanner.
