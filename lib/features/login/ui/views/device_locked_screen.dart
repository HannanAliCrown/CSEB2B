import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/ui/ds.dart';

/// Board 02 · B1 — Refused: the account is locked to a device.
///
/// Grey, never red: being fixed to another phone is a fact, not a fault, and
/// no password reset is offered because this is not a password problem.
class DeviceLockedScreen extends StatelessWidget {
  const DeviceLockedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DsScreen(
      appBar: DsAppBar(
        title: 'Cannot Sign In Here',
        onBack: () => Navigator.of(context).maybePop(),
      ),
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      gap: 18,
      sections: [
        DsCard(
          radius: AppRadii.heroRadius,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
          child: Column(
            children: [
              const DsIconMedallion(
                icon: LucideIcons.smartphone,
                tone: DsTone.neutral,
                size: 64,
                iconSize: 30,
              ),
              const SizedBox(height: 14),
              Text(
                'Your account is fixed to another phone',
                textAlign: TextAlign.center,
                style: context.texts.titleLarge,
              ),
              const SizedBox(height: 14),
              Text.rich(
                textAlign: TextAlign.center,
                TextSpan(
                  style: context.texts.bodyMedium?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                  children: const [
                    TextSpan(
                      text:
                          'You have already moved your account once. It now '
                          'stays on the phone ending ',
                    ),
                    TextSpan(
                      text: '·· 4471',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    TextSpan(
                      text:
                          '. Your account is working normally there — nothing '
                          'is blocked or suspended.',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        DsCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'If you cannot use that phone',
                style: context.texts.bodyLarge?.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.stepMd),
              const DsBody(
                'Lost, stolen, sold or broken — Crown Solar CRM can allow one '
                'move to a new phone. They will ask what happened and record '
                'it.',
              ),
              const SizedBox(height: AppSpacing.stepMd),
              DsButton(
                label: 'Call CRM',
                icon: LucideIcons.phone,
                onPressed: () {},
              ),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 2),
          child: DsCaption(
            'This is not a password problem, so no password reset is offered '
            'here.',
          ),
        ),
      ],
    );
  }
}

/// Board 02 · B4 — Account deactivated.
///
/// Deactivation is deliberately distinguished from a transaction block.
class AccountDeactivatedScreen extends StatelessWidget {
  const AccountDeactivatedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DsScreen(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      gap: AppSpacing.stepLg,
      crossAxisAlignment: CrossAxisAlignment.center,
      sections: [
        const DsIconMedallion(
          icon: LucideIcons.userX,
          tone: DsTone.neutral,
          size: 80,
          iconSize: 38,
        ),
        Column(
          children: [
            Text(
              'This account is deactivated',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                height: 28 / 22,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.02 * 22,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Crown Solar CRM has closed access to this account. Your wallet, '
              'points and history are kept — they are not deleted.',
              textAlign: TextAlign.center,
              style: context.texts.bodyLarge?.copyWith(
                fontSize: 15,
                height: 22 / 15,
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const DsCard(
          child: DsBody(
            'Deactivation is different from a transaction block. A blocked '
            'account can still be opened and its balance viewed; a deactivated '
            'account cannot be opened at all.',
          ),
        ),
        DsButton(label: 'Call CRM', icon: LucideIcons.phone, onPressed: () {}),
      ],
    );
  }
}
