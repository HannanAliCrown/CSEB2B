# Feature Specification: Profile, Preferences, and PIN Security

**Feature Branch**: `008-profile-security`
**Created**: 2026-09-21
**Status**: Draft
**Input**: Profile identity, QR, contacts, language/theme, PIN, support, About, and sign-out.

## User Scenarios & Testing

### User Story 1 - View and share profile identity (Priority: P1)
A partner sees their name, business, mobile number, role, and profile QR.

**Independent Test**: Open Profile and display the QR screen.

### User Story 2 - Manage app security and preferences (Priority: P1)
A partner selects language/theme and enables, verifies, changes, or disables a four-digit PIN.

**Independent Test**: Set a PIN, close/reopen with a valid session, unlock, and change preferences.

**Acceptance Scenarios**
1. Given an enabled PIN and valid session, when the app opens, then the PIN gate appears.
2. Given no enabled PIN, when a valid session opens, then the dashboard appears directly.
3. Given a wrong PIN, when verification is attempted, then access remains locked and no PIN data is exposed.
4. Given a language or theme choice, when saved, then it applies across the app.
5. Given sign-out, when completed, then only local session state is cleared.

### User Story 3 - Sync contacts and contact support (Priority: P2)
Only registered app partners are retained from device contacts; support numbers open the phone dialer.

## Edge Cases
- A failed settings server read must not invent a PIN state.
- PIN values must never be returned or displayed by the service.
- Contact sync must exclude unregistered contacts.

## Requirements
- **FR-001**: Profile MUST show core partner identity and role.
- **FR-002**: PIN MUST be exactly four digits.
- **FR-003**: PIN verification MUST precede access when enabled and the session remains valid.
- **FR-004**: Language MUST support English, Urdu, and Roman Urdu.
- **FR-005**: Theme MUST support system, light, and dark modes.
- **FR-006**: Support actions MUST open the phone dialer with the selected number.
- **FR-007**: Sign-out MUST not change device binding.

## Key Entities
- **ProfileSettings**, **SupportContact**, **Contact**, **PinState**, **SessionReference**.

## Success Criteria
- **SC-001**: PIN-enabled valid sessions require successful PIN verification before Home.
- **SC-002**: Preferences remain consistent across reopened screens.
- **SC-003**: Sign-out leaves the account/device business state unchanged.

## Assumptions
- Session expiry remains deferred for now.
- PIN recovery is handled through support rather than an in-app reset flow.
