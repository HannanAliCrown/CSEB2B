# Implementation Plan: Wallet, Cash Requests, and Ledger

**Branch**: `004-wallet-ledger` | **Date**: 2026-09-21 | **Spec**: [spec.md](spec.md)

## Summary
Use one wallet ledger as the source for available balance, held amount, transfers, receiver decisions, and ledger presentation.

## Technical Context
- **Language/Version**: Dart/Flutter and plain Dart prototype server
- **Dependencies**: Provider, HTTP, PostgreSQL prototype store, path_provider for CSV export
- **Storage**: PostgreSQL wallet entries and cash transfers; mock repository for local mode
- **Testing**: Flutter ViewModel tests and prototype server wallet tests
- **Target Platform**: Android/iOS portrait-first
- **Project Type**: Flutter mobile plus local prototype API
- **Constraints**: paisa arithmetic, atomic transfer decisions, no product settlement
- **Scale/Scope**: wallet, send cash, cash requests, ledger

## Constitution Check
Pass: reuses WalletRepository and existing data stores; no new domain layer.

## Project Structure
```text
lib/features/wallet/{data,ui}/
db/migrations/002_dashboard.sql
db/migrations/006_cash_and_scan.sql
prototype_server/lib/data/postgres_wallet_data_store.dart
prototype_server/lib/routes/wallet_routes.dart
test/features/wallet/
prototype_server/test/routes/wallet_test.dart
```

## Design Decisions
- Keep PKR 100 minimum and held-transfer semantics in the repository/server.
- Derive totals from wallet entries, not duplicated balance state.
- Retain CSV export; PDF is explicitly deferred.

## Complexity Tracking
None.
