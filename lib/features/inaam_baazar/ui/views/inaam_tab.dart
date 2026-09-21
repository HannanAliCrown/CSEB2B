import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../../core/ui/ds.dart';
import '../../../session/ui/session_controller.dart';
import '../../../wallet/data/wallet_repository.dart';
import '../../data/inaam_service.dart';
import 'scheme_screens.dart' show TierRow;
import 'spin_screens.dart' show SpinWheel;

/// Board 09 — Inaam Baazar.
///
/// Three ways Crown Solar rewards an installer for scanning, behind one
/// segmented control. Every prize lands in the cash wallet; Inaam has no
/// balance of its own, and none is shown here.
class InaamTab extends StatefulWidget {
  const InaamTab({super.key, required this.onOpenScanner});

  final VoidCallback onOpenScanner;

  @override
  State<InaamTab> createState() => _InaamTabState();
}

class _InaamTabState extends State<InaamTab> {
  static const _spin = 'Spin and Win';
  static const _reward = 'Reward Program';
  static const _item = 'Item Scheme';

  String _tab = _spin;

  SpinState? _spinState;
  RewardProgram? _program;
  List<ItemScheme>? _schemes;
  bool _reachable = true;
  bool _busy = false;

  /// How many spins the history card shows before "See all".
  static const _historyPreview = 3;
  bool _allHistory = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final user = context.read<SessionController>().user;
    if (user == null) return;
    final service = context.read<InaamService>();

