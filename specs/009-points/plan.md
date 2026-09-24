# Implementation Plan: Points and Targets

**Branch**: `009-points` | **Date**: 2026-09-21 | **Spec**: [spec.md](spec.md)

## Summary
Use the points-specific ledger and configurable role rules to support manual transfers and target reporting without automatic 1% accrual.

## Technical Context
- **Language/Version**: Dart/Flutter and plain Dart
- **Dependencies**: HTTP, PostgreSQL prototype store, Provider
- **Storage**: point entries, role transfer rules, restrictions, schemes, periods, extras; the app uses `PointsService` against the prototype API only (no in-memory implementation)
- **Testing**: prototype server points tests; Flutter points tests (Not implemented)
- **Target Platform**: Android/iOS portrait-first
- **Project Type**: Flutter mobile plus local prototype API
- **Constraints**: points/cash separation; manual points; company-managed scheme data
- **Scale/Scope**: points hub, ledger, transfers, targets

## Constitution Check
Pass: no SAP integration or speculative automation is introduced; company operations remain the source of configuration. Deviation: the points screens read `PointsService` directly, without ViewModels.

## Project Structure
```text
lib/features/points/data/points_service.dart
lib/features/points/ui/views/{points_tab,points_ledger_screen,send_points_screen,targets_screen}.dart
db/migrations/007_points_and_targets.sql
db/seed/007_points_and_targets.sql
prototype_server/lib/data/{points_data_store,postgres_points_data_store}.dart
prototype_server/lib/routes/points_routes.dart
prototype_server/test/routes/points_test.dart
prototype_server/test/support/fake_points_data_store.dart
```

## Design Decisions
- Keep transfer permission checks server-side.
- Compute target scoring from qualifying point-entry types.
- Treat missing scheme as a first-class UI state.
- Write both transfer legs in one transaction under the sender's account lock.
- Filter the full points ledger on the device; the server returns it whole.

## Complexity Tracking
None.
