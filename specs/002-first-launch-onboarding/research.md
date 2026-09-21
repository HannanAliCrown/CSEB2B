# Research: First Launch Onboarding

- **Decision**: Reuse existing preferences, permission, and launch-reporting boundaries.
- **Rationale**: The repository already separates ViewModel behavior from platform services.
- **Alternatives considered**: A new onboarding state container was rejected as unnecessary.
- **Open boundary**: Native push delivery is outside this feature; only permission state is covered.
