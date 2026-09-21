---
description: "Tasks for first-launch onboarding"
---

# Tasks: First Launch Onboarding

## Phase 1: Existing Foundation
- [x] T001 [P] [US1] Preserve onboarding preferences in `lib/core/prefs/app_preferences.dart`.
- [x] T002 [P] [US1] Preserve native permission boundary in `lib/features/onboarding/data/services/permission_service.dart`.

## Phase 2: User Story 1 - Complete First Launch
- [x] T003 [US1] Maintain ordered notification -> language -> Login state flow in `lib/features/onboarding/ui/view_models/first_launch_view_model.dart`.
- [x] T004 [US1] Maintain English, Urdu, Roman Urdu and remembered-choice presentation in `lib/features/registration/ui/views/first_launch_screens.dart`.
- [x] T005 [US1] Add/maintain tests for fresh launch, denial, and remembered language in `test/features/onboarding/first_launch_view_model_test.dart`.

## Phase 3: User Story 2 - Optional Location
- [x] T006 [US2] Persist granted phone location without using it as the shop pin in `lib/features/onboarding/data/repositories/onboarding_repository.dart`.
- [x] T007 [US2] Verify denied, disabled, skipped, and settings paths in `test/features/onboarding/first_launch_view_model_test.dart`.

## Phase 4: Polish
- [ ] T008 [P] Run localization and RTL/LTR accessibility review for onboarding copy in `lib/core/localization/arb/`.
- [ ] T009 Run the onboarding scenarios from `specs/002-first-launch-onboarding/quickstart.md` and record results in the feature checklist.

## Dependencies
- T001-T002 precede all story work.
- US2 depends on the onboarding state flow from US1.

## MVP
US1: fresh launch reaches Login in the correct order.
