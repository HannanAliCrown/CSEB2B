import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../../core/ui/ds.dart';
import '../../../session/ui/session_controller.dart';
import '../../data/space_repository.dart';
import 'space_feed_tab.dart';

/// Board 10 · A2 — one post, its comments, and the replies under them.
///
/// A comment appears only once the repository has accepted it, never
/// optimistically: a partner should not see their own words and then lose
/// them.
class PostDetailScreen extends StatefulWidget {
  const PostDetailScreen({super.key, required this.post});

  final SpacePost post;

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final _composer = TextEditingController();
  final _focus = FocusNode();

  /// The comment being replied to, or null when writing a new comment.
  PostComment? _replyingTo;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SpaceRepository>().changes.addListener(_refresh);
    });
  }

  @override
  void dispose() {
    context.read<SpaceRepository>().changes.removeListener(_refresh);
    _composer.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  Future<void> _send() async {
    final body = _composer.text.trim();
    if (body.isEmpty || _sending) return;

    final user = context.read<SessionController>().user;
    if (user == null) return;

    setState(() => _sending = true);
    final repository = context.read<SpaceRepository>();
    final replyingTo = _replyingTo;

    if (replyingTo == null) {
      await repository.comment(postId: widget.post.id, user: user, body: body);
    } else {
      await repository.reply(
        postId: widget.post.id,
        commentId: replyingTo.id,
        user: user,
        body: body,
      );
    }

    if (!mounted) return;
    _composer.clear();
    setState(() {
      _sending = false;
      _replyingTo = null;
    });
  }

  void _startReply(PostComment comment) {
    setState(() => _replyingTo = comment);
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;

    return Scaffold(
      appBar: DsAppBar(
        title: 'Post',
        onBack: () => Navigator.of(context).maybePop(),
      ),
      // The composer sits in the body, as it does in a chat, so the keyboard
      // lifts it instead of covering it.
      body: Column(
        children: [
          Expanded(
            child: SafeArea(
              bottom: false,
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.screenPadding),
                children: [
                  PostCard(post: post, onComment: _focus.requestFocus),
                  const SizedBox(height: AppSpacing.md),
                  DsSectionHeader(
                    title: post.commentCount == 0
                        ? 'No comments yet'
                        : '${post.commentCount} comments',
                  ),
                  if (post.comments.isEmpty)
                    const DsEmptyState(
                      icon: LucideIcons.messageSquare,
                      title: 'Be the first to comment',
                      message:
                          'Ask a question or tell Crown Solar what you think.',
                    )
                  else
                    for (final comment in post.comments)
                      Padding(
                        padding: const EdgeInsets.only(
                          bottom: AppSpacing.stepMd,
                        ),
                        child: _CommentCard(
                          comment: comment,
                          onReply: () => _startReply(comment),
                        ),
                      ),
                ],
              ),
            ),
          ),
          _Composer(
            controller: _composer,
            focus: _focus,
            sending: _sending,
            replyingTo: _replyingTo?.author,
            onCancelReply: () => setState(() => _replyingTo = null),
            onSend: _send,
          ),
        ],
      ),
    );
  }
}

class _CommentCard extends StatelessWidget {
  const _CommentCard({required this.comment, required this.onReply});

  final PostComment comment;
  final VoidCallback onReply;

  @override
  Widget build(BuildContext context) {
    return DsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Author(
            name: comment.author,
            official: comment.official,
            postedAt: comment.postedAt,
            body: comment.body,
          ),
          const SizedBox(height: AppSpacing.sm),
          GestureDetector(
            onTap: onReply,
            child: Text(
              'Reply',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: context.colors.primary,
              ),
            ),
          ),
          if (comment.replies.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.stepMd),
            // Replies are indented under their comment, so a conversation
            // reads as one thread rather than a flat list.
            Padding(
              padding: const EdgeInsets.only(left: AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final reply in comment.replies) ...[
                    const DsHairline(),
                    const SizedBox(height: AppSpacing.stepMd),
                    _Author(
                      name: reply.author,
                      official: reply.official,
                      postedAt: reply.postedAt,
                      body: reply.body,
                    ),
                    const SizedBox(height: AppSpacing.stepMd),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Author extends StatelessWidget {
  const _Author({
    required this.name,
    required this.official,
    required this.postedAt,
    required this.body,
  });

  final String name;
  final bool official;
  final DateTime postedAt;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            DsAvatar(initials: DsPartyRow.initialsOf(name), size: 32),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                name,
                style: context.texts.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (official) const DsTag(label: 'Admin', tone: DsTone.accent),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        DsBody(body, size: 14),
        const SizedBox(height: AppSpacing.sm),
        DsCaption(PostCard.ago(postedAt)),
      ],
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.focus,
    required this.sending,
    required this.replyingTo,
    required this.onCancelReply,
    required this.onSend,
  });

  final TextEditingController controller;
  final FocusNode focus;
  final bool sending;
  final String? replyingTo;
  final VoidCallback onCancelReply;
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (replyingTo != null) ...[
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Replying to $replyingTo',
                      style: TextStyle(
                        fontSize: 12,
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: onCancelReply,
                    child: Icon(
                      LucideIcons.x,
                      size: 16,
                      color: context.palette.textTertiary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            Row(
              children: [
                Expanded(
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 44),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ),
                    decoration: BoxDecoration(
                      color: context.palette.sunken,
                      borderRadius: BorderRadius.circular(AppRadii.pill),
                    ),
                    child: TextField(
                      controller: controller,
                      focusNode: focus,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => onSend(),
                      style: context.texts.bodyMedium,
                      decoration: InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        hintText: replyingTo == null
                            ? 'Write a comment'
                            : 'Write a reply',
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
                    child: sending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(
                            LucideIcons.send,
                            size: 20,
                            color: Colors.white,
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
