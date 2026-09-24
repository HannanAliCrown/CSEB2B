# Implementation Plan: Product Scanning and Prizes

**Branch**: `005-product-scanning` | **Date**: 2026-09-21 | **Spec**: [spec.md](spec.md)

## Summary
Keep authenticity validation separate from prize claiming and make product claims/wallet credits authoritative in the prototype data store.

## Technical Context
- **Language/Version**: Dart/Flutter and plain Dart
- **Dependencies**: `mobile_scanner`, `permission_handler`, HTTP, PostgreSQL prototype store
- **Storage**: products, scan claims, prize rules, wallet entries; the app always uses `HttpScanRepository`. `MockScanRepository` is used only by tests.
- **Testing**: `test/features/scan/scan_repository_test.dart` (mock repository) and the `scanning` group in `prototype_server/test/routes/wallet_test.dart`
- **Target Platform**: Android/iOS portrait-first
- **Project Type**: Flutter mobile plus local prototype API
- **Constraints**: Wholesaler/Distributor authenticity only; claim/payment consistency
- **Scale/Scope**: scan screen with modes, camera capture, outcomes, wallet credit

## Constitution Check
Pass: existing ScanRepository boundary and server data store are preserved. `ScanScreen`'s state reads `ScanRepository` directly; no scan ViewModel exists.

## Project Structure
```text
lib/features/scan/data/{scan_repository,http_scan_repository}.dart
lib/features/scan/ui/views/scan_screen.dart
lib/core/scanner/qr_scanner_screen.dart
db/migrations/006_cash_and_scan.sql
db/seed/006_cash_and_scan.sql
prototype_server/lib/data/{scan_data_store,postgres_scan_data_store}.dart
prototype_server/lib/routes/wallet_routes.dart
test/features/scan/scan_repository_test.dart
prototype_server/test/routes/wallet_test.dart
```
`scanner_screens.dart`, `scan_prize_screens.dart`, and `scanner_chrome.dart` are design-preview boards only, not the live flow.

## Design Decisions
- One endpoint, `POST /scan` with `claim` true/false; `claim: false` never mutates claims or wallet.
- Prize eligibility is role/configuration data (`scan_prize_rules`, `wins_prize`), not UI assumptions.
- One claim per product per role is the `scan_claims (product_id, role)` unique key; claim and wallet credit are one transaction.
- Preserve distinct blocked, not recognised, already scanned, genuine, and unchecked states; unchecked is decided on the device on network error or non-200.

## Complexity Tracking
None.
