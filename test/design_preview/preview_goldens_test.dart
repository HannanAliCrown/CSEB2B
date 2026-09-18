import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cse_b2b/core/localization/generated/app_localizations.dart';
import 'package:cse_b2b/core/theme/app_theme.dart';
import 'package:cse_b2b/features/design_preview/preview_catalog.dart';

/// Renders every screen in the design preview at the design's own 390x844
/// frame and writes it to `test/design_preview/goldens/`.
///
/// Run with `flutter test --update-goldens` to refresh the images after a UI
/// change; run it plain to catch an unintended visual change.
void main() {
  for (final board in previewBoards) {
    group('board ${board.number}', () {
      for (final screen in board.screens) {
        testWidgets('${screen.id} ${screen.title}', (tester) async {
          tester.view.physicalSize = const Size(390 * 2, 844 * 2);
          tester.view.devicePixelRatio = 2;
          addTearDown(tester.view.reset);

          await tester.pumpWidget(
            MaterialApp(
              theme: AppTheme.light,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: AppLocalizations.supportedLocales,
              home: Builder(builder: screen.builder),
            ),
          );
          await tester.pump(const Duration(milliseconds: 300));

          await expectLater(
            find.byType(MaterialApp),
            matchesGoldenFile(
              'goldens/${board.number}-${screen.id}.png',
            ),
          );
        });
      }
    });
  }
}
