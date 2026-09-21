# Feature Specification: Product Scanning and Prizes

**Feature Branch**: `005-product-scanning`
**Created**: 2026-09-21
**Status**: Draft
**Input**: Product authenticity checks and Scan To Win prizes.

## User Scenarios & Testing

### User Story 1 - Check authenticity (Priority: P1)
A partner scans a Crown Solar product code to learn whether it is genuine, blocked, unknown, or previously claimed.

**Independent Test**: Scan representative valid, invalid, blocked, and previously claimed codes.

### User Story 2 - Claim a prize (Priority: P1)
An eligible Installer or Retailer scans a winning code and receives the configured prize in the cash wallet.

**Independent Test**: Claim a winning code once per eligible role and verify the wallet entry.

**Acceptance Scenarios**
1. Given an authenticity scan, when a code is checked, then no claim or wallet credit is created.
2. Given an Installer or Retailer and an unclaimed winning code, when Scan To Win completes, then the code is claimed and the prize is credited.
3. Given a Wholesaler or Distributor, when Scan To Win is attempted, then no prize is awarded; authenticity checking remains available.
4. Given a code already claimed for the same role, when scanned again, then it is refused without another credit.

## Edge Cases
- Unrecognized, blocked, and unavailable checks must remain distinct.
- A code may be claimed once per eligible role according to current rules.
- Prize credit and claim persistence must agree.

## Requirements
- **FR-001**: The scanner MUST provide separate Authenticity Check and Scan To Win journeys.
- **FR-002**: Authenticity checks MUST never claim a product or credit money.
- **FR-003**: Wholesalers and Distributors MUST be restricted to authenticity checks for prizes.
- **FR-004**: Eligible prizes MUST be credited to the cash wallet.
- **FR-005**: The system MUST distinguish genuine, already claimed, blocked, unrecognized, and unchecked outcomes.

## Key Entities
- **Product**: code, product identity, batch, status.
- **ScanClaim**: product, role, account, timestamp, prize.
- **ScanOutcome**: mode, verdict, product, claim, prize.

## Success Criteria
- **SC-001**: Authenticity checks never change wallet or claim state.
- **SC-002**: A valid winning scan creates one wallet credit and one role claim.
- **SC-003**: Ineligible roles cannot receive scan prizes.

## Assumptions
- Prize values and eligibility configuration come from Crown Solar data.
- Teams App administration is outside this mobile feature.
