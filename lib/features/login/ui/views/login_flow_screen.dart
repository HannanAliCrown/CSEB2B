import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../../core/ui/ds.dart';
import '../../../auth/data/repositories/auth_repository.dart';
import '../../../auth/data/services/auth_service.dart';
import '../../../registration/ui/widgets/editable_otp_field.dart';
import '../../../session/ui/session_controller.dart';
import 'sign_in_screen.dart';

/// Where the partner is in signing in.
enum _Step {
  /// Board 02 · A1 — the number and "Keep me signed in".
  number,

  /// Board 02 · A2/A3 — the SMS code for a phone this account has not used.
  verify,

  /// Board 02 · B1 — the free move is spent; only CRM can allow another.
  locked,
}

/// Board 02 — Login and device binding, driven by the real policy.
///
/// The screens are the design's; the decisions are entirely
/// `prototype_server`'s. Nothing here works out whether a phone is trusted,
/// how many moves an account has left, or whether CRM has allowed another —
/// it asks, and renders the answer.
class LoginFlowScreen extends StatefulWidget {
  const LoginFlowScreen({
    super.key,
    required this.onSignedIn,
    required this.onRegister,
    this.notice,
  });

  final VoidCallback onSignedIn;
  final VoidCallback onRegister;

  /// The session-expired variant (B3) hands its notice through to A1.
  final Widget? notice;

  @override
  State<LoginFlowScreen> createState() => _LoginFlowScreenState();
}

class _LoginFlowScreenState extends State<LoginFlowScreen> {
  _Step _step = _Step.number;

  bool _busy = false;
  String? _error;

  String _mobileNumber = '';
  bool _keepSignedIn = true;

  String? _accountId;
  String? _deviceId;

  /// Set when CRM has allowed this move, so the verify screen says so.
  bool _crmAuthorised = false;

  /// The prototype has no SMS gateway, so the server hands the code back and
  /// the screen shows it. A real gateway simply stops returning it and this
  /// line disappears on its own.
  String? _prototypeCode;

  final _code = TextEditingController();
  Timer? _resend;
  int _secondsLeft = 0;

  @override
  void initState() {
    super.initState();
    _code.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _resend?.cancel();
    _code.dispose();
    super.dispose();
  }

  AuthRepository get _auth => context.read<AuthRepository>();

  @override
  Widget build(BuildContext context) => switch (_step) {
    _Step.number => _numberStep(),
    _Step.verify => _verifyStep(),
    _Step.locked => _lockedStep(),
  };

  // --- A1 · the number ------------------------------------------------------

  Widget _numberStep() => SignInScreen(
    notice: widget.notice,
    busy: _busy,
    error: _error,
    onRegister: widget.onRegister,
    onSubmit: (number, {required keepSignedIn}) =>
        _evaluate(number, keepSignedIn: keepSignedIn),
  );

  Future<void> _evaluate(
    String mobileNumber, {
    required bool keepSignedIn,
  }) async {
    setState(() {
      _busy = true;
      _error = null;
      _mobileNumber = mobileNumber;
      _keepSignedIn = keepSignedIn;
    });

    final result = await _auth.evaluateLogin(mobileNumber);
    if (!mounted) return;

    if (result.status == LoginStatus.accountNotFound) {
      setState(() {
        _busy = false;
        _error = 'No Crown Solar account uses this number. Register instead.';
      });
      return;
    }

    _accountId = result.accountId;
    _deviceId = result.deviceId;

    // The phone this account is already bound to: straight in, no code.
    if (result.status == LoginStatus.trusted) {
      await _completeSignIn();
      return;
    }

    // Taking a phone another account holds is stated before anything moves,
    // and it is the partner who decides — declining writes nothing at all.
    if (result.conflict != null) {
      final go = await _confirmTakeover();
      if (!mounted) return;
      if (go != true) {
        setState(() => _busy = false);
        return;
      }
      await _auth.confirmTakeover(mobileNumber);
      if (!mounted) return;
    }

    // The free move is spent. CRM may have allowed another; if they have,
    // this is an ordinary verification, and if not there is nothing the
    // partner can do from here.
    if (result.tier == DeviceMoveTier.thirdOrLater) {
      final authorisation = await _auth.checkRebindingAuthorization(
        accountId: _accountId!,
        deviceId: _deviceId!,
      );
      if (!mounted) return;
      if (authorisation.status != RebindingAuthorizationStatus.authorized) {
        setState(() {
          _busy = false;
          _step = _Step.locked;
        });
        return;
      }
      _crmAuthorised = true;
    }

    await _sendCode();
  }

