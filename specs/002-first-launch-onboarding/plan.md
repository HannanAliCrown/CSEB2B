# Implementation Plan: First Launch Onboarding

**Branch**: `002-first-launch-onboarding` | **Date**: 2026-09-21 | **Spec**: [spec.md](spec.md)

## Summary
Complete first-launch permission, language, optional location, and Login handoff using the existing onboarding MVVM module.

## Technical Context
- **Language/Version**: Dart/Flutter per root `pubspec.yaml`
- **Dependencies**: Flutter permissions, Provider, go_router, existing preferences
- **Storage**: local preferences; optional prototype server launch telemetry
- **Testing**: `flutter_test`, `flutter analyze`
- **Target Platform**: Android 8+ and iOS 15+, portrait-first
- **Project Type**: Flutter mobile feature
- **Constraints**: native permission prompts, RTL Urdu, Roman Urdu LTR, no shop-pin inference
- **Scale/Scope**: existing onboarding screens and services

## Constitution Check
Pass: uses existing MVVM, constructor injection, centralized tokens, localization, and existing services. No new architectural layer.

## Project Structure
```text
lib/features/onboarding/
├── data/repositories/onboarding_repository.dart
├── data/services/{permission_service,device_launch_service}.dart
└── ui/{view_models/first_launch_view_model.dart,views/first_launch_flow_screen.dart}
test/features/onboarding/
```

## Design Decisions
- Keep permission outcomes in the ViewModel and persistence in the repository.
- Keep phone location separate from registration shop coordinates.
- Preserve the current permissive behavior for denied permissions.
- Validate both fresh-install and remembered-language paths.

## Complexity Tracking
None.
