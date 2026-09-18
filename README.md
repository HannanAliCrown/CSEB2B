# Crown Solar Energy — Mobile App

Flutter application for Crown Solar Energy (CSE). This repository currently
contains the **boilerplate only**: the app shell, architecture conventions, the
centralized design system, localization and navigation foundations, and Spec Kit
configuration. No CSE product feature is implemented yet.

## Prerequisites

- Flutter stable (developed against 3.47.4 / Dart 3.13.3)
- Android SDK with API 36 platform and build tools (for Android builds)
- Xcode (for iOS builds — macOS only)

On this machine Flutter is installed at `C:\src\flutter` and is **not** on the
system `PATH`. Add it for the session before running any command below:

```bash
$env:PATH = "C:\src\flutter\bin;$env:PATH"
```

## Getting started

```bash
flutter pub get
```

Run the app:

```bash
flutter run
```

Regenerate localizations after editing any ARB file:

```bash
flutter gen-l10n
```

## Verification

```bash
dart format .
flutter analyze
flutter test
```

All three must pass before a task is considered complete.

## Architecture

Simple MVVM:

```text
View → ViewModel → Repository → Service
```

`provider` + constructor injection for dependencies, `go_router` for
navigation. There is deliberately no domain/use-case layer and no service
locator.

Full detail, including an explicit list of what this project intentionally does
*not* have, is in [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md).

## Design system

All visual tokens live in `lib/core/theme/`. Claude Design is the visual source
of truth; `lib/core/theme/` is the code source of truth. Screens never hardcode
colours, fonts, radii, shadows, or magic spacing.

See [`docs/DESIGN_SYSTEM.md`](docs/DESIGN_SYSTEM.md).

> **The current token values are provisional placeholders.** Claude Design MCP
> could not be authorized when this boilerplate was created. See the design
> system doc for how to sync the real values.

## Features

Feature code lives under `lib/features/<feature>/`, split into `data/`
(models, repositories, services) and `ui/` (views, view_models, widgets).

The only feature present today is `bootstrap` — a temporary startup screen that
proves routing, theming, localization, and View/ViewModel binding work. It is
not product UI and should be deleted once the first real feature ships.

## Localization

English, Urdu (RTL), and Roman Urdu (`ur-Latn`, LTR) are supported. ARB sources
are in `lib/core/localization/arb/`; generated output goes to
`lib/core/localization/generated/`.

## Spec Kit

This repository uses [GitHub Spec Kit](https://github.com/github/spec-kit) with
the Claude Code integration. Project principles are in
[`.specify/memory/constitution.md`](.specify/memory/constitution.md).

Feature workflow:

```text
/speckit-specify → /speckit-clarify → /speckit-plan → /speckit-checklist
→ /speckit-tasks → /speckit-analyze → /speckit-implement → /speckit-converge
```

Agent rules: [`AGENTS.md`](AGENTS.md) (all agents) and
[`CLAUDE.md`](CLAUDE.md) (Claude Code specifics).

## Outstanding configuration

These are not yet supplied and have **not** been guessed:

- **Bundle / application identifier** — still the Flutter placeholder
  `com.example.cse_b2b` (`android/app/build.gradle.kts`, iOS project settings).
- **Release signing** — Android release currently signs with the debug key;
  no iOS signing team or provisioning profile is configured.
- **Design tokens** — all values in `lib/core/theme/` are provisional pending a
  Claude Design MCP sync.
- **Brand font family** — `AppTypography.fontFamily` is `null` (platform
  default). An Urdu Nastaliq-capable face is likely needed for the `ur` locale.
- **API base URLs, Firebase projects, and any secrets** — none configured.

## Platform targets

Portrait-first mobile only. Android and iOS are the only configured platforms;
web and desktop are intentionally absent.

- **Android**: `minSdk` 26 (Android 8.0), set explicitly.
- **iOS**: deployment target 15.0. The product brief asked for iOS 14+, but
  Flutter 3.47 requires iOS 15 as its floor, so 15.0 is the lowest supported
  value.
