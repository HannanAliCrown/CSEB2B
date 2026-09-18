import 'package:flutter/material.dart';

/// Type scale for the CSE application.
///
/// Confirmed against the approved Crown Solar Energy design system
/// (`tokens/typography.css`, read via the Claude Design MCP on
/// 2026-09-17): sizes, line heights, weights, and letter-spacing below map
/// directly onto the design's `--fs-*`/`--lh-*`/`--fw-*`/`--tracking-*`
/// tokens.
///
/// [fontFamily] remains intentionally null (platform default). The design
/// system's brand face is Inter, but bundling it — and an Urdu
/// Nastaliq-capable face for the `ur` locale — is a separate, whole-app
/// decision outside a single feature's scope; see `docs/DESIGN_SYSTEM.md`.
///
/// Colours are deliberately omitted — [ThemeData] applies them from the
/// [ColorScheme], so a text style never needs to name a colour.
abstract final class AppTypography {
  static const String? fontFamily = null;

  static const double _trackingTight = -0.02;

  static const TextTheme textTheme = TextTheme(
    // --fs-title/--lh-title/--fw-title (24/30/600), tracking-tight.
    headlineSmall: TextStyle(
      fontSize: 24,
      height: 30 / 24,
      fontWeight: FontWeight.w600,
      letterSpacing: _trackingTight * 24,
    ),
    // --fs-section/--lh-section/--fw-section (18/24/600), tracking-tight —
    // AppBar titles, dialog titles.
    titleLarge: TextStyle(
      fontSize: 18,
      height: 24 / 18,
      fontWeight: FontWeight.w600,
      letterSpacing: _trackingTight * 18,
    ),
    // A 20/26/600 heading the design uses for in-body OTP-step titles
    // ("Enter the 6-digit code") — between section and title in the scale;
    // titleMedium is otherwise unused by this feature.
    titleMedium: TextStyle(
      fontSize: 20,
      height: 26 / 20,
      fontWeight: FontWeight.w600,
      letterSpacing: _trackingTight * 20,
    ),
    // --fs-body/--lh-body/--fw-body (16/24/400).
    bodyLarge: TextStyle(
      fontSize: 16,
      height: 24 / 16,
      fontWeight: FontWeight.w400,
    ),
    // --fs-secondary/--lh-secondary (14/20), regular weight — banner/card body text.
    bodyMedium: TextStyle(
      fontSize: 14,
      height: 20 / 14,
      fontWeight: FontWeight.w400,
    ),
    // --fs-caption/--lh-caption (12/16) — footnotes, helper text.
    bodySmall: TextStyle(
      fontSize: 12,
      height: 16 / 12,
      fontWeight: FontWeight.w400,
    ),
    // --fs-secondary + --fw-medium (14/20/500) — input labels.
    labelLarge: TextStyle(
      fontSize: 14,
      height: 20 / 14,
      fontWeight: FontWeight.w500,
    ),
  );

  // --fs-button/--lh-button/--fw-button (16/24/600) — the Button
  // component's label. Deliberately not `textTheme.labelLarge`: that slot
  // is already claimed by the 14/500 input-label style above, and Material
  // buttons read their default text style from `labelLarge`, so leaving it
  // at 14/500 is what makes an unthemed [ElevatedButton] render an
  // undersized, under-weight label — set explicitly on each button theme
  // instead.
  static const TextStyle buttonLabel = TextStyle(
    fontSize: 16,
    height: 24 / 16,
    fontWeight: FontWeight.w600,
  );
}