  /// Board 02 · A4 — the takeover dialog: what this phone holds now, and
  /// what it will hold after.
  Future<bool?> _confirmTakeover() => showDialog<bool>(
    context: context,
    barrierColor: const Color(0xFF0F172A).withValues(alpha: 0.45),
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.all(AppSpacing.lg),
      child: SingleChildScrollView(
        child: DsDialogCard(
          icon: LucideIcons.smartphone,
          title: 'This phone is signed in to another account',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              const DsBody(
                'Continuing signs that account out of this phone and moves '
                'your account here. Their account keeps working on any phone '
                'they sign in to next.',
                size: 14,
              ),
              const SizedBox(height: AppSpacing.md),
              DsButton(
                label: 'Continue and Verify',
                onPressed: () => Navigator.of(context).pop(true),
              ),
              const SizedBox(height: 10),
              DsButton(
                label: 'Cancel',
                variant: DsButtonVariant.quiet,
                onPressed: () => Navigator.of(context).pop(false),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  // --- A2 · A3 · the code ---------------------------------------------------

  Future<void> _sendCode() async {
    final result = await _auth.requestLoginOtp(
      accountId: _accountId!,
      deviceId: _deviceId!,
    );
    if (!mounted) return;

    if (result.status == LoginOtpStatus.notYetAuthorized) {
      setState(() {
        _busy = false;
        _step = _Step.locked;
      });
      return;
    }

    setState(() {
      _busy = false;
      _error = null;
      _prototypeCode = result.prototypeCode;
      _code.clear();
      _step = _Step.verify;
    });
    _startResendCountdown();
  }

  void _startResendCountdown() {
    _resend?.cancel();
    setState(() => _secondsLeft = 30);
    _resend = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return timer.cancel();
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 0) timer.cancel();
    });
  }

  Widget _verifyStep() {
    final minutes = (_secondsLeft ~/ 60).toString().padLeft(2, '0');
    final seconds = (_secondsLeft % 60).toString().padLeft(2, '0');

    return DsScreen(
      appBar: DsAppBar(
        title: 'Verify This Phone',
        onBack: () => setState(() {
          _step = _Step.number;
          _busy = false;
          _error = null;
        }),
      ),
      gap: 22,
      sections: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const DsHeading('Enter the 6-digit code'),
            const SizedBox(height: AppSpacing.sm),
            DsBody(
              'Sent by SMS to ${_formatNumber(_mobileNumber)}. This is a new '
              'phone, so we verify it before signing you in.',
              size: 14,
            ),
          ],
        ),
        EditableOtpField(controller: _code, error: _error != null),
        if (_error != null)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                LucideIcons.circleAlert,
                size: 16,
                color: context.colors.error,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: DsBody(_error!, color: context.status.error)),
            ],
          ),
        DsResendRow(
          countdown: '$minutes:$seconds',
          onResend: _secondsLeft > 0 || _busy ? null : _sendCode,
        ),
        if (_crmAuthorised)
          const DsNotice(
            icon: LucideIcons.circleCheck,
            tone: DsTone.success,
            title: 'CRM has allowed one move',
            message:
                'Crown Solar has cleared this phone for you. Verifying the '
                'code below moves your account here.',
          )
        else
          const DsNotice(
            icon: LucideIcons.smartphone,
            tone: DsTone.info,
            message:
                'After this, your account moves to this phone and your old '
                'phone is signed out. This is the one free move — a change '
                'after it needs Crown Solar CRM.',
          ),
        if (_prototypeCode != null)
          DsCaption(
            'Prototype: no SMS is sent, so the code is $_prototypeCode.',
          ),
      ],
      footer: DsFooterBar(
        child: DsButton(
          label: 'Verify and Sign In',
          loading: _busy,
          disabled: _code.text.length != 6 || _busy,
          onPressed: _verify,
        ),
      ),
    );
  }

  Future<void> _verify() async {
    setState(() {
      _busy = true;
      _error = null;
    });

    final verified = await _auth.verifyLoginOtp(
      accountId: _accountId!,
      deviceId: _deviceId!,
      code: _code.text,
    );
    if (!mounted) return;

    // Each refusal keeps its own name: one is fixed by retyping, one by
    // asking for a new code.
    if (verified.status != OtpVerifyStatus.verified) {
      setState(() {
        _busy = false;
        _error = verified.status == OtpVerifyStatus.invalidCode
            ? 'That code is not correct. Check it and try again.'
            : 'That code has expired. Ask for a new one.';
      });
      return;
    }

    // The move itself: the server revokes the old binding and activates this
    // one in the same transaction, so the account is never on two phones.
    final rebind = await _auth.completeRebinding(
      accountId: _accountId!,
      deviceId: _deviceId!,
    );
    if (!mounted) return;

    if (rebind.status != RebindStatus.activated) {
      setState(() {
        _busy = false;
        _error = rebind.status == RebindStatus.notAuthorized
            ? 'This phone is not cleared for your account. Call Crown Solar '
                  'CRM.'
            : 'Could not move your account to this phone. Try again.';
      });
      return;
    }

    await _completeSignIn();
  }

  // --- B1 · the refusal -----------------------------------------------------

  Widget _lockedStep() => DsScreen(
    appBar: DsAppBar(
      title: 'Cannot Sign In Here',
      onBack: () => setState(() {
        _step = _Step.number;
        _busy = false;
        _error = null;
      }),
    ),
    gap: AppSpacing.md,
    sections: [
      DsCard(
        radius: AppRadii.heroRadius,
        padding: const EdgeInsets.all(AppSpacing.stepLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const DsIconMedallion(
                  icon: LucideIcons.smartphoneNfc,
                  tone: DsTone.warning,
                  size: 44,
                  iconSize: 22,
                ),
                const SizedBox(width: AppSpacing.stepMd),
                Expanded(
                  child: Text(
                    'Your account is fixed to another phone',
                    style: context.texts.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            const DsBody(
              'Your account has already used its one free move to a new '
              'phone. It keeps working on the phone it is on now. Crown '
              'Solar CRM can allow one more move.',
              size: 14,
            ),
          ],
        ),
      ),
      DsCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'What to do',
              style: context.texts.bodyLarge?.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            const DsBody(
              'Call Crown Solar CRM and ask them to clear this phone. Once '
              'they do, sign in here again and you will be sent a code.',
              size: 14,
            ),
            const SizedBox(height: AppSpacing.stepMd),
            DsButton(
              label: 'Try Again',
              variant: DsButtonVariant.secondary,
              size: DsButtonSize.sm,
              icon: LucideIcons.refreshCw,
              loading: _busy,
              disabled: _busy,
              onPressed: () =>
                  _evaluate(_mobileNumber, keepSignedIn: _keepSignedIn),
            ),
          ],
        ),
      ),
      const DsCaption(
        'This is not a fault and nothing is lost. The account keeps working '
        'on the phone it is bound to.',
      ),
    ],
  );

  // --- Signed in ------------------------------------------------------------

  /// The device policy is satisfied; now load the partner behind the number
  /// and remember the session if they asked for it.
  Future<void> _completeSignIn() async {
    final session = context.read<SessionController>();
    final ok = await session.signIn(_mobileNumber, keepSignedIn: _keepSignedIn);
    if (!mounted) return;

    if (!ok) {
      setState(() {
        _busy = false;
        _step = _Step.number;
        _error =
            'Signed in on this phone, but your profile could not be loaded. '
            'Try again.';
      });
      return;
    }

    await _auth.persistSessionIfRequested(
      accountId: _accountId!,
      keepSignedIn: _keepSignedIn,
    );
    if (!mounted) return;

    setState(() => _busy = false);
    widget.onSignedIn();
  }

  /// "+92 300 4821190", as the code screen writes it back to the partner.
  static String _formatNumber(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    final local = digits.startsWith('92')
        ? digits.substring(2)
        : digits.startsWith('0')
        ? digits.substring(1)
        : digits;
    if (local.length < 10) return '+92 $local';
    return '+92 ${local.substring(0, 3)} ${local.substring(3)}';
  }
}
