import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/ui/ds.dart';

/// The year-total header every target screen opens with.
class _YearTotalCard extends StatelessWidget {
  const _YearTotalCard({
    required this.status,
    required this.statusTone,
    required this.value,
    required this.target,
    required this.note,
    required this.percent,
  });

  final String status;
  final DsTone statusTone;
  final String value;
  final String target;
  final String note;
  final double percent;

  @override
  Widget build(BuildContext context) {
    return DsCard(
      radius: AppRadii.heroRadius,
      padding: const EdgeInsets.all(AppSpacing.stepLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'YEAR TOTAL · 2026',
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 0.06 * 11,
                    fontWeight: FontWeight.w600,
                    color: context.palette.textTertiary,
                  ),
                ),
              ),
              DsTag(label: status, tone: statusTone),
            ],
          ),
          const SizedBox(height: AppSpacing.stepMd),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 30,
                  height: 36 / 30,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Text(
                  'of $target',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    color: context.palette.textTertiary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.stepMd),
          DsProgressBar(value: percent),
          const SizedBox(height: 10),
          DsCaption(note),
        ],
      ),
    );
  }
}

/// One four-month period: what was scored, whether it was met, and the prize
/// that went with it.
class TargetPeriodCard extends StatelessWidget {
  const TargetPeriodCard({
    super.key,
    required this.period,
    required this.score,
    required this.status,
    required this.statusTone,
    required this.prize,
    required this.note,
    this.percent,
  });

  final String period;
  final String score;
  final String status;
  final DsTone statusTone;
  final String prize;
  final String note;
  final double? percent;

  @override
  Widget build(BuildContext context) {
    return DsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      period,
                      style: context.texts.bodyLarge?.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      score,
                      style: TextStyle(
                        fontSize: 12,
                        color: context.palette.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              DsTag(label: status, tone: statusTone),
            ],
          ),
          if (percent != null) ...[
            const SizedBox(height: AppSpacing.stepMd),
            DsProgressBar(value: percent!),
          ],
          const SizedBox(height: AppSpacing.stepMd),
          Text(
            prize,
            style: context.texts.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          DsCaption(note),
        ],
      ),
    );
  }
}

/// Board 06 · B1 — View Target · in progress. Progress without promises: what
/// counts, what is left, and what the prize is if it is reached.
class TargetsInProgressScreen extends StatelessWidget {
  const TargetsInProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DsScreen(
      appBar: DsAppBar(
        title: 'View Targets',
        onBack: () => Navigator.of(context).maybePop(),
      ),
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      gap: AppSpacing.md,
      sections: [
        const _YearTotalCard(
          status: 'In progress',
          statusTone: DsTone.info,
          value: '686,900',
          target: '1,000,000',
          percent: 0.69,
          note: '313,100 points to go · 3 months and 21 days left in the year',
        ),
        Row(
          children: [
            Text(
              'FOUR-MONTH TARGETS',
              style: TextStyle(
                fontSize: 11,
                letterSpacing: 0.06 * 11,
                fontWeight: FontWeight.w600,
                color: context.palette.textTertiary,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            const DsTag(label: 'On paper'),
          ],
        ),
        const TargetPeriodCard(
          period: 'Jan — Apr 2026',
          score: '312,600 of 280,000 points',
          status: 'Achieved',
          statusTone: DsTone.success,
          prize: 'Won: 32-inch LED television · delivered 9 May',
          note: '32,600 points above target',
        ),
        const TargetPeriodCard(
          period: 'May — Aug 2026',
          score: '191,900 of 320,000 points',
          status: 'Not met',
          statusTone: DsTone.neutral,
          prize: 'Not won: Haier 1-ton inverter AC',
          note: '128,100 points short when the period closed',
        ),
        const TargetPeriodCard(
          period: 'Sep — Dec 2026',
          score: '182,400 of 400,000 points',
          status: 'Running',
          statusTone: DsTone.info,
          percent: 0.46,
          prize: 'Prize at target: Honda 125 motorcycle',
          note: '217,600 points to go · closes 31 December',
        ),
        DsCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'What counts toward your target',
                style: context.texts.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.stepMd),
              const _CountRow(
                label: 'From your own purchases',
                value: '141,900',
              ),
              const DsHairline(),
              const _CountRow(
                label: 'Transferred in by others',
                value: '44,800',
              ),
              const DsHairline(),
              const _CountRow(label: 'Reversals from SAP', value: '− 4,300'),
              const SizedBox(height: AppSpacing.stepMd),
              const DsCaption(
                'Points transferred in count the same as points from your own '
                'purchases — achievement is measured on points arriving in '
                'your account.',
              ),
            ],
          ),
        ),
        DsCard(
          tone: DsCardTone.accent,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    LucideIcons.trophy,
                    size: 18,
                    color: context.colors.primary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'Year total prize',
                    style: context.texts.bodyLarge?.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: context.colors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const DsBody(
                'Umrah package for two, as printed on your signed scheme. '
                'Awarded on reaching the 1,000,000 point year total — not won '
                'yet, and separate from the four-month prizes.',
              ),
            ],
          ),
        ),
        const DsCaption(
          'Points you send out reduce your balance and do not count toward '
          'your target. Schemes are signed on paper with your Crown Solar '
          'representative — this screen shows what you signed.',
        ),
      ],
    );
  }
}

