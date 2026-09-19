// Constructor parameters are named for their public API rather than the
// private fields they populate, so the initializing-formal shorthand the
// linter suggests is not available here.
// ignore_for_file: prefer_initializing_formals

import 'package:flutter/foundation.dart';

import '../../data/models/registration_draft.dart';
import '../../data/repositories/registration_repository.dart';
import '../../data/services/media_capture_service.dart';
import '../../../../core/prefs/app_preferences.dart';
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

  /// Confirming the CNIC number, once all three captures are in hand.
  cnicNumber,

  /// Submitted; the approval chain has started.
  submitted,
}

/// Drives the existing registration screens. All validation, lookups and
/// persistence live here or below — never in a screen.
class RegistrationFlowViewModel extends ChangeNotifier {
  RegistrationFlowViewModel({
    required RegistrationRepository repository,
    required MediaCaptureService mediaCapture,
    AppPreferences? preferences,
  }) : _repository = repository,
       _mediaCapture = mediaCapture,
       _preferences = preferences;

  final RegistrationRepository _repository;
  final MediaCaptureService _mediaCapture;

  /// Where first launch stored the phone's position, if it was granted. It
  /// only ever centres the map — it is never taken as the shop's pin.
  final AppPreferences? _preferences;

  ({double latitude, double longitude})? phoneLocation;

  RegistrationDraft draft = const RegistrationDraft();
  RegistrationStep step = RegistrationStep.number;
  RegistrationStage stage = RegistrationStage.wizard;

  bool busy = false;

  /// The step's current validation message, shown by the existing screens in
  /// their own error styling.
  String? error;

  /// The same validation, split by field, so a message sits under the input
  /// it belongs to instead of collecting under the first field on the step.
  /// Keys are the field ids used by [errorFor].
  Map<String, String> fieldErrors = const {};

