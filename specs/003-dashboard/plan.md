# Implementation Plan: Role-Based Dashboard

**Branch**: `003-dashboard` | **Date**: 2026-09-21 | **Spec**: [spec.md](spec.md)

## Summary
Maintain a role-aware Home dashboard whose financial values, slides, tickers, and request badges come from the established repository/service boundaries.

## Technical Context
- **Language/Version**: Dart/Flutter
- **Dependencies**: Provider, go_router, HTTP client, existing design system
- **Storage**: prototype server PostgreSQL (`wallet_entries`, `promo_slides`, `ticker_messages`); the app always uses `HttpDashboardRepository`. `MockDashboardRepository` exists but is not wired.
- **Testing**: prototype server route tests (`partner_test.dart`, `home` group); no Flutter dashboard tests yet
- **Target Platform**: Android 8+ and iOS 15+
- **Project Type**: Flutter mobile feature with local prototype API
- **Constraints**: no fabricated financial values; role and audience filtering server-authoritative
- **Scale/Scope**: Home dashboard and route-connected tiles

## Constitution Check
Pass with one deviation: `DashboardScreen`'s state reads `DashboardRepository`, `ComplaintsService`, `ProfileRequestsService`, and `CashRequestsService` directly; no dashboard ViewModel exists. No global state or generic API layer is introduced.

## Project Structure
```text
lib/features/home/data/{dashboard_repository,http_dashboard_repository}.dart
lib/features/home/ui/views/dashboard_screen.dart
lib/features/home/ui/widgets/home_widgets.dart
lib/app/shell/app_shell.dart
lib/app/router/app_router.dart
prototype_server/lib/routes/partner_routes.dart
prototype_server/lib/data/{partner_data_store,partner_models,postgres_partner_data_store}.dart
db/migrations/002_dashboard.sql
db/seed/002_dashboard.sql
prototype_server/test/routes/partner_test.dart
```

## Design Decisions
- Keep wallet totals and dashboard totals derived from the same `wallet_entries` rows; the balance is never stored.
- Filter scheduled content by active flag, role, and active window in the server SQL.
- `GET /dashboard?mobileNumber=` returns `availablePaisa`, `heldPaisa`, `slides`, `ticker`; 400 without a number, 404 for an unknown number.
- Name and role come from the session; the scan subtitle is derived from the role on the device.
- Shop Branding is reached from Home's tile via `onShopBranding`; other unknown module labels show a "not built yet" snackbar.

## Complexity Tracking
None.
