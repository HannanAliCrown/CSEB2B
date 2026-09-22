import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/ui/ds.dart';
import '../widgets/inaam_widgets.dart';

/// Board 09 · A4 — Reward Program: this month's tiers, with progress shown
/// and nothing to claim until month end.
class RewardProgramScreen extends StatelessWidget {
  const RewardProgramScreen({super.key});

  static const _tiers = [
    ('Silver', '10 scans', '+25%'),
    ('Gold', '25 scans', '+50%'),
    ('Platinum', '40 scans', '+100%'),
  ];

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
                value: 'Reward Program',
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
                  const InaamRewardBanner(
                    title: 'Active Rewards · June',
                    remaining: '21 days',
                    endDate: '31 Jul',
                    tierName: 'Silver',
                    bonus: '+25%',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text("This Month's Scheme", style: context.texts.titleLarge),
                  const SizedBox(height: AppSpacing.md),
                  DsCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Target · July · in progress',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        const InaamDateStrip(
                          startLabel: 'Start date',
                          startValue: '1 Jul',
                          endLabel: 'End date',
                          endValue: '31 Jul',
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Your progress',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 11,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: context.colors.primary,
                                borderRadius: BorderRadius.circular(
                                  AppRadii.pill,
                                ),
                              ),
                              child: Text(
                                '20 scans',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: context.colors.onPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        const InaamMilestoneTrack(
                          milestones: [
                            InaamMilestone(
                              name: 'Silver',
                              target: 10,
                              reached: true,
                            ),
                            InaamMilestone(
                              name: 'Gold',
                              target: 25,
                              reached: false,
                            ),
                            InaamMilestone(
                              name: 'Platinum',
                              target: 40,
                              reached: false,
                            ),
                          ],
                          scans: 20,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        const InaamNextUp(
                          '5 more scans to unlock Gold and get +50% bonus',
                        ),
                        const SizedBox(height: AppSpacing.md),
                        IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              for (var i = 0; i < _tiers.length; i++) ...[
                                if (i != 0) const SizedBox(width: 10),
                                Expanded(
                                  child: InaamRewardTierCard(
                                    name: _tiers[i].$1,
                                    requirement: _tiers[i].$2,
                                    bonus: _tiers[i].$3,
                                    index: i,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const DsNotice(
                    icon: LucideIcons.info,
                    tone: DsTone.info,
                    message:
                        'Reaching a tier marks it complete but there is '
                        'nothing to claim here. At month end the highest tier '
                        'you reached is awarded, and it becomes the extra you '
                        'earn on every scheme-product scan next month.',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const DsCaption(
                    'CSE-OPN-06 · Reward Program logic is not finalised. Scan '
                    'counts and percentages shown here are sample data.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Board 09 · B1 — A scan-based scheme with Silver unlocked, and the
/// one-claim-only rule stated before the button is ever pressed.
class ScanSchemeScreen extends StatelessWidget {
  const ScanSchemeScreen({super.key});

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
                value: 'Item Scheme',
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
                children: const [
                  InaamMeasureCard(
                    label: 'Measured on scans',
                    value: '168',
                    suffix: 'scans so far',
                    percent: 168 / 300,
                    note: 'Silver reached at 150 · 132 more scans for Gold',
                  ),
                  SizedBox(height: 14),
                  DsNotice(
                    icon: LucideIcons.triangleAlert,
                    tone: DsTone.warning,
                    message:
                        'You can claim one tier only. Taking Silver now '
                        'closes Gold and Platinum for good, even if you reach '
                        'their targets later.',
                  ),
                  SizedBox(height: 14),
                  InaamTierCard(
                    name: 'Silver',
                    prize: '· Rs. 14,000',
                    target: '150 scans · reached',
                    state: 'Claim now',
                    claimable: true,
                  ),
                  SizedBox(height: 14),
                  InaamTierCard(
                    name: 'Gold',
                    prize: '· Rs. 25,000',
                    target: '300 scans · 132 to go',
                    state: 'Locked',
                  ),
                  SizedBox(height: 14),
                  InaamTierCard(
                    name: 'Platinum',
                    prize: '· Rs. 40,000',
                    target: '500 scans · 332 to go',
                    state: 'Locked',
                    dimmed: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: DsFooterBar(
        child: DsButton(label: 'Claim Silver · Rs. 14,000', onPressed: () {}),
      ),
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
      gap: 14,
      sections: const [
        InaamMeasureCard(
          label: 'Measured on amount',
          prefix: 'PKR',
          value: '840,000',
          percent: 840000 / 1200000,
          note: 'PKR 360,000 more for Silver',
        ),
        InaamTierCard(
          name: 'Silver',
          prize: '· Rs. 14,000',
          target: 'PKR 1.2 M in purchases',
          state: 'Locked',
        ),
        InaamTierCard(
          name: 'Gold',
          prize: '· Rs. 25,000',
          target: 'PKR 2.5 M in purchases',
          state: 'Locked',
        ),
        InaamTierCard(
          name: 'Platinum',
          prize: '· Rs. 40,000',
          target: 'PKR 4 M in purchases',
          state: 'Locked',
          dimmed: true,
        ),
        InaamSoftNote(
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
              icon: LucideIcons.triangleAlert,
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
                  const SizedBox(height: AppSpacing.md),
                  const InaamSoftNote(
                    'You are at 168 scans. Gold needs 300 — about two more '
                    'months at your current pace.',
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
      gap: 14,
      sections: const [
        InaamClaimedCard(
          title: 'Silver claimed · Rs. 14,000',
          reference: 'Ref ITM-2026-1180',
          note: 'Credited to your wallet. Your balance is PKR 198,500.',
        ),
        InaamCapsLabel('Now closed to you', size: 13),
        InaamTierCard(
          name: 'Gold',
          prize: '· Rs. 25,000',
          target: '300 scans',
          dimmed: true,
        ),
        InaamTierCard(
          name: 'Platinum',
          prize: '· Rs. 40,000',
          target: '500 scans',
          dimmed: true,
        ),
        InaamSoftNote(
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
