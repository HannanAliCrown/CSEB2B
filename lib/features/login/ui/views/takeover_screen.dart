import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/ui/ds.dart';

/// Board 02 · A4 — Takeover: this phone belongs to another account.
///
/// Both bindings that will be removed are named *before* the OTP, because two
/// traders sharing a counter phone is a real situation.
class TakeoverScreen extends StatelessWidget {
  const TakeoverScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // The OTP step behind the dialog, dimmed to .35 as in the design.
          Opacity(
            opacity: 0.35,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.screenPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: const [
                    DsHeading('Enter the 6-digit code'),
                    SizedBox(height: 18),
                    DsOtpBoxes(digits: ''),
                  ],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: ColoredBox(
              color: const Color(0xFF0F172A).withValues(alpha: 0.45),
              child: SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: _TakeoverDialog(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TakeoverDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: AppRadii.lgRadius,
        boxShadow: AppShadows.dialog,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const DsIconMedallion(
            icon: LucideIcons.smartphoneNfc,
            tone: DsTone.warning,
            size: 48,
            iconSize: 24,
            rounded: true,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'This phone is signed in to another account',
            style: context.texts.titleLarge,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text.rich(
            TextSpan(
              style: context.texts.bodyMedium?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
              children: const [
                TextSpan(text: 'Continuing signs '),
                TextSpan(
                  text: 'Bilal Traders',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                TextSpan(
                  text:
                      ' out of this phone and moves your account here. Their '
                      'account is not deleted — they can sign back in on their '
                      'own phone.',
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: context.palette.sunken,
              borderRadius: AppRadii.mdRadius,
            ),
            child: Column(
              children: [
                _BindingRow(
                  label: 'This phone now',
                  value: 'Bilal Traders · Retailer',
                ),
                const SizedBox(height: AppSpacing.sm),
                _BindingRow(
                  label: 'After you continue',
                  value: 'Adnan Solar Works · Installer',
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          DsButton(label: 'Continue and Verify', onPressed: () {}),
          const SizedBox(height: 10),
          DsButton(
            label: 'Cancel',
            variant: DsButtonVariant.quiet,
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ],
      ),
    );
  }
}

class _BindingRow extends StatelessWidget {
  const _BindingRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        DsCaption(label),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}
