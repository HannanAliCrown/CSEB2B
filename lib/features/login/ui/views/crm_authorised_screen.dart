import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/ui/ds.dart';

/// Board 02 · B2 — CRM authorised: one move available.
///
/// The authorisation banner sits above the OTP entry, and the two
/// consequences of completing the move are spelled out beneath it.
class CrmAuthorisedScreen extends StatelessWidget {
  const CrmAuthorisedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DsScreen(
      appBar: DsAppBar(
        title: 'Verify This Phone',
        onBack: () => Navigator.of(context).maybePop(),
      ),
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      gap: 18,
      sections: [
        const DsNotice(
          icon: LucideIcons.shieldCheck,
          tone: DsTone.success,
          title: 'CRM has allowed one move',
          message:
              'Authorised by Crown Solar CRM today at 3:22 PM. Verify this '
              'phone to complete the move.',
        ),
        const DsOtpBoxes(digits: '73', focusedIndex: 2),
        Text.rich(
          TextSpan(
            style: context.texts.bodyMedium?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
            children: [
              const TextSpan(text: 'Resend code in '),
              TextSpan(
                text: '00:41',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: context.colors.onSurface,
                ),
              ),
            ],
          ),
        ),
        DsCard(
          radius: AppRadii.mdRadius,
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: const [
              _InfoLine(
                'This allowance covers one move only. Once this phone is '
                'verified, your account locks to it again.',
              ),
              SizedBox(height: 10),
              _InfoLine(
                'The old phone will be signed out and cannot open your account.',
              ),
            ],
          ),
        ),
      ],
      footer: DsFooterBar(
        child: DsButton(label: 'Verify and Sign In', onPressed: () {}),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(LucideIcons.info, size: 16, color: context.status.info),
        const SizedBox(width: 10),
        Expanded(child: DsBody(text)),
      ],
    );
  }
}
