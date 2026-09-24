# Feature Specification: First Launch Onboarding

**Feature Branch**: `002-first-launch-onboarding`
**Created**: 2026-09-21
**Status**: Draft
**Input**: First-launch notification permission, language selection, and optional location capture.

## User Scenarios & Testing

### User Story 1 - Complete first launch (Priority: P1)
A newly installed app requests notification permission, then presents language selection, then the optional location step, then continues to Login.

**Independent Test**: Start with cleared preferences and verify the ordered flow.

**Acceptance Scenarios**
1. Given a fresh installation, when notification permission is dismissed either way, then language selection appears.
2. Given language selection, when English is confirmed with remember enabled, then the location step appears and, once it is finished, Login appears and the choice is retained.
3. Given remember is disabled, when the app is reopened, then language selection appears again; confirming it goes straight to Login without repeating the permission or location steps.

### User Story 2 - Optional location setup (Priority: P2)
The partner may allow or choose "Not now" on the location education screen. Any non-granted OS answer shows the "Location is switched off" screen, from which the partner can open system settings or continue without location.

**Independent Test**: Exercise each permission result and confirm the app remains usable.

**Acceptance Scenarios**
1. Given location is granted, when capture completes, then the phone location is stored as context only.
2. Given location is denied or skipped, when the partner continues, then Login remains reachable.

## Edge Cases
- Notification denial must not block the journey.
- A denied or permanently denied location answer shows the switched-off screen, which offers Open Settings and Continue without location; Back also continues without location. Location services being disabled is not detected separately.
- Reopening after remembered language must skip the modal.
- An unreachable server must never block onboarding; launch reporting is best-effort.

## Requirements
- **FR-001**: The app MUST request native notification permission before in-app language selection on first launch.
- **FR-002**: The app MUST offer English, Urdu, and Roman Urdu, with English initially selected and Remember my choice initially checked.
- **FR-003**: The app MUST persist language only when Remember my choice is selected; confirming with it unchecked clears any remembered language.
- **FR-004**: The app MUST continue to Login after onboarding regardless of notification or location denial.
- **FR-005**: Granted phone location MUST remain separate from any business/shop pin. It is used only to centre the registration shop-location map.
- **FR-006**: When server-backed, the app MUST report each onboarding answer (language, remember flag, notification and location outcome, phone coordinates, first-launch completion) to `POST /devices/launch` keyed by installation UUID. Failures are swallowed and later calls update only the fields supplied.
- **FR-007**: A returning install with first launch complete but no remembered language MUST show only the language modal, then Login.

## Key Entities
- **OnboardingState**: first-launch completion and remembered language.
- **PermissionOutcome**: notification and location outcomes.
- **DeviceLaunchRecord**: optional device launch telemetry and location context.

## Success Criteria
- **SC-001**: A fresh install reaches Login after one ordered onboarding journey.
- **SC-002**: Reopening with remembered language does not show the language modal.
- **SC-003**: Denied permissions never prevent reaching Login.

## Assumptions
- Native permission dialogs are controlled by the operating system and are shown over the brand splash.
- Location is optional and is not used to infer a shop location.
- The prototype does not read a real device position: a granted location stores a fixed Lahore coordinate (`MockCurrentLocationSource`).
- The onboarding language choice is stored and reported, but onboarding does not change the app's display locale; onboarding screen copy is English-only.
