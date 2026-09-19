import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../core/ui/ds.dart';
import '../../features/home/ui/views/dashboard_screen.dart';
import '../../features/session/data/signed_in_user.dart';
import '../../features/session/ui/session_controller.dart';

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
  });

  final VoidCallback onSendCash;
  final VoidCallback onViewLedger;
  final VoidCallback onScan;
  final VoidCallback onSignOut;

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
        'profile' => _Profile(user: user, onSignOut: widget.onSignOut),
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

/// Enough Profile to see who is signed in and to leave.
class _Profile extends StatelessWidget {
  const _Profile({required this.user, required this.onSignOut});

  final SignedInUser user;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        children: [
          DsPartyRow(
            name: user.businessName,
            meta: '${user.role.label} · ${user.market}',
          ),
          const SizedBox(height: AppSpacing.md),
          DsCard(
            child: Column(
              children: [
                DsSettingRow(label: 'Contact', value: user.contactName),
                DsSettingRow(label: 'Mobile', value: user.mobileNumber),
                DsSettingRow(label: 'Market', value: user.market),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          DsButton(
            label: 'Sign Out',
            variant: DsButtonVariant.secondary,
            icon: LucideIcons.logOut,
            onPressed: () async {
              await context.read<SessionController>().signOut();
              onSignOut();
            },
          ),
        ],
      ),
    );
  }
}
