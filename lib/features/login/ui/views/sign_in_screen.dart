import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/ui/ds.dart';
import '../../../design_preview/preview_journey.dart';
import '../widgets/crown_wordmark.dart';

/// Board 02 · A1 — Sign in.
///
/// Mobile number only, "Keep me signed in", and the device-policy notice
/// stated up front so the OTP screen is never a surprise.
class SignInScreen extends StatefulWidget {
  const SignInScreen({
    super.key,
    this.notice,
    this.onSignIn,
    this.onRegister,
    this.onSubmit,
    this.busy = false,
    this.error,
  });

  /// The session-expired variant (B3) reuses this screen with a notice.
  final Widget? notice;

  /// Signing in on the bound device goes straight to the dashboard — no OTP.
  final VoidCallback? onSignIn;

  /// Called with the typed number and the "Keep me signed in" choice. When
  /// this is given the screen is live; without it the design's static
  /// sample number stands, for the preview.
  final void Function(String mobileNumber, {required bool keepSignedIn})?
  onSubmit;

  final bool busy;
  final String? error;

  /// "Register" is the only path from here into the registration wizard.
  final VoidCallback? onRegister;

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  bool _keepSignedIn = true;
  final _number = TextEditingController();

  @override
  void dispose() {
    _number.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DsScreen(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.xl,
        AppSpacing.screenPadding,
        AppSpacing.lg,
      ),
      gap: AppSpacing.lg,
      sections: [
        const Align(
          alignment: AlignmentDirectional.centerStart,
          child: CrownWordmark(height: 52),
        ),
        if (widget.notice != null) widget.notice!,
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sign in', style: context.texts.headlineSmall),
            const SizedBox(height: AppSpacing.sm),
            const DsBody(
              'Use the mobile number registered with Crown Solar.',
              size: 14,
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // The number is always typed. Outside the wizard the design's
            // sample number stands, for the preview only.
            if (widget.onSubmit == null)
              const DsInput(
                label: 'Mobile number',
                value: '+92 300 4821190',
                keyboardType: TextInputType.phone,
              )
            else
              DsInput(
                label: 'Mobile number',
                placeholder: '300 4821190',
                prefix: Text('+92', style: context.texts.bodyLarge),
                controller: _number,
                keyboardType: TextInputType.phone,
                error: widget.error,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
              ),
            const SizedBox(height: 14),
            DsCheckbox(
              checked: _keepSignedIn,
              label: 'Keep me signed in',
              onChanged: (value) => setState(() => _keepSignedIn = value),
            ),
          ],
        ),
        const DsNotice(
          icon: LucideIcons.smartphone,
          message:
              'Your account works on one phone at a time. Signing in on a new '
              'phone needs an SMS code.',
        ),
      ],
      footer: DsFooterBar(
        child: Column(
          children: [
            DsButton(
              label: 'Sign In',
              loading: widget.busy,
              onPressed: widget.onSubmit != null
                  ? () => widget.onSubmit!(
                      _number.text,
                      keepSignedIn: _keepSignedIn,
                    )
                  : widget.onSignIn ?? () => openDashboard(context),
            ),
            const SizedBox(height: AppSpacing.stepMd),
            GestureDetector(
              onTap: widget.onRegister ?? () => PreviewJourney.next(context),
              child: Text.rich(
                textAlign: TextAlign.center,
                TextSpan(
                  style: TextStyle(
                    fontSize: 13,
                    height: 19 / 13,
                    color: context.colors.onSurfaceVariant,
                  ),
                  children: [
                    const TextSpan(text: 'New to Crown Solar? '),
                    TextSpan(
                      text: 'Register',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: context.colors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Board 02 · B3 — Session expired: the same sign-in screen with an
/// explanatory notice, no OTP, and no password reset offered.
class SessionExpiredScreen extends StatelessWidget {
  const SessionExpiredScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SignInScreen(
      notice: DsNotice(
        icon: LucideIcons.clock,
        tone: DsTone.info,
        message:
            'You were signed out because your session ended. Sign in again to '
            'continue — this is not a device change, and no code is needed on '
            'this phone.',
      ),
    );
  }
}
