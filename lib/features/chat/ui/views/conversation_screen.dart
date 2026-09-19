import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../../core/ui/ds.dart';
import '../../../session/ui/session_controller.dart';
import '../../data/chat_repository.dart';

/// Board 10 · B2 — one conversation: the messages, and the composer.
class ConversationScreen extends StatefulWidget {
  const ConversationScreen({super.key, required this.party});

  final ChatParty party;

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  final _composer = TextEditingController();
  final _scroll = ScrollController();

  ChatThread? _thread;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _open());
  }

  @override
  void dispose() {
    _composer.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _open() async {
    final user = context.read<SessionController>().user;
    if (user == null) return;
    // Opening a conversation is what clears its unread badge.
    await context.read<ChatRepository>().markRead(user, widget.party);
    await _reload();
  }

  /// Re-reads the conversation rather than trusting the copy this screen was
  /// handed: a message sent over HTTP comes back as a new thread, not a
  /// mutated one.
  Future<void> _reload() async {
    final user = context.read<SessionController>().user;
    if (user == null) return;

    final thread = await context.read<ChatRepository>().openWith(
      user,
      widget.party,
    );
    if (!mounted) return;
    setState(() => _thread = thread);
    _scrollToEnd();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.jumpTo(_scroll.position.maxScrollExtent);
    });
  }

  Future<void> _send() async {
    final text = _composer.text.trim();
    if (text.isEmpty) return;

    final user = context.read<SessionController>().user;
    if (user == null) return;

    _composer.clear();
    await context.read<ChatRepository>().send(
      user: user,
      party: widget.party,
      text: text,
    );
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    final thread = _thread;
    final messages = thread?.messages ?? const <ChatMessage>[];

    return Scaffold(
      appBar: DsAppBar(
        title: widget.party.name,
        subtitle: widget.party.isDepartment
            ? 'Usually replies within an hour'
            : widget.party.subtitle,
        onBack: () => Navigator.of(context).maybePop(),
      ),
      body: Column(
        children: [
          Expanded(
            child: thread == null
                ? const Center(child: CircularProgressIndicator())
                : messages.isEmpty
                ? DsEmptyState(
                    icon: LucideIcons.messageCircle,
                    title: 'No messages yet',
                    message: 'Say hello to ${widget.party.name}.',
                  )
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.all(AppSpacing.screenPadding),
                    itemCount: messages.length,
                    itemBuilder: (context, i) => _Bubble(message: messages[i]),
                  ),
          ),
          _Composer(controller: _composer, onSend: _send),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message});

  final ChatMessage message;

  String get _time {
    final at = message.sentAt;
    final hour = at.hour % 12 == 0 ? 12 : at.hour % 12;
    return '$hour:${at.minute.toString().padLeft(2, '0')} '
        '${at.hour < 12 ? 'AM' : 'PM'}';
  }

  /// Read receipts only make sense on messages the partner sent.
  String? get _status => !message.mine
      ? null
      : switch (message.status) {
          MessageStatus.sending => 'Sending',
          MessageStatus.sent => 'Sent',
          MessageStatus.delivered => 'Delivered',
          MessageStatus.read => 'Read',
        };

  @override
  Widget build(BuildContext context) {
    final mine = message.mine;
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
              message.text,
              style: TextStyle(
                fontSize: 14,
                height: 20 / 14,
                color: mine ? Colors.white : context.colors.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _status == null ? _time : '$_time · $_status',
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

class _Composer extends StatelessWidget {
  const _Composer({required this.controller, required this.onSend});

  final TextEditingController controller;
  final VoidCallback onSend;

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
            Expanded(
              child: Container(
                constraints: const BoxConstraints(minHeight: 44),
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                decoration: BoxDecoration(
                  color: context.palette.sunken,
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                ),
                child: TextField(
                  controller: controller,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => onSend(),
                  style: context.texts.bodyMedium,
                  decoration: InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    hintText: 'Message',
                    hintStyle: TextStyle(
                      fontSize: 14,
                      color: context.palette.textTertiary,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.stepMd),
            GestureDetector(
              onTap: onSend,
              child: Container(
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
            ),
          ],
        ),
      ),
    );
  }
}
