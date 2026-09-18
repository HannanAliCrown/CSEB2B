import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Design tokens that Material's [ColorScheme] has no slot for: the sunken
/// surface, the soft accent fill, tertiary text, the strong border, and the
/// brand/energy hues the design uses for illustration and charting.
///
/// Read through `Theme.of(context).extension<AppPalette>()!` — screens never
/// restate these values.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.sunken,
    required this.accentSoft,
    required this.textTertiary,
    required this.borderStrong,
    required this.crownRed,
    required this.crownGold,
    required this.crownAmber,
    required this.solar,
    required this.battery,
    required this.grid,
    required this.offline,
  });

  /// --surface-sunken
  final Color sunken;

  /// --accent-soft
  final Color accentSoft;

  /// --text-tertiary
  final Color textTertiary;

  /// --border-strong
  final Color borderStrong;

  final Color crownRed;
  final Color crownGold;
  final Color crownAmber;
  final Color solar;
  final Color battery;
  final Color grid;
  final Color offline;

  static const light = AppPalette(
    sunken: AppColors.lightSurfaceVariant,
    accentSoft: AppColors.brandPrimaryTint,
    textTertiary: AppColors.lightTextTertiary,
    borderStrong: AppColors.lightBorderStrong,
    crownRed: Color(0xFFC6292C),
    crownGold: Color(0xFFE5B83A),
    crownAmber: Color(0xFFE09330),
    solar: Color(0xFFE8A21C),
    battery: Color(0xFF0E9F6E),
    grid: Color(0xFF0F8FA8),
    offline: Color(0xFF94A3B8),
  );

  static const dark = AppPalette(
    sunken: Color(0xFF0F1620),
    accentSoft: Color(0xFF161843),
    textTertiary: AppColors.darkTextTertiary,
    borderStrong: AppColors.darkBorderStrong,
    crownRed: Color(0xFFE8555A),
    crownGold: Color(0xFFF0C64F),
    crownAmber: Color(0xFFEEA24A),
    solar: Color(0xFFF5C243),
    battery: Color(0xFF34D399),
    grid: Color(0xFF3EC0D6),
    offline: Color(0xFF64748B),
  );

  @override
  AppPalette copyWith({
    Color? sunken,
    Color? accentSoft,
    Color? textTertiary,
    Color? borderStrong,
    Color? crownRed,
    Color? crownGold,
    Color? crownAmber,
    Color? solar,
    Color? battery,
    Color? grid,
    Color? offline,
  }) {
    return AppPalette(
      sunken: sunken ?? this.sunken,
      accentSoft: accentSoft ?? this.accentSoft,
      textTertiary: textTertiary ?? this.textTertiary,
      borderStrong: borderStrong ?? this.borderStrong,
      crownRed: crownRed ?? this.crownRed,
      crownGold: crownGold ?? this.crownGold,
      crownAmber: crownAmber ?? this.crownAmber,
      solar: solar ?? this.solar,
      battery: battery ?? this.battery,
      grid: grid ?? this.grid,
      offline: offline ?? this.offline,
    );
  }

  @override
  AppPalette lerp(AppPalette? other, double t) {
    if (other == null) return this;
    return AppPalette(
      sunken: Color.lerp(sunken, other.sunken, t)!,
      accentSoft: Color.lerp(accentSoft, other.accentSoft, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      borderStrong: Color.lerp(borderStrong, other.borderStrong, t)!,
      crownRed: Color.lerp(crownRed, other.crownRed, t)!,
      crownGold: Color.lerp(crownGold, other.crownGold, t)!,
      crownAmber: Color.lerp(crownAmber, other.crownAmber, t)!,
      solar: Color.lerp(solar, other.solar, t)!,
      battery: Color.lerp(battery, other.battery, t)!,
      grid: Color.lerp(grid, other.grid, t)!,
      offline: Color.lerp(offline, other.offline, t)!,
    );
  }
}

/// Shorthand accessors so screens read tokens without restating lookups.
extension AppThemeX on BuildContext {
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get texts => Theme.of(this).textTheme;
  AppPalette get palette => Theme.of(this).extension<AppPalette>()!;
  AppStatusColors get status => Theme.of(this).extension<AppStatusColors>()!;
}
