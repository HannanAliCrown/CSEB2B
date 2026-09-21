# Feature Specification: Role-Based Dashboard

**Feature Branch**: `003-dashboard`
**Created**: 2026-09-21
**Status**: Draft
**Input**: Role-specific Home dashboard, wallet summary, sliders, tickers, and navigation tiles.

## User Scenarios & Testing

### User Story 1 - View role-based Home (Priority: P1)
A signed-in partner sees a dashboard appropriate to their assigned role.

**Independent Test**: Sign in as each role and compare visible navigation and Home tiles.

**Acceptance Scenarios**
1. Given an Installer, when Home loads, then Inaam and installer capabilities are available.
2. Given a Retailer, Wholesaler, or Distributor, when Home loads, then Points and selling-side actions are available.
3. Given a role-filtered content feed, when a slide or ticker is outside its audience or time window, then it is not shown.

### User Story 2 - Use dashboard actions (Priority: P1)
The partner can open Send Cash, Ledger, Scanner, Complaints, Notifications, and relevant requests from Home.

**Independent Test**: Tap each available tile and verify the expected destination.

## Edge Cases
- Unknown or unreachable dashboard data must not fabricate financial values.
- Empty slides and tickers must not leave broken placeholders.
- Installer-only and seller-side tiles must not appear for the wrong role.

## Requirements
- **FR-001**: Home MUST show the signed-in partner's business identity and role.
- **FR-002**: Home MUST show wallet available and held values from the same financial source.
- **FR-003**: Home MUST filter slides and tickers by role and active time window.
- **FR-004**: Home MUST show role-specific tiles and badges for pending requests.
- **FR-005**: Home MUST expose five role-appropriate bottom navigation destinations.

## Key Entities
- **Dashboard**: balance, held note, slides, ticker messages, scan subtitle.
- **PromoSlide**: audience, active window, image, headline.
- **TickerMessage**: message and optional display colors.

## Success Criteria
- **SC-001**: Each supported role reaches a usable Home screen with only valid modules.
- **SC-002**: Dashboard content reflects server data without fabricated financial information.
- **SC-003**: Every available Home action opens its corresponding module.

## Assumptions
- Role assignment is authoritative outside the mobile UI.
- Branding is deferred and remains unavailable from Home until separately specified.
