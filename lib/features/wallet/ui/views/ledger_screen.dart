import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/ui/ds.dart';
import '../../data/wallet_repository.dart';
import '../ledger_view_model.dart';

/// Board 04 · C1 — the ledger: Balance / Held / Available across the top,
/// filters beneath, then the lines grouped by day, each carrying the running
/// balance it left behind.
class LedgerScreen extends StatefulWidget {
  const LedgerScreen({super.key});

  @override
  State<LedgerScreen> createState() => _LedgerScreenState();
}

class _LedgerScreenState extends State<LedgerScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<LedgerViewModel>().load(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ledger = context.watch<LedgerViewModel>();
    final groups = ledger.groups;

    return Scaffold(
      appBar: DsAppBar(
        title: 'View Ledger',
        subtitle: ledger.user.businessName,
        onBack: () => Navigator.of(context).maybePop(),
        actions: [
          DsIconButton(
            icon: LucideIcons.slidersHorizontal,
            onPressed: () => _openFilters(context, ledger),
          ),
          DsIconButton(
            icon: LucideIcons.download,
            onPressed: () => _openExport(context, ledger),
          ),
        ],
      ),
      body: ledger.busy && ledger.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              bottom: false,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenPadding,
                  14,
                  AppSpacing.screenPadding,
                  AppSpacing.stepLg,
                ),
                children: [
                  _BalanceStrip(ledger: ledger),
                  const SizedBox(height: AppSpacing.stepMd),
                  _FilterRow(ledger: ledger),
                  const SizedBox(height: 18),
                  if (groups.isEmpty)
                    _EmptyState(ledger: ledger)
                  else
                    for (final group in groups) ...[
                      _DaySection(label: group.label, rows: group.rows),
                      const SizedBox(height: AppSpacing.md),
                    ],
                ],
              ),
            ),
    );
  }

  Future<void> _openFilters(BuildContext context, LedgerViewModel ledger) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => ChangeNotifierProvider<LedgerViewModel>.value(
          value: ledger,
          child: const _FilterSheet(),
        ),
      );

  Future<void> _openExport(BuildContext context, LedgerViewModel ledger) =>
      Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => ChangeNotifierProvider<LedgerViewModel>.value(
            value: ledger,
            child: const LedgerExportScreen(),
          ),
        ),
      );
}

/// Balance, Held and Available side by side. Held is called out in its own
/// colour because it is the figure partners ask about.
class _BalanceStrip extends StatelessWidget {
  const _BalanceStrip({required this.ledger});

  final LedgerViewModel ledger;

  @override
  Widget build(BuildContext context) {
    return DsCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          _BalanceCell(label: 'Balance', value: ledger.balance.formatted),
          const _Divider(),
          _BalanceCell(
            label: 'Held',
            value: ledger.held.formatted,
            tone: DsTone.info,
          ),
          const _Divider(),
          _BalanceCell(label: 'Available', value: ledger.available.formatted),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) => Container(
    width: 1,
    height: 40,
    margin: const EdgeInsets.symmetric(horizontal: AppSpacing.stepMd),
    color: context.colors.outline,
  );
}

class _BalanceCell extends StatelessWidget {
  const _BalanceCell({
    required this.label,
    required this.value,
    this.tone = DsTone.neutral,
  });

  final String label;
  final String value;
  final DsTone tone;

  @override
  Widget build(BuildContext context) {
    final accent = tone == DsTone.info;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              letterSpacing: 0.06 * 11,
              fontWeight: FontWeight.w600,
              color: accent
                  ? context.status.info
                  : context.palette.textTertiary,
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: accent ? context.status.info : context.colors.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The chips that summarise what is being shown, and clear it.
class _FilterRow extends StatelessWidget {
  const _FilterRow({required this.ledger});

  final LedgerViewModel ledger;

  @override
  Widget build(BuildContext context) {
    final typeLabel = switch (ledger.types.length) {
      0 => 'All types',
      1 => ledger.types.first.label,
      final count => '$count types',
    };

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          DsFilterChip(label: ledger.rangeLabel, selected: true),
          const SizedBox(width: AppSpacing.sm),
          DsFilterChip(
            label: switch (ledger.direction) {
              LedgerDirectionFilter.all => 'All movements',
              LedgerDirectionFilter.credits => 'Credits',
              LedgerDirectionFilter.debits => 'Debits',
            },
            selected: ledger.direction != LedgerDirectionFilter.all,
          ),
          const SizedBox(width: AppSpacing.sm),
          DsFilterChip(label: typeLabel, selected: ledger.types.isNotEmpty),
          if (ledger.isFiltered) ...[
            const SizedBox(width: AppSpacing.sm),
            DsFilterChip(
              label: 'Reset',
              icon: LucideIcons.x,
              onTap: ledger.resetFilters,
            ),
          ],
        ],
      ),
    );
  }
}

class _DaySection extends StatelessWidget {
  const _DaySection({required this.label, required this.rows});

