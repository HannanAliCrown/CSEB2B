# Implementation Plan: Points and Targets

**Branch**: `009-points` | **Date**: 2026-09-21 | **Spec**: [spec.md](spec.md)

## Summary
Use the points-specific ledger and configurable role rules to support manual transfers and target reporting without automatic 1% accrual.

## Technical Context
- **Language/Version**: Dart/Flutter and plain Dart
- **Dependencies**: HTTP, PostgreSQL prototype store, Provider
- **Storage**: point entries, role transfer rules, restrictions, schemes, periods, extras
- **Testing**: Flutter points tests and prototype server points tests
- **Target Platform**: Android/iOS portrait-first
- **Project Type**: Flutter mobile plus local prototype API
- **Constraints**: points/cash separation; manual points; company-managed scheme data
- **Scale/Scope**: points hub, ledger, transfers, targets

## Constitution Check
Pass: no SAP integration or speculative automation is introduced; company operations remain the source of configuration.

## Project Structure
```text
lib/features/points/{data,ui}/
db/migrations/007_points_and_targets.sql
prototype_server/lib/{data,routes}/points_*
test/features/points/
prototype_server/test/routes/points_test.dart
```

## Design Decisions
- Keep transfer permission checks server-side.
- Compute target scoring from qualifying point-entry types.
- Treat missing scheme as a first-class UI state.

## Complexity Tracking
None.
