import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../../core/ui/ds.dart';
import '../../../session/ui/session_controller.dart';
import '../../data/points_service.dart';
import 'points_tab.dart';

/// How far back the ledger is shown, matching the wallet ledger's ranges so
/// the two statements are asked for the same way.
enum PointsRange { everything, thisMonth, lastSixty, custom }

extension PointsRangeX on PointsRange {
  String get label => switch (this) {
    PointsRange.everything => 'Everything',
    PointsRange.thisMonth => 'This month',
    PointsRange.lastSixty => 'Last 60 days',
    PointsRange.custom => 'Custom range',
  };
}

/// Which side of the ledger to show.
enum PointsDirectionFilter { all, credits, debits }

/// The whole points ledger, which the hub's "See all" opens.
///
/// The same rows as the hub, unabridged, with a date range and a side of the
/// ledger to narrow them by. Points are never shown beside a currency figure
/// here either.
class PointsLedgerScreen extends StatefulWidget {
  const PointsLedgerScreen({super.key});

  @override
  State<PointsLedgerScreen> createState() => _PointsLedgerScreenState();
}

class _PointsLedgerScreenState extends State<PointsLedgerScreen> {
  PointsLedger? _ledger;
  bool _reachable = true;

  /// Everything, until the partner asks for less: opening the full ledger
  /// and being shown part of it would be an answer they never asked for.
  PointsRange _range = PointsRange.everything;
  PointsDirectionFilter _direction = PointsDirectionFilter.all;

