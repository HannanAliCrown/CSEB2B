import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/ui/ds.dart';

/// One tier in a scheme or the Reward Program: its name, what it takes, what
/// it pays, and whether it is reached, claimable or closed.
class TierRow extends StatelessWidget {
  const TierRow({
    super.key,
    required this.name,
    required this.requirement,
    required this.reward,
    required this.status,
    required this.statusTone,
    this.closed = false,
  });

  final String name;
  final String requirement;
  final String reward;
  final String status;
  final DsTone statusTone;
  final bool closed;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: closed ? 0.55 : 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 13),
        child: Row(
          children: [
            DsIconMedallion(
              icon: closed ? LucideIcons.lock : LucideIcons.medal,
              tone: closed ? DsTone.neutral : statusTone,
              size: 36,
              iconSize: 17,
            ),
            const SizedBox(width: AppSpacing.stepMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '· $reward',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: context.colors.primary,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    requirement,
                    style: TextStyle(
                      fontSize: 12,
                      color: context.palette.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            DsTag(label: status, tone: statusTone),
          ],
        ),
      ),
    );
  }
}

/// Board 09 · A4 — Reward Program: this month's tiers, with progress shown
/// and nothing to claim until month end.
class RewardProgramScreen extends StatelessWidget {
  const RewardProgramScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DsScreen(
      appBar: DsAppBar(
        title: 'Inaam Baazar',
        onBack: () => Navigator.of(context).maybePop(),
      ),
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      gap: AppSpacing.md,
      sections: [
        const DsSegmentedControl(
          options: ['Spin and Win', 'Reward Program', 'Item Scheme'],
          value: 'Reward Program',
        ),
        DsCard(
          tone: DsCardTone.accent,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Active Rewards · June',
                      style: context.texts.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const DsTag(label: 'Silver Inaam +25%', tone: DsTone.accent),
                ],
              ),
              const SizedBox(height: AppSpacing.stepMd),
              Row(
                children: const [
                  Expanded(
                    child: _MetaCell(label: 'REMAINING', value: '21 days'),
                  ),
                  Expanded(
                    child: _MetaCell(label: 'END DATE', value: '31 Jul'),
                  ),
                ],
              ),
            ],
          ),
        ),
        DsCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "This Month's Scheme",
                style: context.texts.bodyLarge?.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const DsCaption('Target · July · in progress'),
              const SizedBox(height: AppSpacing.stepMd),
              Row(
                children: const [
                  Expanded(
                    child: _MetaCell(label: 'START DATE', value: '1 Jul'),
                  ),
                  Expanded(
                    child: _MetaCell(label: 'END DATE', value: '31 Jul'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Your progress',
                      style: context.texts.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Text(
                    '20 scans',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const DsProgressBar(value: 20 / 40),
              const SizedBox(height: 10),
              const DsCaption('5 more scans to unlock Gold and get +50% bonus'),
            ],
          ),
        ),
        DsCard(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Column(
            children: const [
              TierRow(
                name: 'SILVER',
                requirement: '10 scans',
                reward: '+25%',
                status: 'Reached',
                statusTone: DsTone.success,
              ),
              DsHairline(),
              TierRow(
                name: 'GOLD',
                requirement: '25 scans',
                reward: '+50%',
                status: '5 to go',
                statusTone: DsTone.info,
              ),
              DsHairline(),
              TierRow(
                name: 'PLATINUM',
                requirement: '40 scans',
                reward: '+100%',
                status: '20 to go',
                statusTone: DsTone.neutral,
              ),
            ],
          ),
        ),
        const DsCaption(
          'Reaching a tier marks it complete but there is nothing to claim '
          'here. At month end the highest tier you reached is awarded, and it '
          "becomes the extra you earn on every scheme-product scan next month.",
        ),
        const DsCaption(
          'CSE-OPN-06 · Reward Program logic is not finalised. Scan counts and '
          'percentages shown here are sample data.',
        ),
      ],
    );
  }
}

