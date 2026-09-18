// Constructor parameters are named for their public API rather than the
// private fields they populate, so the initializing-formal shorthand the
// linter suggests is not available here.
// ignore_for_file: prefer_initializing_formals

import 'package:flutter/foundation.dart';

import '../../data/models/registration_draft.dart';
import '../../data/repositories/registration_repository.dart';
import '../../data/services/media_capture_service.dart';
import '../../data/services/registration_service.dart';

/// The eight wizard steps, in the order the design walks them.
enum RegistrationStep {
  number,
  role,
  details,
  media,
  otp,
  source,
  cnic,
  review,
}

extension RegistrationStepX on RegistrationStep {
  /// 1-based, for "Step 3 of 8".
  int get number => index + 1;
}

/// Where the flow is, beyond the step itself.
enum RegistrationStage {
  /// Offering to resume a saved draft.
  resume,

  /// Working through the wizard.
  wizard,

  /// Placing the shop pin on the map.
  shopPin,

  /// Reviewing the three captures before confirming the CNIC number.
  cnicCaptureReview,

  /// Submitted; the approval chain has started.
  submitted,
}

/// Drives the existing registration screens. All validation, lookups and
/// persistence live here or below — never in a screen.
class RegistrationFlowViewModel extends ChangeNotifier {
  RegistrationFlowViewModel({
    required RegistrationRepository repository,
    required MediaCaptureService mediaCapture,
  }) : _repository = repository,
       _mediaCapture = mediaCapture;

  final RegistrationRepository _repository;
  final MediaCaptureService _mediaCapture;

  RegistrationDraft draft = const RegistrationDraft();
  RegistrationStep step = RegistrationStep.number;
  RegistrationStage stage = RegistrationStage.wizard;

  bool busy = false;

  /// The step's current validation message, shown by the existing screens in
  /// their own error styling.
  String? error;

  /// Set when step 1 finds the number already belongs to an account.
  AccountLookupResult? existingAccount;

  List<String> markets = const [];

  /// The prototype's stand-in for the delivered SMS, surfaced so the journey
  /// is testable without a phone. A real OTP service would not return it.
  String? prototypeOtp;
  bool otpInvalid = false;

  /// The result of the last buying-source lookup, for the row being edited.
  BuyingSourceLookup? lastSourceLookup;

  RegistrationSubmission? submission;

  /// Loads any saved draft and the market list. A draft that has progressed
  /// past step 1 offers to resume rather than starting over.
  Future<void> start() async {
    busy = true;
    notifyListeners();

    markets = await _repository.markets();
    final saved = await _repository.readDraft();
    if (saved != null && saved.stepIndex > 0) {
      draft = saved;
      step = RegistrationStep.values[saved.stepIndex];
      stage = RegistrationStage.resume;
    }

    busy = false;
    notifyListeners();
  }

  // --- Resume / discard -------------------------------------------------

  void resumeDraft() {
    stage = RegistrationStage.wizard;
    notifyListeners();
  }

  Future<void> discardDraft() async {
    await _repository.discardDraft();
    draft = const RegistrationDraft();
    step = RegistrationStep.number;
    stage = RegistrationStage.wizard;
    existingAccount = null;
    notifyListeners();
  }

  // --- Draft edits ------------------------------------------------------

  void updateDraft(RegistrationDraft Function(RegistrationDraft) change) {
    draft = change(draft);
    error = null;
    notifyListeners();
    _repository.saveDraft(draft);
  }

  void setMobileNumber(String value) {
    existingAccount = null;
    updateDraft((d) => d.copyWith(mobileNumber: value));
  }

  void setRole(RegistrationRole role) =>
      updateDraft((d) => d.copyWith(role: role));

  void setVideoLink(int index, String link) {
    final links = [...draft.videoLinks];
    while (links.length <= index) {
      links.add('');
    }
    links[index] = link;
    updateDraft((d) => d.copyWith(videoLinks: links));
  }

  void setShopImage(String slot, String? path) {
    final images = {...draft.shopImagePaths};
    if (path == null) {
      images.remove(slot);
    } else {
      images[slot] = path;
    }
    updateDraft((d) => d.copyWith(shopImagePaths: images));
  }

  void setShopPin(double latitude, double longitude) => updateDraft(
    (d) => d.copyWith(shopLatitude: latitude, shopLongitude: longitude),
  );

