import 'package:flutter_test/flutter_test.dart';

import 'package:cse_b2b/features/registration/data/models/registration_draft.dart';
import 'package:cse_b2b/features/registration/data/repositories/registration_repository.dart';
import 'package:cse_b2b/features/registration/data/services/media_capture_service.dart';
import 'package:cse_b2b/features/registration/data/services/mock_registration_data_store.dart';
import 'package:cse_b2b/features/registration/data/services/mock_registration_service.dart';
import 'package:cse_b2b/features/registration/data/services/registration_draft_store.dart';
import 'package:cse_b2b/features/registration/ui/view_models/registration_flow_view_model.dart';

({
  RegistrationFlowViewModel model,
  InMemoryRegistrationDraftStore drafts,
  FakeMediaCaptureService media,
})
_build({InMemoryRegistrationDraftStore? drafts}) {
  final draftStore = drafts ?? InMemoryRegistrationDraftStore();
  final media = FakeMediaCaptureService();
  return (
    model: RegistrationFlowViewModel(
      repository: RegistrationRepository(
        service: MockRegistrationService(),
        draftStore: draftStore,
      ),
      mediaCapture: media,
    ),
    drafts: draftStore,
    media: media,
  );
}

/// Walks the wizard up to [stop], filling each step with valid data.
Future<RegistrationFlowViewModel> _fillTo(
  RegistrationFlowViewModel model,
  RegistrationStep stop, {
  RegistrationRole role = RegistrationRole.installer,
}) async {
  await model.start();

  model.setMobileNumber('300 1122334');
  await model.submitMobileNumber();
  if (stop == RegistrationStep.role) return model;

  model.setRole(role);
  model.next();
  if (stop == RegistrationStep.details) return model;

  model.updateDraft(
    (d) => d.copyWith(
      fullName: 'Test Partner',
      businessName: 'Test Solar Works',
      businessAddress: 'Shop 1, Test Market',
      market: 'Ravi Road, Lahore',
    ),
  );
  model.next();
  if (stop == RegistrationStep.media) return model;

  if (role == RegistrationRole.installer) {
    model.setVideoLink(0, 'youtu.be/one');
    model.setVideoLink(1, 'youtu.be/two');
  } else {
    await model.captureShopImage('Shop Board', MediaSource.camera);
    await model.captureShopImage('Shop Image', MediaSource.gallery);
  }
  model.next();
  if (stop == RegistrationStep.otp) return model;

  await model.requestOtp();
  await model.submitOtp(MockRegistrationDataStore.developmentOtp);
  if (stop == RegistrationStep.source) return model;

  final source = await model.lookupBuyingSource('+92 300 7781204');
  model.replaceBuyingSource(0, source);
  model.next();
  if (stop == RegistrationStep.cnic) return model;

  model.updateDraft((d) => d.copyWith(cnicNumber: '35202-7719480-3'));
  await model.captureCnicFront();
  await model.captureCnicBack();
  await model.captureSelfie();
  model.next();
  return model;
}

