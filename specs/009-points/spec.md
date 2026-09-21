# Feature Specification: Points and Targets

**Feature Branch**: `009-points`
**Created**: 2026-09-21
**Status**: Draft
**Input**: Role-controlled points ledger, manual transfers, schemes, quarterly/annual targets, and extras.

## User Scenarios & Testing

### User Story 1 - View points (Priority: P1)
A partner views a points balance, ledger, scheme state, targets, progress, and extra targets.

**Independent Test**: Load a user with and without a signed scheme and compare the target state.

**Acceptance Scenarios**
1. Given no signed scheme, when targets open, then a no-scheme state appears while points remain visible.
2. Given a signed scheme, when targets open, then quarterly and annual targets show progress and status.
3. Given an extra target, when targets open, then it is shown separately from the signed scheme.
4. Points received count toward targets; points sent do not count for the sender.

### User Story 2 - Send points manually (Priority: P1)
A partner sends a manually specified points amount to an allowed recipient.

**Independent Test**: Send valid and refused transfers using configured role rules.

**Acceptance Scenarios**
1. Given an allowed pair and sufficient points, when a transfer is sent, then sender and receiver entries are created immediately.
2. Given a restricted sender/receiver, disallowed pair, self-recipient, unknown recipient, or insufficient balance, then no transfer occurs.

## Edge Cases
- Points are separate from cash and must never be combined.
- No automatic 1% purchase calculation is required.
- Scheme signing is external/manual and one scheme applies per user.

## Requirements
- **FR-001**: Points MUST remain separate from the cash wallet.
- **FR-002**: Transfer permissions MUST be role-pair and account restriction driven.
- **FR-003**: Users MUST be able to send points manually when permitted.
- **FR-004**: Users without a signed scheme MUST retain ledger visibility but have no scheme targets.
- **FR-005**: Targets MUST include quarterly periods, annual target, and company-created extras where present.
- **FR-006**: Target progress MUST count purchases and received points, subtract reversals, and exclude sent points.
- **FR-007**: SAP/Teams administration is outside this mobile feature; no automatic 1% accrual is required.

## Key Entities
- **PointEntry**, **PointTransferRule**, **PointRestriction**, **PointScheme**, **SchemePeriod**, **ExtraTarget**.

## Success Criteria
- **SC-001**: Points ledger and cash ledger never share balances or units.
- **SC-002**: Valid manual transfers reconcile sender and receiver entries.
- **SC-003**: Target progress follows the specified inclusion/exclusion rules.

## Assumptions
- Scheme rows and transfer rules are supplied by company operations.
- Contact/QR selection may resolve through existing app discovery services.
