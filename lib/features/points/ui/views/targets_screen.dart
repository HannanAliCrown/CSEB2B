import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../../core/ui/ds.dart';
import '../../../session/ui/session_controller.dart';
import '../../data/points_service.dart';

/// Board 06 · B1–B4 — View Targets.
///
/// One screen with four faces, chosen by what the data says: no scheme
/// signed, a year in progress, a year already met, and a year met with extra
/// targets Crown Solar set afterwards. Nothing here is a claim button —
/// what follows an early finish is a conversation.
class TargetsScreen extends StatefulWidget {
  const TargetsScreen({super.key, required this.onChatWithTeam});

  final VoidCallback onChatWithTeam;

  @override
  State<TargetsScreen> createState() => _TargetsScreenState();
}

class _TargetsScreenState extends State<TargetsScreen> {
  PointTargets? _targets;
  bool _reachable = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final user = context.read<SessionController>().user;
    if (user == null) return;
    final loaded = await context.read<PointsService>().targets(
      user.mobileNumber,
    );
    if (!mounted) return;
    setState(() {
      _targets = loaded ?? PointTargets.empty;
      _reachable = loaded != null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final targets = _targets;

    if (targets == null) {
      return Scaffold(
        appBar: DsAppBar(
          title: 'View Targets',
          onBack: () => Navigator.of(context).maybePop(),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return DsScreen(
      appBar: DsAppBar(
        title: 'View Targets',
        onBack: () => Navigator.of(context).maybePop(),
      ),
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      gap: AppSpacing.md,
      sections: targets.hasScheme
          ? _withScheme(targets)
          : _withoutScheme(targets),
    );
  }

  // --- B4 · no scheme signed ------------------------------------------------

  List<Widget> _withoutScheme(PointTargets targets) => [
    if (!_reachable)
      const DsEmptyState(
        icon: LucideIcons.cloudOff,
        title: 'Could not reach Crown Solar',
        message:
            'Your targets are held by Crown Solar, not on this phone. Check '
            'your connection and try again.',
      )
    else ...[
      DsCard(
        radius: AppRadii.heroRadius,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
        child: Column(
          children: [
            const DsIconMedallion(
              icon: LucideIcons.fileSignature,
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
              onPressed: widget.onChatWithTeam,
            ),
          ],
        ),
      ),
      _Explainer(
        title: 'Your points still work normally',
        body:
            'You can send and receive points as your role allows. Nothing is '
            'measured against you because you hold no target.',
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
              'Shop Branding is limited: Frontlit and Backlit boards, and the '
              'points-based options, all need a signed scheme. Complaints, '
              'ledger, cash and chat are unaffected.',
            ),
          ],
        ),
      ),
      // Extras are assigned per partner and can exist without a scheme, so
      // they are never hidden behind one.
      if (targets.extras.isNotEmpty) ..._extraSection(targets),
    ],
  ];

  // --- B1 · B2 · B3 ---------------------------------------------------------

  List<Widget> _withScheme(PointTargets targets) {
    final annual = targets.annual!;
    final met = annual.met;

    return [
      _YearTotalCard(annual: annual),

      // B2 — the year is done early. There is nothing to claim, so what is
      // offered is the conversation rather than a button that pretends to
      // award something.
      if (met && targets.extras.isEmpty)
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
                'Finishing your year early earns no automatic bonus, and '
                'there is nothing to claim here. Talk to the Crown Solar team '
                'about the extra — they decide what follows.',
              ),
              const SizedBox(height: AppSpacing.stepMd),
              DsButton(
                label: 'Chat with the Crown Solar Team',
                variant: DsButtonVariant.secondary,
                size: DsButtonSize.sm,
                icon: LucideIcons.messageCircle,
                onPressed: widget.onChatWithTeam,
              ),
            ],
          ),
        ),

      // B3 — the conversation has happened and the team set fresh targets.
      if (targets.extras.isNotEmpty) ...[
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
                'New targets set for you',
                style: context.texts.bodyLarge?.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              const DsBody(
                'After your conversation with the team, they have set you '
                'fresh targets with their own points targets and their own '
                'prizes. They run alongside your signed scheme and take '
                'nothing away from it.',
              ),
            ],
          ),
        ),
        ..._extraSection(targets),
      ],

      Row(
        children: [
          _Eyebrow('FOUR-MONTH TARGETS'),
          const SizedBox(width: AppSpacing.sm),
          const DsTag(label: 'On paper'),
        ],
      ),
      for (final period in targets.periods) TargetPeriodCard(target: period),

      // Only worth showing while a period is open: a breakdown of a window
      // nobody is in any more is a history lesson, not a nudge.
      if (targets.runningPeriod != null) _breakdownCard(targets),

      if (targets.annualPrize != null)
        _PrizeCard(
          title: 'Year total prize',
          body:
              '${targets.annualPrize}, as printed on your signed scheme. '
              'Awarded on reaching the '
              '${formatPoints(annual.targetPoints)} point year total'
              '${met ? ' — reached in ${formatPointsMonth(annual.metOn!)}.' : ' — not won yet, and separate from the four-month prizes.'}',
        ),

      if (targets.grandPrize != null)
        _PrizeCard(
          icon: LucideIcons.medal,
          title: 'Grand prize',
          body:
              '${targets.grandPrize}. Awarded only if every four-month target '
              'is hit, and separate from the year total prize.',
        ),

      const DsCaption(
        'Points you send out reduce your balance and do not count toward '
        'your target. Schemes are signed on paper with your Crown Solar '
        'representative — this screen shows what you signed.',
      ),
    ];
  }

  List<Widget> _extraSection(PointTargets targets) => [
    _Eyebrow('NEW TARGETS AND PRIZES'),
    for (final extra in targets.extras) TargetPeriodCard(target: extra),
    const DsCaption(
      'Same measurement as your normal target — points arriving in your '
      'account, whether from your own purchases or transferred in.',
    ),
    const DsCaption(
      'What follows the conversation — a new target, a different prize, or '
      'nothing at all — is decided by Crown Solar per user. There is nothing '
      'to accept here; if it appears, it is already yours to work toward.',
    ),
  ];

  Widget _breakdownCard(PointTargets targets) {
    final breakdown = targets.breakdown;
    return DsCard(
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
          _CountRow(
            label: 'From your own purchases',
            value: formatPoints(breakdown.purchases),
          ),
          const DsHairline(),
          _CountRow(
            label: 'Transferred in by others',
            value: formatPoints(breakdown.transferredIn),
          ),
          const DsHairline(),
          _CountRow(
            label: 'Reversals from SAP',
            value: breakdown.reversals == 0
                ? '0'
                : '− ${formatPoints(breakdown.reversals)}',
          ),
          const SizedBox(height: AppSpacing.stepMd),
          const DsCaption(
            'Points transferred in count the same as points from your own '
            'purchases — achievement is measured on points arriving in your '
            'account.',
          ),
        ],
      ),
    );
  }
}

