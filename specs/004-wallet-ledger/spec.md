# Feature Specification: Wallet, Cash Requests, and Ledger

**Feature Branch**: `004-wallet-ledger`
**Created**: 2026-09-21
**Status**: Draft
**Input**: Cash transfers, receiver approval/rejection, wallet balances, and transaction history.

## User Scenarios & Testing

### User Story 1 - Send cash (Priority: P1)
A partner selects a recipient and sends a monetary transfer that remains held until the recipient decides.

**Independent Test**: Send a valid transfer and verify sender, receiver, and held states.

**Acceptance Scenarios**
1. Given a valid recipient and sufficient funds, when cash is sent, then the sender debit is held immediately and nothing is written to the receiver's ledger.
2. Given an invalid recipient, self-recipient, insufficient balance, or amount below PKR 100, when sending, then no money moves and a specific error is shown.
3. Given an installer's number, when it is looked up as a recipient, then no recipient is found.

### User Story 2 - Decide a cash request (Priority: P1)
A receiving partner approves or rejects a pending transfer from the Cash Requests inbox.

**Independent Test**: Approve and reject separate held transfers and inspect both wallets.

**Acceptance Scenarios**
1. Given a held request, when approved, then the sender's held debit clears and a cleared credit is written to the approver's wallet.
2. Given a held request, when rejected, then the sender's debit is marked rejected and no longer counts against their balance, and the receiver is not credited.
3. Given an already-decided or unrelated request, when a decision is submitted, then no state changes and the request is reported as not waiting.

### User Story 3 - Review ledger (Priority: P2)
A partner reviews credits, debits, held entries, and historical balances.

**Independent Test**: Apply each filter and compare rows and totals with the wallet source.

**Acceptance Scenarios**
1. Given ledger entries, when filtered by date range, direction, or type, then only matching rows display.
2. Given a held debit, when running balances are calculated, then it reduces available funds but has no settled balance-after value.

## Edge Cases
- Integer paisa arithmetic must not round money.
- Repeated requests must not apply a decision twice.
- A server failure must not be represented as a successful transfer or decision.
- Two transfers sent at once must not both pass a balance check only one could afford.

## Requirements
- **FR-001**: The wallet MUST represent money as whole paisa.
- **FR-002**: The minimum transfer MUST be PKR 100.
- **FR-003**: A transfer MUST be held until receiver approval or rejection; only the sender's debit is written when it is sent.
- **FR-004**: Approval MUST clear the sender's held debit and write a cleared credit to the approving receiver's wallet.
- **FR-005**: Rejection MUST return the amount to the sender by marking the sender's debit rejected, which excludes it from their balance; no separate return entry is written.
- **FR-006**: The ledger MUST show credits, debits, held state, filters (date range: This month (default), Last 60 days, Everything, or a custom inclusive range; direction; one or more types), and running balances computed over the full history.
- **FR-007**: The ledger MUST support CSV export of the visible rows via the share sheet; PDF export is deferred.
- **FR-008**: Available balance MUST equal cleared credits minus every debit that is not rejected; the held total is the sum of held debits; the ledger balance is available plus held. No balance is stored.
- **FR-009**: Only retailers, wholesalers, and distributors with a display name MUST be offered or resolved as cash recipients; installers cannot receive cash. Previously paid recipients are listed first.
- **FR-010**: Cash requests MUST be listed for the receiving account only, in Waiting, Approved, and Rejected tabs (expired requests appear under Rejected), and each decision MUST be confirmed before it is sent.
- **FR-011**: A decision MUST apply only to a held transfer addressed to the deciding account; anything else changes nothing.
- **FR-012**: The Cash Request tile and its waiting-count badge MUST appear on Home only for roles other than installer.
- **FR-013**: A held transfer MUST record an expiry 7 days after sending, shown to the receiver; returning an undecided transfer to the sender at expiry is (Not implemented).

## Key Entities
- **WalletEntry**: direction, type (send cash, cash request, scan prize, spin prize, returned, CRM adjustment), state (cleared, held, rejected), amount, reference, timestamp, counterparty.
- **CashTransfer**: reference, sender, receiver, amount, note, state (held, accepted, rejected, expired), sent, expiry, and decision time.
- **CashRequest**: a transfer as seen by its receiver, waiting or already decided.

## Success Criteria
- **SC-001**: Valid transfers produce exactly one held sender entry.
- **SC-002**: Approval and rejection produce consistent balances on both sides.
- **SC-003**: Ledger totals reconcile with wallet totals.

## Assumptions
- Equipment/product settlement is out of scope; this feature handles money only.
- Cash moves up the chain: any role may send, only retailer, wholesaler, and distributor may receive. Confirmed by the product owner on 2026-09-24.
