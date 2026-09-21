import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../../core/ui/ds.dart';
import '../../../session/ui/session_controller.dart';
import '../../data/complaints_service.dart';

/// Board 08 · B2 — the notification centre the bell on Home opens.
///
/// Each line says what happened and where tapping it lands. Reading one
/// marks it read; nothing here changes anything else.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key, required this.onOpenDestination});

  /// Follows a notification's deep link. Returns false when that screen is
  /// not built yet, so this screen can say so instead of doing nothing.
  final Future<bool> Function(String route) onOpenDestination;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  NotificationList? _list;
  bool _reachable = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final user = context.read<SessionController>().user;
    if (user == null) return;
    final loaded = await context.read<ComplaintsService>().notifications(
      user.mobileNumber,
    );
    if (!mounted) return;
    setState(() {
      _list = loaded ?? NotificationList.empty;
      _reachable = loaded != null;
    });
  }

  Future<void> _open(AppNotification notification) async {
    final user = context.read<SessionController>().user;
    if (user == null) return;

    // Read first, and whatever happens next: the partner has seen it.
    if (!notification.read) {
      await context.read<ComplaintsService>().markRead(
        mobileNumber: user.mobileNumber,
        id: notification.id,
      );
      await _load();
    }
    if (!mounted) return;

    final route = notification.destinationRoute;
    if (route == null || !await widget.onOpenDestination(route)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${notification.destinationName} is not built yet.'),
        ),
      );
      return;
    }
    await _load();
  }

  Future<void> _markAllRead() async {
    final user = context.read<SessionController>().user;
    if (user == null) return;
    await context.read<ComplaintsService>().markRead(
      mobileNumber: user.mobileNumber,
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final list = _list;

    if (list == null) {
      return Scaffold(
        appBar: DsAppBar(
          title: 'Notifications',
          onBack: () => Navigator.of(context).maybePop(),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return DsScreen(
      appBar: DsAppBar(
        title: 'Notifications',
        subtitle: list.unread == 0 ? null : '${list.unread} unread',
        onBack: () => Navigator.of(context).maybePop(),
        actions: [
          if (list.unread > 0)
            DsIconButton(
              icon: LucideIcons.checkCheck,
              tooltip: 'Mark all read',
              onPressed: _markAllRead,
            ),
        ],
      ),
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      gap: AppSpacing.stepMd,
      sections: [
        if (list.notifications.isEmpty)
          DsEmptyState(
            icon: _reachable ? LucideIcons.bellOff : LucideIcons.cloudOff,
            title: _reachable
                ? 'Nothing to catch up on'
                : 'Could not reach Crown Solar',
            message: _reachable
                ? 'Prizes, cash requests and complaint updates appear here '
                      'as they happen.'
                : 'Your notifications are held by Crown Solar, not on this '
                      'phone. Check your connection and try again.',
          )
        else
          for (final notification in list.notifications)
            DsAlert(
              title: notification.title,
              message: notification.body,
              timestamp: notification.timestampLine,
              unread: !notification.read,
              level: switch (notification.level) {
                'success' => DsAlertLevel.success,
                'warning' => DsAlertLevel.warning,
                'critical' => DsAlertLevel.critical,
                _ => DsAlertLevel.info,
              },
              onTap: () => _open(notification),
            ),
      ],
    );
  }
}
