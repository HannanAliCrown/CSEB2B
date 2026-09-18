# Architecture

## Layers

```text
View
  ↓ user actions
ViewModel
  ↓
Repository
  ↓
Service / external source
```

Data flows back upward:

```text
Service → Repository → ViewModel → View
```

Dependencies point downward only. Nothing below the ViewModel knows that a UI
exists.

### View

Flutter widgets and screens. A View renders UI state, observes its ViewModel,
and forwards user interactions to it. It holds layout and presentation logic
only — no business rules, and no direct repository or service calls.

### ViewModel

Owns the UI state and behaviour for its View. Written as a plain Dart class
extending `ChangeNotifier` (or exposing a `Listenable`) when reactive state is
needed. It receives repositories through its constructor.

`BuildContext`-dependent logic stays in the View, not the ViewModel.

### Repository

Source of truth for application and domain data. A repository coordinates the
data a ViewModel needs, and may later handle caching, synchronization,
transformation, or several services once a real feature requires it.

### Service

A thin boundary around one external source: a REST API, a platform API, a
device capability, or a persistence mechanism. Services hold no presentation
state.

## Folder convention

Feature-first, with shared infrastructure kept small:

```text
lib/
├── main.dart
├── app/
│   ├── app.dart              # MaterialApp.router, theme + locale wiring
│   └── router/
│       ├── app_router.dart   # route table
│       └── route_not_found_screen.dart
├── core/
│   ├── localization/         # ARB sources, generated output, locale helpers
│   └── theme/                # design tokens and ThemeData
└── features/
    └── <feature>/
        ├── data/
        │   ├── models/
        │   ├── repositories/
        │   └── services/
        └── ui/
            ├── views/
            ├── view_models/
            └── widgets/
```

Only the directories a feature actually uses are created. The bootstrap feature
has no `data/` folder because it has no data.

Code moves into `core/` when it is genuinely application-wide — not because it
might be reused one day. Prefer keeping something feature-local until real
reuse appears.

## Dependency injection

`provider` makes ViewModels and dependencies available where they are needed.
Dependencies are otherwise passed explicitly through constructors.

ViewModels are provided at the route that uses them (see `app_router.dart`),
not registered in a global container. A dependency is hoisted to the app level
only when more than one feature genuinely shares it.

## Navigation

`go_router`, configured in `lib/app/router/app_router.dart`. Route paths are
constants on `AppRoutes` so no caller spells a location as a bare string. Each
feature adds its own routes when it is specified; there is no pre-built global
route table.

## Localization

ARB files in `lib/core/localization/arb/` generate into
`lib/core/localization/generated/` via `flutter gen-l10n` (configured in
`l10n.yaml`). Supported locales come from the generated
`AppLocalizations.supportedLocales`.

Roman Urdu is modelled as `ur-Latn`. Flutter infers text direction from the
language code alone, which would wrongly render Roman Urdu RTL, so
`AppLocales.directionOf` resolves direction from the script code and
`CseApp.builder` applies it.

## What We Intentionally Do Not Have

These omissions are deliberate. Do not "improve" the architecture by adding
them without a real, specified requirement.

- **No domain / use-case / interactor layer.** `View → ViewModel → Repository
  → Service` is enough. A feature plan may introduce one only when that
  feature's complexity justifies it, with the reason documented.
- **No service locator** (`get_it`, `injectable`) and no automatic dependency
  registration. Constructor injection plus `provider`.
- **No global business singletons** or app-wide mutable state container.
- **No `BaseViewModel`, `BaseRepository`, or `BaseService`.**
- **No generic `Result<T>` / error architecture.** Handle failures where a
  specification describes the failure behaviour.
- **No code generation** for models (`freezed`, `json_serializable`,
  `build_runner`). Plain Dart models until serialization genuinely demands
  otherwise.
- **No networking stack.** `dio`/`retrofit` belong to the first feature that
  has an API contract.
- **No custom responsive framework.** Standard Flutter layout widgets only.
- **No environment/flavor system, feature flags, or CI/CD** until they are
  requested.
- **No alternative state management.** `provider` + `ChangeNotifier` only.
