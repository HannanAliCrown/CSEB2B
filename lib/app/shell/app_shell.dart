import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../core/ui/ds.dart';
import '../../features/chat/data/chat_repository.dart';
import '../../features/chat/ui/views/chat_list_tab.dart';
import '../../features/home/ui/views/dashboard_screen.dart';
import '../../features/inaam_baazar/ui/views/inaam_tab.dart';
import '../../features/points/ui/views/points_tab.dart';
import '../../features/profile/ui/views/profile_tab.dart';
import '../../features/session/data/signed_in_user.dart';
import '../../features/session/ui/session_controller.dart';
import '../../features/space/data/space_repository.dart';
import '../../features/space/ui/views/space_feed_tab.dart';

/// The signed-in app: five destinations behind one bottom bar.
///
/// Only Home is built out so far; the rest state plainly that they are next
/// rather than showing a mock that cannot be used.
class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    required this.onSendCash,
    required this.onViewLedger,
    required this.onScan,
    required this.onComplaints,
    required this.onNotifications,
    required this.onProfileRequests,
    required this.onCashRequests,
    required this.onSendPoints,
    required this.onViewTargets,
    required this.onPointsLedger,
    required this.onSignOut,
    required this.onShowQrCode,
    required this.onSyncContacts,
    required this.onNewConversation,
    required this.onOpenThread,
    required this.onOpenPost,
    required this.onOpenSetting,
    required this.onShopBranding,
  });

  final VoidCallback onSendCash;
  final VoidCallback onViewLedger;
  final VoidCallback onScan;
  final VoidCallback onComplaints;
  final VoidCallback onNotifications;
  final Future<void> Function() onProfileRequests;
  final Future<void> Function() onCashRequests;

  /// The three places the Points hub leads. Each is awaited, so the hub
  /// reloads rather than showing a balance from before the partner left it.
  final Future<void> Function() onSendPoints;
  final Future<void> Function() onViewTargets;
  final Future<void> Function() onPointsLedger;
  final VoidCallback onSignOut;
  final VoidCallback onShowQrCode;
  final VoidCallback onSyncContacts;
  final VoidCallback onNewConversation;
  final ValueChanged<ChatParty> onOpenThread;
  final ValueChanged<SpacePost> onOpenPost;
  final Future<void> Function(String route) onOpenSetting;

  /// Shop Branding, reached from Home's tile.
  final Future<void> Function() onShopBranding;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  String _tab = 'home';

  /// The third destination, which is the only one that differs by role
  /// (board 03 · A1–A4): Inaam for an installer, Points for everyone who
  /// sells on.
  ///
  /// Not [PartnerRoleX.earnsPrizes] — a retailer earns scan prizes and still
  /// belongs on Points, so the two questions are kept apart.
  List<DsNavItem> _navFor(PartnerRole role) => [
    const DsNavItem(id: 'home', label: 'Home', icon: LucideIcons.house),
    const DsNavItem(
      id: 'space',
      label: 'Space',
      icon: LucideIcons.messagesSquare,
    ),
    if (role == PartnerRole.installer)
      const DsNavItem(id: 'inaam', label: 'Inaam', icon: LucideIcons.gift)
    else
      const DsNavItem(id: 'points', label: 'Points', icon: LucideIcons.award),
    const DsNavItem(id: 'chat', label: 'Chat', icon: LucideIcons.messageCircle),
    const DsNavItem(id: 'profile', label: 'Profile', icon: LucideIcons.user),
  ];

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();
    final user = session.user;
    if (user == null) return const Scaffold(body: SizedBox.shrink());

    final nav = _navFor(user.role);

    return Scaffold(
      body: switch (_tab) {
        'home' => DashboardScreen(
          onSendCash: widget.onSendCash,
          onViewLedger: widget.onViewLedger,
          onScan: widget.onScan,
          onComplaints: widget.onComplaints,
          onNotifications: widget.onNotifications,
          onProfileRequests: widget.onProfileRequests,
          onCashRequests: widget.onCashRequests,
          onOpenModule: _openModule,
        ),
        'space' => SpaceFeedTab(onOpenPost: widget.onOpenPost),
        'inaam' => InaamTab(onOpenScanner: widget.onScan),
        'points' => PointsTab(
          onSendPoints: widget.onSendPoints,
          onViewTargets: widget.onViewTargets,
          onSeeAllEntries: widget.onPointsLedger,
        ),
        'chat' => ChatListTab(
          onNewConversation: widget.onNewConversation,
          onOpenThread: widget.onOpenThread,
        ),
        'profile' => ProfileTab(
          onShowQrCode: widget.onShowQrCode,
          onSyncContacts: widget.onSyncContacts,
          onOpenSetting: widget.onOpenSetting,
          onSignOut: () async {
            await context.read<SessionController>().signOut();
            widget.onSignOut();
          },
        ),
        _ => _NotBuiltYet(
          label: nav.firstWhere((item) => item.id == _tab).label,
        ),
      },
      bottomNavigationBar: DsBottomNav(
        items: nav,
        activeId: _tab,
        onChanged: (id) => setState(() => _tab = id),
      ),
    );
  }

  /// Home's tiles name their module rather than carrying a callback each.
  /// Shop Branding is built; the rest still say so plainly.
  void _openModule(String module) {
    if (module == 'Shop Branding') {
      widget.onShopBranding();
      return;
    }
    _comingSoon(module);
  }

  void _comingSoon(String module) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('$module is not built yet.')));
  }
}

/// A destination that has not been built, said plainly.
class _NotBuiltYet extends StatelessWidget {
  const _NotBuiltYet({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: DsEmptyState(
            title: '$label is not built yet',
            message:
                'The installer dashboard came first. This destination is '
                'still to come.',
            icon: LucideIcons.hammer,
          ),
        ),
      ),
    );
  }
}
