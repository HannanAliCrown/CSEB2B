import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/ui/ds.dart';

/// Board 02 · A2 — New device · SMS code.
///
/// The consequence of verifying is stated before the user commits, and the
/// resend countdown gates the resend action.
class VerifyPhoneScreen extends StatelessWidget {
  const VerifyPhoneScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DsScreen(
      appBar: DsAppBar(
        title: 'Verify This Phone',
        onBack: () => Navigator.of(context).maybePop(),
      ),
      gap: 22,
      sections: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const DsHeading('Enter the 6-digit code'),
            const SizedBox(height: AppSpacing.sm),
            const DsBody(
              'Sent by SMS to +92 300 4821190. This is a new phone, so we '
              'verify it before signing you in.',
              size: 14,
            ),
          ],
        ),
        const DsOtpBoxes(digits: '4812', focusedIndex: 4),
        DsResendRow(countdown: '00:24'),
        const DsNotice(
          icon: LucideIcons.smartphone,
          tone: DsTone.info,
          message:
              'After this, your account moves to this phone and your old phone '
              'is signed out. This is the one free move — a change after it '
              'needs Crown Solar CRM.',
        ),
      ],
      footer: DsFooterBar(
        child: DsButton(label: 'Verify and Sign In', onPressed: () {}),
      ),
    );
  }
}

/// Board 02 · A3 — Wrong code, then lockout.
///
/// Expired code, wrong code and rate limit are three different messages; the
/// attempts remaining and the exact retry time are both named.
class VerifyPhoneLockedScreen extends StatelessWidget {
  const VerifyPhoneLockedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DsScreen(
      appBar: DsAppBar(
        title: 'Verify This Phone',
        onBack: () => Navigator.of(context).maybePop(),
      ),
      gap: AppSpacing.stepLg,
      sections: [
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
        const DsHairline(),
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
                'Too many incorrect codes. You can try again at 10:02 AM — '
                'that is 14 minutes from now. Codes also expire 10 minutes '
                'after they are sent.',
              ),
              const SizedBox(height: AppSpacing.stepMd),
              DsButton(
                label: 'Call Crown Solar CRM',
                variant: DsButtonVariant.tertiary,
                size: DsButtonSize.sm,
                icon: LucideIcons.phone,
                onPressed: () {},
              ),
            ],
          ),
        ),
        const DsCaption(
          'Expired code, wrong code and rate limit are three different '
          'messages. None of them says "something went wrong".',
        ),
      ],
      footer: const DsFooterBar(
        child: DsButton(label: 'Verify and Sign In', disabled: true),
      ),
    );
  }
}
