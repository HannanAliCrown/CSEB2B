# Implementation Plan: Inaam Rewards

**Branch**: `010-inaam-rewards` | **Date**: 2026-09-21 | **Spec**: [spec.md](spec.md)

## Summary
Expose configured Spin and Win, item schemes, and reward-program state through the existing server-backed InaamService; keep Teams configuration and monthly jobs external.

## Technical Context
- **Language/Version**: Dart/Flutter and plain Dart
- **Dependencies**: HTTP, PostgreSQL prototype store, wallet transaction support
- **Storage**: spin configs/prizes/history, item schemes/tiers/progress/claims, reward programs/tiers/awards
- **Testing**: prototype server Inaam tests (fake store); no Flutter Inaam tests yet
- **Target Platform**: Android/iOS portrait-first
- **Project Type**: Flutter mobile plus local prototype API
- **Constraints**: atomic prize payment, one item-scheme claim, external monthly evaluation
- **Scale/Scope**: Inaam tab, spin, item schemes, reward program

## Constitution Check
Pass with deviation: no background-job framework is added; deferred operations remain outside this feature. `InaamTab` reads `InaamService` directly through `provider` without a ViewModel.

## Project Structure
```text
lib/features/inaam_baazar/{data,ui}/
lib/app/shell/app_shell.dart
db/migrations/009_inaam_baazar.sql
db/seed/009_inaam_baazar.sql
prototype_server/lib/{data,routes}/*inaam_*
prototype_server/test/routes/inaam_test.dart
```

`spin_screens.dart` and `scheme_screens.dart` are static design-preview boards; the live UI is `inaam_tab.dart`.

## Design Decisions
- Server chooses prize by weight and writes wallet entry with spin/claim state in one transaction.
- Spins are serialised per account by locking the account row; claims rely on the `(scheme, account)` primary key.
- UI presents configured values and clear unavailable/refused states.
- Monthly winner evaluation is documented as an external dependency, not implemented here.

## Complexity Tracking
None.
