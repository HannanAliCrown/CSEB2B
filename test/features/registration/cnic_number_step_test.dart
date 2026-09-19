import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:cse_b2b/core/theme/app_theme.dart';
import 'package:cse_b2b/core/ui/ds.dart';
import 'package:cse_b2b/features/registration/data/repositories/registration_repository.dart';
import 'package:cse_b2b/features/registration/data/services/media_capture_service.dart';
import 'package:cse_b2b/features/registration/data/services/mock_registration_service.dart';
import 'package:cse_b2b/features/registration/data/services/registration_draft_store.dart';
import 'package:cse_b2b/features/registration/ui/view_models/registration_flow_view_model.dart';
import 'package:cse_b2b/features/registration/ui/views/registration_flow_screen.dart';

/// Step 7 built the way the app builds it — through [RegistrationFlowScreen],
/// not the screen on its own — at the phone's own size.
///
/// A screenshot from the emulator showed this step as nothing but its two
/// footer buttons at the top of the screen, so these tests check the layout
/// itself, not just that the widgets exist.
///
/// Nothing here may call `pumpAndSettle`: the OTP step runs a resend
/// countdown, and a repeating timer never settles.
void main() {
  Future<RegistrationFlowViewModel> pumpAtCnic(
    WidgetTester tester, {
    required bool captured,
  }) async {
    tester.view.physicalSize = const Size(390 * 2, 844 * 2);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    final flow = RegistrationFlowViewModel(
      repository: RegistrationRepository(
        service: MockRegistrationService(),
        draftStore: InMemoryRegistrationDraftStore(),
      ),
      mediaCapture: FakeMediaCaptureService(),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: ChangeNotifierProvider.value(
          value: flow,
          child: RegistrationFlowScreen(
            onGoToLogin: () {},
            onSeeApprovalStatus: (_) {},
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));

    if (captured) {
      await flow.captureCnicFront();
      await flow.captureCnicBack();
      await flow.captureSelfie();
    }
    // Straight to step 7 — walking through step 5 would mount the countdown.
    flow.editStep(RegistrationStep.cnic);
    await tester.pump(const Duration(milliseconds: 400));
    return flow;
  }

  testWidgets('step 7 opens on the capture list, not a camera', (tester) async {
    await pumpAtCnic(tester, captured: false);

    expect(find.text('Check Your Captures'), findsOneWidget);
    expect(find.text('CNIC front'), findsOneWidget);
    expect(find.text('CNIC back'), findsOneWidget);
    expect(find.text('Liveness selfie'), findsOneWidget);
  });

  testWidgets('the number step lays out under its app bar', (tester) async {
    final flow = await pumpAtCnic(tester, captured: true);
    flow.openCnicNumber();
    await tester.pump(const Duration(milliseconds: 400));

    final title = find.text('Confirm CNIC Number');
    final field = find.byType(DsInput);
    final submit = find.widgetWithText(DsButton, 'Yes, This Is Correct');

    expect(title, findsOneWidget, reason: 'the step keeps its app bar');
    expect(field, findsOneWidget, reason: 'the number can always be typed');
    expect(submit, findsOneWidget);

    final fieldRect = tester.getRect(field);
    final titleBottom = tester.getRect(title).bottom;
    final submitTop = tester.getRect(submit).top;

    expect(
      fieldRect.top,
      greaterThan(titleBottom),
      reason: 'the field sits below the app bar, not above it',
    );
    expect(
      submitTop,
      greaterThan(fieldRect.bottom),
      reason: 'the buttons stay below the content, never on top of it',
    );
    expect(fieldRect.height, greaterThan(0));
    expect(
      fieldRect.bottom,
      lessThanOrEqualTo(844.0),
      reason: 'the field is on screen, not pushed off it',
    );
  });

  testWidgets('with nothing read from the photo the field starts empty', (
    tester,
  ) async {
    final flow = await pumpAtCnic(tester, captured: true);
    flow.openCnicNumber();
    await tester.pump(const Duration(milliseconds: 400));

    final field = tester.widget<DsInput>(find.byType(DsInput));

    expect(
      field.controller?.text,
      isEmpty,
      reason: 'no OCR runs, so no number is ever invented from the image',
    );
    expect(find.text('READ FROM IMAGE'), findsNothing);
    expect(find.text('35202-7719480-3'), findsNothing);
  });
}
