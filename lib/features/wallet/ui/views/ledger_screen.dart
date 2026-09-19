import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../../core/ui/ds.dart';
import '../../data/wallet_repository.dart';
import '../wallet_view_model.dart';

/// The wallet ledger: balance, then every movement, newest first.
///
/// Nothing here is written into the screen — the balance, the lines and the
/// held total all come from [WalletRepository].
class LedgerScreen extends StatefulWidget {
  const LedgerScreen({super.key});

  @override
  State<LedgerScreen> createState() => _LedgerScreenState();
}

class _LedgerScreenState extends State<LedgerScreen> {
  /// Which lines are shown. "Held" is worth its own tab — it is the money the
  /// partner is most likely to be asking about.
  String _filter = 'All';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<WalletViewModel>().load(),
    );
  }

  List<LedgerEntry> _visible(List<LedgerEntry> entries) => switch (_filter) {
    'Money in' => entries.where((e) => e.isCredit).toList(),
    'Money out' => entries.where((e) => !e.isCredit).toList(),
    'Held' => entries.where((e) => e.state == LedgerState.held).toList(),
    _ => entries,
  };

  @override
  Widget build(BuildContext context) {
    final wallet = context.watch<WalletViewModel>();
    final entries = _visible(wallet.entries);

    return Scaffold(
      appBar: DsAppBar(
        title: 'Ledger',
        subtitle: wallet.user.businessName,
        onBack: () => Navigator.of(context).maybePop(),
      ),
      body: wallet.busy && wallet.entries.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.screenPadding),
              children: [
                _BalanceSummary(wallet: wallet),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    for (final option in const [
                      'All',
                      'Money in',
                      'Money out',
                      'Held',
                    ])
                      Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.sm),
                        child: DsFilterChip(
                          label: option,
                          selected: _filter == option,
                          onTap: () => setState(() => _filter = option),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                if (entries.isEmpty)
                  const DsEmptyState(
                    title: 'Nothing here yet',
                    message:
                        'Movements appear as soon as money comes in or '
                        'goes out.',
                    icon: LucideIcons.receiptText,
                  )
                else
                  DsRowGroup(
                    children: [
                      for (final entry in entries) _LedgerRow(entry: entry),
                    ],
                  ),
              ],
            ),
    );
  }
}

class _BalanceSummary extends StatelessWidget {
  const _BalanceSummary({required this.wallet});

  final WalletViewModel wallet;

  @override
  Widget build(BuildContext context) {
    final held = wallet.entries
        .where((e) => e.state == LedgerState.held)
        .fold(const Money(0), (Money sum, e) => sum + e.amount);

    return DsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const DsCaption('AVAILABLE BALANCE'),
          const SizedBox(height: 4),
          Text(
            'PKR ${wallet.balance.formatted}',
            style: context.texts.headlineSmall,
          ),
          if (!held.isZero) ...[
            const SizedBox(height: AppSpacing.sm),
            DsNotice(
              icon: LucideIcons.clock,
              tone: DsTone.warning,
              dense: true,
              message:
                  'PKR ${held.formatted} is held until the partners you sent '
                  'it to accept it.',
            ),
          ],
        ],
      ),
    );
  }
}

class _LedgerRow extends StatelessWidget {
  const _LedgerRow({required this.entry});

  final LedgerEntry entry;

  /// "18 Sep" — enough to place a movement without a full timestamp.
  String get _day {
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
    return '${entry.postedAt.day} ${months[entry.postedAt.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final colour = entry.state == LedgerState.rejected
        ? context.palette.textTertiary
        : entry.isCredit
        ? context.status.success
        : context.colors.onSurface;

    return DsSettingRow(
      label: entry.title,
      meta: '$_day · ${entry.subtitle}',
      leading: DsIconMedallion(
        icon: entry.isCredit
            ? LucideIcons.arrowDownLeft
            : LucideIcons.arrowUpRight,
        tone: entry.isCredit ? DsTone.success : DsTone.info,
        size: 36,
        iconSize: 18,
        rounded: true,
      ),
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            entry.signedAmount,
            style: context.texts.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: colour,
            ),
          ),
          if (entry.state != LedgerState.cleared)
            Text(
              entry.state == LedgerState.held ? 'Held' : 'Rejected',
              style: context.texts.bodySmall?.copyWith(
                color: entry.state == LedgerState.held
                    ? context.status.warning
                    : context.colors.error,
              ),
            ),
        ],
      ),
    );
  }
}
