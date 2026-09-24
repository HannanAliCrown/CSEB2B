# Feature Specification: Product Scanning and Prizes

**Feature Branch**: `005-product-scanning`
**Created**: 2026-09-21
**Status**: Draft
**Input**: Product authenticity checks and Scan To Win prizes.

## User Scenarios & Testing

### User Story 1 - Check authenticity (Priority: P1)
A partner scans a Crown Solar product code to learn whether it is genuine, blocked, or not recognised, or that it could not be checked. An authenticity check never reports who claimed a code.

**Independent Test**: Scan representative genuine, unknown, and blocked codes, and a code with the server unreachable.

### User Story 2 - Claim a prize (Priority: P1)
An eligible Installer or Retailer scans a winning code and receives the configured prize in the cash wallet.

**Independent Test**: Claim a winning code once per eligible role and verify the wallet entry.

**Acceptance Scenarios**
1. Given an authenticity scan, when a code is checked, then no claim or wallet credit is created.
2. Given an Installer or Retailer and an unclaimed winning code, when Scan To Win completes, then the code is claimed and the prize is credited.
3. Given a Wholesaler or Distributor, when the scanner opens, then only Authenticity Check is offered; if Scan To Win is requested anyway, no prize is awarded and no claim is taken.
4. Given a code already claimed for the same role, when scanned again in Scan To Win, then it is refused as already scanned, naming the claimant, without another credit.
5. Given an Installer or Retailer and a genuine code that pays nothing, when Scan To Win completes, then the role's claim is still taken and no credit is made.

## Edge Cases
- Not recognised (no product row), blocked (withdrawn batch, still named), and unchecked (network error or non-200 response) remain distinct.
- A code may be claimed once per role: one Installer claim and one Retailer claim per product.
- Two simultaneous claims in the same role: the database unique key admits one; the other is answered as already scanned.
- Prize credit and claim persistence are written in one transaction and must agree.
- Camera permission refused: the scanner shows a refusal state with a retry.

## Requirements
- **FR-001**: The scanner MUST provide separate Authenticity Check and Scan To Win journeys; Installers and Retailers see both as tabs (Scan To Win by default), other roles see no tabs.
- **FR-002**: Authenticity checks MUST never claim a product or credit money.
- **FR-003**: Wholesalers and Distributors MUST be restricted to authenticity checks: their role has no prize rule, so they win nothing and take no claim.
- **FR-004**: Eligible prizes MUST be credited to the cash wallet as a cleared `scan_prize` entry.
- **FR-005**: The system MUST distinguish genuine, already scanned, blocked, not recognised, and unchecked outcomes; already scanned is only returned by Scan To Win.
- **FR-006**: The prize amount MUST come from the role's `scan_prize_rules` row, and whether a code pays from the product's `wins_prize` flag.
- **FR-007**: A live Reward Program award for the partner and product MUST add its bonus percentage to the paid prize.
- **FR-008**: An already scanned result MUST show the claimant's name, role, and claim date.
- **FR-009**: Codes MUST be read by the camera (QR only) or by tapping a listed sample code, and be trimmed and upper-cased before checking.
- **FR-010**: The scan intro MUST supply the role's prize amount and sample codes with per-partner meanings; the Scan To Win notice quotes an amount only when the server supplied one.
- **FR-011**: A credited prize MUST notify the wallet so Home and the ledger reload.

## Key Entities
- **Product**: code, name, batch, plant, made-on date, state (active/blocked), wins-prize flag.
- **ScanPrizeRule**: role and configured prize amount.
- **ScanClaim**: product, role (copied at claim time), account, timestamp, prize, wallet entry.
- **ScanOutcome**: mode, verdict, product, claim, prize.

## Success Criteria
- **SC-001**: Authenticity checks never change wallet or claim state.
- **SC-002**: A valid winning scan creates one wallet credit and one role claim.
- **SC-003**: Ineligible roles cannot receive scan prizes.

## Assumptions
- Prize values and eligibility configuration come from Crown Solar data (`scan_prize_rules`, `products`).
- Teams App administration is outside this mobile feature.
- The scanner always uses `prototype_server` (`GET /scan/intro`, `POST /scan`), regardless of `DATA_SOURCE`.