void main() {
  group('registration wizard', () {
    test('REG-01 a new number moves to the role step', () async {
      final harness = _build();
      await harness.model.start();

      harness.model.setMobileNumber('300 1122334');
      await harness.model.submitMobileNumber();

      expect(harness.model.existingAccount, isNull);
      expect(harness.model.step, RegistrationStep.role);
      expect(
        harness.model.draft.role,
        RegistrationRole.installer,
        reason: 'the draft matches the role the step renders as selected',
      );
      expect(harness.model.validationFor(RegistrationStep.role), isNull);
    });

    test('REG-02 an existing number does not start a registration', () async {
      final harness = _build();
      await harness.model.start();

      harness.model.setMobileNumber('321 7745002');
      await harness.model.submitMobileNumber();

      expect(harness.model.existingAccount?.exists, isTrue);
      expect(harness.model.existingAccount?.role, 'Retailer');
      expect(harness.model.step, RegistrationStep.number);
      expect(
        harness.model.validationFor(RegistrationStep.number),
        isNotNull,
        reason: 'Continue stays unavailable until the number changes',
      );
    });

    test('REG-03/04 the media step follows the chosen role', () async {
      final installer = _build().model;
      await _fillTo(installer, RegistrationStep.media);
      expect(installer.draft.role, RegistrationRole.installer);

      final retailer = _build().model;
      await _fillTo(
        retailer,
        RegistrationStep.media,
        role: RegistrationRole.retailer,
      );
      expect(retailer.draft.role, RegistrationRole.retailer);
    });

    test('REG-05 missing required media blocks the step', () async {
      final model = _build().model;
      await _fillTo(model, RegistrationStep.media);

      model.setVideoLink(0, 'youtu.be/only-one');
      model.next();

      expect(model.step, RegistrationStep.media);
      expect(model.error, isNotNull);
    });

    test('REG-06 a wrong OTP keeps the step and the draft', () async {
      final model = _build().model;
      await _fillTo(model, RegistrationStep.otp);

      await model.requestOtp();
      await model.submitOtp('000000');

      expect(model.otpInvalid, isTrue);
      expect(model.draft.mobileVerified, isFalse);
      expect(model.step, RegistrationStep.otp);
      expect(model.draft.fullName, 'Test Partner');
    });

    test('REG-07 the right OTP verifies the number and continues', () async {
      final model = _build().model;
      await _fillTo(model, RegistrationStep.source);

      expect(model.draft.mobileVerified, isTrue);
      expect(model.step, RegistrationStep.source);
    });

    test('REG-08 a buying source resolves to its business name', () async {
      final model = _build().model;
      await _fillTo(model, RegistrationStep.source);

      final entry = await model.lookupBuyingSource('+92 300 7781204');

      expect(entry.matchedName, 'Al-Noor Electric Store');
      expect(entry.matchedRole, 'Retailer');
    });

    test('REG-09 every source is kept, and the first one verifies', () async {
      final model = _build().model;
      await _fillTo(model, RegistrationStep.source);

      model.replaceBuyingSource(
        0,
        await model.lookupBuyingSource('+92 300 7781204'),
      );
      model.replaceBuyingSource(
        1,
        await model.lookupBuyingSource('+92 301 4429911'),
      );

      expect(model.draft.buyingSources, hasLength(2));
      expect(
        model.draft.verifyingSource?.matchedName,
        'Al-Noor Electric Store',
      );
    });

    test('REG-10 an unknown buying source reports not found', () async {
      final model = _build().model;
      await _fillTo(model, RegistrationStep.source);

      final entry = await model.lookupBuyingSource('+92 399 0000000');

      expect(entry.isFound, isFalse);
      expect(model.lastSourceLookup?.found, isFalse);
    });

    test('REG-11 identity captures only ever use the camera', () async {
      final harness = _build();
      await _fillTo(harness.model, RegistrationStep.cnic);

      await harness.model.captureCnicFront();
      await harness.model.captureCnicBack();
      await harness.model.captureSelfie();

      expect(
        harness.media.calls.where((c) => c.startsWith('identity')),
        hasLength(3),
      );
      expect(
        harness.media.calls.any((c) => c.contains('gallery')),
        isFalse,
        reason: 'the gallery is never offered for CNIC or the selfie',
      );
    });

    test('REG-12 shop photos may come from camera or gallery', () async {
      final harness = _build();
      await _fillTo(
        harness.model,
        RegistrationStep.media,
        role: RegistrationRole.retailer,
      );

      await harness.model.captureShopImage('Shop Board', MediaSource.camera);
      await harness.model.captureShopImage('Shop Stock', MediaSource.gallery);

      expect(harness.media.calls, contains('shop:camera'));
      expect(harness.media.calls, contains('shop:gallery'));
    });

    test('REG-13 review shows what was entered, not sample data', () async {
      final model = _build().model;
      await _fillTo(model, RegistrationStep.review);

      expect(model.step, RegistrationStep.review);
      expect(model.draft.fullName, 'Test Partner');
      expect(model.draft.businessName, 'Test Solar Works');
      expect(model.draft.mobileNumber, '300 1122334');
      expect(model.validationFor(RegistrationStep.review), isNull);
    });

    test('REG-14 submitting records a pending request', () async {
      final model = _build().model;
      await _fillTo(model, RegistrationStep.review);

      await model.submitRegistration();

      expect(model.stage, RegistrationStage.submitted);
      expect(model.submission, isNotNull);
      expect(model.submission!.approvalsReceived, 0);
      expect(model.submission!.verifyingSourceName, 'Al-Noor Electric Store');
    });

    test('REG-15 leaving mid-way offers to resume at that step', () async {
      final drafts = InMemoryRegistrationDraftStore();
      final first = _build(drafts: drafts).model;
      await _fillTo(first, RegistrationStep.media);

      final resumed = _build(drafts: drafts).model;
      await resumed.start();

      expect(resumed.stage, RegistrationStage.resume);
      expect(resumed.step, RegistrationStep.media);
      expect(resumed.draft.fullName, 'Test Partner');

      resumed.resumeDraft();
      expect(resumed.stage, RegistrationStage.wizard);
    });

    test('REG-16 discarding clears the draft and starts fresh', () async {
      final drafts = InMemoryRegistrationDraftStore();
      final model = _build(drafts: drafts).model;
      await _fillTo(model, RegistrationStep.details);

      await model.discardDraft();

      expect(model.step, RegistrationStep.number);
      expect(model.draft.fullName, isEmpty);
      expect(await drafts.read(), isNull);
    });

    test('moving back keeps everything that was entered', () async {
      final model = _build().model;
      await _fillTo(model, RegistrationStep.media);

      model.back();

      expect(model.step, RegistrationStep.details);
      expect(model.draft.businessName, 'Test Solar Works');
    });

    test('the shop pin is separate from the typed address', () async {
      final model = _build().model;
      await _fillTo(model, RegistrationStep.media);

      model.setShopPin(31.6, 74.4);

      expect(model.draft.hasShopPin, isTrue);
      expect(model.draft.businessAddress, 'Shop 1, Test Market');
    });
  });
}
