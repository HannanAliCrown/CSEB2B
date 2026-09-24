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
1. Given an Installer, when Home loads, then the third bottom destination is Inaam and the Cash Request and New Profile tiles are absent.
2. Given a Retailer, Wholesaler, or Distributor, when Home loads, then the third bottom destination is Points and the Cash Request and New Profile tiles are shown, each badged with its waiting count when above zero.
3. Given a role-filtered content feed, when a slide or ticker message is inactive, outside its audience, or outside its time window, then it is not shown.

### User Story 2 - Use dashboard actions (Priority: P1)
The partner can open Send Cash, View Ledger, Scan QR, Shop Branding, Complaints, Notifications, and (seller-side roles) Cash Request and New Profile from Home.

**Independent Test**: Tap each available tile, the wallet card actions, the Scan QR card, and the notification bell, and verify the expected destination.

## Edge Cases
- A dashboard response other than 200 shows a zero balance with no held note, slides, or ticker; no other value is invented.
- An unreachable server (network error) leaves Home on its loading indicator; no error state is shown. (Not implemented)
- Empty slides and tickers hide the slider and ticker entirely rather than leaving placeholders.
- Cash Request and New Profile tiles are absent (not dimmed) for Installers.
- A ticker colour that is not `#RRGGBB` is ignored and the app's own ticker colours are used.

## Requirements
- **FR-001**: Home MUST show the signed-in partner's business name and role, taken from the session rather than the dashboard response.
- **FR-002**: Home MUST show wallet available and held values derived from the same `wallet_entries` rows as the ledger; the held note appears only when the held total is above zero.
- **FR-003**: Home MUST filter slides and tickers by `active`, audience (`all` or the partner's role), and active time window on the server, ordered by position.
- **FR-004**: Home MUST show Send Cash, View Ledger, Shop Branding, and Complaints tiles to every role, and Cash Request and New Profile tiles with pending-count badges only to Retailers, Wholesalers, and Distributors.
- **FR-005**: Home MUST expose five bottom navigation destinations: Home, Space, Inaam (Installer) or Points (other roles), Chat, Profile.
- **FR-006**: The wallet balance MUST start hidden and be revealed or hidden by the partner's toggle.
- **FR-007**: The Scan QR card subtitle MUST follow the role: "Check a product or claim a prize" for Installers and Retailers, "Check a product is genuine" otherwise.
- **FR-008**: The notification bell MUST show its dot only when the partner's unread notification count is above zero.
- **FR-009**: Home MUST reload on pull-to-refresh, whenever the wallet reports a change, and after returning from Notifications, Cash Request, or New Profile.
- **FR-010**: All ticker messages MUST run as one line, using the first message's text and background colours when set.

## Key Entities
- **Dashboard**: balance, held note, slides, ticker messages, scan subtitle.
- **PromoSlide**: audience, active window, position, optional image, eyebrow, and headline.
- **TickerMessage**: message, optional text and background colours, audience, active window, position.

## Success Criteria
- **SC-001**: Each supported role reaches a usable Home screen with only valid modules.
- **SC-002**: Dashboard content reflects server data without fabricated financial information.
- **SC-003**: Every available Home action opens its corresponding module.

## Assumptions
- Role assignment is authoritative outside the mobile UI.
- Home data is always read from `prototype_server` (`GET /dashboard`), regardless of `DATA_SOURCE`.
- The Shop Branding tile opens the Shop Branding module (`/branding`); that module's behaviour is outside this feature.
