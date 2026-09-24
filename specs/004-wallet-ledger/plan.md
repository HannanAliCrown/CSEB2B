# Implementation Plan: Wallet, Cash Requests, and Ledger

**Branch**: `004-wallet-ledger` | **Date**: 2026-09-21 | **Spec**: [spec.md](spec.md)

## Summary
Use one wallet ledger as the source for available balance, held amount, transfers, receiver decisions, and ledger presentation.

## Technical Context
- **Language/Version**: Dart/Flutter and plain Dart prototype server
- **Dependencies**: Provider, HTTP, PostgreSQL prototype store, path_provider for CSV export, share_plus for sharing it
- **Storage**: PostgreSQL wallet entries and cash transfers; the app uses `HttpWalletRepository` only, and `MockWalletRepository` backs the Flutter tests
- **Testing**: Flutter ViewModel tests and prototype server wallet tests
- **Target Platform**: Android/iOS portrait-first
- **Project Type**: Flutter mobile plus local prototype API
- **Constraints**: paisa arithmetic, atomic transfer decisions, no product settlement
- **Scale/Scope**: wallet, send cash, cash requests, ledger

## Constitution Check
Pass: reuses WalletRepository and existing data stores; no new domain layer. Deviation: the Cash Requests screen reads `CashRequestsService` directly, without a ViewModel.

## Project Structure
```text
lib/features/wallet/data/{wallet_repository,http_wallet_repository,cash_requests_service}.dart
lib/features/wallet/ui/{wallet_view_model,ledger_view_model}.dart
lib/features/wallet/ui/views/{send_cash_screen,ledger_screen,cash_requests_screen}.dart
db/migrations/002_dashboard.sql
db/migrations/006_cash_and_scan.sql
db/migrations/008_profile_requests_and_cash_requests.sql
db/seed/002_dashboard.sql
db/seed/008_profile_requests_and_cash_requests.sql
prototype_server/lib/data/{wallet_data_store,postgres_wallet_data_store}.dart
prototype_server/lib/routes/wallet_routes.dart
test/features/wallet/
prototype_server/test/routes/wallet_test.dart
prototype_server/test/support/fake_wallet_data_store.dart
```

## Design Decisions
- Keep PKR 100 minimum and held-transfer semantics in the repository/server.
- Derive totals from wallet entries, not duplicated balance state.
- Write the receiver's credit only on approval; express rejection by marking the sender's debit rejected.
- Guard decisions with a single conditional update (held, addressed to the decider) so a second decision changes nothing.
- Lock the sender's account row while checking balance and writing the debit.
- Retain CSV export; PDF is explicitly deferred.

## Complexity Tracking
None.
