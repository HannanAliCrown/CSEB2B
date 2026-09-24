# Feature Specification: Inaam Rewards

**Feature Branch**: `010-inaam-rewards`
**Created**: 2026-09-21
**Status**: Draft
**Input**: Installer rewards including Spin and Win, item schemes, and monthly reward programs.

## User Scenarios & Testing

### User Story 1 - Spin and Win (Priority: P1)
An Installer earns one spin for every configured number of scans claimed today and receives a cash prize when spinning.

**Independent Test**: Seed scan entitlement, take a spin, and verify the wallet credit and history.

**Acceptance Scenarios**
1. Given fewer than the configured scans, when spin is attempted, then no spin is consumed.
2. Given one or more earned spins, when one is taken, then one prize is selected by weight on the server and paid to the cash wallet.
3. Given an unavailable connection during spin, when the request fails, then the app reports the spin was not used and reloads the entitlement.
4. Given a spin result, when "Use Your Next Spin" is tapped, then another spin is taken if one remains.

### User Story 2 - Item schemes (Priority: P1)
An Installer reaches scan or amount tiers for specific products and claims one reward per scheme.

**Independent Test**: Reach tiers, claim once, and attempt a second claim.

**Acceptance Scenarios**
1. Given a reached tier before scheme end, when claimed and confirmed, then the reward is paid and the scheme records its claim.
2. Given an unreached, expired, unknown, or already claimed tier, when claimed, then no reward is paid.
3. Given several reached tiers, when the scheme is shown, then only the highest reached tier is offered, with the tiers it would close named.

### User Story 3 - Reward program (Priority: P2)
An Installer views the current monthly program and the award earned in the prior month.

**Independent Test**: Load configured program data and verify progress, reached tier, and award display.

## Edge Cases
- Inaam Baazar is shown only to Installers; other roles see Points. The server endpoints do not check role.
- Prize payment and entitlement consumption must be atomic.
- An unconfigured wheel, no running schemes, or no current programme each show a clear unavailable state.
- An unreachable server shows a warning instead of any reward position.
- Unused spins lapse at the end of the day because entitlement counts only today's scans and spins.
- An amount scheme with no posted progress reads zero.

## Requirements
- **FR-001**: Spin entitlement MUST be derived from scans claimed today and configured scans-per-spin, less spins taken today; it is never stored and never negative.
- **FR-002**: A successful spin MUST credit the cash wallet exactly once, as a cleared `spin_prize` entry in the same transaction as the spin record.
- **FR-003**: Item schemes MUST support scan-count or amount measures and multiple tiers.
- **FR-004**: A partner MUST claim at most one item-scheme tier per scheme.
- **FR-005**: Scheme end dates MUST prevent late claims; ended schemes are not listed.
- **FR-006**: Reward program progress and previous awards MUST be viewable.
- **FR-007**: Teams App configuration and background evaluation are external/deferred operations, not mobile UI behavior.
- **FR-008**: Spin prize weights MUST NOT be sent to the phone; only segment amounts and positions are.
- **FR-009**: Only one spin configuration MUST be active at a time; each spin records the configuration and prize in force.
- **FR-010**: Scan-scheme progress MUST count claimed scans of the scheme's products within its dates; amount progress comes from externally posted figures.
- **FR-011**: An item-scheme claim MUST credit the cash wallet as a cleared `scheme_prize` entry atomically with the claim, and require confirmation in the app.
- **FR-012**: Reward program tiers are not claimable; a live award's bonus percent is added to scan prizes for that programme's products during the award window.
- **FR-013**: Spin history MUST show the latest 20 spins, three until "See all" is tapped.

## Key Entities
- **SpinConfig**, **SpinPrize**, **Spin**, **ItemScheme**, **SchemeTier**, **ItemSchemeClaim**, **ItemSchemeProgress**, **RewardProgram**, **ProgramTier**, **RewardProgramAward**.

## Success Criteria
- **SC-001**: Each earned spin is consumed at most once and produces one wallet outcome.
- **SC-002**: Item-scheme claims cannot be duplicated.
- **SC-003**: Reward progress accurately reflects configured product activity.

## Assumptions
- The server/database is authoritative for prize selection and payment.
- Monthly background evaluation is not implemented in the mobile app.
- "Today" is the database server's day (`date_trunc('day', now())`).
