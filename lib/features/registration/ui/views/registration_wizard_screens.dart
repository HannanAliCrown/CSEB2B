import 'dart:async';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/ui/ds.dart';
import '../../../design_preview/preview_journey.dart';
import '../../data/models/registration_draft.dart';
import '../../data/services/media_capture_service.dart';
import '../registration_scope.dart';
import '../widgets/editable_otp_field.dart';
import '../widgets/shop_location_map.dart';
import '../view_models/registration_flow_view_model.dart';
import '../widgets/registration_scaffold.dart';

Widget _continueFooter(
  BuildContext context, {
  String label = 'Continue',
  VoidCallback? onPressed,
  bool busy = false,
}) {
  final flow = RegistrationScope.maybeOf(context);
  return DsFooterBar(
    child: DsButton(
      label: label,
      iconAfter: LucideIcons.arrowRight,
      loading: busy,
      onPressed:
          onPressed ??
          (flow == null ? () => PreviewJourney.next(context) : flow.next),
    ),
  );
}

/// Board 01 · B1 — Step 1 · Mobile number.
class RegistrationNumberScreen extends StatefulWidget {
  const RegistrationNumberScreen({super.key});

  @override
  State<RegistrationNumberScreen> createState() =>
      _RegistrationNumberScreenState();
}

class _RegistrationNumberScreenState extends State<RegistrationNumberScreen> {
  TextEditingController? _number;

  @override
  void dispose() {
    _number?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final flow = RegistrationScope.maybeOf(context);
    // Outside the wizard the screen keeps the design's sample number.
    _number ??= TextEditingController(
      text: flow?.draft.mobileNumber ?? '300 4821190',
    );

    return RegistrationScaffold(
      title: 'Register',
      step: 0,
      footer: _continueFooter(
        context,
        busy: flow?.busy ?? false,
        onPressed: flow?.submitMobileNumber,
      ),
      children: [
        const RegistrationPrompt(
          question: 'What is your mobile number?',
          detail:
              'This becomes your login. We will validate it with a code later '
              'in this form.',
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            SizedBox(
              width: 96,
              child: DsInput(
                label: 'Code',
                value: flow?.draft.countryCode ?? '+92',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: DsInput(
                label: 'Mobile number',
                controller: _number,
                onChanged: flow?.setMobileNumber,
                error: flow?.error,
                keyboardType: TextInputType.phone,
              ),
            ),
          ],
        ),
        const DsNotice(
          icon: LucideIcons.info,
          message:
              'One account per number. If this number is already registered we '
              'will take you to Login instead.',
        ),
      ],
    );
  }
}

/// Board 01 · B2 — the number already has an account.
class RegistrationNumberTakenScreen extends StatefulWidget {
  const RegistrationNumberTakenScreen({super.key, this.onGoToLogin});

  final VoidCallback? onGoToLogin;

  @override
  State<RegistrationNumberTakenScreen> createState() =>
      _RegistrationNumberTakenScreenState();
}

class _RegistrationNumberTakenScreenState
    extends State<RegistrationNumberTakenScreen> {
  TextEditingController? _number;

  @override
  void dispose() {
    _number?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final flow = RegistrationScope.maybeOf(context);
    _number ??= TextEditingController(
      text: flow?.draft.mobileNumber ?? '321 7745002',
    );
    final existing = flow?.existingAccount;

    return RegistrationScaffold(
      title: 'Register',
      step: 0,
      // Continue stays unavailable until the number changes.
      footer: const DsFooterBar(
        child: DsButton(label: 'Continue', disabled: true),
      ),
      children: [
        const RegistrationPrompt(question: 'What is your mobile number?'),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            SizedBox(
              width: 96,
              child: DsInput(
                label: 'Code',
                value: flow?.draft.countryCode ?? '+92',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: DsInput(
                label: 'Mobile number',
                controller: _number,
                onChanged: flow?.setMobileNumber,
                keyboardType: TextInputType.phone,
              ),
            ),
          ],
        ),
        DsCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const DsIconMedallion(
                    icon: LucideIcons.userCheck,
                    tone: DsTone.info,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'This number already has a Crown Solar account.',
                      style: context.texts.bodyLarge?.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.stepMd),
              DsBody(
                '${flow?.draft.fullMobileNumber ?? '+92 321 7745002'} is '
                'registered to a ${existing?.role ?? 'Retailer'} account.',
              ),
              const SizedBox(height: AppSpacing.stepMd),
              DsButton(
                label: 'Go to Login',
                icon: LucideIcons.logIn,
                size: DsButtonSize.sm,
                onPressed:
                    widget.onGoToLogin ?? () => PreviewJourney.next(context),
              ),
            ],
          ),
        ),
        const DsCaption(
          'Using a different number? Edit the field above and continue.',
        ),
      ],
    );
  }
}

