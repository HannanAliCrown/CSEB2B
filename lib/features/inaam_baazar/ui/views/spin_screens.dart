import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/ui/ds.dart';
import '../../../home/ui/models/home_demo_data.dart';
import '../widgets/inaam_widgets.dart';

/// Board 09 · A1 — Inaam hub: spins waiting, how the next one is earned, and
/// the wheel itself.
class InaamHubScreen extends StatelessWidget {
  const InaamHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: DsAppBar(
        title: 'Inaam Baazar',
        onBack: () => Navigator.of(context).maybePop(),
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.screenPadding,
                10,
                AppSpacing.screenPadding,
                0,
              ),
              child: DsTabs(
                tabs: ['Spin and Win', 'Reward Program', 'Item Scheme'],
                value: 'Spin and Win',
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenPadding,
                  AppSpacing.md,
                  AppSpacing.screenPadding,
                  AppSpacing.stepLg,
                ),
                children: [
                  const InaamSpinsCard(
                    spins: 2,
                    scansToday: 24,
                    scansTarget: 30,
                    progress: 0.8,
                    note:
                        '6 more scans earns another spin. There is no limit '
                        'on how many you can earn in a day.',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  DsCard(
                    child: Column(
                      children: [
                        const InaamSpinWheel(),
                        const SizedBox(height: 14),
                        Text(
                          'Prizes range from Rs. 50 to Rs. 50,000 and are '
                          'credited to your wallet.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            height: 19 / 13,
                            color: context.colors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 14),
                        DsButton(label: 'Spin Now', onPressed: () {}),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Spin history',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        'See all',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: context.colors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const DsCard(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    child: Column(
                      children: [
                        InaamSpinRow(prize: 'Rs. 50', when: 'Today, 5:31 PM'),
                        InaamSpinRow(prize: 'Rs. 200', when: '07 Sep, 7:14 PM'),
                        InaamSpinRow(
                          prize: 'Rs. 1,000',
                          when: '05 Sep, 4:48 PM',
                          last: true,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: DsBottomNav(
        items: HomeDemo.installer.nav,
        activeId: 'inaam',
      ),
    );
  }
}

/// Board 09 · A2 — Result: the prize is revealed and credited to the wallet
/// in the same breath, with the reference for the ledger row.
class SpinResultScreen extends StatelessWidget {
  const SpinResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: 26,
          ),
          child: Column(
            children: [
              const InaamSpinWheel(
                size: 216,
                centre: InaamWheelPrize(amount: 'Rs. 50'),
              ),
              const SizedBox(height: AppSpacing.cardPadding),
              const Text(
                'Rs. 50 added to your wallet',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  height: 28 / 22,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.02 * 22,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              const DsBody(
                'Your balance is now PKR 184,550. Ref SPN-2026-44192 · '
                'Today, 5:31 PM',
                size: 14,
                align: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.cardPadding),
              const DsCard(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Column(
                  children: [
                    InaamSpinRow(prize: 'Rs. 50', when: 'Today, 5:31 PM'),
                    InaamSpinRow(prize: 'Rs. 50', when: 'Yesterday, 6:02 PM'),
                    InaamSpinRow(prize: 'Rs. 200', when: '07 Sep, 7:14 PM'),
                    InaamSpinRow(
                      prize: 'Rs. 1,000',
                      when: '05 Sep, 4:48 PM',
                      last: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: DsFooterBar(
        child: Column(
          children: [
            DsButton(label: 'Use Your Second Spin', onPressed: () {}),
            const SizedBox(height: 10),
            DsButton(
              label: 'Done',
              variant: DsButtonVariant.quiet,
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          ],
        ),
      ),
    );
  }
}

/// Board 09 · A3 — No spins, already used, and a mid-spin connection drop —
/// the three ways a spin can be unavailable, and why a retry is safe.
class SpinUnavailableScreen extends StatelessWidget {
  const SpinUnavailableScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DsScreen(
      appBar: DsAppBar(
        title: 'Spin and Win',
        onBack: () => Navigator.of(context).maybePop(),
      ),
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      gap: 14,
      sections: [
        DsCard(
          padding: EdgeInsets.zero,
          child: DsEmptyState(
            icon: LucideIcons.scanLine,
            title: 'No Spins Right Now',
            message:
                'You have 4 scans today. Reach 10 scans in one day to earn a '
                'spin.',
            actionLabel: 'Open Scanner',
            onAction: () {},
          ),
        ),
        DsCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const DsIconMedallion(
                icon: LucideIcons.circleCheck,
                tone: DsTone.neutral,
              ),
              const SizedBox(width: AppSpacing.stepMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'This spin has already been used',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'You won Rs. 50 on it at 5:31 PM yesterday. It cannot '
                      'be spun again.',
                      style: TextStyle(
                        fontSize: 13,
                        height: 19 / 13,
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        DsCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const DsIconMedallion(
                    icon: LucideIcons.wifiOff,
                    tone: DsTone.neutral,
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Spin could not be completed',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'The connection dropped mid-spin. Your spin has not been '
                'used. Try again when you have signal.',
                style: TextStyle(
                  fontSize: 13,
                  height: 19 / 13,
                  color: context.colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 10),
              DsButton(
                label: 'Try Again',
                size: DsButtonSize.sm,
                icon: LucideIcons.refreshCw,
                onPressed: () {},
              ),
            ],
          ),
        ),
        const DsCaption(
          'A retried spin never consumes two entitlements or pays two prizes.',
        ),
      ],
    );
  }
}
