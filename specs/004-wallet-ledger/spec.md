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
1. Given a valid recipient and sufficient funds, when cash is sent, then the sender debit is held immediately.
2. Given an invalid recipient, self-recipient, insufficient balance, or amount below PKR 100, when sending, then no money moves and a specific error is shown.

### User Story 2 - Decide a cash request (Priority: P1)
A receiving partner approves or rejects a pending transfer.

**Independent Test**: Approve and reject separate held transfers and inspect both wallets.

**Acceptance Scenarios**
1. Given a held request, when approved, then the receiver is credited and the sender transfer settles.
2. Given a held request, when rejected, then the sender is returned the amount and the receiver is not credited.
3. Given an already-decided or unrelated request, when a decision is submitted, then no state changes.

### User Story 3 - Review ledger (Priority: P2)
A partner reviews credits, debits, held entries, and historical balances.

**Independent Test**: Apply each filter and compare rows and totals with the wallet source.

**Acceptance Scenarios**
1. Given ledger entries, when filtered by direction or type, then only matching rows display.
2. Given a held debit, when running balances are calculated, then it reduces available funds but has no settled balance-after value.

## Edge Cases
- Integer paisa arithmetic must not round money.
- Repeated requests must not apply a decision twice.
- A server failure must not be represented as a successful transfer.

## Requirements
- **FR-001**: The wallet MUST represent money as whole paisa.
- **FR-002**: The minimum transfer MUST be PKR 100.
- **FR-003**: A transfer MUST be held until receiver approval or rejection.
- **FR-004**: Approval MUST credit the receiver and settle the sender debit.
- **FR-005**: Rejection MUST return the amount to the sender.
- **FR-006**: The ledger MUST show credits, debits, held state, filters, and running balances.
- **FR-007**: The ledger MUST support CSV export; PDF export is deferred.

## Key Entities
- **WalletEntry**: direction, type, state, amount, reference, timestamp.
- **CashTransfer**: sender, receiver, amount, state, decision time.
- **CashRequest**: a transfer awaiting receiver action.

## Success Criteria
- **SC-001**: Valid transfers produce exactly one held sender entry.
- **SC-002**: Approval and rejection produce consistent balances on both sides.
- **SC-003**: Ledger totals reconcile with wallet totals.

## Assumptions
- Equipment/product settlement is out of scope; this feature handles money only.
- Existing role recipient behavior is retained as currently implemented.
