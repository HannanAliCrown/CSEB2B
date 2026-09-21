# Implementation Plan: Product Scanning and Prizes

**Branch**: `005-product-scanning` | **Date**: 2026-09-21 | **Spec**: [spec.md](spec.md)

## Summary
Keep authenticity validation separate from prize claiming and make product claims/wallet credits authoritative in the prototype data store.

## Technical Context
- **Language/Version**: Dart/Flutter and plain Dart
- **Dependencies**: mobile scanner plugin, HTTP, PostgreSQL prototype store
- **Storage**: products, scan claims, prize rules, wallet entries
- **Testing**: Flutter scanner tests and prototype server scan tests
- **Target Platform**: Android/iOS portrait-first
- **Project Type**: Flutter mobile plus local prototype API
- **Constraints**: Wholesaler/Distributor authenticity only; claim/payment consistency
- **Scale/Scope**: scanner intro, scan modes, outcomes, wallet credit

## Constitution Check
Pass: existing ScanRepository boundary and server data store are preserved.

## Project Structure
```text
lib/features/scan/{data,ui}/
db/migrations/006_cash_and_scan.sql
prototype_server/lib/data/postgres_scan_data_store.dart
prototype_server/lib/routes/wallet_routes.dart
test/features/scan/
prototype_server/test/routes/scan_test.dart
```

## Design Decisions
- Authenticity requests never mutate claims or wallet.
- Prize eligibility remains role/configuration data, not UI assumptions.
- Preserve distinct blocked, unknown, claimed, genuine, and unchecked states.

## Complexity Tracking
None.