/// Board 01 · B3 — Step 2 · Role selection.
class RegistrationRoleScreen extends StatefulWidget {
  const RegistrationRoleScreen({super.key});

  @override
  State<RegistrationRoleScreen> createState() => _RegistrationRoleScreenState();
}

class _RegistrationRoleScreenState extends State<RegistrationRoleScreen> {
  String _role = 'Installer';

  @override
  Widget build(BuildContext context) {
    final flow = RegistrationScope.maybeOf(context);
    final role = flow?.draft.role?.label ?? _role;

    void select(RegistrationRole value) {
      setState(() => _role = value.label);
      flow?.setRole(value);
    }

    return RegistrationScaffold(
      title: 'Register',
      step: 1,
      gap: AppSpacing.md,
      footer: DsFooterBar(
        child: DsButton(
          label: 'Continue as $role',
          iconAfter: LucideIcons.arrowRight,
          onPressed: flow == null
              ? () => PreviewJourney.next(context)
              : flow.next,
        ),
      ),
      children: [
        const RegistrationPrompt(
          question: 'How do you work with Crown Solar?',
          detail:
              'This decides what the app shows you. It can be changed later '
              'only by CRM.',
        ),
        Column(
          children: [
            DsOptionCard(
              title: 'Installer',
              description:
                  'I install solar systems for customers. Scan products to '
                  'earn prizes and spins.',
              icon: LucideIcons.hardHat,
              selected: role == 'Installer',
              onTap: () => select(RegistrationRole.installer),
            ),
            const SizedBox(height: AppSpacing.stepMd),
            DsOptionCard(
              title: 'Retailer',
              description:
                  'I sell Crown Solar products from a shop. Earn points, sign '
                  'schemes, approve cash requests.',
              icon: LucideIcons.store,
              selected: role == 'Retailer',
              onTap: () => select(RegistrationRole.retailer),
            ),
          ],
        ),
        const DsNotice(
          icon: LucideIcons.info,
          message:
              'Wholesaler and Distributor accounts are set up by Crown Solar '
              'CRM. Register as Retailer and CRM will change your class if it '
              'applies to you.',
        ),
      ],
    );
  }
}

/// Board 01 · C1 — Step 3 · Details form.
class RegistrationDetailsScreen extends StatefulWidget {
  const RegistrationDetailsScreen({super.key});

  @override
  State<RegistrationDetailsScreen> createState() =>
      _RegistrationDetailsScreenState();
}

class _RegistrationDetailsScreenState extends State<RegistrationDetailsScreen> {
  final _controllers = <String, TextEditingController>{};

  TextEditingController _controller(String key, String initial) =>
      _controllers.putIfAbsent(key, () => TextEditingController(text: initial));

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final flow = RegistrationScope.maybeOf(context);
    final draft = flow?.draft;

