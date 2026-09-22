import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../../core/ui/ds.dart';
import '../../../session/ui/session_controller.dart';
import '../../../wallet/data/wallet_repository.dart';
import '../../data/inaam_service.dart';
import '../widgets/inaam_widgets.dart';

/// Board 09 — Inaam Baazar.
///
/// Three ways Crown Solar rewards an installer for scanning, behind one set
/// of tabs. Every prize lands in the cash wallet; Inaam has no balance of its
/// own, and none is shown here.
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

    // The board rules the tabs across the top and scrolls only what is under
    // them, so switching tab never scrolls the control out of reach.
    final sections = !_reachable
        ? const [
            DsNotice(
              icon: LucideIcons.cloudOff,
              tone: DsTone.warning,
              message:
                  'Could not reach Crown Solar, so nothing here is your '
                  'real position. Pull down to try again.',
            ),
          ]
        : switch (_tab) {
            _reward => _rewardSection(),
            _item => _itemSection(),
            _ => _spinSection(spin),
          };

    final gap = _tab == _item ? 14.0 : AppSpacing.md;

    return Scaffold(
      appBar: const DsAppBar(title: 'Inaam Baazar'),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenPadding,
                10,
                AppSpacing.screenPadding,
                0,
              ),
              child: DsTabs(
                tabs: const [_spin, _reward, _item],
                value: _tab,
                onChanged: (tab) => setState(() => _tab = tab),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _load,
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenPadding,
                    AppSpacing.md,
                    AppSpacing.screenPadding,
                    AppSpacing.stepLg,
                  ),
                  itemCount: sections.length,
                  separatorBuilder: (_, _) => SizedBox(height: gap),
                  itemBuilder: (_, index) => sections[index],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _claimFooter(),
    );
  }

  // --- A1 · A2 · A3 · Spin and Win ------------------------------------------

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

    final visible = _visibleHistory(spin);

    return [
      InaamSpinsCard(
        spins: spin.spinsAvailable,
        scansToday: spin.scansToday,
        scansTarget: spin.scansToday + spin.scansToNextSpin,
        progress: spin.progress,
        note:
            '${spin.scansToNextSpin} more '
            '${spin.scansToNextSpin == 1 ? 'scan' : 'scans'} earns another '
            'spin. There is no limit on how many you can earn in a day.',
      ),

      // With a spin waiting the wheel is the screen; with none it would be a
      // control that does nothing, so the board replaces it outright.
      if (spin.spinsAvailable > 0)
        DsCard(
          child: Column(
            children: [
              InaamSpinWheel(
                labels: [for (final prize in spin.segments) prize.formatted],
              ),
              const SizedBox(height: 14),
              Text(
                spin.segments.isEmpty
                    ? 'Prizes are credited to your wallet.'
                    : 'Prizes range from Rs. ${spin.segments.first.formatted} '
                          'to Rs. ${_largest(spin.segments).formatted} and are '
                          'credited to your wallet.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  height: 19 / 13,
                  color: context.colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 14),
              DsButton(
                label: 'Spin Now',
                loading: _busy,
                disabled: _busy,
                onPressed: _takeSpin,
              ),
            ],
          ),
        )
      else
        DsCard(
          padding: EdgeInsets.zero,
          child: DsEmptyState(
            icon: LucideIcons.scanLine,
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

      Row(
        children: [
          const Expanded(
            child: Text(
              'Spin history',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
          // "See all" opens nothing: the rest of the history is already here,
          // just folded. A control that led to a screen which does not exist
          // would be worse than none.
          if (spin.history.length > _historyPreview && !_allHistory)
            GestureDetector(
              onTap: () => setState(() => _allHistory = true),
              child: Text(
                'See all',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: context.colors.primary,
                ),
              ),
            ),
        ],
      ),
      if (spin.history.isEmpty)
        const DsCaption('Your spins will be listed here once you take one.')
      else
        DsCard(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Column(
            children: [
              for (var i = 0; i < visible.length; i++)
                InaamSpinRow(
                  prize: 'Rs. ${visible[i].amount.formatted}',
                  when: formatSpinWhen(visible[i].spunAt),
                  last: i == visible.length - 1,
                ),
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
    final wallet = context.read<WalletRepository>();
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
    wallet.announceChange();
    final balance = await wallet.balance(user);
    await _load();
    if (!mounted) return;

    final again = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => _SpinResultScreen(
          spin: spin!,
          balance: balance,
          spinsLeft: _spinState?.spinsAvailable ?? 0,
          history: _spinState?.history ?? const [],
        ),
      ),
    );
    if (again == true && mounted) await _takeSpin();
  }

  // --- A4 · Reward Program --------------------------------------------------

  List<Widget> _rewardSection() {
    final program = _program!;

    return [
      // What last month earned, and how long it runs. Shown first because it
      // is the thing paying out right now.
      if (program.hasAward)
        InaamRewardBanner(
          // The month named here is the one that earned the bonus, not the
          // one it runs in.
          title: program.awardEarnedOn == null
              ? 'Active Rewards'
              : 'Active Rewards · '
                    '${formatInaamMonth(program.awardEarnedOn!)}',
          remaining: '${program.daysRemaining} days',
          endDate: formatInaamDate(program.awardAppliesUntil!),
          tierName: _titled(program.awardTierName!),
          bonus: '+${program.awardBonusPercent}%',
        )
      else
        const DsNotice(
          icon: LucideIcons.info,
          message:
              'You have no bonus running. Reach a tier this month and the '
              'bonus applies to next month\'s scans.',
        ),

      if (!program.running)
        const DsEmptyState(
          icon: LucideIcons.calendarClock,
          title: 'No programme this month',
          message:
              'Crown Solar creates each month\'s programme at the end of the '
              'one before. It will appear here when it does.',
        )
      else ...[
        Text("This Month's Scheme", style: context.texts.titleLarge),
        DsCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Target · ${formatInaamMonth(program.startsOn!)} · in progress',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              InaamDateStrip(
                startLabel: 'Start date',
                startValue: formatInaamDate(program.startsOn!),
                endLabel: 'End date',
                endValue: formatInaamDate(program.endsOn!),
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
                      borderRadius: BorderRadius.circular(AppRadii.pill),
                    ),
                    child: Text(
                      '${program.scans} '
                      '${program.scans == 1 ? 'scan' : 'scans'}',
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
              InaamMilestoneTrack(
                milestones: [
                  for (final tier in program.tiers)
                    InaamMilestone(
                      name: tier.name,
                      target: tier.scanTarget,
                      reached: program.scans >= tier.scanTarget,
                    ),
                ],
                scans: program.scans,
              ),
              const SizedBox(height: AppSpacing.md),
              InaamNextUp(
                program.next == null
                    ? 'You have reached every tier this month.'
                    : '${program.next!.scanTarget - program.scans} more scans '
                          'to unlock ${_titled(program.next!.name)} and get '
                          '+${program.next!.bonusPercent}% bonus',
              ),
              const SizedBox(height: AppSpacing.md),
              // The three cards stand to the height of the tallest, as the
              // board draws them, rather than each shrinking to its own copy.
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < program.tiers.length; i++) ...[
                      if (i != 0) const SizedBox(width: 10),
                      Expanded(
                        child: InaamRewardTierCard(
                          name: program.tiers[i].name,
                          requirement: '${program.tiers[i].scanTarget} scans',
                          bonus: '+${program.tiers[i].bonusPercent}%',
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
        const DsNotice(
          icon: LucideIcons.info,
          tone: DsTone.info,
          message:
              'Reaching a tier marks it complete but there is nothing to '
              'claim here. At month end the highest tier you reached is '
              'awarded, and it becomes the extra you earn on every '
              'scheme-product scan next month.',
        ),
      ],
    ];
  }

  // --- B1 · B2 · B4 · Item Scheme -------------------------------------------

  /// Every scheme with a tier waiting to be taken, and the tier it is.
  List<(ItemScheme, SchemeTier)> get _open => [
    for (final scheme in _schemes ?? const <ItemScheme>[])
      if (scheme.claimable != null) (scheme, scheme.claimable!),
  ];

  /// The board pins the claim to the bottom of the screen. With one scheme
  /// open that is unambiguous; with several, each button stays under the
  /// scheme it belongs to instead.
  Widget? _claimFooter() {
    if (_tab != _item || !_reachable || _open.length != 1) return null;
    final (scheme, tier) = _open.single;
    return DsFooterBar(
      child: DsButton(
        label: 'Claim ${tier.name} · Rs. ${tier.reward.formatted}',
        loading: _busy,
        disabled: _busy,
        onPressed: () => _confirmClaim(scheme, tier),
      ),
    );
  }

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
        if (schemes.length > 1) DsSectionHeader(title: scheme.name),
        if (scheme.claimed)
          ..._claimedScheme(scheme)
        else
          ..._openScheme(scheme),
      ],
    ];
  }

  List<Widget> _openScheme(ItemScheme scheme) {
    final claimable = scheme.claimable;
    final next = scheme.next;

    return [
      InaamMeasureCard(
        label: scheme.byScans ? 'Measured on scans' : 'Measured on amount',
        prefix: scheme.byScans ? null : 'PKR',
        value: scheme.byScans
            ? '${scheme.progress}'
            : Money(scheme.progress).formatted,
        suffix: scheme.byScans ? 'scans so far' : null,
        percent: scheme.percent,
        note: _schemeNote(scheme),
      ),

      // Stated before the button is ever pressed, not after — and naming the
      // tiers it would close, because "the rest" is not a number a partner
      // can weigh.
      if (claimable != null)
        DsNotice(
          icon: LucideIcons.triangleAlert,
          tone: DsTone.warning,
          message:
              'You can claim one tier only. Taking ${claimable.name} now '
              'closes ${_closingNames(scheme, claimable)} for good, even if '
              'you reach their targets later.',
        ),

      for (final tier in scheme.tiers)
        InaamTierCard(
          name: tier.name,
          prize: '· Rs. ${tier.reward.formatted}',
          target: _tierRequirement(scheme, tier),
          state: tier.id == claimable?.id
              ? 'Claim now'
              : tier.reached
              ? 'Reached'
              : 'Locked',
          claimable: tier.id == claimable?.id,
          // The rung after next recedes: the ladder stays legible without
          // competing with the tier actually within reach.
          dimmed:
              !tier.reached && next != null && tier.threshold > next.threshold,
        ),

      if (claimable == null)
        const InaamSoftNote(
          'A scheme is either scans or amount, set when Crown Solar creates '
          'it. You will never see both measures on one scheme.',
        )
      else if (_open.length > 1)
        DsButton(
          label: 'Claim ${claimable.name} · Rs. ${claimable.reward.formatted}',
          loading: _busy,
          disabled: _busy,
          onPressed: () => _confirmClaim(scheme, claimable),
        ),
    ];
  }

  /// Board 09 · B4 — claimed, with the other tiers closed.
  List<Widget> _claimedScheme(ItemScheme scheme) {
    final closed = [
      for (final tier in scheme.tiers)
        if (tier.name != scheme.claimedTierName) tier,
    ];

    return [
      InaamClaimedCard(
        title:
            '${scheme.claimedTierName} claimed · '
            'Rs. ${scheme.claimedAmount!.formatted}',
        reference: 'Ref ${scheme.claimedReference}',
        note: 'Credited to your wallet.',
      ),
      const InaamCapsLabel('Now closed to you', size: 13),
      for (final tier in closed)
        InaamTierCard(
          name: tier.name,
          prize: '· Rs. ${tier.reward.formatted}',
          target: _tierRequirement(scheme, tier),
          dimmed: true,
        ),
      const InaamSoftNote(
        'Your scanning still earns QR prizes, spins and Reward Program '
        'bonuses as normal. Only this scheme is closed.',
      ),
    ];
  }

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
            icon: LucideIcons.triangleAlert,
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
                  const SizedBox(height: AppSpacing.md),
                  InaamSoftNote(
                    scheme.byScans
                        ? 'You are at ${scheme.progress} scans. '
                              '${scheme.next!.name} needs '
                              '${scheme.next!.threshold}.'
                        : 'You are at PKR '
                              '${Money(scheme.progress).formatted}. '
                              '${scheme.next!.name} needs PKR '
                              '${Money(scheme.next!.threshold).formatted}.',
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

/// Board 09 · A2 — the prize revealed and credited in the same breath: the
/// wheel settled on what it paid, the wallet's new balance, and the ledger
/// rows it now sits at the top of.
class _SpinResultScreen extends StatelessWidget {
  const _SpinResultScreen({
    required this.spin,
    required this.balance,
    required this.spinsLeft,
    required this.history,
  });

  final Spin spin;
  final Money balance;
  final int spinsLeft;
  final List<Spin> history;

  /// Four rows, as the board draws them.
  static const _rows = 4;

  @override
  Widget build(BuildContext context) {
    final rows = history.take(_rows).toList();

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: 26,
          ),
          child: Column(
            children: [
              InaamSpinWheel(
                size: 216,
                centre: InaamWheelPrize(amount: 'Rs. ${spin.amount.formatted}'),
              ),
              const SizedBox(height: AppSpacing.cardPadding),
              Text(
                'Rs. ${spin.amount.formatted} added to your wallet',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  height: 28 / 22,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.02 * 22,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              DsBody(
                'Your balance is now PKR ${balance.formatted}. '
                'Ref ${spin.reference} · ${formatSpinWhen(spin.spunAt)}',
                size: 14,
                align: TextAlign.center,
              ),
              if (rows.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.cardPadding),
                DsCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  child: Column(
                    children: [
                      for (var i = 0; i < rows.length; i++)
                        InaamSpinRow(
                          prize: 'Rs. ${rows[i].amount.formatted}',
                          when: formatSpinWhen(rows[i].spunAt),
                          last: i == rows.length - 1,
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: DsFooterBar(
        child: Column(
          children: [
            if (spinsLeft > 0) ...[
              DsButton(
                label: 'Use Your Next Spin',
                onPressed: () => Navigator.of(context).pop(true),
              ),
              const SizedBox(height: 10),
            ],
            DsButton(
              label: 'Done',
              variant: DsButtonVariant.quiet,
              onPressed: () => Navigator.of(context).pop(false),
            ),
          ],
        ),
      ),
    );
  }
}
