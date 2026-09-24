---
description: "Tasks for product scanning and prizes"
---

# Tasks: Product Scanning and Prizes

## Phase 1: Existing Foundation
- [x] T001 [P] Retain scanner models and modes in `lib/features/scan/data/scan_repository.dart`.
- [x] T002 [P] Retain product, claim, prize, and wallet schema in `db/migrations/006_cash_and_scan.sql`.

## Phase 2: User Story 1 - Check Authenticity
- [x] T003 [US1] Keep authenticity checks non-mutating in `lib/features/scan/data/http_scan_repository.dart` and `prototype_server/lib/data/postgres_scan_data_store.dart`.
- [x] T004 [US1] Expose genuine, blocked, not recognised, already scanned (Scan To Win only), and unchecked outcomes in `lib/features/scan/ui/views/scan_screen.dart`.
- [x] T005 [US1] Test authenticity does not create claims or wallet entries in `test/features/scan/scan_repository_test.dart` and `prototype_server/test/routes/wallet_test.dart`.

## Phase 3: User Story 2 - Claim Prize
- [x] T006 [US2] Enforce Installer/Retailer prize eligibility and Wholesaler/Distributor authenticity-only behavior in `prototype_server/lib/data/postgres_scan_data_store.dart`.
- [x] T007 [US2] Persist claim and prize wallet credit in one transaction in `prototype_server/lib/data/postgres_scan_data_store.dart`, served by `prototype_server/lib/routes/wallet_routes.dart`.
- [x] T008 [US2] Test duplicate claims and prize credit in `prototype_server/test/routes/wallet_test.dart`.

## Phase 4: Polish
- [ ] T009 [P] Verify physical scanner failure/unavailable messaging in `lib/core/scanner/qr_scanner_screen.dart` and `lib/features/scan/ui/views/scan_screen.dart`.
- [ ] T010 Run scan scenarios for all four roles from `specs/005-product-scanning/quickstart.md`.

## Dependencies
- US2 depends on product/claim state from US1.

## MVP
US1: authenticity checks; US2 adds prize claims.
