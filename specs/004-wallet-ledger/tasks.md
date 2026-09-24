---
description: "Tasks for wallet, cash requests, and ledger"
---

# Tasks: Wallet, Cash Requests, and Ledger

## Phase 1: Existing Foundation
- [x] T001 [P] Retain paisa-based wallet models in `lib/features/wallet/data/wallet_repository.dart`.
- [x] T002 [P] Retain wallet/cash schema in `db/migrations/002_dashboard.sql`, `db/migrations/006_cash_and_scan.sql`, and `db/migrations/008_profile_requests_and_cash_requests.sql`.

## Phase 2: User Story 1 - Send Cash
- [x] T003 [US1] Validate minimum amount, self-recipient, recipient role, and balance in `prototype_server/lib/data/postgres_wallet_data_store.dart`.
- [x] T004 [US1] Persist held sender debit and transfer in one operation in `prototype_server/lib/data/postgres_wallet_data_store.dart`.
- [x] T005 [US1] Cover recipient selection and review/send states in `lib/features/wallet/ui/wallet_view_model.dart` and `test/features/wallet/wallet_view_model_test.dart`.

## Phase 3: User Story 2 - Decide Cash Request
- [x] T006 [US2] Implement approve/reject settlement in `prototype_server/lib/data/postgres_wallet_data_store.dart`.
- [x] T007 [US2] Expose pending requests and decisions through `prototype_server/lib/routes/wallet_routes.dart`.
- [x] T008 [US2] Test approval, rejection, duplicate, and unrelated request cases in `prototype_server/test/routes/wallet_test.dart`.
- [x] T014 [US2] Show the Waiting/Approved/Rejected inbox with confirmed decisions in `lib/features/wallet/ui/views/cash_requests_screen.dart` via `lib/features/wallet/data/cash_requests_service.dart`.
- [ ] T015 [US2] Return undecided transfers to the sender at `expires_at` in `prototype_server/lib/data/postgres_wallet_data_store.dart` (Not implemented).

## Phase 4: User Story 3 - Review Ledger
- [x] T009 [US3] Implement direction, type, date-range, running-balance, and CSV export behavior in `lib/features/wallet/ui/ledger_view_model.dart`.
- [ ] T010 [US3] Add profile/mobile search and amount filters in `lib/features/wallet/ui/ledger_view_model.dart` and `lib/features/wallet/ui/views/ledger_screen.dart`.
- [ ] T011 [US3] Add Today and This Week presets in `lib/features/wallet/ui/ledger_view_model.dart`.
- [ ] T012 [US3] Add PDF export in `lib/features/wallet/ui/ledger_view_model.dart` only if separately approved; current scope retains CSV.

## Phase 5: Polish
- [ ] T013 Run wallet reconciliation scenarios from `specs/004-wallet-ledger/quickstart.md`.

## Dependencies
- Foundation precedes all stories.
- US2 depends on the transfer model from US1.
- US3 reads the same ledger source as US1/US2.

## MVP
US1 and US2: money can move safely and be decided by the receiver.