class _CountRow extends StatelessWidget {
  const _CountRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: DsBody(label, size: 14)),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

/// Board 06 · B2 — Annual target passed, with no automatic reward: the extra
/// is recorded, and the next move is a conversation, not a claim button.
class TargetPassedScreen extends StatelessWidget {
  const TargetPassedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DsScreen(
      appBar: DsAppBar(
        title: 'View Targets',
        onBack: () => Navigator.of(context).maybePop(),
      ),
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      gap: AppSpacing.md,
      sections: [
        const _YearTotalCard(
          status: 'Met in August',
          statusTone: DsTone.success,
          value: '1,042,300',
          target: '1,000,000',
          percent: 1,
          note:
              '42,300 points above your year total, with the last four-month '
              'period still to run. The extra is recorded and visible to the '
              'Crown Solar team.',
        ),
        DsCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'What happens with the extra',
                style: context.texts.bodyLarge?.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              const DsBody(
                'Finishing your year early earns no automatic bonus, and there '
                'is nothing to claim here. Talk to the Crown Solar team about '
                'the extra — they decide what follows.',
              ),
              const SizedBox(height: AppSpacing.stepMd),
              DsButton(
                label: 'Chat with the Crown Solar Team',
                variant: DsButtonVariant.secondary,
                size: DsButtonSize.sm,
                icon: LucideIcons.messageCircle,
                onPressed: () {},
              ),
            ],
          ),
        ),
        const DsSectionHeader(title: 'Four-month period history'),
        const TargetPeriodCard(
          period: 'Jan — Apr 2026',
          score: '470,000 of 280,000 · LED television won',
          status: 'Achieved',
          statusTone: DsTone.success,
          prize: 'Won: 32-inch LED television',
          note: 'Delivered 9 May',
        ),
        const TargetPeriodCard(
          period: 'May — Aug 2026',
          score: '572,300 of 320,000 · Motorcycle won',
          status: 'Achieved',
          statusTone: DsTone.success,
          prize: 'Won: Honda 125 motorcycle',
          note: 'Delivered 2 September',
        ),
        const TargetPeriodCard(
          period: 'Sep — Dec 2026',
          score: 'Starts 1 September · 400,000',
          status: 'Not started',
          statusTone: DsTone.neutral,
          prize: 'Prize at target: to be confirmed on your scheme',
          note: 'Closes 31 December',
        ),
      ],
    );
  }
}

