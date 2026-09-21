# Implementation Plan: Role-Based Dashboard

**Branch**: `003-dashboard` | **Date**: 2026-09-21 | **Spec**: [spec.md](spec.md)

## Summary
Maintain a role-aware Home dashboard whose financial values, slides, tickers, and request badges come from the established repository/service boundaries.

## Technical Context
- **Language/Version**: Dart/Flutter
- **Dependencies**: Provider, go_router, HTTP client, existing design system
- **Storage**: prototype server PostgreSQL or deterministic mock data source
- **Testing**: Flutter tests plus prototype server route/data-store tests
- **Target Platform**: Android 8+ and iOS 15+
- **Project Type**: Flutter mobile feature with local prototype API
- **Constraints**: no fabricated financial values; role and audience filtering server-authoritative
- **Scale/Scope**: Home dashboard and route-connected tiles

## Constitution Check
Pass: extends existing dashboard repository and ViewModel surfaces without introducing global state or a generic API layer.

## Project Structure
```text
lib/features/home/{data,ui}/
prototype_server/lib/{routes,data}/partner_*
test/features/home/
prototype_server/test/routes/partner_test.dart
```

## Design Decisions
- Keep wallet totals and dashboard totals sourced from the same entries.
- Filter scheduled content by role and active window in the data layer.
- Keep Branding unavailable until its own feature is specified and implemented.

## Complexity Tracking
None.
