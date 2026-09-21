---
description: "Tasks for profile and security"
---

# Tasks: Profile, Preferences, and PIN Security

## Phase 1: Existing Foundation
- [x] T001 [P] Retain profile settings service in `lib/features/profile/data/profile_settings_service.dart`.
- [x] T002 [P] Retain profile settings schema in `db/migrations/004_profile_settings.sql`.

## Phase 2: User Story 1 - Profile Identity
- [x] T003 [US1] Render identity and role data in `lib/features/profile/ui/views/profile_tab.dart`.
- [x] T004 [US1] Render partner QR screen in `lib/features/profile/ui/views/my_qr_code_screen.dart`.
- [ ] T005 [US1] Connect QR payload resolution to real cash/chat/points discovery services in `lib/features/profile/ui/views/my_qr_code_screen.dart` and the receiving repositories.

## Phase 3: User Story 2 - Preferences and PIN
- [x] T006 [US2] Support language/theme settings in `lib/features/profile/ui/views/settings_pages.dart` and `lib/features/profile/ui/app_settings_controller.dart`.
- [x] T007 [US2] Support four-digit PIN set/change/verify/disable in `lib/features/profile/ui/views/app_security_page.dart` and `lib/features/profile/ui/views/pin_gate.dart`.
- [x] T008 [US2] Keep sign-out local and independent of device binding in `lib/features/session/ui/session_controller.dart`.
- [ ] T009 [US2] Add focused PIN and preference tests in `test/features/profile/` and `test/features/session/`.

## Phase 4: User Story 3 - Contacts and Support
- [x] T010 [US3] Filter synced contacts to known Crown Solar partners in `lib/features/profile/data/contacts_repository.dart`.
- [x] T011 [US3] Open support numbers through the phone dialer in `lib/features/profile/ui/views/settings_pages.dart`.

## Phase 5: Polish
- [ ] T012 Keep token expiry/refresh absent from `lib/features/session/data/session_repository.dart` until separately specified.

## Dependencies
- US2 depends on the profile service and active session.
- US3 can proceed independently after profile identity exists.

## MVP
US1 and PIN gate in US2.
