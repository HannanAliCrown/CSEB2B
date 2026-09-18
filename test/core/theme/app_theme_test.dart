import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cse_b2b/core/theme/app_colors.dart';
import 'package:cse_b2b/core/theme/app_theme.dart';

void main() {
  group('AppTheme', () {
    test('builds a light theme carrying the status colour extension', () {
      final theme = AppTheme.light;

      expect(theme.colorScheme.brightness, Brightness.light);
      expect(theme.extension<AppStatusColors>(), AppStatusColors.light);
    });

    test('builds a dark theme carrying the status colour extension', () {
      final theme = AppTheme.dark;

      expect(theme.colorScheme.brightness, Brightness.dark);
      expect(theme.extension<AppStatusColors>(), AppStatusColors.dark);
    });

    test('applies the shared type scale to both themes', () {
      expect(
        AppTheme.light.textTheme.bodyMedium?.fontSize,
        AppTheme.dark.textTheme.bodyMedium?.fontSize,
      );
    });

    test('primary (elevated) buttons are filled navy with a white 16/600 '
        'label, not Material 3\'s surface-coloured elevated default', () {
      final theme = AppTheme.light;
      final style = theme.elevatedButtonTheme.style!;
      const enabled = <WidgetState>{};

      expect(
        style.backgroundColor?.resolve(enabled),
        theme.colorScheme.primary,
      );
      expect(
        style.foregroundColor?.resolve(enabled),
        theme.colorScheme.onPrimary,
      );
      expect(style.elevation?.resolve(enabled), 0);
      expect(style.surfaceTintColor?.resolve(enabled), Colors.transparent);
      expect(style.textStyle?.resolve(enabled)?.fontSize, 16);
      expect(style.textStyle?.resolve(enabled)?.fontWeight, FontWeight.w600);
    });
  });
}
