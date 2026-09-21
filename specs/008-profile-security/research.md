# Research: Profile, Preferences, and PIN Security

- **Decision**: Keep PIN/settings server-backed and session/device references local.
- **Rationale**: PIN and account preferences must survive restart without exposing secret values.
- **Alternatives considered**: Local plaintext PIN storage was rejected.
- **Deferred**: Session expiry and refresh-token policy remain intentionally unspecified.
