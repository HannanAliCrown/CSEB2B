import 'package:flutter/material.dart';

/// Colour primitives for the CSE application.
///
/// Confirmed against the approved Crown Solar Energy design system
/// (`_ds/cse-design-system-.../tokens/colors.css`, read via the Claude
/// Design MCP on 2026-09-17) — see `docs/DESIGN_SYSTEM.md`. These are no
/// longer provisional.
abstract final class AppColors {
  // Brand
  static const brandPrimary = Color(0xFF04037E); // --c-primary / --c-crown-navy
  static const brandPrimaryDark = Color(0xFF02024F); // --accent-pressed
  static const brandPrimaryLight = Color(0xFF2E31B5); // --c-primary-light
  static const brandPrimaryHover = Color(0xFF0A0A9C); // --accent-hover
  static const brandPrimaryTint = Color(0xFFEEEEFB); // --c-primary-tint

  // Light surfaces and text
  static const lightBackground = Color(0xFFF8FAFC); // --c-bg
  static const lightSurface = Color(0xFFFFFFFF); // --c-surface
  static const lightSurfaceVariant = Color(
    0xFFF1F5F9,
  ); // --c-surface-2 / --fill-neutral
  static const lightTextPrimary = Color(0xFF0F172A); // --c-text-1
  static const lightTextSecondary = Color(0xFF475569); // --c-text-2
  static const lightTextTertiary = Color(0xFF94A3B8); // --c-text-3
  static const lightBorder = Color(
    0xFFE2E8F0,
  ); // --c-border / --border-hairline
  static const lightBorderStrong = Color(0xFFCBD5E1); // --border-strong
  static const lightFocusRing = Color(
    0x5204037E,
  ); // --focus-ring: rgba(4,3,126,.32)

  // Dark surfaces and text
  static const darkBackground = Color(0xFF0B0F14);
  static const darkSurface = Color(0xFF111827);
  static const darkSurfaceVariant = Color(0xFF1F2937);
  static const darkTextPrimary = Color(0xFFF8FAFC);
  static const darkTextSecondary = Color(0xFFCBD5E1);
  static const darkTextTertiary = Color(0xFF64748B);
  static const darkBorder = Color(0xFF374151);
  static const darkBorderStrong = Color(0xFF4B5563);
  static const darkFocusRing = Color(0x736A6FE8); // rgba(106,111,232,.45)
  static const darkBrandPrimary = Color(0xFF6A6FE8);

  // Status — strong colours (borders, icons, direct emphasis)
  static const lightSuccess = Color(0xFF0E9F6E);
  static const lightWarning = Color(0xFFD97706);
  static const lightError = Color(0xFFC6292C);
  static const lightInfo = Color(0xFF0F8FA8);

  static const darkSuccess = Color(0xFF34D399);
  static const darkWarning = Color(0xFFF0A83C);
  static const darkError = Color(0xFFF08A8C);
  static const darkInfo = Color(0xFF3EC0D6);
}

/// Status tones Material's [ColorScheme] has no slot for: a text/icon
/// colour plus its soft background fill, for success, warning, error,
/// info, and a neutral tone (used where the design deliberately avoids
/// error/red — e.g. "your account is fixed to another phone" is a fact,
/// not a fault). Each `*` field is the on-fill colour (for text/icons on
/// top of the matching `*Fill`); `ColorScheme.error` remains the *strong*
/// colour for borders/icons directly, a different slot from `error` here.
///
/// Anything [ColorScheme] already models (primary, surface, the strong
/// error colour, outline) is read from the scheme instead of being
/// duplicated here. Flat [Color] fields (rather than a wrapper type) so
/// existing call sites that read a single status colour — e.g.
/// `registration_screen.dart`'s `.success` — keep working unchanged.
@immutable
class AppStatusColors extends ThemeExtension<AppStatusColors> {
  const AppStatusColors({
    required this.success,
    required this.successFill,
    required this.warning,
    required this.warningFill,
    required this.error,
    required this.errorFill,
    required this.info,
    required this.infoFill,
    required this.neutral,
    required this.neutralFill,
  });

  final Color success;
  final Color successFill;
  final Color warning;
  final Color warningFill;
  final Color error;
  final Color errorFill;
  final Color info;
  final Color infoFill;
  final Color neutral;
  final Color neutralFill;

  static const light = AppStatusColors(
    success: Color(0xFF0A7A54),
    successFill: Color(0xFFD8F3E7),
    warning: Color(0xFFA65B05),
    warningFill: Color(0xFFFEF0DC),
    error: Color(0xFF9E1F22),
    errorFill: Color(0xFFFBE3E3),
    info: Color(0xFF0A6E82),
    infoFill: Color(0xFFDCF1F5),
    neutral: AppColors.lightTextSecondary,
    neutralFill: AppColors.lightSurfaceVariant,
  );

  static const dark = AppStatusColors(
    success: Color(0xFF4ADE80),
    successFill: Color(0xFF0E2A1B),
    warning: Color(0xFFF0A83C),
    warningFill: Color(0xFF2E2210),
    error: Color(0xFFF5A9AB),
    errorFill: Color(0xFF2E1414),
    info: Color(0xFF7DD8E8),
    infoFill: Color(0xFF0C2830),
    neutral: AppColors.darkTextSecondary,
    neutralFill: AppColors.darkSurfaceVariant,
  );

  @override
  AppStatusColors copyWith({
    Color? success,
    Color? successFill,
    Color? warning,
    Color? warningFill,
    Color? error,
    Color? errorFill,
    Color? info,
    Color? infoFill,
    Color? neutral,
    Color? neutralFill,
  }) {
    return AppStatusColors(
      success: success ?? this.success,
      successFill: successFill ?? this.successFill,
      warning: warning ?? this.warning,
      warningFill: warningFill ?? this.warningFill,
      error: error ?? this.error,
      errorFill: errorFill ?? this.errorFill,
      info: info ?? this.info,
      infoFill: infoFill ?? this.infoFill,
      neutral: neutral ?? this.neutral,
      neutralFill: neutralFill ?? this.neutralFill,
    );
  }

  @override
  AppStatusColors lerp(AppStatusColors? other, double t) {
    if (other == null) return this;
    return AppStatusColors(
      success: Color.lerp(success, other.success, t)!,
      successFill: Color.lerp(successFill, other.successFill, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningFill: Color.lerp(warningFill, other.warningFill, t)!,
      error: Color.lerp(error, other.error, t)!,
      errorFill: Color.lerp(errorFill, other.errorFill, t)!,
      info: Color.lerp(info, other.info, t)!,
      infoFill: Color.lerp(infoFill, other.infoFill, t)!,
      neutral: Color.lerp(neutral, other.neutral, t)!,
      neutralFill: Color.lerp(neutralFill, other.neutralFill, t)!,
    );
  }
}