/// The year-total header every target screen opens with.
class _YearTotalCard extends StatelessWidget {
  const _YearTotalCard({required this.annual});

  final PointTarget annual;

  @override
  Widget build(BuildContext context) {
    final met = annual.met;
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
                  'YEAR TOTAL · ${annual.startsOn.year}',
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 0.06 * 11,
                    fontWeight: FontWeight.w600,
                    color: context.palette.textTertiary,
                  ),
                ),
              ),
              DsTag(
                label: met
                    ? 'Met in ${formatPointsMonth(annual.metOn!)}'
                    : 'In progress',
                tone: met ? DsTone.success : DsTone.info,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.stepMd),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                formatPoints(annual.scoredPoints),
                style: const TextStyle(
                  fontSize: 30,
                  height: 36 / 30,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Text(
                  'of ${formatPoints(annual.targetPoints)}',
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
          DsProgressBar(value: annual.percent),
          const SizedBox(height: 10),
          DsCaption(
            met
                ? '${formatPoints(annual.scoredPoints - annual.targetPoints)} '
                      'points above your year total. The extra is recorded '
                      'and visible to the Crown Solar team.'
                : '${formatPoints(annual.toGo)} points to go · '
                      '${formatTimeLeft(annual.endsOn)} left in the year',
          ),
        ],
      ),
    );
  }
}

