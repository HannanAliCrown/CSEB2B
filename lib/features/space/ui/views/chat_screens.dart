import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/ui/ds.dart';
import '../../../home/ui/models/home_demo_data.dart';

/// Board 10 · A4 — Chat list, filtered by All / Read / Unread.
class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key, this.empty = false});

  /// B4 shows the same screen with no conversations.
  final bool empty;

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  String _tab = 'All';

  static const _threads = [
    (
      'CRM · Crown Solar',
      'We are checking both scans against the record.',
      '9:20 AM',
      2,
      true,
    ),
    ('Bilal Traders', 'Bhai, panels ka rate kya hai aaj?', '8:47 AM', 3, false),
    (
      'Branding · Crown Solar',
      'Supplier will call you before 12 Sep.',
      'Yesterday',
      0,
      true,
    ),
    (
      'Hamza Solar House',
      'You: points bhej diye hain, check karein',
      'Yesterday',
      0,
      false,
    ),
    ('Adnan Solar Works', 'Photo', '07 Sep', 2, false),
    ('Technical Support', 'Inverter manual bhej diya hai.', '05 Sep', 0, true),
  ];

  @override
  Widget build(BuildContext context) {
    final threads = widget.empty ? _threads.take(2).toList() : _threads;

    return Scaffold(
      appBar: DsAppBar(
        title: 'Chat',
        onBack: () => Navigator.of(context).maybePop(),
        actions: [DsIconButton(icon: LucideIcons.squarePen, onPressed: () {})],
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
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.screenPadding),
                children: [
                  DsCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ),
                    child: Column(
                      children: [
                        for (var i = 0; i < threads.length; i++) ...[
                          DsPartyRow(
                            name: threads[i].$1,
                            meta: threads[i].$2,
                            avatarColor: threads[i].$5
                                ? context.status.infoFill
                                : null,
                            trailing: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  threads[i].$3,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: context.palette.textTertiary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                if (threads[i].$4 > 0)
                                  Container(
                                    constraints: const BoxConstraints(
                                      minWidth: 20,
                                    ),
                                    height: 20,
                                    alignment: Alignment.center,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: context.colors.primary,
                                      borderRadius: BorderRadius.circular(
                                        AppRadii.pill,
                                      ),
                                    ),
                                    child: Text(
                                      '${threads[i].$4}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            onTap: () {},
                          ),
                          if (i != threads.length - 1) const DsHairline(),
                        ],
                      ],
                    ),
                  ),
                  if (widget.empty) ...[
                    const SizedBox(height: AppSpacing.md),
                    DsCard(
                      padding: EdgeInsets.zero,
                      child: DsEmptyState(
                        icon: LucideIcons.messageCircle,
                        title: 'No Conversations Yet',
                        message:
                            "Start a chat with a contact, scan someone's "
                            'profile QR, or message a Crown Solar department.',
                        actionLabel: 'New Conversation',
                        onAction: () {},
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: DsBottomNav(
        items: HomeDemo.retailer.nav,
        activeId: 'chat',
      ),
    );
  }
}

/// Board 10 · B1 — New conversation: three ways in, and the departments a
/// partner can always reach.
class NewConversationScreen extends StatelessWidget {
  const NewConversationScreen({super.key});

  static const _departments = [
    (
      'CRM',
      'Accounts, device changes, points adjustments',
      LucideIcons.headset,
    ),
    ('Branding', 'Shop branding requests and suppliers', LucideIcons.store),
    (
      'Technical Support',
      'Product and installation questions',
      LucideIcons.wrench,
    ),
    ('Accounts', 'Wallet, ledger and settlement queries', LucideIcons.wallet),
  ];

  @override
  Widget build(BuildContext context) {
    return DsScreen(
      appBar: DsAppBar(
        title: 'New Conversation',
        onBack: () => Navigator.of(context).maybePop(),
      ),
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      gap: AppSpacing.md,
      sections: [
        DsSegmentedControl(
          options: const ['Contacts', 'Scan QR', 'Departments'],
          value: 'Departments',
          onChanged: (_) {},
        ),
        const DsSectionHeader(title: 'Crown Solar departments'),
        DsCard(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Column(
            children: [
              for (var i = 0; i < _departments.length; i++) ...[
                DsSettingRow(
                  label: _departments[i].$1,
                  meta: _departments[i].$2,
                  leading: DsIconMedallion(
                    icon: _departments[i].$3,
                    size: 36,
                    iconSize: 18,
                    rounded: true,
                  ),
                  onTap: () {},
                ),
                if (i != _departments.length - 1) const DsHairline(),
              ],
            ],
          ),
        ),
        const DsCaption(
          'Only contacts already registered on Crown Solar Energy appear under '
          'Contacts. Numbers without an account are never stored.',
        ),
      ],
    );
  }
}

/// One chat bubble.
class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.text,
    required this.time,
    required this.mine,
    this.status,
  });

  final String text;
  final String time;
  final bool mine;
  final String? status;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 280),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: mine ? context.colors.primary : context.colors.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(AppRadii.lg),
            topRight: const Radius.circular(AppRadii.lg),
            bottomLeft: Radius.circular(mine ? AppRadii.lg : 4),
            bottomRight: Radius.circular(mine ? 4 : AppRadii.lg),
          ),
          border: mine ? null : Border.all(color: context.colors.outline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              style: TextStyle(
                fontSize: 14,
                height: 20 / 14,
                color: mine ? Colors.white : context.colors.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              status == null ? time : '$time · $status',
              style: TextStyle(
                fontSize: 11,
                color: mine
                    ? Colors.white.withValues(alpha: 0.75)
                    : context.palette.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Board 10 · B2 — A conversation: text, media upload progress and read
/// receipts.
class ConversationScreen extends StatelessWidget {
  const ConversationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: DsAppBar(
        title: 'CRM · Crown Solar',
        subtitle: 'Usually replies within an hour',
        onBack: () => Navigator.of(context).maybePop(),
      ),
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          children: [
            Center(child: DsTag(label: 'Today')),
            const SizedBox(height: AppSpacing.md),
            const _Bubble(
              text:
                  'My prize for the 6kW inverter scan has not come into my '
                  'wallet.',
              time: '9:02 AM',
              mine: true,
              status: 'Read',
            ),
            const _Bubble(
              text:
                  'Ticket CMP-2026-5514 is open for this. We are checking both '
                  'scans against the installation record.',
              time: '9:20 AM',
              mine: false,
            ),
            const _Bubble(
              text: 'Kitna time lagega?',
              time: '9:44 AM',
              mine: true,
            ),
            const _Bubble(
              text:
                  'By tomorrow evening. You will get a notification when it is '
                  'decided.',
              time: '9:46 AM',
              mine: false,
            ),
            const _Bubble(
              text: 'Theek hai, shukriya.',
              time: '9:47 AM',
              mine: true,
              status: 'Sent',
            ),
            const SizedBox(height: AppSpacing.sm),
            DsUploadRow(
              label: 'Photo of the board',
              meta: 'Uploading 62%',
              state: DsUploadState.uploading,
              progress: 0.62,
              icon: LucideIcons.image,
            ),
            const SizedBox(height: AppSpacing.stepMd),
            const DsUploadRow(
              label: 'Photo of the board',
              meta: 'Not sent',
              state: DsUploadState.failed,
              icon: LucideIcons.image,
            ),
          ],
        ),
      ),
      bottomNavigationBar: const _ChatComposer(),
    );
  }
}

