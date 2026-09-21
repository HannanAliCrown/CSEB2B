# Data Model: First Launch Onboarding

- **OnboardingState**: `firstLaunchComplete`, optional `rememberedLanguage`.
- **PermissionOutcome**: notification/location result such as granted, denied, or not requested.
- **DeviceLaunchRecord**: installation identifier, language choice, permission outcomes, optional phone coordinates.

Phone coordinates are context only and are never copied into registration shop coordinates.
