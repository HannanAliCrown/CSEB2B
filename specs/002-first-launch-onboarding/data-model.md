# Data Model: First Launch Onboarding

- **OnboardingState**: `firstLaunchComplete`, optional `rememberedLanguage` (`en`, `ur`, `ur_Latn`). Local preferences also hold the notification and location outcomes and the phone coordinates.
- **PermissionOutcome**: `granted`, `denied`, `permanentlyDenied`, or `notRequested`.
- **DeviceLaunchRecord**: installation UUID, platform, language code and remembered flag, permission outcomes, optional phone coordinates, first-launch completion time. Stored on the `devices` table (`db/migrations/001_first_launch_and_registration.sql`).

Phone coordinates are context only and are never copied into registration shop coordinates.
