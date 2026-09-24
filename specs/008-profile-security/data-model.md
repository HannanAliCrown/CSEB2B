# Data Model: Profile, Preferences, and PIN Security

- **ProfileSettings**: language (`en`/`ur`/`ur-Latn`), remember-language flag, theme (`system`/`light`/`dark`), PIN-set/enabled flags; stored on `accounts`.
- **AppPin**: account, bcrypt verifier, enabled state; the PIN itself is never returned. Disabling keeps the row.
- **SupportContact**: label, phone number, optional description, audience (`all` or one role), position, active.
- **AppInfo**: key/value About copy with position; excludes the app version.
- **Contact**: device contact matched to a registered Crown Solar account (number, business, role, phone name); stored only on the phone with a last-synced time.