  final String label;
  final List<LedgerRow> rows;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            letterSpacing: 0.06 * 11,
            fontWeight: FontWeight.w600,
            color: context.palette.textTertiary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        DsCard(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Column(
            children: [
              for (var i = 0; i < rows.length; i++) ...[
                _LedgerRowTile(row: rows[i]),
                if (i != rows.length - 1) const DsHairline(),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _LedgerRowTile extends StatelessWidget {
  const _LedgerRowTile({required this.row});

  final LedgerRow row;

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

  /// "1:42 PM" for today's lines, "06 Sep" for older ones.
  String get _when {
    final when = row.entry.postedAt;
    final now = DateTime.now();
    final sameDay =
        when.year == now.year && when.month == now.month && when.day == now.day;
    if (!sameDay) {
      return '${when.day.toString().padLeft(2, '0')} '
          '${_months[when.month - 1]}';
    }
    final hour = when.hour % 12 == 0 ? 12 : when.hour % 12;
    final minute = when.minute.toString().padLeft(2, '0');
    return '$hour:$minute ${when.hour < 12 ? 'AM' : 'PM'}';
  }

  /// Direction is icon, sign and colour together — never colour alone.
  ({IconData icon, DsTone tone}) get _mark {
    if (row.entry.state == LedgerState.held) {
      return (icon: LucideIcons.hand, tone: DsTone.warning);
    }
    return switch (row.entry.type) {
      LedgerType.scanPrize => (icon: LucideIcons.gift, tone: DsTone.success),
      LedgerType.spinPrize => (
        icon: LucideIcons.sparkles,
        tone: DsTone.success,
      ),
      LedgerType.returned => (icon: LucideIcons.undo2, tone: DsTone.success),
      LedgerType.adjustment => (icon: LucideIcons.scale, tone: DsTone.neutral),
      LedgerType.cashRequest => (
        icon: LucideIcons.handCoins,
        tone: DsTone.info,
      ),
      LedgerType.sendCash => (
        icon: LucideIcons.banknoteArrowUp,
        tone: row.entry.isCredit ? DsTone.success : DsTone.neutral,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final mark = _mark;
    final (_, foreground) = dsToneColors(context, mark.tone);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 13),
      child: Row(
        children: [
          DsIconMedallion(
            icon: mark.icon,
            tone: mark.tone,
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
                  row.entry.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '$_when · ${row.entry.type.label} · ${row.entry.id}',
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
                row.entry.signedAmount,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: foreground,
                ),
              ),
              Text(
                // A held line has settled nowhere, so it has no balance yet.
                row.balanceAfter?.formatted ?? 'Held',
                style: TextStyle(
                  fontSize: 11,
                  color: row.balanceAfter == null
                      ? context.status.warning
                      : context.palette.textTertiary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Board 04 · C4 — nothing to show, said differently depending on whether a
/// filter caused it.
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.ledger});

  final LedgerViewModel ledger;

  @override
  Widget build(BuildContext context) {
    if (ledger.isEmpty) {
      return const DsEmptyState(
        title: 'Nothing here yet',
        message: 'Movements appear as soon as money comes in or goes out.',
        icon: LucideIcons.receiptText,
      );
    }
    return DsEmptyState(
      title: 'No transactions match',
      message: 'Nothing in this range and type. Widen the filters to see more.',
      icon: LucideIcons.filterX,
      actionLabel: 'Reset filters',
      onAction: ledger.resetFilters,
    );
  }
}

/// Board 04 · C2 — the filter sheet.
class _FilterSheet extends StatelessWidget {
  const _FilterSheet();

  @override
  Widget build(BuildContext context) {
    final ledger = context.watch<LedgerViewModel>();

    return DsSheet(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Filter ledger', style: context.texts.titleLarge),
              GestureDetector(
                onTap: ledger.resetFilters,
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
              for (final option in LedgerRange.values)
                if (option == LedgerRange.custom)
                  // Choosing this one opens the picker: there is nothing to
                  // select until two dates exist.
                  DsFilterChip(
                    label: ledger.range == LedgerRange.custom
                        ? ledger.rangeLabel
                        : 'Choose dates',
                    icon: LucideIcons.calendarRange,
                    selected: ledger.range == LedgerRange.custom,
                    onTap: () => _pickDates(context, ledger),
                  )
                else
                  DsFilterChip(
                    label: option.label,
                    selected: ledger.range == option,
                    onTap: () => ledger.setRange(option),
                  ),
            ],
          ),
          if (ledger.range == LedgerRange.custom &&
              ledger.customFrom != null &&
              ledger.customTo != null) ...[
            const SizedBox(height: 10),
            DsCaption(
              'Showing ${_fullDay(ledger.customFrom!)} to '
              '${_fullDay(ledger.customTo!)}, both days included.',
            ),
          ],
          const SizedBox(height: 18),
          const _GroupLabel('Direction'),
          DsSegmentedControl(
            options: const ['All', 'Credits', 'Debits'],
            value: switch (ledger.direction) {
              LedgerDirectionFilter.all => 'All',
              LedgerDirectionFilter.credits => 'Credits',
              LedgerDirectionFilter.debits => 'Debits',
            },
            onChanged: (value) => ledger.setDirection(switch (value) {
              'Credits' => LedgerDirectionFilter.credits,
              'Debits' => LedgerDirectionFilter.debits,
              _ => LedgerDirectionFilter.all,
            }),
          ),
          const SizedBox(height: 18),
          const _GroupLabel('Type'),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final type in LedgerType.values)
                DsFilterChip(
                  label: type.label,
                  selected: ledger.types.contains(type),
                  onTap: () => ledger.toggleType(type),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          DsButton(
            label: 'Show ${ledger.rows.length} Transactions',
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ],
      ),
    );
  }
}

/// Opens the platform's own two-ended date picker and hands the result to the
/// view model. Nothing changes if the partner backs out.
Future<void> _pickDates(BuildContext context, LedgerViewModel ledger) async {
  final now = DateTime.now();
  final picked = await showDateRangePicker(
    context: context,
    // The ledger cannot hold anything from the future, and a prototype's
    // history does not reach back further than this.
    firstDate: DateTime(now.year - 2),
    lastDate: DateTime(now.year, now.month, now.day),
    initialDateRange: ledger.customFrom != null && ledger.customTo != null
        ? DateTimeRange(start: ledger.customFrom!, end: ledger.customTo!)
        : null,
    helpText: 'Select ledger dates',
    saveText: 'Apply',
  );
  if (picked == null) return;
  ledger.setCustomRange(picked.start, picked.end);
}

/// "5 Sep 2026" — the full date, where there is room for it.
String _fullDay(DateTime when) {
  const months = [
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
  return '${when.day} ${months[when.month - 1]} ${when.year}';
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

/// Board 04 · C3 — downloading the ledger.
class LedgerExportScreen extends StatefulWidget {
  const LedgerExportScreen({super.key});

  @override
  State<LedgerExportScreen> createState() => _LedgerExportScreenState();
}

class _LedgerExportScreenState extends State<LedgerExportScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<LedgerViewModel>().exportLedger(),
    );
  }

  @override
  void dispose() {
    // Leaving resets it, so opening the screen again starts a fresh export.
    context.read<LedgerViewModel>().dismissExport();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ledger = context.watch<LedgerViewModel>();

    return DsScreen(
      appBar: DsAppBar(
        title: 'Download Ledger',
        onBack: () => Navigator.of(context).maybePop(),
      ),
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      gap: AppSpacing.md,
      sections: [
        switch (ledger.exportStage) {
          ExportStage.ready => _ExportReady(ledger: ledger),
          ExportStage.failed => _ExportFailed(ledger: ledger),
          _ => _ExportWorking(ledger: ledger),
        },
        const DsCaption(
          'The file is a spreadsheet (CSV) so it opens in Excel, Google '
          'Sheets or any accounts package. Sharing uses your phone\'s own '
          'share sheet.',
        ),
      ],
    );
  }
}

class _ExportWorking extends StatelessWidget {
  const _ExportWorking({required this.ledger});

  final LedgerViewModel ledger;

  @override
  Widget build(BuildContext context) {
    return DsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
              const SizedBox(width: AppSpacing.stepMd),
              Expanded(
                child: Text(
                  'Preparing your ledger',
                  style: context.texts.bodyLarge?.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          DsBody('${ledger.range.label} · ${ledger.rows.length} transactions'),
        ],
      ),
    );
  }
}

class _ExportReady extends StatelessWidget {
  const _ExportReady({required this.ledger});

  final LedgerViewModel ledger;

  @override
  Widget build(BuildContext context) {
    final file = ledger.exportFile!;
    final name = file.path.split(RegExp(r'[/\\]')).last;
    final kb = (ledger.exportBytes / 1024).toStringAsFixed(1);

    return DsCard(
      child: Column(
        children: [
          Row(
            children: [
              const DsIconMedallion(
                icon: LucideIcons.fileText,
                tone: DsTone.success,
                size: 40,
                iconSize: 20,
                rounded: true,
              ),
              const SizedBox(width: AppSpacing.stepMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.texts.bodyLarge?.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    DsCaption('$kb KB · ready to share'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          DsButton(
            label: 'Share',
            icon: LucideIcons.share2,
            onPressed: () => SharePlus.instance.share(
              ShareParams(
                files: [XFile(file.path)],
                text: 'Crown Solar ledger · ${ledger.user.businessName}',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExportFailed extends StatelessWidget {
  const _ExportFailed({required this.ledger});

  final LedgerViewModel ledger;

  @override
  Widget build(BuildContext context) {
    return DsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const DsIconMedallion(
                icon: LucideIcons.fileX,
                tone: DsTone.error,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Could not create the file',
                  style: context.texts.bodyLarge?.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.stepMd),
          DsBody(
            'Your filters are still applied — try again. '
            '${ledger.exportError ?? ''}',
          ),
          const SizedBox(height: AppSpacing.stepMd),
          DsButton(
            label: 'Try Again',
            variant: DsButtonVariant.secondary,
            size: DsButtonSize.sm,
            icon: LucideIcons.refreshCw,
            onPressed: ledger.exportLedger,
          ),
        ],
      ),
    );
  }
}
