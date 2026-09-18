import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_palette.dart';
import 'app_radii.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// The single source of truth for application theming.
///
/// Feature screens read colours, type and shape from `Theme.of(context)`. They
/// must not construct their own [ThemeData] or restate token values.
abstract final class AppTheme {
  static ThemeData get light => _build(
    colorScheme: const ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.brandPrimary,
      onPrimary: Colors.white, // --text-on-accent
      secondary: AppColors.brandPrimaryLight,
      onSecondary: Colors.white,
      error: AppColors.lightError,
      onError: Colors.white,
      surface: AppColors.lightSurface,
      onSurface: AppColors.lightTextPrimary,
      onSurfaceVariant: AppColors.lightTextSecondary,
      surfaceContainerHighest: AppColors.lightSurfaceVariant,
      outline: AppColors.lightBorder,
      outlineVariant: AppColors.lightBorderStrong,
    ),
    scaffoldBackground: AppColors.lightBackground,
    divider: AppColors.lightBorder,
    focusRing: AppColors.lightFocusRing,
    textTertiary: AppColors.lightTextTertiary,
    statusColors: AppStatusColors.light,
    palette: AppPalette.light,
  );

  static ThemeData get dark => _build(
    colorScheme: const ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.darkBrandPrimary,
      onPrimary: Colors.white,
      secondary: AppColors.brandPrimaryLight,
      onSecondary: Colors.white,
      error: AppColors.darkError,
      onError: AppColors.darkTextPrimary,
      surface: AppColors.darkSurface,
      onSurface: AppColors.darkTextPrimary,
      onSurfaceVariant: AppColors.darkTextSecondary,
      surfaceContainerHighest: AppColors.darkSurfaceVariant,
      outline: AppColors.darkBorder,
      outlineVariant: AppColors.darkBorderStrong,
    ),
    scaffoldBackground: AppColors.darkBackground,
    divider: AppColors.darkBorder,
    focusRing: AppColors.darkFocusRing,
    textTertiary: AppColors.darkTextTertiary,
    statusColors: AppStatusColors.dark,
    palette: AppPalette.dark,
  );

  static ThemeData _build({
    required ColorScheme colorScheme,
    required Color scaffoldBackground,
    required Color divider,
    required Color focusRing,
    required Color textTertiary,
    required AppStatusColors statusColors,
    required AppPalette palette,
  }) {
    return ThemeData(
      colorScheme: colorScheme,
      fontFamily: AppTypography.fontFamily,
      textTheme: AppTypography.textTheme,
      scaffoldBackgroundColor: scaffoldBackground,
      dividerTheme: DividerThemeData(color: divider, space: 1, thickness: 1),
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        titleTextStyle: AppTypography.textTheme.titleLarge?.copyWith(
          color: colorScheme.onSurface,
        ),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      // --h-button/--radius-button: 50px tall, 13px corners, navy fill,
      // white 16/600 label. Material 3's [ElevatedButton] defaults to a
      // *surface*-coloured background with a primary-coloured label and a
      // tonal elevation/surface tint — the opposite of the design's filled
      // Button — so background, foreground, elevation and the surface tint
      // are all set explicitly rather than left to that default.
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          textStyle: AppTypography.buttonLabel,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          minimumSize: const Size.fromHeight(AppSpacing.buttonHeight),
          shape: const RoundedRectangleBorder(
            borderRadius: AppRadii.buttonRadius,
          ),
          disabledBackgroundColor: colorScheme.primary.withValues(alpha: 0.45),
          disabledForegroundColor: colorScheme.onPrimary.withValues(
            alpha: 0.45,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(AppSpacing.buttonHeight),
          shape: const RoundedRectangleBorder(
            borderRadius: AppRadii.buttonRadius,
          ),
          side: BorderSide(color: colorScheme.outline),
          foregroundColor: colorScheme.onSurface,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(0, AppSpacing.buttonHeightSm),
          foregroundColor: colorScheme.primary,
        ),
      ),
      // --h-input/--radius-input: 52px tall, 12px corners, hairline
      // border → accent focus ring → error border (Input component).
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        labelStyle: AppTypography.textTheme.labelLarge?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        hintStyle: AppTypography.textTheme.bodyLarge?.copyWith(
          color: textTertiary,
        ),
        border: OutlineInputBorder(
          borderRadius: AppRadii.mdRadius,
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadii.mdRadius,
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadii.mdRadius,
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadii.mdRadius,
          borderSide: BorderSide(color: colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadii.mdRadius,
          borderSide: BorderSide(color: colorScheme.error, width: 1.5),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: AppRadii.mdRadius,
          borderSide: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.5),
          ),
        ),
      ),
      // Checkbox component: 22x22, 6px corners, 1.5px border, navy-filled
      // with a white check when selected (design has no default Material
      // checkbox shape, so this is expressed via CheckboxThemeData rather
      // than a bespoke widget).
      checkboxTheme: CheckboxThemeData(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(6)),
        ),
        side: BorderSide(color: colorScheme.outlineVariant, width: 1.5),
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? colorScheme.primary
              : Colors.transparent,
        ),
        checkColor: const WidgetStatePropertyAll(Colors.white),
      ),
      extensions: [statusColors, palette],
    );
  }
}
