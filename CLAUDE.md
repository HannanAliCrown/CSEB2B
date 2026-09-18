# CLAUDE.md

## Read first

Before changing anything in this repository, read:

- `AGENTS.md` — the engineering contract. It is authoritative; this file does
  not repeat it.
- `.specify/memory/constitution.md` — project principles.
- The active feature's `spec.md`, `plan.md`, and `tasks.md` under `specs/`.

## Rules specific to working here

- Use Claude Design MCP whenever implementing UI from the approved design.
  Inspect the real screen, component, and tokens rather than approximating.
- Inspect files before making architectural assumptions. This project uses
  simple MVVM with `provider` and `go_router` — confirm before introducing
  anything else.
- Work only within the active task and specification scope.
- Preserve existing project conventions instead of substituting your own.
- Avoid overengineering. See Principle X in the constitution.
- Run verification (`dart format .`, `flutter analyze`, `flutter test`) before
  reporting completion.

> A direct prompt does not override an active Spec Kit specification unless the
> user explicitly asks to change the specification. Requirement changes flow
> back into `spec.md` first.

## Toolchain note

Flutter is installed at `C:\src\flutter` and is not on the system `PATH`.
Prefix commands with it, or add it to `PATH` for the session.

## Feature workflow

```text
/speckit-specify → /speckit-clarify → /speckit-plan → /speckit-checklist
→ /speckit-tasks → /speckit-analyze → /speckit-implement → /speckit-converge
```