class _ChatComposer extends StatelessWidget {
  const _ChatComposer();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.stepMd),
      decoration: BoxDecoration(
        color: context.colors.surface,
        border: Border(top: BorderSide(color: context.colors.outline)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Icon(
              LucideIcons.paperclip,
              size: 22,
              color: context.colors.onSurfaceVariant,
            ),
            const SizedBox(width: AppSpacing.stepMd),
            Expanded(
              child: Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                alignment: AlignmentDirectional.centerStart,
                decoration: BoxDecoration(
                  color: context.palette.sunken,
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                ),
                child: Text(
                  'Message',
                  style: TextStyle(
                    fontSize: 14,
                    color: context.palette.textTertiary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.stepMd),
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: context.colors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.send,
                size: 20,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Board 10 · B3 — Connection loss and a blocked recipient: messages queue,
/// and a deactivated account is explained rather than hidden.
class ConversationBlockedScreen extends StatelessWidget {
  const ConversationBlockedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: DsAppBar(
        title: 'Bilal Traders',
        subtitle: 'Reconnecting',
        onBack: () => Navigator.of(context).maybePop(),
      ),
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          children: [
            DsNotice(
              icon: LucideIcons.wifiOff,
              tone: DsTone.warning,
              message:
                  'No connection · messages will send when you are back '
                  'online',
              dense: true,
            ),
            const SizedBox(height: AppSpacing.md),
            const _Bubble(
              text: 'Bhai, panels ka rate kya hai aaj?',
              time: '7:02 PM',
              mine: false,
            ),
            const _Bubble(
              text: '550W ka rate WhatsApp per bhej raha hoon',
              time: '7:22 PM',
              mine: true,
              status: 'Waiting to send',
            ),
            const SizedBox(height: AppSpacing.md),
            DsCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const DsIconMedallion(
                        icon: LucideIcons.userX,
                        tone: DsTone.neutral,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'This person cannot receive messages',
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
                    'Their Crown Solar account is not active. You can still '
                    'see your earlier messages. Contact CRM if you need to '
                    'reach them.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.stepMd),
            const DsCaption(
              'Messages that arrive while you are offline come through as a '
              'push notification and open straight into the conversation.',
            ),
          ],
        ),
      ),
      bottomNavigationBar: const _ChatComposer(),
    );
  }
}
