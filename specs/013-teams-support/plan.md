# Implementation Plan: Crown Solar Teams Support

**Branch**: `013-teams-support` | **Date**: 2026-09-24 | **Spec**: [spec.md](spec.md)

## Summary

One idempotent migration (`db/migrations/012_teams_support.sql`) adds the columns, constraints and link tables for CSE-1 … CSE-7; one seed (`db/seed/011_teams_support.sql`) demonstrates each. Server stores read the new columns; the app shows the officer only where it exists, resolves staff chat parties, and adds the `unassigned` scan verdict. No new dependency, layer or screen.

## Technical Context

Flutter/Dart app (MVVM, provider, go_router); shelf prototype server over PostgreSQL (`cse_b2b_prototype`, shared with Crown Solar Teams on port 8081). Tests: server route tests with in-memory fakes; app repository tests.

## Constitution Check

Spec-driven (this spec); no redesign — new rows reuse `DsSettingRow` inside existing `DsRowGroup`s and the existing scan result layout; no new dependencies; Principle X — no generic staff model, only the three columns a request needs.

## Data Model (migration 012)

| Change | Table | Detail |
|---|---|---|
| CSE-1 | `registration_approvals` | `decided_by_staff_id uuid`, `decided_by_staff_role text CHECK IN ('mo','asm','rsm')`; `registration_approvals_mo_reject_note` CHECK: `approver <> 'marketing_officer' OR state <> 'rejected' OR btrim(coalesce(note,'')) <> ''` |
| CSE-2 | `complaints` | `raised_by_staff_id uuid`, `raised_by_staff_name text`, `raised_by_staff_role text CHECK IN ('mo','asm')`; all-or-nothing CHECK |
| CSE-3 | `branding_requests` | same three columns and CHECK |
| CSE-4 | `accounts` | `accounts_status_check` → `status IN ('active','closed')` |
| CSE-5 | `chat_staff_parties` (new) | `address text PK CHECK (address LIKE 'staff:%')`, `display_name text NOT NULL`, `role text CHECK IN ('mo','asm','rsm')`, `updated_at` — written by Crown Solar Teams |
| CSE-6 | `point_scheme_markets`, `item_scheme_markets`, `reward_program_markets` (new) | `(scheme_id/program_id, market_id)` PK; no rows = every market |
| CSE-7 | `products` | `products_state_check` → `state IN ('active','blocked','unassigned')` |

Staff ids carry no foreign key: `teams_staff` is created by Teams migrations that run after this one.

## API changes

| Endpoint | Change |
|---|---|
| `GET /complaints`, `GET /complaints/<reference>` | each complaint gains `raisedBy: {name, role}` or `null` |
| `GET /branding`, `GET /branding/requests/<reference>` | each request gains `raisedBy` likewise |
| chat thread/party JSON | `staff:` party → `{address, isDepartment:false, name, role}` with role `mo`/`asm`/`rsm` |
| `GET /inaam/...` item schemes, reward program | filtered to the partner's market (D2) |
| `POST /scan`, `GET /scan/intro` | verdict `unassigned`; intro meaning "Not yet assigned" |

## Design Decisions

| # | Decision | Rationale |
|---|---|---|
| D1 | Officer name and role are stored on the row (snapshot), like `decided_by_name` | No join into Teams tables; the partner sees who raised it at the time |
| D2 | Market filter: `NOT EXISTS (targets) OR EXISTS (target = partner's market_id)` | Untargeted rows keep today's behaviour until Super Admin exists |
| D3 | Point scheme targets are not applied to a signed scheme (`targets()`), only stored for Teams Focus › Offers | Signing is per account; hiding a signed scheme would break the partner's targets |
| D4 | `unassigned` is checked first in `check()` and returns no product details | The code is not a product yet |
| D5 | App role labels: `mo` → Marketing Officer, `asm` → Area Sales Manager, `rsm` → Regional Sales Manager | Same words as the Approval Status screen |

## Complexity Tracking

None.
