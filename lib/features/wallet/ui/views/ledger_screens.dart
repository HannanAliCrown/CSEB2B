import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/ui/ds.dart';

/// One ledger line: who, why, how much, and the running balance after it.
class _LedgerEntry {
  const _LedgerEntry({
    required this.who,
    required this.meta,
    required this.amount,
    required this.after,
    required this.icon,
    required this.tone,
  });

  final String who;
  final String meta;
  final String amount;
  final String after;
  final IconData icon;
  final DsTone tone;
}

/// Board 04 · C1 — Ledger: reconciles with the wallet, and every row carries
/// its running balance. Direction is icon + sign + colour, never colour alone.
class LedgerScreen extends StatelessWidget {
  const LedgerScreen({super.key});

  static const _today = [
    _LedgerEntry(
      who: 'Prize · Crown 6kW Inverter',
      meta: '1:42 PM · QR claim · Ref QR-88214',
      amount: '+ 1,500',
      after: '184,500',
      icon: LucideIcons.gift,
      tone: DsTone.success,
    ),
    _LedgerEntry(
      who: 'Al-Noor Electric Store',
      meta: '9:43 AM · Send Cash · Currency',
      amount: '− 25,000',
      after: 'Held',
      icon: LucideIcons.hand,
      tone: DsTone.warning,
    ),
    _LedgerEntry(
      who: 'Spin and Win prize',
      meta: '8:11 AM · Inaam Baazar',
      amount: '+ 500',
      after: '183,000',
      icon: LucideIcons.sparkles,
      tone: DsTone.success,
    ),
  ];

  static const _earlier = [
    _LedgerEntry(
      who: 'Hamza Solar House',
      meta: 'Yesterday · Approved · Product',
      amount: '− 60,000',
      after: '182,500',
      icon: LucideIcons.banknoteArrowUp,
      tone: DsTone.neutral,
    ),
    _LedgerEntry(
      who: 'Returned · Bilal Traders rejected',
      meta: '07 Sep · Send Cash reversed',
      amount: '+ 9,500',
      after: '242,500',
      icon: LucideIcons.undo2,
      tone: DsTone.success,
    ),
    _LedgerEntry(
      who: 'Prize · Crown 550W Panel',
      meta: '06 Sep · QR claim',
      amount: '+ 300',
      after: '233,000',
      icon: LucideIcons.gift,
      tone: DsTone.success,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: DsAppBar(
        title: 'View Ledger',
        onBack: () => Navigator.of(context).maybePop(),
        actions: [
          DsIconButton(icon: LucideIcons.slidersHorizontal, onPressed: () {}),
          DsIconButton(icon: LucideIcons.download, onPressed: () {}),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenPadding,
            14,
            AppSpacing.screenPadding,
            AppSpacing.stepLg,
          ),
          children: [
            const _BalanceStrip(),
            const SizedBox(height: AppSpacing.stepMd),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  const DsFilterChip(label: 'Sep 2026', selected: true),
                  const SizedBox(width: AppSpacing.sm),
                  _AccentChip(label: 'Credits'),
                  const SizedBox(width: AppSpacing.sm),
                  const DsFilterChip(label: 'All types'),
                  const SizedBox(width: AppSpacing.sm),
                  _ResetChip(),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const _DaySection(label: 'Today', entries: _today),
            const SizedBox(height: AppSpacing.md),
            const _DaySection(label: 'Earlier', entries: _earlier),
          ],
        ),
      ),
    );
  }
}

class _BalanceStrip extends StatelessWidget {
  const _BalanceStrip();

  @override
  Widget build(BuildContext context) {
    return DsCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          _BalanceCell(label: 'Balance', value: '184,500'),
          _Divider(),
          _BalanceCell(label: 'Held', value: '12,000', tone: DsTone.info),
          _Divider(),
          _BalanceCell(label: 'Available', value: '172,500'),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 40,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.stepMd),
      color: context.colors.outline,
    );
  }
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
    final highlight = tone == DsTone.info
        ? context.status.info
        : context.colors.onSurface;
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
              color: tone == DsTone.info
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
                color: highlight,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AccentChip extends StatelessWidget {
  const _AccentChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
      decoration: BoxDecoration(
        color: context.palette.accentSoft,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(color: context.colors.primary),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: context.colors.primary,
        ),
      ),
    );
  }
}

class _ResetChip extends StatelessWidget {
  const _ResetChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(color: context.colors.outline),
      ),
      child: Text(
        'Reset',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: context.colors.primary,
        ),
      ),
    );
  }
}

class _DaySection extends StatelessWidget {
  const _DaySection({required this.label, required this.entries});