    return RegistrationScaffold(
      title: 'Your Details',
      step: 2,
      gap: 14,
      footer: _continueFooter(context),
      children: [
        DsInput(
          label: 'Full name',
          controller: _controller(
            'fullName',
            draft?.fullName ?? 'Muhammad Adnan Shahid',
          ),
          onChanged: (v) => flow?.updateDraft((d) => d.copyWith(fullName: v)),
          error: flow?.errorFor('fullName'),
        ),
        DsInput(
          label: 'Alternate mobile number',
          placeholder: 'Optional · a second way to reach you',
          controller: _controller('alternate', draft?.alternateNumber ?? ''),
          onChanged: (v) =>
              flow?.updateDraft((d) => d.copyWith(alternateNumber: v)),
          keyboardType: TextInputType.phone,
        ),
        DsInput(
          label: 'Business name',
          controller: _controller(
            'business',
            draft?.businessName ?? 'Adnan Solar Works',
          ),
          onChanged: (v) =>
              flow?.updateDraft((d) => d.copyWith(businessName: v)),
          error: flow?.errorFor('businessName'),
        ),
        DsInput(
          label: 'Business address',
          controller: _controller(
            'address',
            draft?.businessAddress ?? 'Shop 14, Bilal Market, Shahdara',
          ),
          onChanged: (v) =>
              flow?.updateDraft((d) => d.copyWith(businessAddress: v)),
          error: flow?.errorFor('businessAddress'),
        ),
        DsSelect(
          label: 'Market',
          // Inside the wizard nothing is pre-chosen: showing the design's
          // sample market would claim a choice the draft has not made.
          value: flow == null ? 'Ravi Road, Lahore' : draft?.market,
          placeholder: 'Choose your market',
          error: flow?.errorFor('market'),
          onTap: flow == null ? null : () => _pickMarket(context, flow),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Shop location on the map',
              style: context.texts.labelLarge?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            DsMapPlaceholder(
              // A coordinate is only ever shown once a pin has actually been
              // dropped; inside the wizard nothing is invented before that.
              // Outside it (design preview) the sample coordinate stands.
              coordinates: draft == null
                  ? '31.5871° N, 74.3142° E'
                  : draft.hasShopPin
                  ? '${draft.shopLatitude!.toStringAsFixed(4)}° N, '
                        '${draft.shopLongitude!.toStringAsFixed(4)}° E'
                  : 'No pin dropped yet',
              // A read-only preview of the pin; placing it happens on the
              // full-screen map behind the action.
              surface: draft == null
                  ? null
                  : ShopLocationMap(
                      pin: draft.hasShopPin
                          ? LatLng(draft.shopLatitude!, draft.shopLongitude!)
                          : null,
                      interactive: false,
                    ),
              actionLabel: 'Drop pin on map',
              onAction: flow?.openShopPin,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'The pin can be different from where your phone is right now, '
              'and from the business address you typed above.',
              style: context.texts.bodySmall?.copyWith(
                height: 17 / 12,
                color: context.palette.textTertiary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// The market list comes from the data layer, never from this screen.
  Future<void> _pickMarket(
    BuildContext context,
    RegistrationFlowViewModel flow,
  ) async {
    final chosen = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => DsSheet(
        title: 'Market',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final market in flow.markets)
              DsRadio(
                selected: flow.draft.market == market,
                label: market,
                onTap: () => Navigator.of(context).pop(market),
              ),
          ],
        ),
      ),
    );
    if (chosen != null) {
      flow.updateDraft((d) => d.copyWith(market: chosen));
    }
  }
}

/// Board 01 · C2 — Pin drop · market mismatch, non-blocking.
class RegistrationPinDropScreen extends StatefulWidget {
  const RegistrationPinDropScreen({super.key});

  @override
  State<RegistrationPinDropScreen> createState() =>
      _RegistrationPinDropScreenState();
}

class _RegistrationPinDropScreenState extends State<RegistrationPinDropScreen> {
  /// Where the pin sits while the partner is still placing it. It only
  /// becomes the shop's location when they confirm.
  LatLng? _pin;
  bool _restored = false;

  /// What is actually known once a pin is down: which market it will be
  /// checked against, and that it need not match anything else. Whether the
  /// pin really falls inside that market is not something this app can tell —
  /// there are no market boundaries here — so it never claims it does or
  /// does not.
  String _pinnedMessage(String? market) {
    final checkedAgainst = market == null
        ? 'Crown Solar CRM will check it with you once you choose your market.'
        : 'Crown Solar CRM will check it against $market with you.';
    return 'Your pin is recorded. It does not have to match your business '
        'address or where your phone is right now — $checkedAgainst';
  }

