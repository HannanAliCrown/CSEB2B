import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../../core/ui/ds.dart';
import '../../../session/ui/session_controller.dart';
import '../../data/points_service.dart';

/// Board 06 · A1 — the Points hub.
///
/// Balance, the two live meters, and the ledger. Points and currency are
/// never mixed into one figure on this screen or anywhere else: the wallet
/// is a different ledger with a different unit.
class PointsTab extends StatefulWidget {
  const PointsTab({
    super.key,
    required this.onSendPoints,
    required this.onViewTargets,
    required this.onSeeAllEntries,
  });

  /// Each returns once the partner comes back, so the hub reloads rather
  /// than showing a balance from before they sent anything.
  final Future<void> Function() onSendPoints;
  final Future<void> Function() onViewTargets;
  final Future<void> Function() onSeeAllEntries;

  @override
  State<PointsTab> createState() => _PointsTabState();
}

class _PointsTabState extends State<PointsTab> {
  PointsLedger? _ledger;
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
    final service = context.read<PointsService>();

    final ledger = await service.ledger(user.mobileNumber);
    final targets = await service.targets(user.mobileNumber);
    if (!mounted) return;
    setState(() {
      _ledger = ledger ?? PointsLedger.empty;
      _targets = targets ?? PointTargets.empty;
      _reachable = ledger != null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ledger = _ledger;
    final targets = _targets;

    return Scaffold(
      appBar: const DsAppBar(title: 'Points'),
      body: ledger == null || targets == null
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              bottom: false,
              child: RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.screenPadding),
                  children: _sections(ledger, targets),
                ),
              ),
            ),
    );
  }

  List<Widget> _sections(PointsLedger ledger, PointTargets targets) {
    // The five most recent lines. "See all" opens the rest, so the hub stays
    // a summary rather than a second ledger screen.
    final recent = ledger.entries.take(5).toList();
    final period = targets.runningPeriod;
    final annual = targets.annual;

    return [
      _BalanceCard(
        balance: ledger.balance,
        canSend: ledger.canSend,
        onSendPoints: () async {
          await widget.onSendPoints();
          await _load();
        },
        onViewTargets: () async {
          await widget.onViewTargets();
          await _load();
        },
      ),
      if (!_reachable) ...[
        const SizedBox(height: AppSpacing.md),
        const DsNotice(
          icon: LucideIcons.cloudOff,
          tone: DsTone.warning,
          message:
              'Could not reach Crown Solar, so this is not your balance. '
              'Pull down to try again.',
        ),
      ],
      // Only what the partner is actually measured against. Without a signed
      // scheme there are no meters at all, rather than empty ones.
      if (period != null) ...[
        const SizedBox(height: AppSpacing.md),
        TargetMeter(
          label:
              '${_withoutYear(period.label)} target · '
              '${formatPoints(period.targetPoints)}',
          percent: period.percent,
          note: period.prize == null
              ? '${formatPoints(period.toGo)} points to go'
              : '${formatPoints(period.toGo)} points to go · prize at target '
                    'is ${period.prize}',
        ),
      ],
      if (annual != null) ...[
        const SizedBox(height: AppSpacing.stepMd),
        TargetMeter(
          label: 'Year total · ${formatPoints(annual.targetPoints)}',
          percent: annual.percent,
          note:
              '${formatPoints(annual.scoredPoints)} of '
              '${formatPoints(annual.targetPoints)} for ${annual.startsOn.year}'
              ' · ${formatPoints(annual.toGo)} to go',
        ),
      ],
      const SizedBox(height: AppSpacing.lg),
      DsSectionHeader(
        title: 'Points ledger',
        actionLabel: ledger.entries.length > recent.length ? 'See all' : null,
        onAction: ledger.entries.length > recent.length
            ? () async {
                await widget.onSeeAllEntries();
                await _load();
              }
            : null,
      ),
      if (recent.isEmpty)
        const DsEmptyState(
          icon: LucideIcons.award,
          title: 'No points yet',
          message:
              'Points arrive from SAP when a purchase is posted, and from '
              'partners who send you some.',
        )
      else
        DsCard(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Column(
            children: [
              for (var i = 0; i < recent.length; i++) ...[
                PointsLedgerRow(entry: recent[i]),
                if (i != recent.length - 1) const DsHairline(),
              ],
            ],
          ),
        ),
    ];
  }

  /// 'Sep — Dec 2026' reads as 'Sep — Dec' on the meter, where the year is
  /// already stated by the one below it.
  static String _withoutYear(String label) =>
      label.replaceAll(RegExp(r'\s+\d{4}$'), '');
}

/// The navy hero card: the balance and the two actions.
class _BalanceCard extends StatelessWidget {
  const _BalanceCard({
    required this.balance,
    required this.canSend,
    required this.onSendPoints,
    required this.onViewTargets,
  });

  final int balance;
  final bool canSend;
  final VoidCallback onSendPoints;
  final VoidCallback onViewTargets;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.stepLg),
      decoration: BoxDecoration(
        color: context.colors.primary,
        borderRadius: AppRadii.heroRadius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'POINTS BALANCE',
            style: TextStyle(
              fontSize: 12,
              letterSpacing: 0.06 * 12,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.75),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            formatPoints(balance),
            style: const TextStyle(
              fontSize: 34,
              height: 40 / 34,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _PointsAction(
                  label: 'Send Points',
                  // Dimmed rather than hidden: a restricted partner should
                  // see that sending exists and is not available to them.
                  enabled: canSend,
                  onTap: onSendPoints,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _PointsAction(
                  label: 'View Targets',
                  onTap: onViewTargets,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PointsAction extends StatelessWidget {
  const _PointsAction({
    required this.label,
    required this.onTap,
    this.enabled = true,
  });

  final String label;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: enabled ? 0.16 : 0.07),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: enabled ? 1 : 0.5),
            ),
          ),
        ),
      ),
    );
  }
}

/// A target meter: label, percentage, bar and the plain-words gap to go.
class TargetMeter extends StatelessWidget {
  const TargetMeter({
    super.key,
    required this.label,
    required this.percent,
    required this.note,
  });

  final String label;
  final double percent;
  final String note;

  @override
  Widget build(BuildContext context) {
    return DsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: context.texts.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '${(percent * 100).round()}%',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: context.colors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          DsProgressBar(value: percent),
          const SizedBox(height: 10),
          DsCaption(note),
        ],
      ),
    );
  }
}

/// One line of the points ledger.
class PointsLedgerRow extends StatelessWidget {
  const PointsLedgerRow({super.key, required this.entry});

  final PointEntry entry;

  @override
  Widget build(BuildContext context) {
    final clause = entry.clause;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 13),
      child: Row(
        children: [
          DsIconMedallion(
            icon: entry.credit
                ? LucideIcons.arrowDownLeft
                : LucideIcons.arrowUpRight,
            tone: entry.credit ? DsTone.success : DsTone.neutral,
            size: 36,
            iconSize: 17,
            rounded: true,
          ),
          const SizedBox(width: AppSpacing.stepMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  entry.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  [formatPointsWhen(entry.postedAt), ?clause].join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    height: 15 / 11,
                    color: context.palette.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                entry.signedAmount,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: entry.credit
                      ? context.status.success
                      : context.colors.onSurface,
                ),
              ),
              Text(
                formatPoints(entry.balanceAfter),
                style: TextStyle(
                  fontSize: 11,
                  color: context.palette.textTertiary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