  void addBuyingSource(BuyingSourceEntry entry) => updateDraft(
    (d) => d.copyWith(buyingSources: [...d.buyingSources, entry]),
  );

  void replaceBuyingSource(int index, BuyingSourceEntry entry) {
    final sources = [...draft.buyingSources];
    if (index >= sources.length) {
      sources.add(entry);
    } else {
      sources[index] = entry;
    }
    updateDraft((d) => d.copyWith(buyingSources: sources));
  }

  void removeBuyingSource(int index) {
    final sources = [...draft.buyingSources]..removeAt(index);
    updateDraft((d) => d.copyWith(buyingSources: sources));
  }

  // --- Step 1: the number -----------------------------------------------

  /// Looks the number up before letting the wizard continue. An existing
  /// account never starts a second registration.
  Future<void> submitMobileNumber() async {
    final digits = draft.mobileNumber.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 10) {
      error = 'Enter the 10-digit mobile number, for example 300 4821190.';
      notifyListeners();
      return;
    }

    busy = true;
    error = null;
    notifyListeners();

    final result = await _repository.lookupAccount(draft.fullMobileNumber);
    busy = false;

    if (result.exists) {
      existingAccount = result;
      notifyListeners();
      return;
    }

    existingAccount = null;
    // The role step renders Installer pre-selected and its button reads
    // "Continue as Installer", so the draft has to agree with what is on
    // screen — otherwise Continue silently fails the role check.
    if (draft.role == null) setRole(RegistrationRole.installer);
    _goTo(RegistrationStep.role);
  }

  // --- Media capture -----------------------------------------------------

  /// A shop photo, from the camera or the gallery — both are allowed here.
  Future<void> captureShopImage(String slot, MediaSource source) async {
    final path = await _mediaCapture.pickShopImage(source);
    if (path != null) setShopImage(slot, path);
  }

  /// CNIC front, CNIC back and the liveness selfie. Camera only: the gallery
  /// is never offered for an identity capture.
  Future<void> captureCnicFront() async {
    final path = await _mediaCapture.captureIdentityImage();
    if (path != null) updateDraft((d) => d.copyWith(cnicFrontPath: path));
  }

  Future<void> captureCnicBack() async {
    final path = await _mediaCapture.captureIdentityImage();
    if (path != null) updateDraft((d) => d.copyWith(cnicBackPath: path));
  }

  Future<void> captureSelfie() async {
    final path = await _mediaCapture.captureIdentityImage(frontCamera: true);
    if (path != null) updateDraft((d) => d.copyWith(selfiePath: path));
  }

  // --- Step 5: the OTP ---------------------------------------------------

  Future<void> requestOtp() async {
    busy = true;
    otpInvalid = false;
    notifyListeners();

    final issued = await _repository.requestOtp(draft.fullMobileNumber);
    prototypeOtp = issued.prototypeCode;

    busy = false;
    notifyListeners();
  }

  Future<void> submitOtp(String code) async {
    busy = true;
    otpInvalid = false;
    notifyListeners();

    final outcome = await _repository.verifyOtp(
      mobileNumber: draft.fullMobileNumber,
      code: code,
    );
    busy = false;

    if (outcome != OtpVerifyOutcome.verified) {
      otpInvalid = true;
      error = 'That code is not correct.';
      notifyListeners();
      return;
    }

    updateDraft((d) => d.copyWith(mobileVerified: true));
    _goTo(RegistrationStep.source);
  }

  // --- Step 6: buying source --------------------------------------------

  /// Resolves a buying-source number to its business name. The applicant
  /// never types the name themselves.
  Future<BuyingSourceEntry> lookupBuyingSource(String mobileNumber) async {
    busy = true;
    notifyListeners();

    final result = await _repository.lookupBuyingSource(mobileNumber);
    lastSourceLookup = result;
    busy = false;
    notifyListeners();

    return BuyingSourceEntry(
      mobileNumber: mobileNumber,
      matchedName: result.name,
      matchedRole: result.role,
      matchedMarket: result.market,
    );
  }

  // --- Step 8: submit ----------------------------------------------------

  Future<void> submitRegistration() async {
    final problem = validationFor(RegistrationStep.review);
    if (problem != null) {
      error = problem;
      notifyListeners();
      return;
    }

    busy = true;
    notifyListeners();

    submission = await _repository.submit(draft);
    await _repository.discardDraft();

    busy = false;
    stage = RegistrationStage.submitted;
    notifyListeners();
  }

  // --- Navigation --------------------------------------------------------

  /// Moves forward only when the current step is complete.
  void next() {
    final problem = validationFor(step);
    if (problem != null) {
      error = problem;
      notifyListeners();
      return;
    }
    if (step == RegistrationStep.review) return;
    _goTo(RegistrationStep.values[step.index + 1]);
  }

  /// Moves back without discarding anything that was entered.
  void back() {
    if (stage != RegistrationStage.wizard) {
      stage = RegistrationStage.wizard;
      notifyListeners();
      return;
    }
    if (step.index == 0) return;
    _goTo(RegistrationStep.values[step.index - 1]);
  }

  /// Jumps to a step from the review screen's Edit actions.
  void editStep(RegistrationStep target) {
    stage = RegistrationStage.wizard;
    _goTo(target);
  }

  void openShopPin() {
    stage = RegistrationStage.shopPin;
    notifyListeners();
  }

  void openCnicReview() {
    stage = RegistrationStage.cnicCaptureReview;
    notifyListeners();
  }

  void closeSubStage() {
    stage = RegistrationStage.wizard;
    notifyListeners();
  }

  void _goTo(RegistrationStep target) {
    step = target;
    stage = RegistrationStage.wizard;
    error = null;
    // The furthest step reached is what "You stopped at step n of 8" names.
    final furthest = target.index > draft.stepIndex
        ? target.index
        : draft.stepIndex;
    draft = draft.copyWith(stepIndex: furthest);
    notifyListeners();
    _repository.saveDraft(draft);

    if (target == RegistrationStep.otp && prototypeOtp == null) {
      requestOtp();
    }
  }

  // --- Validation --------------------------------------------------------

  /// The reason [step] cannot be left yet, or null when it is complete.
  String? validationFor(RegistrationStep step) {
    switch (step) {
      case RegistrationStep.number:
        if (draft.mobileNumber.replaceAll(RegExp(r'\D'), '').length < 10) {
          return 'Enter the 10-digit mobile number.';
        }
        if (existingAccount?.exists ?? false) {
          return 'This number already has a Crown Solar account.';
        }
        return null;

      case RegistrationStep.role:
        return draft.role == null
            ? 'Choose how you work with Crown Solar.'
            : null;

      case RegistrationStep.details:
        if (draft.fullName.trim().isEmpty) return 'Enter your full name.';
        if (draft.businessName.trim().isEmpty) {
          return 'Enter your business name.';
        }
        if (draft.businessAddress.trim().isEmpty) {
          return 'Enter your business address.';
        }
        if (draft.market == null) return 'Choose your market.';
        return null;

      case RegistrationStep.media:
        if (draft.role == RegistrationRole.installer) {
          final filled = draft.videoLinks
              .where((link) => link.trim().isNotEmpty)
              .length;
          return filled >= 2
              ? null
              : 'Add at least two installation video links.';
        }
        final required = ['Shop Board', 'Shop Image'];
        final missing = required
            .where((slot) => !draft.shopImagePaths.containsKey(slot))
            .toList();
        return missing.isEmpty
            ? null
            : 'Add ${missing.join(' and ')} to continue.';

      case RegistrationStep.otp:
        return draft.mobileVerified ? null : 'Verify your mobile number.';

      case RegistrationStep.source:
        return draft.buyingSources.isEmpty
            ? 'Add the buying source you purchase from.'
            : null;

      case RegistrationStep.cnic:
        if (draft.cnicNumber.replaceAll(RegExp(r'\D'), '').length != 13) {
          return 'Enter the 13-digit CNIC number.';
        }
        if (draft.cnicFrontPath == null) {
          return 'Capture the front of your CNIC.';
        }
        if (draft.cnicBackPath == null) return 'Capture the back of your CNIC.';
        if (draft.selfiePath == null) return 'Capture your liveness selfie.';
        return null;

      case RegistrationStep.review:
        for (final earlier in RegistrationStep.values) {
          if (earlier == RegistrationStep.review) break;
          final problem = validationFor(earlier);
          if (problem != null) return problem;
        }
        return null;
    }
  }

  bool get canContinue => validationFor(step) == null;
}