class _MetaCell extends StatelessWidget {
  const _MetaCell({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            letterSpacing: 0.06 * 11,
            fontWeight: FontWeight.w600,
            color: context.palette.textTertiary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

/// Board 09 · B1 — A scan-based scheme with Silver unlocked, and the
/// one-claim-only rule stated before the button is ever pressed.
class ScanSchemeScreen extends StatelessWidget {
  const ScanSchemeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DsScreen(
      appBar: DsAppBar(
        title: 'Inaam Baazar',
        onBack: () => Navigator.of(context).maybePop(),
      ),
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      gap: AppSpacing.md,
      footer: DsFooterBar(
        child: DsButton(label: 'Claim Silver · Rs. 14,000', onPressed: () {}),
      ),
      sections: [
        const DsSegmentedControl(
          options: ['Spin and Win', 'Reward Program', 'Item Scheme'],
          value: 'Item Scheme',
        ),
        DsCard(
          radius: AppRadii.heroRadius,
          padding: const EdgeInsets.all(AppSpacing.stepLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'MEASURED ON SCANS',
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 0.06 * 11,
                  fontWeight: FontWeight.w600,
                  color: context.palette.textTertiary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  const Text(
                    '168',
                    style: TextStyle(
                      fontSize: 34,
                      height: 40 / 34,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  DsBody('scans so far', size: 14),
                ],
              ),
              const SizedBox(height: AppSpacing.stepMd),
              const DsProgressBar(value: 168 / 300),
              const SizedBox(height: 10),
              const DsCaption(
                'Silver reached at 150 · 132 more scans for Gold',
              ),
            ],
          ),
        ),
        const DsNotice(
          icon: LucideIcons.triangleAlert,
          tone: DsTone.warning,
          message:
              'You can claim one tier only. Taking Silver now closes Gold and '
              'Platinum for good, even if you reach their targets later.',
        ),
        DsCard(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Column(
            children: const [
              TierRow(
                name: 'Silver',
                requirement: '150 scans · reached',
                reward: 'Rs. 14,000',
                status: 'Claim now',
                statusTone: DsTone.success,
              ),
              DsHairline(),
              TierRow(
                name: 'Gold',
                requirement: '300 scans · 132 to go',
                reward: 'Rs. 25,000',
                status: 'Locked',
                statusTone: DsTone.neutral,
                closed: true,
              ),
              DsHairline(),
              TierRow(
                name: 'Platinum',
                requirement: '500 scans · 332 to go',
                reward: 'Rs. 40,000',
                status: 'Locked',
                statusTone: DsTone.neutral,
                closed: true,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Board 09 · B2 — An amount-based scheme with nothing unlocked yet. A scheme
/// is either scans or amount, never both.
class AmountSchemeScreen extends StatelessWidget {
  const AmountSchemeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DsScreen(
      appBar: DsAppBar(
        title: 'Item Scheme',
        onBack: () => Navigator.of(context).maybePop(),
      ),
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      gap: AppSpacing.md,
      sections: [
        DsCard(
          radius: AppRadii.heroRadius,
          padding: const EdgeInsets.all(AppSpacing.stepLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'MEASURED ON AMOUNT',
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 0.06 * 11,
                  fontWeight: FontWeight.w600,
                  color: context.palette.textTertiary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    'PKR',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: context.palette.textTertiary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  const Text(
                    '840,000',
                    style: TextStyle(
                      fontSize: 34,
                      height: 40 / 34,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.stepMd),
              const DsProgressBar(value: 840000 / 1200000),
              const SizedBox(height: 10),
              const DsCaption('PKR 360,000 more for Silver'),
            ],
          ),
        ),
        DsCard(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Column(
            children: const [
              TierRow(
                name: 'Silver',
                requirement: 'PKR 1.2 M in purchases',
                reward: 'Rs. 14,000',
                status: 'Locked',
                statusTone: DsTone.neutral,
                closed: true,
              ),
              DsHairline(),
              TierRow(
                name: 'Gold',
                requirement: 'PKR 2.5 M in purchases',
                reward: 'Rs. 25,000',
                status: 'Locked',
                statusTone: DsTone.neutral,
                closed: true,
              ),
              DsHairline(),
              TierRow(
                name: 'Platinum',
                requirement: 'PKR 4 M in purchases',
                reward: 'Rs. 40,000',
                status: 'Locked',
                statusTone: DsTone.neutral,
                closed: true,
              ),
            ],
          ),
        ),
        const DsCaption(
          'A scheme is either scans or amount, set when Crown Solar creates '
          'it. You will never see both measures on one scheme.',
        ),
      ],
    );
  }
}

/// Board 09 · B3 — Claim confirmation: the cost of claiming now is spelled
/// out, in the user's own numbers.
class SchemeClaimConfirmScreen extends StatelessWidget {
  const SchemeClaimConfirmScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A).withValues(alpha: 0.45),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: DsDialogCard(
              icon: LucideIcons.medal,
              title: 'Claim Silver for Rs. 14,000?',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const DsBody(
                    'This is the only tier you will be able to claim from this '
                    'scheme. Gold at Rs. 25,000 and Platinum at Rs. 40,000 '
                    'close permanently, even if you reach their targets.',
                    size: 14,
                  ),
                  const SizedBox(height: AppSpacing.stepMd),
                  const DsNotice(
                    message:
                        'You are at 168 scans. Gold needs 300 — about two more '
                        'months at your current pace.',
                    dense: true,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  DsButton(label: 'Yes, Claim Silver', onPressed: () {}),
                  const SizedBox(height: 10),
                  DsButton(
                    label: 'Keep Scanning Instead',
                    variant: DsButtonVariant.quiet,
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Board 09 · B4 — Claimed: the other tiers are now closed, and the screen
/// says exactly what is unaffected.
class SchemeClaimedScreen extends StatelessWidget {
  const SchemeClaimedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DsScreen(
      appBar: DsAppBar(
        title: 'Item Scheme',
        onBack: () => Navigator.of(context).maybePop(),
      ),
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      gap: AppSpacing.md,
      sections: [
        DsCard(
          radius: AppRadii.heroRadius,
          padding: const EdgeInsets.all(AppSpacing.stepLg),
          child: Column(
            children: [
              const DsIconMedallion(
                icon: LucideIcons.medal,
                tone: DsTone.success,
                size: 64,
                iconSize: 30,
              ),
              const SizedBox(height: 14),
              Text(
                'Silver claimed · Rs. 14,000',
                textAlign: TextAlign.center,
                style: context.texts.titleLarge,
              ),
              const SizedBox(height: AppSpacing.sm),
              const DsBody(
                'Ref ITM-2026-1180 · Credited to your wallet. Your balance is '
                'PKR 198,500.',
                size: 14,
                align: TextAlign.center,
              ),
            ],
          ),
        ),
        Text(
          'NOW CLOSED TO YOU',
          style: TextStyle(
            fontSize: 11,
            letterSpacing: 0.06 * 11,
            fontWeight: FontWeight.w600,
            color: context.palette.textTertiary,
          ),
        ),
        DsCard(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Column(
            children: const [
              TierRow(
                name: 'Gold',
                requirement: '300 scans',
                reward: 'Rs. 25,000',
                status: 'Closed',
                statusTone: DsTone.neutral,
                closed: true,
              ),
              DsHairline(),
              TierRow(
                name: 'Platinum',
                requirement: '500 scans',
                reward: 'Rs. 40,000',
                status: 'Closed',
                statusTone: DsTone.neutral,
                closed: true,
              ),
            ],
          ),
        ),
        const DsCaption(
          'Your scanning still earns QR prizes, spins and Reward Program '
          'bonuses as normal. Only this scheme is closed.',
        ),
      ],
    );
  }
}

/// Board 09 · B5 — The retired feature and the open items, kept visible so
/// the gaps are not mistaken for oversights.
class InaamDesignNotesScreen extends StatelessWidget {
  const InaamDesignNotesScreen({super.key});

  static const _notes = [
    (
      'CSE-INM-02',
      'Daily Scans is retired',
      'No entry point, no tab, no historical view. The scan counter on the '
          'scanner exists only to serve the spin entitlement.',
    ),
    (
      'CSE-OPN-04',
      'Prize weighting and daily cap · TBD',
      'No odds, probabilities, tiers or caps appear anywhere in the UI. Copy '
          'states the Rs. 50 – Rs. 50,000 range as configuration, and each '
          'spin records the configuration version in force.',
    ),
    (
      'CSE-OPN-06',
      'Reward Program logic · TBD',
      'Progress, qualified, awaiting month-end and result states are '
          'designed. The bonus mechanic is described as "the target you hit '
          "changes next month's bonus\" and no arithmetic is shown.",
    ),
    (
      'CSE-INM-12',
      'Month-end evaluation is a backend job',
      'The UI shows an awaiting-result state between month end and the job '
          'completing, rather than pretending the result is instant.',
    ),
    (
      'CSE-INM-05/07',
      'Weighting is never exposed as a choice',
      'The wheel is presented as a single action with a controlled reveal. '
          'Nothing suggests the user can influence, pick or improve their '
          'odds.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return DsScreen(
      appBar: DsAppBar(
        title: 'Design Notes',
        subtitle: 'Not a product screen',
        onBack: () => Navigator.of(context).maybePop(),
      ),
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      gap: AppSpacing.stepMd,
      sections: [
        for (final (ref, title, body) in _notes)
          DsCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DsTag(label: ref, tone: DsTone.accent),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  title,
                  style: context.texts.bodyLarge?.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                DsBody(body),
              ],
            ),
          ),
      ],
    );
  }
}
