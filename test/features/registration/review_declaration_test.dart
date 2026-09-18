import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cse_b2b/core/theme/app_theme.dart';
import 'package:cse_b2b/core/ui/ds.dart';
import 'package:cse_b2b/features/registration/data/repositories/registration_repository.dart';
import 'package:cse_b2b/features/registration/data/services/media_capture_service.dart';
import 'package:cse_b2b/features/registration/data/services/mock_registration_service.dart';
import 'package:cse_b2b/features/registration/data/services/registration_draft_store.dart';
import 'package:cse_b2b/features/registration/ui/registration_scope.dart';
import 'package:cse_b2b/features/registration/ui/view_models/registration_flow_view_model.dart';
import 'package:cse_b2b/features/registration/ui/views/registration_review_screens.dart';

/// The review step's declaration is a statement the partner makes. It must
/// never arrive already agreed to.
void main() {
  Future<void> pumpReview(WidgetTester tester, {required bool inWizard}) async {
    // Tall enough that the whole step fits, so the declaration is reachable
    // without scrolling it under the app bar.
    tester.view.physicalSize = const Size(390 * 2, 1600 * 2);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    final screen = const RegistrationReviewScreen();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: inWizard
            ? RegistrationScope(
                model: RegistrationFlowViewModel(
                  repository: RegistrationRepository(
                    service: MockRegistrationService(),
                    draftStore: InMemoryRegistrationDraftStore(),
                  ),
                  mediaCapture: FakeMediaCaptureService(),
                ),
                child: screen,
              )
            : screen,
      ),
    );
    await tester.pumpAndSettle();
  }

  DsCheckbox declaration(WidgetTester tester) =>
      tester.widget<DsCheckbox>(find.byType(DsCheckbox));

  DsButton submitButton(WidgetTester tester) => tester.widget<DsButton>(
    find.widgetWithText(DsButton, 'Submit Registration'),
  );

  testWidgets('the declaration starts unticked and blocks Submit', (
    tester,
  ) async {
    await pumpReview(tester, inWizard: true);

    expect(declaration(tester).checked, isFalse);
    expect(submitButton(tester).disabled, isTrue);
  });

  testWidgets('ticking the declaration releases Submit', (tester) async {
    await pumpReview(tester, inWizard: true);

    declaration(tester).onChanged!(true);
    await tester.pumpAndSettle();

    expect(declaration(tester).checked, isTrue);
    expect(submitButton(tester).disabled, isFalse);
  });

  testWidgets('the design preview keeps the ticked sample', (tester) async {
    await pumpReview(tester, inWizard: false);

    expect(declaration(tester).checked, isTrue);
  });
}
