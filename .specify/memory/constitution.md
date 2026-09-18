# Crown Solar Energy Mobile App Constitution

## Core Principles

### I. Spec-Driven Development

No substantial feature implementation starts before a feature specification exists.

The specification defines WHAT and WHY. The plan defines HOW. Tasks define the
implementation sequence. Implementation follows those artifacts.

A direct chat prompt does not override an active specification. Requirement
changes flow back into `spec.md` first.

### II. Approved Design Is Authoritative

Claude Design is the authority for UI/UX. Code reproduces the approved design;
it does not reinterpret it.

Inspect the approved screen or component through Claude Design MCP before
implementing UI. Never substitute a generic Flutter widget because it is faster,
and never redesign an approved interaction unless the specification explicitly
changes the product requirement.

### III. Simple MVVM

The default architecture is:

```text
View → ViewModel → Repository → Service
```

Views render state and forward user intent. ViewModels own UI state and
behaviour. Repositories own application data. Services wrap one external source.

There is no domain/use-case layer. A feature plan may introduce one only when
that feature's real complexity justifies it, with the reason documented in
`plan.md`.

Add complexity only when a real requirement makes it necessary.

### IV. Centralized Design System

Visual tokens live in `lib/core/theme/`. Feature screens do not create parallel
themes, raw hex colours, ad-hoc font declarations, repeated radii or shadows, or
unexplained magic spacing.

A feature that genuinely needs a new reusable token or component first confirms
it is absent from the design system, then adds the smallest required extension.

### V. Minimum Necessary Dependencies

Every dependency must solve an immediate, documented requirement. A package is
added by the first feature that actually needs it, not in advance.

Prefer framework capabilities over third-party packages. Prefer plain Dart
models over code generation until serialization genuinely requires it.

### VI. Scope Discipline

A feature implementation changes only what is necessary to satisfy its
specification. No unrelated refactoring, no opportunistic cleanup, no
"while I was in here" improvements.

### VII. Testable Boundaries

Business and UI logic belongs outside widgets where practical so it can be
tested independently. Tests are written where they carry information, not to
inflate coverage.

### VIII. Localization and Accessibility

New UI must remain compatible with English, Urdu (RTL), Roman Urdu (LTR), light
mode, dark mode, system text scaling, and accessibility semantics.

User-visible strings are localized, never hardcoded in widgets.

### IX. Verification

Before implementation is considered complete, the following must succeed for the
affected project unless an environment limitation is documented:

```bash
dart format .
flutter analyze
flutter test
```

Environment-specific build failures are reported, not hidden. Distinguish a code
failure from a missing local SDK, signing, or tooling.

### X. No Overengineering (NON-NEGOTIABLE)

Implement the smallest clear solution that satisfies the current specification.
Do not add abstractions, extensibility, configuration, infrastructure, defensive
code, or architectural layers for requirements that do not exist.

Three similar lines of code are sometimes better than an abstraction nobody
currently needs.

## Technology Constraints

- Flutter stable toolchain; Dart SDK as pinned in `pubspec.yaml`.
- Targets: iOS 14+, Android 8+ (API 26+). Portrait-first mobile only. Web,
  macOS, Windows, and Linux targets are not supported.
- State management and DI: `provider`, `ChangeNotifier`/`Listenable`, and
  constructor injection. Riverpod, BLoC, GetX, MobX, GetIt, injectable, Redux,
  and custom service locators are out of scope.
- Navigation: `go_router`, with routes added by the feature that needs them.
- Secrets, production bundle identifiers, signing configuration, and environment
  credentials are never invented or committed.

## Development Workflow

Feature lifecycle:

```text
/speckit-specify → /speckit-clarify → /speckit-plan → /speckit-checklist
→ /speckit-tasks → /speckit-analyze → /speckit-implement → /speckit-converge
```

`/speckit-analyze` inconsistencies are fixed in the source artifacts before
implementation begins. Convergence does not expand feature scope.

One coherent feature or flow per specification. The CSE application is not
specified as a single document.

## Governance

This constitution supersedes ad-hoc practice. When the design, the
specification, and the code disagree, stop and surface the conflict in the
appropriate Spec Kit artifact rather than guessing.

Amendments are made by editing this file and noting the change below.
Complexity that violates Principle X must be justified in the feature's
`plan.md` or removed.

Runtime engineering guidance for AI agents lives in `AGENTS.md`.

**Version**: 1.0.0 | **Ratified**: 2026-09-17 | **Last Amended**: 2026-09-17
