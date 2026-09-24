# Implementation Plan: Profile, Preferences, and PIN Security

**Branch**: `008-profile-security` | **Date**: 2026-09-21 | **Spec**: [spec.md](spec.md)

## Summary
Keep account preferences and PIN state server-backed while retaining local session, device identity, and synced-contact boundaries.

## Technical Context
- **Language/Version**: Dart/Flutter and plain Dart
- **Dependencies**: HTTP, secure storage (device identity), shared_preferences, url_launcher, qr_flutter, flutter_contacts, permission_handler, package_info_plus, PostgreSQL prototype store with pgcrypto
- **Storage**: account language/theme columns, bcrypt-hashed PIN state, support contacts, About copy; local session reference and matched contacts
- **Testing**: prototype server profile tests; session controller tests; no focused Flutter profile/PIN tests yet
- **Target Platform**: Android/iOS portrait-first
- **Project Type**: Flutter mobile plus local prototype API
- **Constraints**: PIN never returned, support uses phone dialer, session expiry deferred
- **Scale/Scope**: Profile, QR, contacts, settings, PIN, support, About, logout

## Constitution Check
Pass with deviation: uses constructor injection and existing ProfileSettingsService/SessionController boundaries, but Profile views read `ProfileSettingsService` and `ContactsRepository` directly through `provider` without a ViewModel.

## Project Structure
```text
lib/features/{profile,session}/{data,ui}/
lib/core/mock/partner_directory.dart
lib/app/router/app_router.dart
db/migrations/004_profile_settings.sql
db/seed/004_profile_settings.sql
prototype_server/lib/{data,routes}/*profile_*
test/features/session/
prototype_server/test/routes/profile_test.dart
```

`profile_screens.dart` and `settings_screens.dart` are static design-preview boards, not the live screens.

## Design Decisions
- Keep PIN verification server-owned and never serialize PIN values.
- Apply account language/theme when the PIN gate first reads profile settings.
- Fail open: an unreachable settings server does not lock the partner out.
- Match contacts on-device against the partner directory; keep only matches, locally.
- Leave token expiry/refresh behavior deferred as requested.

## Complexity Tracking
None.
