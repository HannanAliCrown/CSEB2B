import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../../core/ui/ds.dart';
import '../../../session/ui/session_controller.dart';
import '../../data/points_service.dart';
import 'points_tab.dart';

/// The whole points ledger, which the hub's "See all" opens.
///
/// The same rows as the hub, unabridged. Points are never shown beside a
/// currency figure here either.
class PointsLedgerScreen extends StatefulWidget {
  const PointsLedgerScreen({super.key});

  @override
  State<PointsLedgerScreen> createState() => _PointsLedgerScreenState();
}

class _PointsLedgerScreenState extends State<PointsLedgerScreen> {
  PointsLedger? _ledger;
  bool _reachable = true;

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
              else
                DsCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  child: Column(
                    children: [
                      for (var i = 0; i < ledger.entries.length; i++) ...[
                        PointsLedgerRow(entry: ledger.entries[i]),
                        if (i != ledger.entries.length - 1) const DsHairline(),
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
}
