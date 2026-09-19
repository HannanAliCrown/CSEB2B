import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../../core/ui/ds.dart';
import '../../../session/data/signed_in_user.dart';
import '../../../session/ui/session_controller.dart';
import '../../data/dashboard_repository.dart';
import '../widgets/home_widgets.dart';

/// Home for the signed-in partner.
///
/// Every value on this screen — the business name, the role, the balance, the
/// slides and the ticker — comes from the session and [DashboardRepository].
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    super.key,
    required this.onSendCash,
    required this.onViewLedger,
    required this.onScan,
    required this.onOpenModule,
  });

  final VoidCallback onSendCash;
  final VoidCallback onViewLedger;
  final VoidCallback onScan;

  /// Opens one of the "Everything else" tiles by its label.
  final ValueChanged<String> onOpenModule;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Dashboard? _dashboard;
  bool _balanceHidden = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final user = context.read<SessionController>().user;
    if (user == null) return;
    final loaded = await context.read<DashboardRepository>().load(user);
    if (!mounted) return;
    setState(() => _dashboard = loaded);
  }

  /// The modules a role actually has. An installer has no cash requests to
  /// approve and no points, so those tiles are absent rather than dimmed.
  List<HomeTile> _tilesFor(PartnerRole role) {
    final trade = role != PartnerRole.installer;
    return [
      HomeTile(
        label: 'Send Cash',
        icon: LucideIcons.banknoteArrowUp,
        onTap: widget.onSendCash,
      ),
      if (trade)
        HomeTile(
          label: 'Cash Request',
          icon: LucideIcons.handCoins,
          onTap: () => widget.onOpenModule('Cash Request'),
        ),
      HomeTile(
        label: 'View Ledger',
        icon: LucideIcons.receiptText,
        onTap: widget.onViewLedger,
      ),
      HomeTile(
        label: 'Shop Branding',
        icon: LucideIcons.store,
        onTap: () => widget.onOpenModule('Shop Branding'),
      ),
      HomeTile(
        label: 'Complaints',
        icon: LucideIcons.lifeBuoy,
        onTap: () => widget.onOpenModule('Complaints'),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<SessionController>().user;
    if (user == null) return const SizedBox.shrink();

    final dashboard = _dashboard;

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          HomeHeader(businessName: user.businessName, role: user.role.label),
          Expanded(
            child: dashboard == null
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView(
                      padding: const EdgeInsets.only(
                        top: 10,
                        bottom: AppSpacing.stepLg,
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.screenPadding,
                          ),
                          child: WalletBalanceCard(
                            amount: dashboard.balance.formatted,
                            hidden: _balanceHidden,
                            heldNote: dashboard.heldNote,
                            onToggleHidden: () => setState(
                              () => _balanceHidden = !_balanceHidden,
                            ),
                            onSendCash: widget.onSendCash,
                            onViewLedger: widget.onViewLedger,
                          ),
                        ),
                        if (dashboard.slides.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.md),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.screenPadding,
                            ),
                            child: HomePromoSlider(
                              eyebrow: dashboard.slides.first.eyebrow,
                              headline: dashboard.slides.first.headline,
                              slides: [
                                for (final slide in dashboard.slides)
                                  (
                                    eyebrow: slide.eyebrow,
                                    headline: slide.headline,
                                  ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: AppSpacing.md),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.screenPadding,
                          ),
                          child: ScanQrCta(
                            subtitle: dashboard.scanSubtitle,
                            onTap: widget.onScan,
                          ),
                        ),
                        if (dashboard.tickerMessages.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.md),
                          HomeTicker(
                            message: dashboard.tickerMessages.first,
                            messages: dashboard.tickerMessages,
                          ),
                        ],
                        const SizedBox(height: AppSpacing.md),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.screenPadding,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Everything else',
                                style: context.texts.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.stepMd),
                              HomeTileGrid(tiles: _tilesFor(user.role)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
