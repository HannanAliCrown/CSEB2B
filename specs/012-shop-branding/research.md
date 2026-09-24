# Research: Shop Branding

- **Decision**: Decide eligibility only on the server and re-check on submit.
- **Rationale**: A scan window can close or a board can be installed between loading options and submitting; one place for the rule prevents drift.
- **Alternatives considered**: Client-side filtering was rejected because it duplicates the rule and can be stale.
- **Configuration**: Board types, prices, splits and windows live in tables owned by the Teams app so they can be retuned without a release.
- **Data reuse**: Points, schemes and scan claims are read from their owning modules; branding keeps no counters.
- **Locked reasons**: Only the first unmet condition is shown, phrased as the next action.
