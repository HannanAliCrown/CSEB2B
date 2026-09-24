# Implementation Plan: First Launch Onboarding

**Branch**: `002-first-launch-onboarding` | **Date**: 2026-09-21 | **Spec**: [spec.md](spec.md)

## Summary
Complete first-launch permission, language, optional location, and Login handoff using the existing onboarding MVVM module.

## Technical Context
- **Language/Version**: Dart/Flutter per root `pubspec.yaml`
- **Dependencies**: `permission_handler`, `shared_preferences`, `http`, Provider, go_router
- **Storage**: local preferences; optional best-effort prototype server launch telemetry (`POST /devices/launch` → `devices` table)
- **Testing**: `flutter_test`, `flutter analyze`
- **Target Platform**: Android 8+ and iOS 15+, portrait-first
- **Project Type**: Flutter mobile feature
- **Constraints**: native permission prompts, RTL Urdu, Roman Urdu LTR, no shop-pin inference
- **Scale/Scope**: existing onboarding screens and services

## Constitution Check
Pass: uses existing MVVM, constructor injection, centralized tokens, and existing services. No new architectural layer. Onboarding copy is not yet localized (T008).

## Project Structure
```text
lib/core/prefs/app_preferences.dart
lib/features/onboarding/
├── data/repositories/onboarding_repository.dart
├── data/services/{permission_service,device_launch_service}.dart
└── ui/{view_models/first_launch_view_model.dart,views/first_launch_flow_screen.dart}
lib/features/registration/ui/views/first_launch_screens.dart
lib/app/router/app_router.dart
prototype_server/lib/routes/partner_routes.dart          (POST /devices/launch)
prototype_server/lib/data/postgres_partner_data_store.dart (recordDeviceLaunch)
db/migrations/001_first_launch_and_registration.sql
test/features/onboarding/
```

## Design Decisions
- Keep permission outcomes in the ViewModel and persistence in the repository.
- Keep phone location separate from registration shop coordinates; the registration ViewModel reads it only to centre the map.
- Preserve the current permissive behavior for denied permissions.
- Validate both fresh-install and remembered-language paths.
- Use `MockCurrentLocationSource` (fixed Lahore coordinate) as the prototype position source.
- Launch reporting uses `HttpDeviceLaunchService` when server-backed, otherwise `NoDeviceLaunchService`; failures are swallowed.

## Complexity Tracking
None.