/// One target period: what was scored, whether it was met, and its prize.
class TargetPeriodCard extends StatelessWidget {
  const TargetPeriodCard({super.key, required this.target});

  final PointTarget target;

  @override
  Widget build(BuildContext context) {
    final status = target.status;
    final closed =
        status == TargetStatus.achieved || status == TargetStatus.notMet;

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
                      target.label,
                      style: context.texts.bodyLarge?.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      status == TargetStatus.notStarted
                          ? 'Starts ${formatPointsDate(target.startsOn)} · '
                                '${formatPoints(target.targetPoints)}'
                          : '${formatPoints(target.scoredPoints)} of '
                                '${formatPoints(target.targetPoints)} points',
                      style: TextStyle(
                        fontSize: 12,
                        color: context.palette.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              DsTag(
                label: status.label,
                tone: switch (status) {
                  TargetStatus.achieved => DsTone.success,
                  TargetStatus.running => DsTone.info,
                  TargetStatus.notMet ||
                  TargetStatus.notStarted => DsTone.neutral,
                },
              ),
            ],
          ),
          // A bar only where there is still something to move. A closed
          // period's bar would invite a partner to push a number that can no
          // longer change.
          if (status == TargetStatus.running) ...[
            const SizedBox(height: AppSpacing.stepMd),
            DsProgressBar(value: target.percent),
          ],
          const SizedBox(height: AppSpacing.stepMd),
          Text(
            _prizeLine(status),
            style: context.texts.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          DsCaption(_note(status, closed)),
        ],
      ),
    );
  }

  String _prizeLine(TargetStatus status) {
    final prize = target.prize;
    if (prize == null) return 'No prize is printed for this period.';
    return switch (status) {
      TargetStatus.achieved => 'Won: $prize',
      TargetStatus.notMet => 'Not won: $prize',
      _ => 'Prize at target: $prize',
    };
  }

  String _note(TargetStatus status, bool closed) => switch (status) {
    TargetStatus.achieved =>
      '${formatPoints(target.scoredPoints - target.targetPoints)} points '
          'above target',
    TargetStatus.notMet =>
      '${formatPoints(target.targetPoints - target.scoredPoints)} points '
          'short when the period closed',
    TargetStatus.notStarted => 'Closes ${formatPointsDate(target.endsOn)}',
    TargetStatus.running =>
      '${formatPoints(target.toGo)} points to go · closes '
          '${formatPointsDate(target.endsOn)}',
  };
}

class _Eyebrow extends StatelessWidget {
  const _Eyebrow(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: TextStyle(
      fontSize: 11,
      letterSpacing: 0.06 * 11,
      fontWeight: FontWeight.w600,
      color: context.palette.textTertiary,
    ),
  );
}

class _PrizeCard extends StatelessWidget {
  const _PrizeCard({
    required this.title,
    required this.body,
    this.icon = LucideIcons.trophy,
  });

  final String title;
  final String body;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return DsCard(
      tone: DsCardTone.accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: context.colors.primary),
              const SizedBox(width: AppSpacing.sm),
              Text(
                title,
                style: context.texts.bodyLarge?.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: context.colors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          DsBody(body),
        ],
      ),
    );
  }
}

class _Explainer extends StatelessWidget {
  const _Explainer({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return DsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: context.texts.bodyLarge?.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          DsBody(body),
        ],
      ),
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
