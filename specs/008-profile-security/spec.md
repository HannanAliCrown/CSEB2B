# Feature Specification: Profile, Preferences, and PIN Security

**Feature Branch**: `008-profile-security`
**Created**: 2026-09-21
**Status**: Draft
**Input**: Profile identity, QR, contacts, language/theme, PIN, support, About, and sign-out.

## User Scenarios & Testing

### User Story 1 - View and share profile identity (Priority: P1)
A partner sees their contact name, business, mobile number, role, market, approval status (Active/Pending), and profile QR. The QR carries only the mobile number; other partners scan it from Send Cash, Send Points, and New Conversation.

**Independent Test**: Open Profile and display the QR screen.

### User Story 2 - Manage app security and preferences (Priority: P1)
A partner selects language/theme and enables, verifies, changes, or disables a four-digit PIN.

**Independent Test**: Set a PIN, close/reopen with a valid session, unlock, and change preferences.

**Acceptance Scenarios**
1. Given an enabled PIN and valid session, when the app opens, then the PIN gate appears.
2. Given no enabled PIN, when a valid session opens, then the dashboard appears directly.
3. Given a wrong PIN, when verification is attempted, then the entry clears, access remains locked, and no PIN data is exposed.
4. Given a language choice, when confirmed and saved, then it applies across the app; given a theme choice, it applies at once and reverts if the save fails.
5. Given sign-out, when confirmed in the dialog, then only the locally saved session is cleared.
6. Given an enabled PIN, when the settings server cannot be reached at app open, then the app opens without the PIN gate.
7. Given the unlock screen, when "Forgot PIN?" is tapped, then the app explains support can remove the PIN and offers to dial the first support number.

### User Story 3 - Sync contacts and contact support (Priority: P2)
Only registered app partners are retained from device contacts; support numbers open the phone dialer.

## Edge Cases
- A failed settings server read must not invent a PIN state: App Security shows an error and offers no changes; the PIN gate opens the app.
- PIN values must never be returned or displayed by the service.
- Contact sync must exclude unregistered contacts; non-matching numbers are discarded in memory and never stored or uploaded.
- Contacts permission refused shows an "Open Settings" state; sync reads contacts only and never writes to the address book.
- No support numbers (or a failed load) shows an empty state; a device without a dialer shows the number in a snackbar.
- Wrong PIN entries are not rate-limited or locked out.

## Requirements
- **FR-001**: Profile MUST show core partner identity and role, plus market and approval status; identity fields are read-only (changed through CRM).
- **FR-002**: PIN MUST be exactly four digits (enforced by the server).
- **FR-003**: PIN verification MUST precede access when enabled and the session remains valid; the check runs once per app process, and an unreachable server opens the app.
- **FR-004**: Language MUST support English, Urdu, and Roman Urdu, saved against the account with a "Remember my choice" flag and applied on sign-in.
- **FR-005**: Theme MUST support system, light, and dark modes, saved against the account and applied on sign-in.
- **FR-006**: Support actions MUST open the phone dialer with the selected number; numbers are filtered by the partner's role (or "all") and ordered by position.
- **FR-007**: Sign-out MUST not change device binding and MUST require confirmation.
- **FR-008**: Setting a new PIN MUST ask for it twice; setting a PIN enables it.
- **FR-009**: Changing or disabling a PIN MUST require the current PIN; disabling keeps the stored PIN so re-enabling asks for the existing PIN, not a new one.
- **FR-010**: The PIN MUST be stored only as a bcrypt hash (pgcrypto `crypt()`), one per account.
- **FR-011**: The profile QR MUST encode only the mobile number and list its uses: chat for everyone; send cash and send points only when the owner is not an Installer.
- **FR-012**: Synced contacts MUST be stored only on the phone, de-duplicated by number, and removable with "Forget Synced Contacts".
- **FR-013**: About MUST show server-supplied company copy and the version/build read from the installed app.
- **FR-014**: Sign-out MUST re-lock the PIN gate and reset theme/language to phone defaults (Not implemented: `PinLock.relock()` and `AppSettingsController.reset()` are never called).

## Key Entities
- **ProfileSettings**, **SupportContact**, **Contact**, **PinState**, **SessionReference**, **AppInfo**.

## Success Criteria
- **SC-001**: PIN-enabled valid sessions require successful PIN verification before Home whenever the settings server is reachable.
- **SC-002**: Preferences remain consistent across reopened screens.
- **SC-003**: Sign-out leaves the account/device business state unchanged.

## Assumptions
- Session expiry remains deferred for now.
- PIN recovery is handled through support rather than an in-app reset flow.
- Contact matching uses the bundled prototype partner directory (`lib/core/mock/partner_directory.dart`), not the server.
- Profile copy is English-only; switching language changes the app locale but these screens' strings are not yet localized.