  final String label;
  final List<_LedgerEntry> entries;

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
              for (var i = 0; i < entries.length; i++) ...[
                _LedgerRow(entry: entries[i]),
                if (i != entries.length - 1) const DsHairline(),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _LedgerRow extends StatelessWidget {
  const _LedgerRow({required this.entry});

  final _LedgerEntry entry;

  @override
  Widget build(BuildContext context) {
    final (_, foreground) = dsToneColors(context, entry.tone);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 13),
      child: Row(
        children: [
          DsIconMedallion(
            icon: entry.icon,
            tone: entry.tone,
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
                  entry.who,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  entry.meta,
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
                entry.amount,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: foreground,
                ),
              ),
              Text(
                entry.after,
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

/// Board 04 · C2 — Filter sheet and date range.
class LedgerFilterScreen extends StatefulWidget {
  const LedgerFilterScreen({super.key});

  @override
  State<LedgerFilterScreen> createState() => _LedgerFilterScreenState();
}

class _LedgerFilterScreenState extends State<LedgerFilterScreen> {
  String _direction = 'Credits';
  final _types = <String>{'Send Cash', 'QR prize'};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A).withValues(alpha: 0.45),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            DsSheet(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Filter ledger', style: context.texts.titleLarge),
                      Text(
                        'Reset all',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: context.colors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const _FilterGroupLabel('Date range'),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: const [
                      DsFilterChip(label: 'This month', selected: true),
                      DsFilterChip(label: '01 Aug – 09 Sep'),
                      DsFilterChip(label: 'Custom'),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const _FilterGroupLabel('Direction'),
                  DsSegmentedControl(
                    options: const ['All', 'Credits', 'Debits'],
                    value: _direction,
                    onChanged: (v) => setState(() => _direction = v),
                  ),
                  const SizedBox(height: 18),
                  const _FilterGroupLabel('Type'),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      for (final type in const [
                        'Send Cash',
                        'Cash Request',
                        'QR prize',
                        'Spin prize',
                        'Returned',
                        'CRM adjustment',
                      ])
                        DsFilterChip(
                          label: type,
                          selected: _types.contains(type),
                          onTap: () => setState(() {
                            _types.contains(type)
                                ? _types.remove(type)
                                : _types.add(type);
                          }),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  DsButton(
                    label: 'Show Transactions',
                    onPressed: () => Navigator.of(context).maybePop(),
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

class _FilterGroupLabel extends StatelessWidget {
  const _FilterGroupLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        label,
        style: context.texts.labelLarge?.copyWith(
          color: context.colors.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// Board 04 · C3 — PDF export: progress, ready, and the failure case.
class LedgerExportScreen extends StatelessWidget {
  const LedgerExportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DsScreen(
      appBar: DsAppBar(
        title: 'Download Ledger',
        onBack: () => Navigator.of(context).maybePop(),
      ),
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      gap: AppSpacing.md,
      sections: [
        DsCard(
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
                      'Generating PDF',
                      style: context.texts.bodyLarge?.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              const DsBody('01 Aug – 09 Sep · credits only · 34 transactions'),
            ],
          ),
        ),
        DsCard(
          child: Row(
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
                      'Ledger_Aug01-Sep09.pdf',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.texts.bodyLarge?.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const DsCaption('218 KB · ready to share'),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              DsIconButton(icon: LucideIcons.share2, onPressed: () {}),
            ],
          ),
        ),
        DsCard(
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
                      'Could not create the PDF',
                      style: context.texts.bodyLarge?.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.stepMd),
              const DsBody(
                'The connection dropped while the file was being made. Your '
                'filters are still applied — try again.',
              ),
              const SizedBox(height: AppSpacing.stepMd),
              DsButton(
                label: 'Try Again',
                variant: DsButtonVariant.secondary,
                size: DsButtonSize.sm,
                icon: LucideIcons.refreshCw,
                onPressed: () {},
              ),
            ],
          ),
        ),
        const DsCaption(
          "Sharing uses your phone's own share sheet — WhatsApp, email, Drive, "
          'or anything else installed.',
        ),
      ],
    );
  }
}

/// Board 04 · C4 — Empty, filtered-empty and error, shown together.
class LedgerEmptyStatesScreen extends StatelessWidget {
  const LedgerEmptyStatesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DsScreen(
      appBar: DsAppBar(
        title: 'View Ledger',
        onBack: () => Navigator.of(context).maybePop(),
      ),
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      gap: AppSpacing.md,
      sections: [
        DsCard(
          padding: EdgeInsets.zero,
          child: DsEmptyState(
            icon: LucideIcons.receiptText,
            title: 'No Transactions Yet',
            message:
                'Money you send or receive will appear here with its date, '
                'counterparty and running balance.',
            actionLabel: 'Send Cash',
            onAction: () {},
          ),
        ),
        DsCard(
          padding: EdgeInsets.zero,
          child: DsEmptyState(
            icon: LucideIcons.filterX,
            title: 'Nothing Matches These Filters',
            message:
                'No credits between 01 Aug and 09 Sep. Widen the date range or '
                'clear the direction filter.',
            actionLabel: 'Reset Filters',
            onAction: () {},
          ),
        ),
        const DsCard(
          padding: EdgeInsets.zero,
          child: DsEmptyState(
            icon: LucideIcons.cloudOff,
            title: 'Ledger Did Not Load',
            message:
                'Crown Solar did not respond. Your balance and transactions '
                'are safe — this is a connection problem.',
          ),
        ),
      ],
    );
  }
}
