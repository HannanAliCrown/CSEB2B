import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../../core/ui/ds.dart';
import '../../../session/ui/session_controller.dart';
import '../../data/chat_repository.dart';

/// Board 10 · A4 — the conversation list, filtered by All / Read / Unread.
class ChatListTab extends StatefulWidget {
  const ChatListTab({
    super.key,
    required this.onNewConversation,
    required this.onOpenThread,
  });

  final VoidCallback onNewConversation;
  final ValueChanged<ChatParty> onOpenThread;

  @override
  State<ChatListTab> createState() => _ChatListTabState();
}

class _ChatListTabState extends State<ChatListTab> {
  String _tab = 'All';
  List<ChatThread> _threads = const [];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _load();
      // A message sent from the conversation screen reorders this list.
      context.read<ChatRepository>().changes.addListener(_load);
    });
  }

  @override
  void dispose() {
    context.read<ChatRepository>().changes.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    final user = context.read<SessionController>().user;
    if (user == null) return;
    final threads = await context.read<ChatRepository>().threads(user);
    if (!mounted) return;
    setState(() {
      _threads = threads;
      _loaded = true;
    });
  }

  List<ChatThread> get _visible => switch (_tab) {
    'Unread' => _threads.where((t) => t.hasUnread).toList(),
    'Read' => _threads.where((t) => !t.hasUnread).toList(),
    _ => _threads,
  };

  @override
  Widget build(BuildContext context) {
    final threads = _visible;

    return Scaffold(
      appBar: DsAppBar(
        title: 'Chat',
        actions: [
          DsIconButton(
            icon: LucideIcons.squarePen,
            onPressed: widget.onNewConversation,
          ),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DsTabs(
              tabs: const ['All', 'Read', 'Unread'],
              value: _tab,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPadding,
              ),
              onChanged: (tab) => setState(() => _tab = tab),
            ),
            Expanded(
              child: !_loaded
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      padding: const EdgeInsets.all(AppSpacing.screenPadding),
                      children: [
                        if (threads.isEmpty)
                          DsCard(
                            padding: EdgeInsets.zero,
                            child: DsEmptyState(
                              icon: LucideIcons.messageCircle,
                              title: _tab == 'All'
                                  ? 'No conversations yet'
                                  : 'Nothing $_tab',
                              message: _tab == 'All'
                                  ? 'Start a chat with a contact, scan '
                                        "someone's profile QR, or message a "
                                        'Crown Solar department.'
                                  : 'Every conversation is in the other tab.',
                              actionLabel: _tab == 'All'
                                  ? 'New Conversation'
                                  : null,
                              onAction: _tab == 'All'
                                  ? widget.onNewConversation
                                  : null,
                            ),
                          )
                        else
                          DsCard(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                            ),
                            child: Column(
                              children: [
                                for (var i = 0; i < threads.length; i++) ...[
                                  _ThreadRow(
                                    thread: threads[i],
                                    onTap: () =>
                                        widget.onOpenThread(threads[i].party),
                                  ),
                                  if (i != threads.length - 1)
                                    const DsHairline(),
                                ],
                              ],
                            ),
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

class _ThreadRow extends StatelessWidget {
  const _ThreadRow({required this.thread, required this.onTap});

  final ChatThread thread;
  final VoidCallback onTap;

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

  /// "9:20 AM" today, "Yesterday", then "07 Sep".
  String _when(DateTime at) {
    final now = DateTime.now();
    final days = DateTime(
      now.year,
      now.month,
      now.day,
    ).difference(DateTime(at.year, at.month, at.day)).inDays;

    if (days == 0) {
      final hour = at.hour % 12 == 0 ? 12 : at.hour % 12;
      return '$hour:${at.minute.toString().padLeft(2, '0')} '
          '${at.hour < 12 ? 'AM' : 'PM'}';
    }
    if (days == 1) return 'Yesterday';
    return '${at.day.toString().padLeft(2, '0')} ${_months[at.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final latest = thread.latest;
    // "You:" makes it obvious who spoke last, as every chat list does.
    final preview = latest == null
        ? 'No messages yet'
        : '${latest.mine ? 'You: ' : ''}${latest.text}';

    return DsPartyRow(
      name: thread.party.name,
      meta: preview,
      // Departments are tinted so a Crown Solar team is never mistaken for
      // another partner.
      avatarColor: thread.party.isDepartment ? context.status.infoFill : null,
      onTap: onTap,
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            latest == null ? '' : _when(latest.sentAt),
            style: TextStyle(fontSize: 11, color: context.palette.textTertiary),
          ),
          const SizedBox(height: 4),
          if (thread.hasUnread)
            Container(
              constraints: const BoxConstraints(minWidth: 20),
              height: 20,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: context.colors.primary,
                borderRadius: BorderRadius.circular(AppRadii.pill),
              ),
              child: Text(
                '${thread.unread}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
