# Implementation Plan: Inaam Rewards

**Branch**: `010-inaam-rewards` | **Date**: 2026-09-21 | **Spec**: [spec.md](spec.md)

## Summary
Expose configured Spin and Win, item schemes, and reward-program state through the existing server-backed InaamService; keep Teams configuration and monthly jobs external.

## Technical Context
- **Language/Version**: Dart/Flutter and plain Dart
- **Dependencies**: HTTP, PostgreSQL prototype store, wallet transaction support
- **Storage**: spin configs/prizes/history, item schemes/claims, reward programs
- **Testing**: Flutter Inaam tests and prototype server Inaam tests
- **Target Platform**: Android/iOS portrait-first
- **Project Type**: Flutter mobile plus local prototype API
- **Constraints**: atomic prize payment, one item-scheme claim, external monthly evaluation
- **Scale/Scope**: Inaam tab, spin, item schemes, reward program

## Constitution Check
Pass: no background-job framework is added; deferred operations remain outside this feature.

## Project Structure
```text
lib/features/inaam_baazar/{data,ui}/
db/migrations/009_inaam_baazar.sql
prototype_server/lib/{data,routes}/inaam_*
test/features/inaam_baazar/
prototype_server/test/routes/inaam_test.dart
```

## Design Decisions
- Server chooses prize and writes wallet entry with spin/claim state.
- UI presents configured values and clear unavailable/refused states.
- Monthly winner evaluation is documented as an external dependency, not implemented here.

## Complexity Tracking
None.
