# Feature Specification: First Launch Onboarding

**Feature Branch**: `002-first-launch-onboarding`
**Created**: 2026-09-21
**Status**: Draft
**Input**: First-launch notification permission, language selection, and optional location capture.

## User Scenarios & Testing

### User Story 1 - Complete first launch (Priority: P1)
A newly installed app requests notification permission, then presents language selection, then continues to Login.

**Independent Test**: Start with cleared preferences and verify the ordered flow.

**Acceptance Scenarios**
1. Given a fresh installation, when notification permission is dismissed either way, then language selection appears.
2. Given language selection, when English is confirmed with remember enabled, then Login appears and the choice is retained.
3. Given remember is disabled, when the app is reopened, then language selection appears again.

### User Story 2 - Optional location setup (Priority: P2)
The partner may grant, deny, skip, or later open system settings for location.

**Independent Test**: Exercise each permission result and confirm the app remains usable.

**Acceptance Scenarios**
1. Given location is granted, when capture completes, then the phone location is stored as context only.
2. Given location is denied or skipped, when the partner continues, then Login remains reachable.

## Edge Cases
- Notification denial must not block the journey.
- Location services disabled must offer continuation without location.
- Reopening after remembered language must skip the modal.

## Requirements
- **FR-001**: The app MUST request native notification permission before in-app language selection on first launch.
- **FR-002**: The app MUST offer English, Urdu, and Roman Urdu, with English initially selected.
- **FR-003**: The app MUST persist language only when Remember my choice is selected.
- **FR-004**: The app MUST continue to Login after onboarding regardless of notification or location denial.
- **FR-005**: Granted phone location MUST remain separate from any business/shop pin.

## Key Entities
- **OnboardingState**: first-launch completion and remembered language.
- **PermissionOutcome**: notification and location outcomes.
- **DeviceLaunchRecord**: optional device launch telemetry and location context.

## Success Criteria
- **SC-001**: A fresh install reaches Login after one ordered onboarding journey.
- **SC-002**: Reopening with remembered language does not show the language modal.
- **SC-003**: Denied permissions never prevent reaching Login.

## Assumptions
- Native permission dialogs are controlled by the operating system.
- Location is optional and is not used to infer a shop location.