  @override
  Widget build(BuildContext context) {
    final flow = RegistrationScope.maybeOf(context);
    final draft = flow?.draft;

    if (!_restored) {
      _restored = true;
      if (draft != null && draft.hasShopPin) {
        _pin = LatLng(draft.shopLatitude!, draft.shopLongitude!);
      }
    }

    return Scaffold(
      appBar: DsAppBar(
        title: 'Pin Your Shop',
        onBack: flow == null
            ? () => Navigator.of(context).maybePop()
            : flow.closeSubStage,
      ),
      body: Column(
        children: [
          Expanded(
            child: flow == null
                ? const DsMapPlaceholder(height: null)
                : ShopLocationMap(
                    pin: _pin,
                    onPinMoved: (point) => setState(() => _pin = point),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            child: DsNotice(
              icon: flow == null
                  ? LucideIcons.triangleAlert
                  : LucideIcons.mapPin,
              // Nothing here detects a mismatch, so nothing here warns about
              // one. The design's warning state stands in the preview.
              tone: flow == null ? DsTone.warning : DsTone.info,
              message: flow == null
                  ? 'Your pin is outside Ravi Road, Lahore, and different '
                        'from where your phone is right now. Both are fine — '
                        'you can still continue, and Crown Solar CRM will '
                        'check the location with you.'
                  : _pin == null
                  ? 'Tap the map where your shop is. You can drag the pin to '
                        'adjust it before confirming.'
                  : _pinnedMessage(draft?.market),
              action: DsButton(
                label: 'Confirm This Location',
                // Nothing is confirmed until a pin has actually been placed.
                onPressed: flow != null && _pin == null
                    ? null
                    : () {
                        if (flow == null) {
                          Navigator.of(context).maybePop();
                          return;
                        }
                        flow.setShopPin(_pin!.latitude, _pin!.longitude);
                        flow.closeSubStage();
                      },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Board 01 · D1 — Step 4 · Installer · installation video links.
class RegistrationInstallerMediaScreen extends StatefulWidget {
  const RegistrationInstallerMediaScreen({super.key});

  @override
  State<RegistrationInstallerMediaScreen> createState() =>
      _RegistrationInstallerMediaScreenState();
}

class _RegistrationInstallerMediaScreenState
    extends State<RegistrationInstallerMediaScreen> {
  final _controllers = <int, TextEditingController>{};

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  TextEditingController _controller(int index, String initial) => _controllers
      .putIfAbsent(index, () => TextEditingController(text: initial));

  @override
  Widget build(BuildContext context) {
    final flow = RegistrationScope.maybeOf(context);
    final links =
        flow?.draft.videoLinks ?? const ['youtu.be/8k-install-lhr01', '', ''];

    return RegistrationScaffold(
      title: 'Installation Videos',
      step: 3,
      subtitleSuffix: ' · Installer',
      gap: 14,
      footer: _continueFooter(context),
      children: [
        const DsBody(
          'Share links to three videos of installations you have done — '
          'YouTube, Google Drive or WhatsApp links all work.',
          size: 14,
        ),
        for (var i = 0; i < 3; i++)
          DsInput(
            label: 'Installation video ${i + 1}',
            placeholder: 'Paste a video link',
            hint: i < 2 ? 'Required' : 'Optional',
            controller: _controller(i, i < links.length ? links[i] : ''),
            onChanged: (value) => flow?.setVideoLink(i, value),
            keyboardType: TextInputType.url,
            error: flow?.errorFor('videoLink$i'),
          ),
        const DsNotice(
          icon: LucideIcons.info,
          message:
              'Two links are required to continue. The third is optional and '
              'helps your approval move faster.',
        ),
      ],
    );
  }
}

/// Board 01 · D2 — Step 4 · Retailer · Shop Board, Stock, Image.
class RegistrationRetailerMediaScreen extends StatelessWidget {
  const RegistrationRetailerMediaScreen({super.key});

  static const _slots = [
    ('Shop Board', true),
    ('Shop Stock', false),
    ('Shop Image', true),
  ];

  @override
  Widget build(BuildContext context) {
    final flow = RegistrationScope.maybeOf(context);
    final captured = flow?.draft.shopImagePaths ?? const <String, String>{};

    return RegistrationScaffold(
      title: 'Shop Images',
      step: 3,
      subtitleSuffix: ' · Retailer',
      gap: 14,
      footer: _continueFooter(context),
      children: [
        const DsBody(
          'Add three photos of your shop. Shop Board and Shop Image are '
          'required; Shop Stock is optional.',
          size: 14,
        ),
        for (final (slot, required) in _slots)
          DsUploadRow(
            label: slot,
            meta: _metaFor(
              slot,
              required: required,
              captured: captured,
              inFlow: flow != null,
            ),
            state: _stateFor(slot, captured: captured, inFlow: flow != null)
                ? DsUploadState.uploaded
                : DsUploadState.empty,
            onAction: flow == null
                ? null
                : () => _pickSource(context, flow, slot),
          ),
        const DsNotice(
          icon: LucideIcons.camera,
          message:
              'Camera or gallery for these photos. Shop Stock can be added '
              'later from Profile if you skip it now.',
        ),
      ],
    );
  }

  /// Outside the wizard the design's own sample state is shown: Shop Image
  /// already uploaded, the other two not added yet.
  static String _metaFor(
    String slot, {
    required bool required,
    required Map<String, String> captured,
    required bool inFlow,
  }) {
    if (!inFlow) {
      return slot == 'Shop Image'
          ? 'Uploaded'
          : '${required ? 'Required' : 'Optional'} · not added';
    }
    return captured.containsKey(slot)
        ? 'Added'
        : '${required ? 'Required' : 'Optional'} · not added';
  }

  static bool _stateFor(
    String slot, {
    required Map<String, String> captured,
    required bool inFlow,
  }) => inFlow ? captured.containsKey(slot) : slot == 'Shop Image';

  /// Shop photos may come from the camera or the gallery — unlike the CNIC
  /// and selfie captures, which are camera-only.
  Future<void> _pickSource(
    BuildContext context,
    RegistrationFlowViewModel flow,
    String slot,
  ) async {
    final source = await showModalBottomSheet<MediaSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => DsSheet(
        title: slot,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DsButton(
              label: 'Take a photo',
              icon: LucideIcons.camera,
              onPressed: () => Navigator.of(context).pop(MediaSource.camera),
            ),
            const SizedBox(height: 10),
            DsButton(
              label: 'Choose from gallery',
              variant: DsButtonVariant.secondary,
              icon: LucideIcons.image,
              onPressed: () => Navigator.of(context).pop(MediaSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source != null) await flow.captureShopImage(slot, source);
  }
}

/// Board 01 · E1 — Step 5 · Verify your number.
class RegistrationOtpScreen extends StatefulWidget {
  const RegistrationOtpScreen({super.key});

  @override
  State<RegistrationOtpScreen> createState() => _RegistrationOtpScreenState();
}

class _RegistrationOtpScreenState extends State<RegistrationOtpScreen> {
  final _code = TextEditingController();

  /// Resending is held for this long after a code is sent, and the row counts
  /// down to it rather than showing a frozen time.
  static const _resendHold = Duration(seconds: 30);

  Timer? _ticker;
  int _secondsLeft = _resendHold.inSeconds;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _ticker?.cancel();
    setState(() => _secondsLeft = _resendHold.inSeconds);
    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 0) timer.cancel();
    });
  }

  String get _countdown {
    final seconds = _secondsLeft < 0 ? 0 : _secondsLeft;
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    return '$minutes:${(seconds % 60).toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final flow = RegistrationScope.maybeOf(context);
    final number = flow?.draft.fullMobileNumber ?? '+92 300 4821190';

    return RegistrationScaffold(
      title: 'Verify Your Number',
      step: 4,
      footer: DsFooterBar(
        child: DsButton(
          label: 'Verify and Continue',
          loading: flow?.busy ?? false,
          onPressed: flow == null
              ? () => PreviewJourney.next(context)
              : () => flow.submitOtp(_code.text),
        ),
      ),
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const DsHeading('Enter the 6-digit code'),
            const SizedBox(height: AppSpacing.sm),
            DsBody('Sent by SMS to $number.', size: 14),
          ],
        ),
        if (flow == null)
          const DsOtpBoxes(digits: '4812', focusedIndex: 4)
        else
          EditableOtpField(
            controller: _code,
            error: flow.otpInvalid,
            onCompleted: flow.submitOtp,
          ),
        if (flow?.otpInvalid ?? false)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                LucideIcons.circleAlert,
                size: 16,
                color: context.colors.error,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: DsBody(
                  'That code is not correct.',
                  color: context.status.error,
                ),
              ),
            ],
          ),
        // Resend stays unavailable until the hold expires; the design's
        // sample time stands outside the wizard.
        DsResendRow(
          countdown: flow == null ? '00:24' : _countdown,
          onResend: flow == null || _secondsLeft > 0
              ? null
              : () {
                  flow.requestOtp();
                  _startCountdown();
                },
        ),
        const DsNotice(
          icon: LucideIcons.save,
          tone: DsTone.info,
          message:
              'Your details and photos from the last two steps are already '
              'saved. Verifying just confirms this number is really yours.',
        ),
      ],
    );
  }
}

/// Board 01 · E2 — Wrong code, then rate limit.
class RegistrationOtpLockedScreen extends StatelessWidget {
  const RegistrationOtpLockedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return RegistrationScaffold(
      title: 'Verify Your Number',
      step: 4,
      showProgress: false,
      footer: const DsFooterBar(
        child: DsButton(label: 'Verify and Continue', disabled: true),
      ),
      children: [
        const DsHeading('Enter the 6-digit code'),
        const DsOtpBoxes(digits: '904176', error: true),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              LucideIcons.circleAlert,
              size: 16,
              color: context.colors.error,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: DsBody(
                'That code is not correct. 2 attempts left before verification '
                'is paused.',
                color: context.status.error,
              ),
            ),
          ],
        ),
        DsCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const DsIconMedallion(
                    icon: LucideIcons.clockAlert,
                    tone: DsTone.warning,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Verification paused',
                      style: context.texts.bodyLarge?.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.stepMd),
              const DsBody(
                'Too many incorrect codes. Try again at 10:02 AM. Your '
                'progress in this registration is saved either way.',
              ),
            ],
          ),
        ),
      ],
    );
  }
}
