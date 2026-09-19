import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../core/ui/ds.dart';
import '../../features/chat/data/chat_repository.dart';
import '../../features/chat/ui/views/chat_list_tab.dart';
import '../../features/home/ui/views/dashboard_screen.dart';
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
    required this.onSignOut,
    required this.onShowQrCode,
    required this.onSyncContacts,
    required this.onNewConversation,
    required this.onOpenThread,
    required this.onOpenPost,
  });

  final VoidCallback onSendCash;
  final VoidCallback onViewLedger;
  final VoidCallback onScan;
  final VoidCallback onSignOut;
  final VoidCallback onShowQrCode;
  final VoidCallback onSyncContacts;
  final VoidCallback onNewConversation;
  final ValueChanged<ChatParty> onOpenThread;
  final ValueChanged<SpacePost> onOpenPost;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  String _tab = 'home';

  /// Installers and retailers earn prizes, so their third destination is
  /// Inaam; the trade roles track Points instead.
  List<DsNavItem> _navFor(PartnerRole role) => [
    const DsNavItem(id: 'home', label: 'Home', icon: LucideIcons.house),
    const DsNavItem(
      id: 'space',
      label: 'Space',
      icon: LucideIcons.messagesSquare,
    ),
    if (role.earnsPrizes)
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
          onOpenModule: _comingSoon,
        ),
        'space' => SpaceFeedTab(onOpenPost: widget.onOpenPost),
        'chat' => ChatListTab(
          onNewConversation: widget.onNewConversation,
          onOpenThread: widget.onOpenThread,
        ),
        'profile' => ProfileTab(
          onShowQrCode: widget.onShowQrCode,
          onSyncContacts: widget.onSyncContacts,
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