  String? errorFor(String field) => fieldErrors[field];

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
    phoneLocation = await _preferences?.currentLocation();
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
    fieldErrors = const {};
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
    final problem = mobileNumberProblem(draft.mobileNumber);
    if (problem != null) {
      error = problem;
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

  /// Confirms the typed CNIC before leaving step 7: the 13 digits first, then
  /// whether that identity is already registered to someone.
  Future<void> submitCnic() async {
    final malformed = fieldProblemsFor(RegistrationStep.cnic);
    if (malformed.isNotEmpty) {
      fieldErrors = malformed;
      error = malformed['cnicNumber'];
      notifyListeners();
      return;
    }

    busy = true;
    notifyListeners();

    final taken = await _repository.cnicAlreadyRegistered(draft.cnicNumber);
    busy = false;

    if (taken) {
      // Whose account it is is not this applicant's business — saying only
      // that it is taken avoids disclosing another partner's identity.
      error = 'A partner is already registered with this CNIC.';
      fieldErrors = {'cnicNumber': error!};
      notifyListeners();
      return;
    }

    next();
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

    // An account that cannot sell is not a match: it is recorded as unmatched
    // so it can never become the source that verifies the application.
    return BuyingSourceEntry(
      mobileNumber: mobileNumber,
      matchedName: result.usable ? result.name : null,
      matchedRole: result.usable ? result.role : null,
      matchedMarket: result.usable ? result.market : null,
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
      fieldErrors = fieldProblemsFor(step);
      notifyListeners();
      return;
    }
    if (step == RegistrationStep.review) return;

    // Correcting one answer from review goes back to review, not onward
    // through steps that were already answered.
    if (editingFromReview) {
      _goTo(RegistrationStep.review);
      return;
    }
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

  /// Set while a single step is being corrected from the review screen, so
  /// finishing it returns straight to review rather than walking the rest of
  /// the wizard again.
  bool editingFromReview = false;

  /// Jumps to a step from the review screen's Edit actions.
  void editStep(RegistrationStep target) {
    stage = RegistrationStage.wizard;
    _goTo(target);
    editingFromReview = true;
    notifyListeners();
  }

  void openShopPin() {
    stage = RegistrationStage.shopPin;
    notifyListeners();
  }

  void openCnicNumber() {
    stage = RegistrationStage.cnicNumber;
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
    fieldErrors = const {};
    // Any move other than the one editStep sets up ends the correction.
    editingFromReview = false;
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
        if (mobileNumberProblem(draft.mobileNumber) != null) {
          return mobileNumberProblem(draft.mobileNumber);
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
        if (draft.alternateNumber.trim().isNotEmpty &&
            mobileNumberProblem(draft.alternateNumber) != null) {
          return 'Check the alternate mobile number.';
        }
        return null;

      case RegistrationStep.media:
        if (draft.role == RegistrationRole.installer) {
          for (final link in draft.videoLinks) {
            final malformed = videoLinkProblem(link);
            if (malformed != null) return malformed;
          }
          if (_duplicateLinkIndex(draft.videoLinks) != null) {
            return 'Each video must be a different link.';
          }
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
        // An unmatched number is not a source; at least one has to resolve to
        // an account that actually sells.
        return draft.buyingSources.any((source) => source.isFound)
            ? null
            : 'Add the buying source you purchase from.';

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

  /// The same checks as [validationFor], keyed by the field each one belongs
  /// to. Steps whose content is not a set of named inputs return an empty map
  /// and keep using [error].
  Map<String, String> fieldProblemsFor(RegistrationStep step) {
    final problems = <String, String>{};

    switch (step) {
      case RegistrationStep.details:
        if (draft.fullName.trim().isEmpty) {
          problems['fullName'] = 'Enter your full name.';
        }
        if (draft.businessName.trim().isEmpty) {
          problems['businessName'] = 'Enter your business name.';
        }
        if (draft.businessAddress.trim().isEmpty) {
          problems['businessAddress'] = 'Enter your business address.';
        }
        if (draft.market == null) {
          problems['market'] = 'Choose your market.';
        }
        // Optional, but if one is given it has to be a real number.
        if (draft.alternateNumber.trim().isNotEmpty) {
          final bad = mobileNumberProblem(draft.alternateNumber);
          if (bad != null) problems['alternateNumber'] = bad;
        }

      case RegistrationStep.media:
        if (draft.role != RegistrationRole.installer) break;
        final duplicate = _duplicateLinkIndex(draft.videoLinks);
        for (var i = 0; i < 3; i++) {
          final link = i < draft.videoLinks.length ? draft.videoLinks[i] : '';
          final malformed = videoLinkProblem(link);
          if (malformed != null) {
            problems['videoLink$i'] = malformed;
          } else if (i == duplicate) {
            problems['videoLink$i'] = 'This link is already used above.';
          } else if (i < 2 && link.trim().isEmpty) {
            problems['videoLink$i'] = 'This link is required.';
          }
        }

      case RegistrationStep.cnic:
        if (draft.cnicNumber.replaceAll(RegExp(r'\D'), '').length != 13) {
          problems['cnicNumber'] = 'Enter the 13-digit CNIC number.';
        }

      case RegistrationStep.number:
      case RegistrationStep.role:
      case RegistrationStep.otp:
      case RegistrationStep.source:
      case RegistrationStep.review:
        break;
    }

    return problems;
  }

  /// The first link that repeats one entered above it, or null when they are
  /// all different. Three videos of the same installation prove nothing, so
  /// the same link is never accepted twice. Case and trailing slashes do not
  /// make two links different.
  static int? _duplicateLinkIndex(List<String> links) {
    final seen = <String>{};
    for (var i = 0; i < links.length; i++) {
      final link = links[i].trim().toLowerCase().replaceAll(RegExp(r'/+$'), '');
      if (link.isEmpty) continue;
      if (!seen.add(link)) return i;
    }
    return null;
  }

  /// A Pakistani mobile is eleven digits as it is written locally
  /// (0300 1122334). The +92 shown beside the field takes the place of that
  /// leading zero, so the field itself holds the ten national digits — and a
  /// number pasted with the 0 or the country code still resolves to them.
  static String? mobileNumberProblem(String raw) {
    final national = RegistrationDraft.nationalDigits(raw);
    if (national.length == 10) return null;
    return 'Enter the 10 digits after +92, for example 300 4821190.';
  }

  /// A pasted video link has to look like a real web address: an http or
  /// https scheme and a dotted host. An empty link is not a format problem —
  /// whether it is required is a separate check.
  static String? videoLinkProblem(String raw) {
    final link = raw.trim();
    if (link.isEmpty) return null;

    final uri = Uri.tryParse(link);
    if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) {
      return 'Start the link with http:// or https://.';
    }
    final host = uri.host;
    if (!host.contains('.') || host.startsWith('.') || host.endsWith('.')) {
      return 'Enter a full web address, like https://youtu.be/abc123.';
    }
    return null;
  }

  bool get canContinue => validationFor(step) == null;
}
