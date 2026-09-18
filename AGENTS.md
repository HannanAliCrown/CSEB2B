# AGENTS.md

Engineering contract for AI coding agents working in this repository. It is
vendor-neutral and applies to any agent, regardless of tool.

> The simplest implementation that completely satisfies the active
> specification is preferred.

> Do not design for imaginary future requirements.

## Working method

1. Read the active Spec Kit feature artifacts (`spec.md`, `plan.md`,
   `tasks.md`) before implementing a feature.
2. Do not implement features from vague chat instructions when a Spec Kit
   feature exists for that work. Requirement changes go into `spec.md` first.
3. Keep changes scoped to the active Spec Kit task.
4. Do not refactor unrelated code.
5. When the design, the specification, and the code disagree, stop guessing and
   surface the conflict in the appropriate Spec Kit artifact.

## Architecture

6. Follow MVVM: `View → ViewModel → Repository → Service`.
7. Views contain layout and presentation only — no business logic, and no
   direct calls to repositories or services.
8. ViewModels depend on repositories, not on services directly, unless the
   plan explicitly justifies otherwise.
9. Repositories and services never import UI.
10. Use constructor injection. `provider` only makes dependencies available;
    it is not a global state container.
11. Do not add architectural layers for hypothetical future requirements, and
    do not create a generic abstraction for a single use.

## Design system

12. `lib/core/theme/` is the design token authority.
13. Do not hardcode colours, fonts, radii, shadows, or magic spacing in
    screens.
14. Use Claude Design MCP as the implementation reference for approved UI.
15. Do not redesign approved screens while implementing them.

## Quality

16. Maintain English / Urdu (RTL) / Roman Urdu (LTR) readiness. Localize every
    user-visible string.
17. Respect system text scaling, safe areas, accessible semantics, and
    reasonable touch targets.
18. Run `dart format .`, `flutter analyze`, and `flutter test` before
    considering a task complete.
19. Never commit secrets, signing material, or environment credentials.
20. Do not leave dead code, demo code, or unused dependencies behind.

## Do not create

`BaseViewModel`, `BaseRepository`, `BaseService`, generic CRUD repository
frameworks, speculative `Result<T>` ecosystems, generic use-case classes,
service locators, automatic dependency registration, global event buses,
custom responsive frameworks, generic API layers before an API feature exists,
offline-sync or caching frameworks before they are specified, feature flags
without a feature requirement, environment/flavor systems before environments
are supplied, or CI/CD infrastructure unless explicitly requested.
