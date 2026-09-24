# Implementation Plan: Shop Branding

**Branch**: `012-shop-branding` | **Date**: 2026-09-24 | **Spec**: [spec.md](spec.md)

## Summary
Let partners request shop branding boards from server-filtered board types, see the cost split before submitting, and follow each request's status. All eligibility is decided server-side from existing points, scheme and scan data.

## Technical Context
- **Language/Version**: Dart/Flutter and plain Dart
- **Dependencies**: HTTP, Provider, go_router, image_picker (via `MediaCaptureService`), PostgreSQL prototype store
- **Storage**: `branding_config`, `branding_board_types`, `branding_board_type_roles`, `branding_installations`, `branding_requests`, `branding_request_boards`; reads `point_entries`, `account_schemes`, `scan_claims`, `accounts`
- **Testing**: none yet (see tasks Phase 6)
- **Target Platform**: Android/iOS portrait-first
- **Project Type**: Flutter mobile plus local prototype API
- **Constraints**: no eligibility rule on device; one live request per account; price/split snapshotted per board
- **Scale/Scope**: landing, two-step wizard, board-type sheet, request history, request status

## Constitution Check
Pass with notes: reuses points, scheme and scan tables rather than duplicating counters. Views read `BrandingService` directly through Provider, matching sibling modules (complaints, profile requests) rather than adding a ViewModel. User-visible strings are not yet localized (Principle VIII) — tracked in tasks.

## Project Structure
```text
lib/features/branding/data/branding_service.dart
lib/features/branding/ui/views/{shop_branding,new_branding_request,branding_requests,branding_status}_screen.dart
lib/features/branding/ui/views/{branding_screens,branding_request_screens}.dart   # design-preview only
lib/app/router/app_router.dart          # /branding, /branding/new, /branding/requests[/:reference]
lib/app/shell/app_shell.dart            # Home tile → /branding
db/migrations/011_shop_branding.sql
db/seed/010_shop_branding.sql
prototype_server/lib/data/{branding_data_store,postgres_branding_data_store}.dart
prototype_server/lib/routes/branding_routes.dart
```

## API
- `GET /branding?mobileNumber=` → eligibility, current request, all requests (newest first)
- `GET /branding/board-types?mobileNumber=` → eligibility, board types with `available`/`condition`/`lockedReason`, `replacementOnly`, `replacementNotice`
- `POST /branding/requests` → 201 request; 400 `board_count_mismatch`; 404 `unknown_account`; 409 `option_not_available` / `request_already_open`
- `GET /branding/requests/<reference>?mobileNumber=` → one request or 404 `unknown_request`

## Design Decisions
- Replacement detection runs first and overrides every other condition.
- Role absence hides a type; unmet points/scheme/scan shows it locked with the first unmet reason.
- The live-request check runs inside the insert transaction with `FOR UPDATE`.
- Board price and company percent are copied onto `branding_request_boards` at submit.

## Complexity Tracking
None.
