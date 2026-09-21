# Feature Specification: Inaam Rewards

**Feature Branch**: `010-inaam-rewards`
**Created**: 2026-09-21
**Status**: Draft
**Input**: Installer rewards including Spin and Win, item schemes, and monthly reward programs.

## User Scenarios & Testing

### User Story 1 - Spin and Win (Priority: P1)
An Installer earns one spin for every configured number of qualifying daily scans and receives a cash prize when spinning.

**Independent Test**: Seed scan entitlement, take a spin, and verify the wallet credit and history.

**Acceptance Scenarios**
1. Given fewer than the configured scans, when spin is attempted, then no spin is consumed.
2. Given one or more earned spins, when one is taken, then one prize is selected and paid to the cash wallet.
3. Given an unavailable connection during spin, when the operation fails, then the entitlement is not consumed.

### User Story 2 - Item schemes (Priority: P1)
An Installer reaches scan or amount tiers for specific products and claims one reward per scheme.

**Independent Test**: Reach tiers, claim once, and attempt a second claim.

**Acceptance Scenarios**
1. Given a reached tier before scheme end, when claimed, then the reward is paid and the scheme records its claim.
2. Given an unreached, expired, unknown, or already claimed tier, when claimed, then no reward is paid.

### User Story 3 - Reward program (Priority: P2)
An Installer views the current monthly program and the prior month award.

**Independent Test**: Load configured program data and verify progress, reached tier, and award display.

## Edge Cases
- Wholesaler and Distributor are not prize-scanning users.
- Prize payment and entitlement consumption must be atomic.
- A scheme with no configuration must show a clear unavailable state.

## Requirements
- **FR-001**: Spin entitlement MUST be derived from qualifying scans and configured scans-per-spin.
- **FR-002**: A successful spin MUST credit the cash wallet exactly once.
- **FR-003**: Item schemes MUST support scan-count or amount measures and multiple tiers.
- **FR-004**: A partner MUST claim at most one item-scheme tier per scheme.
- **FR-005**: Scheme end dates MUST prevent late claims.
- **FR-006**: Reward program progress and previous awards MUST be viewable.
- **FR-007**: Teams App configuration and background evaluation are external/deferred operations, not mobile UI behavior.

## Key Entities
- **SpinConfig**, **Spin**, **ItemScheme**, **SchemeTier**, **ItemSchemeClaim**, **RewardProgram**, **ProgramTier**.

## Success Criteria
- **SC-001**: Each earned spin is consumed at most once and produces one wallet outcome.
- **SC-002**: Item-scheme claims cannot be duplicated.
- **SC-003**: Reward progress accurately reflects configured product activity.

## Assumptions
- The server/database is authoritative for prize selection and payment.
- Monthly background evaluation is not implemented in the mobile app.