    final spin = await service.spinState(user.mobileNumber);
    final program = await service.rewardProgram(user.mobileNumber);
    final schemes = await service.itemSchemes(user.mobileNumber);
    if (!mounted) return;
    setState(() {
      _spinState = spin ?? SpinState.empty;
      _program = program ?? RewardProgram.empty;
      _schemes = schemes ?? const [];
      _reachable = spin != null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final spin = _spinState;
    if (spin == null) {
      return Scaffold(
        appBar: const DsAppBar(title: 'Inaam Baazar'),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: const DsAppBar(title: 'Inaam Baazar'),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            children: [
              DsSegmentedControl(
                options: const [_spin, _reward, _item],
                value: _tab,
                onChanged: (tab) => setState(() => _tab = tab),
              ),
              const SizedBox(height: AppSpacing.md),
              if (!_reachable)
                const DsNotice(
                  icon: LucideIcons.cloudOff,
                  tone: DsTone.warning,
                  message:
                      'Could not reach Crown Solar, so nothing here is your '
                      'real position. Pull down to try again.',
                )
              else
                ...switch (_tab) {
                  _reward => _rewardSection(),
                  _item => _itemSection(),
                  _ => _spinSection(spin),
                },
            ],
          ),
        ),
      ),
    );
  }

  // --- A1 · Spin and Win ----------------------------------------------------

  List<Widget> _spinSection(SpinState spin) {
    if (!spin.configured) {
      return const [
        DsEmptyState(
          icon: LucideIcons.sparkles,
          title: 'Spin and Win is not set up',
          message:
              'Crown Solar has not configured the wheel yet. Nothing is owed '
              'to you in the meantime.',
        ),
      ];
    }

    return [
      DsCard(
        tone: DsCardTone.accent,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'SPINS AVAILABLE',
                    style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 0.06 * 11,
                      fontWeight: FontWeight.w600,
                      color: context.colors.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '${spin.spinsAvailable}',
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w600,
                          color: context.colors.primary,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Flexible(
                        child: DsBody(
                          spin.spinsAvailable == 1
                              ? 'spin ready to use'
                              : 'spins ready to use',
                          size: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const DsTag(label: 'Today', tone: DsTone.accent),
          ],
        ),
      ),
      const SizedBox(height: AppSpacing.stepMd),
      DsCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Scans today',
                    style: context.texts.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                DsCaption(
                  '${spin.scansToday} of '
                  '${spin.scansToday + spin.scansToNextSpin} for the next spin',
                ),
              ],
            ),
            const SizedBox(height: 10),
            DsProgressBar(value: spin.progress),
            const SizedBox(height: 10),
            DsCaption(
              '${spin.scansToNextSpin} more '
              '${spin.scansToNextSpin == 1 ? 'scan' : 'scans'} earns another '
              'spin. There is no limit on how many you can earn in a day.',
            ),
          ],
        ),
      ),
      const SizedBox(height: AppSpacing.lg),
      Center(
        child: SpinWheel(
          values: [for (final prize in spin.segments) prize.formatted],
        ),
      ),
      const SizedBox(height: AppSpacing.md),
      DsCaption(
        spin.segments.isEmpty
            ? 'Prizes are credited to your wallet.'
            : 'Prizes range from Rs. ${spin.segments.first.formatted} to '
                  'Rs. ${_largest(spin.segments).formatted} and are credited '
                  'to your wallet.',
        align: TextAlign.center,
      ),
      const SizedBox(height: AppSpacing.md),
      if (spin.spinsAvailable > 0)
        DsButton(
          label: 'Spin Now',
          icon: LucideIcons.sparkles,
          loading: _busy,
          disabled: _busy,
          onPressed: _takeSpin,
        )
      else
        DsCard(
          padding: EdgeInsets.zero,
          child: DsEmptyState(
            icon: LucideIcons.sparkles,
            title: 'No Spins Right Now',
            message:
                'You have ${spin.scansToday} '
                '${spin.scansToday == 1 ? 'scan' : 'scans'} today. Reach '
                '${spin.scansToday + spin.scansToNextSpin} scans in one day to '
                'earn a spin.',
            actionLabel: 'Open Scanner',
            onAction: widget.onOpenScanner,
          ),
        ),
      const SizedBox(height: AppSpacing.lg),
      DsSectionHeader(
        title: 'Spin history',
        // "See all" opens nothing: the rest of the history is already here,
        // just folded. A control that led to a screen which does not exist
        // would be worse than none.
        actionLabel: spin.history.length > _historyPreview && !_allHistory
            ? 'See all'
            : null,
        onAction: () => setState(() => _allHistory = true),
      ),
      if (spin.history.isEmpty)
        const DsCaption('Your spins will be listed here once you take one.')
      else
        DsCard(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Column(
            children: [
              for (var i = 0; i < _visibleHistory(spin).length; i++) ...[
                DsSettingRow(
                  label: 'Rs. ${_visibleHistory(spin)[i].amount.formatted}',
                  meta: formatSpinWhen(_visibleHistory(spin)[i].spunAt),
                  leading: const DsIconMedallion(
                    icon: LucideIcons.sparkles,
                    tone: DsTone.solar,
                    size: 34,
                    iconSize: 16,
                  ),
                  trailing: const DsTag(
                    label: 'Credited',
                    tone: DsTone.success,
                  ),
                ),
                if (i != _visibleHistory(spin).length - 1) const DsHairline(),
              ],
            ],
          ),
        ),
    ];
  }

  /// Three, as the design draws it, until "See all" is pressed.
  List<Spin> _visibleHistory(SpinState spin) =>
      _allHistory || spin.history.length <= _historyPreview
      ? spin.history
      : spin.history.take(_historyPreview).toList();

  static Money _largest(List<Money> prizes) {
    var best = prizes.first;
    for (final prize in prizes) {
      if (prize.compareTo(best) > 0) best = prize;
    }
    return best;
  }

  Future<void> _takeSpin() async {
    final user = context.read<SessionController>().user;
    if (user == null) return;

    setState(() => _busy = true);
    final (spin, failure) = await context.read<InaamService>().spin(
      user.mobileNumber,
    );
    if (!mounted) return;
    setState(() => _busy = false);

    if (failure != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(failure.message)));
      await _load();
      return;
    }

    // A prize won and a prize paid are the same event: the server credited
    // the wallet in the same transaction, so Home is told to reload rather
    // than sitting on a balance that is already wrong.
    context.read<WalletRepository>().announceChange();
    await _load();
    if (!mounted) return;
    await _showResult(spin!);
  }

  /// Board 09 · A2 — the prize revealed and credited in the same breath.
  Future<void> _showResult(Spin spin) => showDialog<void>(
    context: context,
    barrierColor: const Color(0xFF0F172A).withValues(alpha: 0.45),
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.all(AppSpacing.lg),
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.stepLg),
          decoration: BoxDecoration(
            color: context.status.successFill,
            borderRadius: AppRadii.heroRadius,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SpinWheel(size: 200),
              const SizedBox(height: AppSpacing.md),
              Text(
                'YOU WON',
                style: TextStyle(
                  fontSize: 12,
                  letterSpacing: 0.06 * 12,
                  fontWeight: FontWeight.w600,
                  color: context.status.success,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Rs. ${spin.amount.formatted}',
                style: TextStyle(
                  fontSize: 38,
                  height: 44 / 38,
                  fontWeight: FontWeight.w600,
                  color: context.status.success,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              DsBody(
                'Rs. ${spin.amount.formatted} added to your wallet. '
                'Ref ${spin.reference} · ${formatSpinWhen(spin.spunAt)}',
                align: TextAlign.center,
                color: context.status.success,
              ),
              const SizedBox(height: AppSpacing.md),
              DsButton(
                label: 'Done',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  // --- A4 · Reward Program --------------------------------------------------

  List<Widget> _rewardSection() {
    final program = _program!;

    return [
      // What last month earned, and how long it runs. Shown first because it
      // is the thing paying out right now.
      if (program.hasAward)
        DsCard(
          tone: DsCardTone.accent,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      // The month named here is the one that earned the
                      // bonus, not the one it runs in.
                      program.awardEarnedOn == null
                          ? 'Active Rewards'
                          : 'Active Rewards · '
                                '${formatInaamMonth(program.awardEarnedOn!)}',
                      style: context.texts.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  DsTag(
                    label:
                        '${_titled(program.awardTierName!)} Inaam '
                        '+${program.awardBonusPercent}%',
                    tone: DsTone.accent,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.stepMd),
              Row(
                children: [
                  Expanded(
                    child: _MetaCell(
                      label: 'REMAINING',
                      value: '${program.daysRemaining} days',
                    ),
                  ),
                  Expanded(
                    child: _MetaCell(
                      label: 'END DATE',
                      value: formatInaamDate(program.awardAppliesUntil!),
                    ),
                  ),
                ],
              ),
            ],
          ),
        )
      else
        const DsNotice(
          icon: LucideIcons.info,
          message:
              'You have no bonus running. Reach a tier this month and the '
              'bonus applies to next month\'s scans.',
        ),
      const SizedBox(height: AppSpacing.md),

      if (!program.running)
        const DsEmptyState(
          icon: LucideIcons.calendarClock,
          title: 'No programme this month',
          message:
              'Crown Solar creates each month\'s programme at the end of the '
              'one before. It will appear here when it does.',
        )
      else ...[
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
              DsCaption(
                'Target · ${formatInaamMonth(program.startsOn!)} · in progress',
              ),
              const SizedBox(height: AppSpacing.stepMd),
              Row(
                children: [
                  Expanded(
                    child: _MetaCell(
                      label: 'START DATE',
                      value: formatInaamDate(program.startsOn!),
                    ),
                  ),
                  Expanded(
                    child: _MetaCell(
                      label: 'END DATE',
                      value: formatInaamDate(program.endsOn!),
                    ),
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
                  Text(
                    '${program.scans} '
                    '${program.scans == 1 ? 'scan' : 'scans'}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              DsProgressBar(value: program.percent),
              const SizedBox(height: 10),
              DsCaption(
                program.next == null
                    ? 'You have reached every tier this month.'
                    : '${program.next!.scanTarget - program.scans} more scans '
                          'to unlock ${_titled(program.next!.name)} and get '
                          '+${program.next!.bonusPercent}% bonus',
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        DsCard(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Column(
            children: [
              for (var i = 0; i < program.tiers.length; i++) ...[
                TierRow(
                  name: program.tiers[i].name,
                  requirement: '${program.tiers[i].scanTarget} scans',
                  reward: '+${program.tiers[i].bonusPercent}%',
                  status: program.scans >= program.tiers[i].scanTarget
                      ? 'Reached'
                      : '${program.tiers[i].scanTarget - program.scans} to go',
                  statusTone: program.scans >= program.tiers[i].scanTarget
                      ? DsTone.success
                      : program.next?.name == program.tiers[i].name
                      ? DsTone.info
                      : DsTone.neutral,
                ),
                if (i != program.tiers.length - 1) const DsHairline(),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        const DsCaption(
          'Reaching a tier marks it complete but there is nothing to claim '
          'here. At month end the highest tier you reached is awarded, and it '
          "becomes the extra you earn on every scheme-product scan next month.",
        ),
      ],
    ];
  }

  // --- B1 · B2 · B4 · Item Scheme -------------------------------------------

  List<Widget> _itemSection() {
    final schemes = _schemes!;
    if (schemes.isEmpty) {
      return const [
        DsEmptyState(
          icon: LucideIcons.medal,
          title: 'No schemes running',
          message:
              'Crown Solar sets these up with their own products, targets and '
              'end dates. One will appear here when it does.',
        ),
      ];
    }

    return [
      for (final scheme in schemes) ...[
        // The design draws one scheme, so its card carries no name. Crown
        // Solar can run several, and then each needs saying which it is —
        // above the card rather than inside it, so the card is unchanged.
        // The end date is not here but in the card's note below: a scheme
        // name and a date share this row badly, and the name truncating is
        // the worse of the two.
        if (schemes.length > 1) DsSectionHeader(title: scheme.name),
        if (scheme.claimed)
          ..._claimedScheme(scheme)
        else
          ..._openScheme(scheme),
        const SizedBox(height: AppSpacing.lg),
      ],
    ];
  }

  List<Widget> _openScheme(ItemScheme scheme) {
    final claimable = scheme.claimable;

    return [
      DsCard(
        radius: AppRadii.heroRadius,
        padding: const EdgeInsets.all(AppSpacing.stepLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              scheme.byScans ? 'MEASURED ON SCANS' : 'MEASURED ON AMOUNT',
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
                if (!scheme.byScans) ...[
                  Text(
                    'PKR',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: context.palette.textTertiary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                ],
                Text(
                  scheme.byScans
                      ? '${scheme.progress}'
                      : Money(scheme.progress).formatted,
                  style: const TextStyle(
                    fontSize: 34,
                    height: 40 / 34,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (scheme.byScans) ...[
                  const SizedBox(width: AppSpacing.sm),
                  const DsBody('scans so far', size: 14),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.stepMd),
            DsProgressBar(value: scheme.percent),
            const SizedBox(height: 10),
            DsCaption(_schemeNote(scheme)),
          ],
        ),
      ),
      // Stated before the button is ever pressed, not after — and naming the
      // tiers it would close, because "the rest" is not a number a partner
      // can weigh.
      if (claimable != null) ...[
        const SizedBox(height: AppSpacing.md),
        DsNotice(
          icon: LucideIcons.triangleAlert,
          tone: DsTone.warning,
          message:
              'You can claim one tier only. Taking ${claimable.name} now '
              'closes ${_closingNames(scheme, claimable)} for good, even if '
              'you reach their targets later.',
        ),
      ],
      const SizedBox(height: AppSpacing.md),
      DsCard(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: Column(
          children: [
            for (var i = 0; i < scheme.tiers.length; i++) ...[
              TierRow(
                name: scheme.tiers[i].name,
                requirement: _tierRequirement(scheme, scheme.tiers[i]),
                reward: 'Rs. ${scheme.tiers[i].reward.formatted}',
                status: scheme.tiers[i].id == claimable?.id
                    ? 'Claim now'
                    : scheme.tiers[i].reached
                    ? 'Reached'
                    : 'Locked',
                statusTone: scheme.tiers[i].reached
                    ? DsTone.success
                    : DsTone.neutral,
                closed: !scheme.tiers[i].reached,
              ),
              if (i != scheme.tiers.length - 1) const DsHairline(),
            ],
          ],
        ),
      ),
      if (claimable != null) ...[
        const SizedBox(height: AppSpacing.md),
        DsButton(
          label: 'Claim ${claimable.name} · Rs. ${claimable.reward.formatted}',
          loading: _busy,
          disabled: _busy,
          onPressed: () => _confirmClaim(scheme, claimable),
        ),
      ],
    ];
  }

  /// Board 09 · B4 — claimed, with the other tiers closed.
  List<Widget> _claimedScheme(ItemScheme scheme) => [
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
            '${scheme.claimedTierName} claimed · '
            'Rs. ${scheme.claimedAmount!.formatted}',
            textAlign: TextAlign.center,
            style: context.texts.titleLarge,
          ),
          const SizedBox(height: AppSpacing.sm),
          DsBody(
            'Ref ${scheme.claimedReference} · Credited to your wallet.',
            size: 14,
            align: TextAlign.center,
          ),
        ],
      ),
    ),
    const SizedBox(height: AppSpacing.md),
    Text(
      'NOW CLOSED TO YOU',
      style: TextStyle(
        fontSize: 11,
        letterSpacing: 0.06 * 11,
        fontWeight: FontWeight.w600,
        color: context.palette.textTertiary,
      ),
    ),
    const SizedBox(height: AppSpacing.sm),
    Builder(
      builder: (context) {
        final closed = [
          for (final tier in scheme.tiers)
            if (tier.name != scheme.claimedTierName) tier,
        ];
        return DsCard(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Column(
            children: [
              for (var i = 0; i < closed.length; i++) ...[
                TierRow(
                  name: closed[i].name,
                  requirement: _tierRequirement(scheme, closed[i]),
                  reward: 'Rs. ${closed[i].reward.formatted}',
                  status: 'Closed',
                  statusTone: DsTone.neutral,
                  closed: true,
                ),
                if (i != closed.length - 1) const DsHairline(),
              ],
            ],
          ),
        );
      },
    ),
    const SizedBox(height: AppSpacing.md),
    const DsCaption(
      'Your scanning still earns QR prizes, spins and Reward Program bonuses '
      'as normal. Only this scheme is closed.',
    ),
  ];

  /// "Silver reached at 150 · 132 more scans for Gold" — what has been
  /// earned, then what is still ahead. Either clause alone when there is
  /// only one.
  String _schemeNote(ItemScheme scheme) {
    final reached = scheme.claimable;
    final next = scheme.next;

    final earned = reached == null
        ? null
        : scheme.byScans
        ? '${reached.name} reached at ${reached.threshold}'
        : '${reached.name} reached at '
              '${_amount(reached.threshold)}';

    final ahead = next == null
        ? null
        : scheme.byScans
        ? '${next.threshold - scheme.progress} more scans for ${next.name}'
        : 'PKR ${Money(next.threshold - scheme.progress).formatted} more '
              'for ${next.name}';

    final ends = 'ends ${formatInaamDate(scheme.endsOn)}';
    if (earned == null && ahead == null) return 'Every tier reached · $ends';
    return [?earned, ?ahead, ends].join(' · ');
  }

  /// The tiers a claim would close, named. "Gold and Platinum", not "2 more".
  String _closingNames(ItemScheme scheme, SchemeTier taking) {
    final closing = [
      for (final tier in scheme.tiers)
        if (tier.id != taking.id && tier.threshold > taking.threshold)
          tier.name,
    ];
    if (closing.isEmpty) return 'the rest of this scheme';
    if (closing.length == 1) return closing.single;
    return '${closing.sublist(0, closing.length - 1).join(', ')} and '
        '${closing.last}';
  }

  String _tierRequirement(ItemScheme scheme, SchemeTier tier) {
    if (!scheme.byScans) {
      return 'PKR ${_amount(tier.threshold)} in purchases';
    }
    if (tier.reached) return '${tier.threshold} scans · reached';
    return '${tier.threshold} scans · '
        '${tier.threshold - scheme.progress} to go';
  }

  /// "1.2 M" as the design abbreviates a target, because a tier row has no
  /// room for 1,200,000 beside its reward.
  static String _amount(int paisa) {
    final rupees = paisa ~/ 100;
    if (rupees < 100000) return Money(paisa).formatted;
    final millions = rupees / 1000000;
    final text = millions.toStringAsFixed(
      millions == millions.roundToDouble() ? 0 : 1,
    );
    return '$text M';
  }

  /// Board 09 · B3 — the cost of claiming now, in the partner's own numbers.
  Future<void> _confirmClaim(ItemScheme scheme, SchemeTier tier) async {
    final closing = [
      for (final other in scheme.tiers)
        if (other.id != tier.id && other.threshold > tier.threshold) other,
    ];

    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: const Color(0xFF0F172A).withValues(alpha: 0.45),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.all(AppSpacing.lg),
        child: SingleChildScrollView(
          child: DsDialogCard(
            icon: LucideIcons.medal,
            title: 'Claim ${tier.name} for Rs. ${tier.reward.formatted}?',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                DsBody(
                  closing.isEmpty
                      ? 'This is the only tier you will be able to claim from '
                            'this scheme.'
                      : 'This is the only tier you will be able to claim from '
                            'this scheme. ${_closingList(closing)} close '
                            'permanently, even if you reach their targets.',
                  size: 14,
                ),
                if (scheme.next != null) ...[
                  const SizedBox(height: AppSpacing.stepMd),
                  DsNotice(
                    message: scheme.byScans
                        ? 'You are at ${scheme.progress} scans. '
                              '${scheme.next!.name} needs '
                              '${scheme.next!.threshold}.'
                        : 'You are at PKR '
                              '${Money(scheme.progress).formatted}. '
                              '${scheme.next!.name} needs PKR '
                              '${Money(scheme.next!.threshold).formatted}.',
                    dense: true,
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                DsButton(
                  label: 'Yes, Claim ${tier.name}',
                  onPressed: () => Navigator.of(context).pop(true),
                ),
                const SizedBox(height: 10),
                DsButton(
                  label: 'Keep Scanning Instead',
                  variant: DsButtonVariant.quiet,
                  onPressed: () => Navigator.of(context).pop(false),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (confirmed != true || !mounted) return;

    final user = context.read<SessionController>().user;
    if (user == null) return;

    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    final (_, failure) = await context.read<InaamService>().claim(
      mobileNumber: user.mobileNumber,
      schemeId: scheme.id,
      tierId: tier.id,
    );
    if (!mounted) return;

    setState(() => _busy = false);
    if (failure == null) context.read<WalletRepository>().announceChange();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          failure == null
              ? 'Rs. ${tier.reward.formatted} added to your wallet.'
              : failure.message,
        ),
      ),
    );
    await _load();
  }

  static String _closingList(List<SchemeTier> tiers) =>
      [for (final tier in tiers) '${tier.name} at Rs. ${tier.reward.formatted}']
          .join(' and ');

  static String _titled(String name) => name.isEmpty
      ? name
      : name[0].toUpperCase() + name.substring(1).toLowerCase();
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
