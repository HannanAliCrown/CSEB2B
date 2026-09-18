# Design System

```text
Claude Design  = visual source of truth
lib/core/theme = code source of truth for visual tokens
```

Claude Design decides what the product looks like. `lib/core/theme/` decides how
that is expressed in Flutter. Neither is bypassed.

> Feature implementation must reference the approved Claude Design through MCP
> before reproducing UI.

> Do not change the global design system merely to make one feature easier to
> implement.

## ✓ Current token status: synced (2026-09-17)

Colours, typography, spacing, radius, and elevation in `lib/core/theme/`
were confirmed against the approved Crown Solar Energy design system via
the Claude Design MCP (`_ds/cse-design-system-.../tokens/*.css`) during
the Login/Device-Binding UI implementation, and the `PROVISIONAL` headers
were removed from every token file. If Claude Design's tokens change
later, re-read them through the MCP and update these files the same way —
do not hand-edit a value without a corresponding Claude Design change.

Still outstanding: the CSE brand font family. `AppTypography.fontFamily`
remains deliberately `null` (platform default) — bundling the design
system's Inter face, and an Urdu Nastaliq-capable face for the `ur`
locale, is a separate whole-app decision (a new font-asset dependency)
that no single feature should make unilaterally.

## Where things live

| Concern | File |
| --- | --- |
| Colour primitives and status colours | `lib/core/theme/app_colors.dart` |
| Type scale | `lib/core/theme/app_typography.dart` |
| Spacing scale | `lib/core/theme/app_spacing.dart` |
| Corner radii | `lib/core/theme/app_radii.dart` |
| Elevation shadows | `lib/core/theme/app_shadows.dart` |
| Light + dark `ThemeData` | `lib/core/theme/app_theme.dart` |

## How tokens reach a screen

Standard Flutter theming is used before any custom machinery:

- Colours come from `Theme.of(context).colorScheme`.
- Text styles come from `Theme.of(context).textTheme`.
- Shape and component defaults come from the component themes in
  `AppTheme._build`.

Text styles carry no colour. `ThemeData` applies colour from the `ColorScheme`,
so a style never restates one.

### `ThemeExtension`

`AppStatusColors` exists only for `success`, `warning`, and `pending` — statuses
Material's `ColorScheme` has no slot for. Anything the scheme already models
(primary, surface, error, outline, `onSurfaceVariant`) is read from the scheme
and must not be duplicated into the extension.

```dart
final status = Theme.of(context).extension<AppStatusColors>()!;
```

## Light and dark

`AppTheme.light` and `AppTheme.dark` are both built by the same private
`_build` function, so the two themes cannot drift structurally. `CseApp` uses
`ThemeMode.system`.

A user-facing theme switcher is **not** implemented — that is a future Profile
feature. The architecture to support it is already in place.

## Rules for features

- Never write a raw hex colour, font declaration, radius, shadow, or unexplained
  spacing value in a screen.
- Never construct a `ThemeData` outside `lib/core/theme/`.
- Reuse existing tokens and components before adding new ones.
- If a feature genuinely needs a new reusable token or component, first confirm
  it is absent from the approved design system, then add the smallest required
  extension here — not in the feature.
- Verify light/dark and LTR/RTL implications for any new UI.
