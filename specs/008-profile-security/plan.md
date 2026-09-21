# Implementation Plan: Profile, Preferences, and PIN Security

**Branch**: `008-profile-security` | **Date**: 2026-09-21 | **Spec**: [spec.md](spec.md)

## Summary
Keep account preferences and PIN state server-backed while retaining local session and device identity boundaries.

## Technical Context
- **Language/Version**: Dart/Flutter and plain Dart
- **Dependencies**: HTTP, secure storage, url_launcher, PostgreSQL prototype store
- **Storage**: profile settings, hashed PIN state, support contacts; local session reference
- **Testing**: Flutter profile/PIN tests and prototype server profile tests
- **Target Platform**: Android/iOS portrait-first
- **Project Type**: Flutter mobile plus local prototype API
- **Constraints**: PIN never returned, support uses phone dialer, session expiry deferred
- **Scale/Scope**: Profile, QR, contacts, settings, PIN, support, About, logout

## Constitution Check
Pass: uses constructor injection and existing ProfileSettingsService/SessionController boundaries.

## Project Structure
```text
lib/features/{profile,session}/{data,ui}/
db/migrations/004_profile_settings.sql
prototype_server/lib/{data,routes}/profile_*
test/features/{profile,session}/
prototype_server/test/routes/profile_test.dart
```

## Design Decisions
- Keep PIN verification server-owned and never serialize PIN values.
- Apply account language/theme when profile settings become available.
- Leave token expiry/refresh behavior deferred as requested.

## Complexity Tracking
None.
