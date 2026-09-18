import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/ui/ds.dart';
import '../widgets/crown_wordmark.dart';

/// Board 02 · C1 — PIN unlock.
///
/// The PIN protects this handset only; it never affects device binding.
class PinUnlockScreen extends StatefulWidget {
  const PinUnlockScreen({super.key});

  @override
  State<PinUnlockScreen> createState() => _PinUnlockScreenState();
}

class _PinUnlockScreenState extends State<PinUnlockScreen> {
  String _pin = '12';

  @override
  Widget build(BuildContext context) {
    return DsScreen(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
      gap: 22,
      crossAxisAlignment: CrossAxisAlignment.center,
      sections: [
        const CrownWordmark(height: 44),
        Column(
          children: [
            const DsHeading('Enter your PIN'),
            const SizedBox(height: 6),
            const DsBody(
              'Adnan Solar Works · Installer',
              size: 14,
              align: TextAlign.center,
            ),
          ],
        ),
        DsPinDots(filled: _pin.length),
        DsKeypad(
          onDigit: (d) => setState(() {
            if (_pin.length < 4) _pin += d;
          }),
          onBackspace: () => setState(() {
            if (_pin.isNotEmpty) _pin = _pin.substring(0, _pin.length - 1);
          }),
        ),
        Center(
          child: Text(
            'Forgot PIN?',
            style: context.texts.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: context.colors.primary,
            ),
          ),
        ),
      ],
    );
  }
}

/// Board 02 · C3 — Where the PIN is set: Profile → App Security.
class AppSecurityScreen extends StatefulWidget {
  const AppSecurityScreen({super.key});

  @override
  State<AppSecurityScreen> createState() => _AppSecurityScreenState();
}

class _AppSecurityScreenState extends State<AppSecurityScreen> {
  bool _pinEnabled = true;

  @override
  Widget build(BuildContext context) {
    return DsScreen(
      appBar: DsAppBar(
        title: 'App Security',
        onBack: () => Navigator.of(context).maybePop(),
      ),
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      gap: 18,
      sections: [
        DsCard(
          child: Row(
            children: [
              const DsIconMedallion(
                icon: LucideIcons.lockKeyhole,
                size: 40,
                iconSize: 20,
                rounded: true,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'App PIN',
                      style: context.texts.bodyLarge?.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Ask for a 4-digit PIN when the app opens',
                      style: context.texts.bodySmall?.copyWith(
                        color: context.palette.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              DsSwitch(
                checked: _pinEnabled,
                onChanged: (v) => setState(() => _pinEnabled = v),
              ),
            ],
          ),
        ),
        DsCard(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Row(
            children: [
              Icon(
                LucideIcons.keyRound,
                size: 20,
                color: context.colors.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpacing.stepMd),
              Expanded(
                child: Text(
                  'Change PIN',
                  style: context.texts.bodyLarge?.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(
                LucideIcons.chevronRight,
                size: 20,
                color: context.palette.textTertiary,
              ),
            ],
          ),
        ),
        const DsNotice(
          icon: LucideIcons.info,
          message:
              'The PIN protects this phone only. It does not affect which phone '
              'your account is fixed to. Turning the switch off removes the '
              'PIN — there is no separate Remove PIN item.',
        ),
      ],
    );
  }
}