/// Board 06 · B3 — After the CRM conversation: a new target with its own
/// prize, running alongside the signed scheme.
class TargetAssignedScreen extends StatelessWidget {
  const TargetAssignedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DsScreen(
      appBar: DsAppBar(
        title: 'View Targets',
        onBack: () => Navigator.of(context).maybePop(),
      ),
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      gap: AppSpacing.md,
      sections: [
        const _YearTotalCard(
          status: 'Met in August',
          statusTone: DsTone.success,
          value: '1,042,300',
          target: '1,000,000',
          percent: 1,
          note:
              'You reached your year total in August, with the last four-month '
              'period still to run. Your Umrah package prize is confirmed.',
        ),
        DsCard(
          tone: DsCardTone.accent,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ASSIGNED BY CROWN SOLAR CRM',
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 0.06 * 11,
                  fontWeight: FontWeight.w600,
                  color: context.colors.primary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'New target · H2 2026',
                style: context.texts.bodyLarge?.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              const DsBody(
                'After your conversation with the team, they have set you a '
                'fresh target for the remaining months with its own points '
                'target and its own prize. It runs alongside your signed '
                'scheme and takes nothing away from it.',
              ),
            ],
          ),
        ),
        Text(
          'NEW TARGETS AND PRIZES',
          style: TextStyle(
            fontSize: 11,
            letterSpacing: 0.06 * 11,
            fontWeight: FontWeight.w600,
            color: context.palette.textTertiary,
          ),
        ),
        const TargetPeriodCard(
          period: 'Extra · Jul — Aug 2026',
          score: '186,400 of 150,000 points',
          status: 'Achieved',
          statusTone: DsTone.success,
          prize: 'Won: Gold coin, 1 tola · delivered 12 September',
          note: '36,400 points above target',
        ),
        const TargetPeriodCard(
          period: 'Extra · Sep — Dec 2026',
          score: '182,400 of 300,000 points',
          status: 'Running',
          statusTone: DsTone.info,
          percent: 0.61,
          prize: 'Prize at target: 32-inch LED television',
          note: '117,600 points to go · closes 31 December',
        ),
        const TargetPeriodCard(
          period: 'Stretch · Jul — Dec 2026',
          score: '368,800 of 500,000 points',
          status: 'Running',
          statusTone: DsTone.info,
          percent: 0.74,
          prize: 'Prize at target: Foreign tour for two',
          note: '131,200 points to go · runs across both extra periods',
        ),
        const DsCaption(
          'Same measurement as your normal target — points arriving in your '
          'account, whether from your own purchases or transferred in.',
        ),
        const DsCaption(
          'What follows the conversation — a new target, a different prize, or '
          'nothing at all — is decided by Crown Solar per user. There is '
          'nothing to accept here; if it appears, it is already yours to work '
          'toward.',
        ),
      ],
    );
  }
}

/// Board 06 · B4 — No scheme signed: what still works, and what a scheme
/// would unlock.
class NoSchemeScreen extends StatelessWidget {
  const NoSchemeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DsScreen(
      appBar: DsAppBar(
        title: 'View Targets',
        onBack: () => Navigator.of(context).maybePop(),
      ),
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      gap: AppSpacing.md,
      sections: [
        DsCard(
          radius: AppRadii.heroRadius,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
          child: Column(
            children: [
              const DsIconMedallion(
                icon: LucideIcons.fileSignature,
                tone: DsTone.neutral,
                size: 64,
                iconSize: 30,
              ),
              const SizedBox(height: 14),
              Text(
                'You have no scheme yet',
                textAlign: TextAlign.center,
                style: context.texts.titleLarge,
              ),
              const SizedBox(height: 14),
              const DsBody(
                'Targets appear here once you sign a scheme with your Crown '
                'Solar representative. Signing is done on paper.',
                size: 14,
                align: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              DsButton(
                label: 'Ask About Signing a Scheme',
                icon: LucideIcons.messageCircle,
                onPressed: () {},
              ),
            ],
          ),
        ),
        DsCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your points still work normally',
                style: context.texts.bodyLarge?.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              const DsBody(
                'You can send and receive points as your role allows. Nothing '
                'is measured against you because you hold no target.',
              ),
            ],
          ),
        ),
        DsCard(
          tone: DsCardTone.sunken,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Without a scheme',
                style: context.texts.bodyLarge?.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              const DsBody(
                'Shop Branding is limited: Frontlit and Backlit boards, and '
                'the points-based options, all need a signed scheme. '
                'Complaints, ledger, cash and chat are unaffected.',
              ),
            ],
          ),
        ),
      ],
    );
  }
}
