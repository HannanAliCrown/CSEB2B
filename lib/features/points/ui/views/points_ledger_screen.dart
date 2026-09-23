import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../../core/ui/ds.dart';
import '../../../session/ui/session_controller.dart';
import '../../data/points_service.dart';
import 'points_tab.dart';

/// Which direction of movement the ledger is showing.
enum _Direction { all, credit, debit }

extension _DirectionX on _Direction {
  String get label => switch (this) {
    _Direction.all => 'All',
    _Direction.credit => 'Credit',
    _Direction.debit => 'Debit',
  };
}

/// The whole points ledger, which the hub's "See all" opens.
///
/// The same rows as the hub, unabridged, with a date range and a direction
/// to narrow them. Both filters are applied here rather than asked of the
/// server: the ledger arrives whole, so re-fetching to hide rows would cost
/// a round trip and show nothing new.
///
/// Points are never shown beside a currency figure here either.
class PointsLedgerScreen extends StatefulWidget {
  const PointsLedgerScreen({super.key});

  @override
  State<PointsLedgerScreen> createState() => _PointsLedgerScreenState();
}

class _PointsLedgerScreenState extends State<PointsLedgerScreen> {
  PointsLedger? _ledger;
  bool _reachable = true;

  _Direction _direction = _Direction.all;
  DateTimeRange? _range;

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

  bool get _filtered => _direction != _Direction.all || _range != null;

  List<PointEntry> _visible(PointsLedger ledger) => [
    for (final entry in ledger.entries)
      if (_matchesDirection(entry) && _matchesRange(entry)) entry,
  ];

  bool _matchesDirection(PointEntry entry) => switch (_direction) {
    _Direction.all => true,
    _Direction.credit => entry.credit,
    _Direction.debit => !entry.credit,
  };

  /// Both ends are inclusive: a range of "1 Sep to 1 Sep" means that whole
  /// day, not the instant it began.
  bool _matchesRange(PointEntry entry) {
    final range = _range;
    if (range == null) return true;
    final on = DateTime(
      entry.postedAt.year,
      entry.postedAt.month,
      entry.postedAt.day,
    );
    final from = DateTime(range.start.year, range.start.month, range.start.day);
    final to = DateTime(range.end.year, range.end.month, range.end.day);
    return !on.isBefore(from) && !on.isAfter(to);
  }

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

    final visible = _visible(ledger);

    return Scaffold(
      appBar: DsAppBar(
        title: 'Points Ledger',
        subtitle: _reachable ? '${formatPoints(ledger.balance)} points' : null,
        onBack: () => Navigator.of(context).maybePop(),
      ),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            children: [
              // Nothing to narrow on an empty ledger, so the filters only
              // appear once there is something to filter.
              if (ledger.entries.isNotEmpty) ...[
                _filters(),
                const SizedBox(height: AppSpacing.md),
              ],

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
              // An empty result after filtering is not an empty ledger, and
              // saying so keeps the difference plain.
              else if (visible.isEmpty)
                DsEmptyState(
                  icon: LucideIcons.filterX,
                  title: 'Nothing in this range',
                  message:
                      'No ${_direction == _Direction.all ? '' : '${_direction.label.toLowerCase()} '}'
                      'entries fall in the dates you chose.',
                  actionLabel: 'Clear filters',
                  onAction: _clear,
                )
              else
                DsCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  child: Column(
                    children: [
                      for (var i = 0; i < visible.length; i++) ...[
                        PointsLedgerRow(entry: visible[i]),
                        if (i != visible.length - 1) const DsHairline(),
                      ],
                    ],
                  ),
                ),
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

  Widget _filters() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          for (final direction in _Direction.values) ...[
            if (direction != _Direction.values.first)
              const SizedBox(width: AppSpacing.sm),
            DsFilterChip(
              label: direction.label,
              selected: _direction == direction,
              onTap: () => setState(() => _direction = direction),
            ),
          ],
        ],
      ),
      const SizedBox(height: AppSpacing.sm),
      Row(
        children: [
          Expanded(
            child: DsSelect(
              value: _range == null ? null : _rangeLabel(_range!),
              placeholder: 'Any date',
              onTap: _pickRange,
            ),
          ),
          if (_filtered) ...[
            const SizedBox(width: AppSpacing.sm),
            DsIconButton(icon: LucideIcons.x, onPressed: _clear),
          ],
        ],
      ),
    ],
  );

  void _clear() => setState(() {
    _direction = _Direction.all;
    _range = null;
  });

  Future<void> _pickRange() async {
    final ledger = _ledger;
    final now = DateTime.now();

    // The pickable window is the ledger's own: there is nothing to find
    // before the first entry, and nothing after today.
    final earliest = ledger == null || ledger.entries.isEmpty
        ? DateTime(now.year - 1)
        : ledger.entries
              .map((entry) => entry.postedAt)
              .reduce((a, b) => a.isBefore(b) ? a : b);

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(earliest.year, earliest.month, earliest.day),
      lastDate: now,
      initialDateRange: _range,
      helpText: 'Filter by date',
    );
    if (picked != null) setState(() => _range = picked);
  }

  /// "01 Sep – 22 Sep", or one date when both ends are the same day.
  static String _rangeLabel(DateTimeRange range) {
    final from = _day(range.start);
    final to = _day(range.end);
    return from == to ? from : '$from – $to';
  }

  static const _months = [
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

  static String _day(DateTime at) =>
      '${at.day.toString().padLeft(2, '0')} ${_months[at.month - 1]}';
}
