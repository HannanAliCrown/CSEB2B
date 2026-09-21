import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../../core/ui/ds.dart';
import '../../../session/data/signed_in_user.dart';
import '../../../session/ui/session_controller.dart';
import '../../../wallet/data/cash_requests_service.dart';
import '../../../wallet/data/wallet_repository.dart';
import '../../../complaints/data/complaints_service.dart';
import '../../../profile_requests/data/profile_requests_service.dart';
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
    required this.onComplaints,
    required this.onNotifications,
    required this.onProfileRequests,
    required this.onCashRequests,
    required this.onOpenModule,
  });

  final VoidCallback onSendCash;
  final VoidCallback onViewLedger;
  final VoidCallback onScan;
  final VoidCallback onComplaints;
  final VoidCallback onNotifications;

  /// Opens the buying source's inbox of registrations to verify. Awaited so
  /// the badge is recounted when the partner comes back.
  final Future<void> Function() onProfileRequests;

  /// Opens the inbox of transfers waiting on this partner.
  final Future<void> Function() onCashRequests;

  /// Opens one of the "Everything else" tiles by its label.
  final ValueChanged<String> onOpenModule;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Dashboard? _dashboard;
  bool _balanceHidden = true;

  /// Whether the bell shows its dot. Counted from the partner's own
  /// notifications rather than assumed, so a cleared list clears the dot.
  int _unread = 0;

  /// Registrations waiting on this partner to verify them. Zero for an
  /// installer, who nobody buys from.
  int _profileRequests = 0;

  /// Cash already out of someone's wallet, waiting on this partner.
  int _cashRequests = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _load();
      // A scan prize or a transfer made on another screen changes the
      // balance behind this one, so Home reloads rather than going stale.
      context.read<WalletRepository>().changes.addListener(_load);
    });
  }

  @override
  void dispose() {
    context.read<WalletRepository>().changes.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    final user = context.read<SessionController>().user;
    if (user == null) return;
    // Both are taken before the first await: reading a provider off a
    // context afterwards reaches through a widget that may be gone.
    final repository = context.read<DashboardRepository>();
    final complaints = context.read<ComplaintsService>();
    final requests = context.read<ProfileRequestsService>();
    final cash = context.read<CashRequestsService>();

    final loaded = await repository.load(user);
    final notifications = await complaints.notifications(user.mobileNumber);
    // Only the roles that sell on have anyone to verify.
    final waiting = user.role == PartnerRole.installer
        ? 0
        : await requests.outstandingCount(user.mobileNumber);
    final cashWaiting = user.role == PartnerRole.installer
        ? 0
        : await cash.waitingCount(user.mobileNumber);
    if (!mounted) return;
    setState(() {
      _dashboard = loaded;
      _unread = notifications?.unread ?? 0;
      _profileRequests = waiting;
      _cashRequests = cashWaiting;
    });
  }

  /// The modules a role actually has (board 03 · A1–A4).
  ///
  /// An installer has nobody buying from them, so they have no cash requests
  /// to approve and no profiles to verify — those tiles are absent rather
  /// than dimmed. The trade roles sell on, so they get both.
  List<HomeTile> _tilesFor(PartnerRole role) {
    final sellsOn = role != PartnerRole.installer;
    return [
      HomeTile(
        label: 'Send Cash',
        icon: LucideIcons.banknoteArrowUp,
        onTap: widget.onSendCash,
      ),
      if (sellsOn)
        HomeTile(
          label: 'Cash Request',
          icon: LucideIcons.handCoins,
          // Counted, not guessed: no badge at all when nothing is waiting.
          badge: _cashRequests == 0 ? null : _cashRequests,
          onTap: () async {
            await widget.onCashRequests();
            await _load();
          },
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
      if (sellsOn)
        HomeTile(
          label: 'New Profile',
          icon: LucideIcons.userPlus,
          // Counted, not guessed: no badge at all when nothing is waiting.
          badge: _profileRequests == 0 ? null : _profileRequests,
          onTap: () async {
            await widget.onProfileRequests();
            await _load();
          },
        ),
      HomeTile(
        label: 'Complaints',
        icon: LucideIcons.lifeBuoy,
        onTap: widget.onComplaints,
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
          HomeHeader(
            businessName: user.businessName,
            role: user.role.label,
            hasUnread: _unread > 0,
            onNotifications: () async {
              widget.onNotifications();
              // Reading a notification clears its dot, so the badge is
              // recounted when the partner comes back.
              await _load();
            },
          ),
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
                                    imageUrl: slide.imageUrl,
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
                            message: dashboard.tickerMessages.first.text,
                            messages: [
                              for (final message in dashboard.tickerMessages)
                                message.text,
                            ],
                            // The line runs as one, so the first message's
                            // colours are the line's colours.
                            textColour:
                                dashboard.tickerMessages.first.textColour,
                            backgroundColour:
                                dashboard.tickerMessages.first.backgroundColour,
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
