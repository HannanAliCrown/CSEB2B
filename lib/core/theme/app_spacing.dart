/// Spacing scale, in logical pixels.
///
/// Confirmed against the approved Crown Solar Energy design system
/// (`tokens/spacing.css`, read via the Claude Design MCP on 2026-09-17).
/// `xs`–`xxl` map exactly onto the design's `--space-*` scale and are kept
/// under their original names for existing callers; `screenPadding`
/// through `tapMin` are the design's own named tokens, added for new UI
/// that should cite them directly rather than picking the nearest step.
abstract final class AppSpacing {
  static const xs = 4.0; // --space-1
  static const sm = 8.0; // --space-2
  static const stepMd = 12.0; // --space-3 (not `md` — see AppSpacing.md below)
  static const md = 16.0; // --space-4
  static const stepLg = 20.0; // --space-5
  static const lg = 24.0; // --space-6
  static const xl = 32.0; // --space-8
  static const stepXl = 40.0; // --space-10
  static const xxl = 48.0; // --space-12
  static const step2xl = 64.0; // --space-16

  /// --screen-padding: horizontal page padding for full-screen views.
  static const screenPadding = 20.0;

  /// --section-gap: vertical gap between major sections on a screen.
  static const sectionGap = 28.0;

  /// --card-padding: internal padding for a bordered card.
  static const cardPadding = 18.0;

  /// --list-gap: gap between items in a list/stack of rows.
  static const listGap = 12.0;

  /// --h-button: standard button height.
  static const buttonHeight = 50.0;

  /// --h-button-sm: small/compact button height.
  static const buttonHeightSm = 38.0;

  /// --h-input: standard text-input field height.
  static const inputHeight = 52.0;

  /// --tap-min: minimum accessible tap target.
  static const tapMin = 48.0;
}