  /// The two ends of [PointsRange.custom], inclusive. Both are whole days: a
  /// statement is asked for by date, not by the minute.
  DateTime? _customFrom;
  DateTime? _customTo;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final user = context.read<SessionController>().user;
    if (user == null) return;
    final loaded = await context.read<PointsService>().ledger(
      user.mobileNumber,
    );
    if (!mounted) return;
    setState(() {
      _ledger = loaded ?? PointsLedger.empty;
      _reachable = loaded != null;
    });
  }

  // --- What the filters are showing ---------------------------------------

  /// The chip's text: the named ranges say their name, a custom one says its
  /// dates, because "Custom range" on its own tells the partner nothing.
  String get _rangeLabel {
    if (_range != PointsRange.custom) return _range.label;
    final from = _customFrom;
    final to = _customTo;
    if (from == null || to == null) return _range.label;
    return '${_shortDay(from)} – ${_shortDay(to)}';
  }

  bool get _isFiltered =>
      _range != PointsRange.everything ||
      _direction != PointsDirectionFilter.all;

  bool _inRange(PointEntry entry) {
    final now = DateTime.now();
    return switch (_range) {
      PointsRange.everything => true,
      PointsRange.lastSixty => entry.postedAt.isAfter(
        now.subtract(const Duration(days: 60)),
      ),
      PointsRange.thisMonth =>
        entry.postedAt.year == now.year && entry.postedAt.month == now.month,
      // Both ends are inclusive whole days: an entry posted at any time on
      // the closing date belongs in the statement.
      PointsRange.custom => _inCustomRange(entry.postedAt),
    };
  }

  bool _inCustomRange(DateTime when) {
    final from = _customFrom;
    final to = _customTo;
    if (from != null && when.isBefore(from)) return false;
    if (to != null && !when.isBefore(to.add(const Duration(days: 1)))) {
      return false;
    }
    return true;
  }

  bool _matchesDirection(PointEntry entry) => switch (_direction) {
    PointsDirectionFilter.all => true,
    PointsDirectionFilter.credits => entry.credit,
    PointsDirectionFilter.debits => !entry.credit,
  };

  List<PointEntry> _visible(PointsLedger ledger) => [
    for (final entry in ledger.entries)
      if (_inRange(entry) && _matchesDirection(entry)) entry,
  ];

  // --- Changing them -------------------------------------------------------

  void _setRange(PointsRange value) => setState(() => _range = value);

  void _setDirection(PointsDirectionFilter value) =>
      setState(() => _direction = value);

  /// Picks the two dates and switches to them in one step, so the filter can
  /// never sit on [PointsRange.custom] with nothing chosen.
  ///
  /// The dates are normalised to whole days and swapped if they arrive the
  /// wrong way round.
  void _setCustomRange(DateTime from, DateTime to) {
    final start = DateTime(from.year, from.month, from.day);
    final end = DateTime(to.year, to.month, to.day);
    final swap = end.isBefore(start);

    setState(() {
      _customFrom = swap ? end : start;
      _customTo = swap ? start : end;
      _range = PointsRange.custom;
    });
  }

  void _resetFilters() => setState(() {
    _range = PointsRange.everything;
    _direction = PointsDirectionFilter.all;
    _customFrom = null;
    _customTo = null;
  });

  @override
  Widget build(BuildContext context) {
    final ledger = _ledger;

    if (ledger == null) {
      return Scaffold(
        appBar: DsAppBar(
          title: 'Points Ledger',
          onBack: () => Navigator.of(context).maybePop(),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final entries = _visible(ledger);

    return Scaffold(
      appBar: DsAppBar(
        title: 'Points Ledger',
        subtitle: _reachable ? '${formatPoints(ledger.balance)} points' : null,
        onBack: () => Navigator.of(context).maybePop(),
        actions: [
          if (ledger.entries.isNotEmpty)
            DsIconButton(
              icon: LucideIcons.slidersHorizontal,
              onPressed: _openFilters,
            ),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            children: [
              if (ledger.entries.isEmpty)
                DsEmptyState(
                  icon: _reachable ? LucideIcons.award : LucideIcons.cloudOff,
                  title: _reachable
                      ? 'No points yet'
                      : 'Could not reach Crown Solar',
                  message: _reachable
                      ? 'Points arrive from SAP when a purchase is posted, '
                            'and from partners who send you some.'
                      : 'Your points ledger is held by Crown Solar, not on '
                            'this phone. Check your connection and try again.',
                )
              else ...[
                _FilterRow(
                  rangeLabel: _rangeLabel,
                  direction: _direction,
                  isFiltered: _isFiltered,
                  onReset: _resetFilters,
                  onOpen: _openFilters,
                ),
                const SizedBox(height: AppSpacing.stepMd),
                if (entries.isEmpty)
                  // Nothing in this range is not the same as no points at
                  // all, so it says which it is and offers the way back.
                  DsEmptyState(
                    icon: LucideIcons.filterX,
                    title: 'Nothing in this range',
                    message:
                        'No points movements match these filters. Widen them '
                        'to see more.',
                    actionLabel: 'Reset filters',
                    onAction: _resetFilters,
                  )
                else
                  DsCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ),
                    child: Column(
                      children: [
                        for (var i = 0; i < entries.length; i++) ...[
                          PointsLedgerRow(entry: entries[i]),
                          if (i != entries.length - 1) const DsHairline(),
                        ],
                      ],
                    ),
                  ),
              ],
              const SizedBox(height: AppSpacing.md),
              const DsCaption(
                'Points are posted by SAP. Quote the SAP document on a line '
                'if a figure looks wrong.',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openFilters() => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => StatefulBuilder(
      // The sheet reads this screen's filter state, so it has to rebuild on
      // its own as well when a chip changes it.
      builder: (sheetContext, setSheetState) => _FilterSheet(
        range: _range,
        rangeLabel: _rangeLabel,
        direction: _direction,
        customFrom: _customFrom,
        customTo: _customTo,
        shownCount: _visible(_ledger ?? PointsLedger.empty).length,
        onRange: (value) {
          _setRange(value);
          setSheetState(() {});
        },
        onDirection: (value) {
          _setDirection(value);
          setSheetState(() {});
        },
        onPickDates: () async {
          final now = DateTime.now();
          final picked = await showDateRangePicker(
            context: sheetContext,
            // The ledger cannot hold anything from the future, and a
            // prototype's history does not reach back further than this.
            firstDate: DateTime(now.year - 2),
            lastDate: DateTime(now.year, now.month, now.day),
            initialDateRange: _customFrom != null && _customTo != null
                ? DateTimeRange(start: _customFrom!, end: _customTo!)
                : null,
            helpText: 'Select ledger dates',
            saveText: 'Apply',
          );
          if (picked == null) return;
          _setCustomRange(picked.start, picked.end);
          setSheetState(() {});
        },
        onReset: () {
          _resetFilters();
          setSheetState(() {});
        },
      ),
    ),
  );
}

/// The chips that summarise what is being shown, and clear it.
class _FilterRow extends StatelessWidget {
  const _FilterRow({
    required this.rangeLabel,
    required this.direction,
    required this.isFiltered,
    required this.onReset,
    required this.onOpen,
  });

  final String rangeLabel;
  final PointsDirectionFilter direction;
  final bool isFiltered;
  final VoidCallback onReset;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: [
        DsFilterChip(
          label: rangeLabel,
          selected: true,
          icon: LucideIcons.calendarRange,
          onTap: onOpen,
        ),
        const SizedBox(width: AppSpacing.sm),
        DsFilterChip(
          label: switch (direction) {
            PointsDirectionFilter.all => 'All movements',
            PointsDirectionFilter.credits => 'Credits',
            PointsDirectionFilter.debits => 'Debits',
          },
          selected: direction != PointsDirectionFilter.all,
          onTap: onOpen,
        ),
        if (isFiltered) ...[
          const SizedBox(width: AppSpacing.sm),
          DsFilterChip(label: 'Reset', icon: LucideIcons.x, onTap: onReset),
        ],
      ],
    ),
  );
}

/// The filter sheet: how far back, and which side of the ledger.
class _FilterSheet extends StatelessWidget {
  const _FilterSheet({
    required this.range,
    required this.rangeLabel,
    required this.direction,
    required this.customFrom,
    required this.customTo,
    required this.shownCount,
    required this.onRange,
    required this.onDirection,
    required this.onPickDates,
    required this.onReset,
  });

  final PointsRange range;
  final String rangeLabel;
  final PointsDirectionFilter direction;
  final DateTime? customFrom;
  final DateTime? customTo;
  final int shownCount;
  final ValueChanged<PointsRange> onRange;
  final ValueChanged<PointsDirectionFilter> onDirection;
  final VoidCallback onPickDates;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) => DsSheet(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Filter points', style: context.texts.titleLarge),
            GestureDetector(
              onTap: onReset,
              child: Text(
                'Reset all',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: context.colors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        const _GroupLabel('Date range'),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final option in PointsRange.values)
              if (option == PointsRange.custom)
                // Choosing this one opens the picker: there is nothing to
                // select until two dates exist.
                DsFilterChip(
                  label: range == PointsRange.custom
                      ? rangeLabel
                      : 'Choose dates',
                  icon: LucideIcons.calendarRange,
                  selected: range == PointsRange.custom,
                  onTap: onPickDates,
                )
              else
                DsFilterChip(
                  label: option.label,
                  selected: range == option,
                  onTap: () => onRange(option),
                ),
          ],
        ),
        if (range == PointsRange.custom &&
            customFrom != null &&
            customTo != null) ...[
          const SizedBox(height: 10),
          DsCaption(
            'Showing ${_fullDay(customFrom!)} to ${_fullDay(customTo!)}, '
            'both days included.',
          ),
        ],
        const SizedBox(height: 18),
        const _GroupLabel('Direction'),
        DsSegmentedControl(
          options: const ['All', 'Credits', 'Debits'],
          value: switch (direction) {
            PointsDirectionFilter.all => 'All',
            PointsDirectionFilter.credits => 'Credits',
            PointsDirectionFilter.debits => 'Debits',
          },
          onChanged: (value) => onDirection(switch (value) {
            'Credits' => PointsDirectionFilter.credits,
            'Debits' => PointsDirectionFilter.debits,
            _ => PointsDirectionFilter.all,
          }),
        ),
        const SizedBox(height: AppSpacing.lg),
        DsButton(
          label: 'Show $shownCount Movements',
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ],
    ),
  );
}

class _GroupLabel extends StatelessWidget {
  const _GroupLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(
      label,
      style: context.texts.labelLarge?.copyWith(
        color: context.colors.onSurfaceVariant,
      ),
    ),
  );
}

/// "5 Sep" — the date without the year, which the chip has no room for.
String _shortDay(DateTime when) => '${when.day} ${_months[when.month - 1]}';

/// "5 Sep 2026" — the full date, where there is room for it.
String _fullDay(DateTime when) =>
    '${when.day} ${_months[when.month - 1]} ${when.year}';

const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];
