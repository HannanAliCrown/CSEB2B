import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/ui/ds.dart';
import '../../../session/ui/session_controller.dart';
import '../../data/space_repository.dart';

/// Board 10 · A1 — Space: what Crown Solar has posted, newest first.
class SpaceFeedTab extends StatefulWidget {
  const SpaceFeedTab({super.key, required this.onOpenPost});

  final ValueChanged<SpacePost> onOpenPost;

  @override
  State<SpaceFeedTab> createState() => _SpaceFeedTabState();
}

class _SpaceFeedTabState extends State<SpaceFeedTab> {
  List<SpacePost> _posts = const [];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _load();
      // A heart or comment added on the detail screen shows here too.
      context.read<SpaceRepository>().changes.addListener(_load);
    });
  }

  @override
  void dispose() {
    context.read<SpaceRepository>().changes.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    final user = context.read<SessionController>().user;
    if (user == null) return;
    final posts = await context.read<SpaceRepository>().feed(user);
    if (!mounted) return;
    setState(() {
      _posts = posts;
      _loaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const DsAppBar(
        title: 'Space',
        subtitle: 'News and events from Crown Solar',
      ),
      body: SafeArea(
        bottom: false,
        child: !_loaded
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _load,
                child: _posts.isEmpty
                    ? ListView(
                        padding: const EdgeInsets.all(AppSpacing.screenPadding),
                        children: const [
                          DsEmptyState(
                            icon: LucideIcons.newspaper,
                            title: 'Nothing posted yet',
                            message:
                                'Crown Solar posts product news and event '
                                'invitations here.',
                          ),
                        ],
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(AppSpacing.screenPadding),
                        itemCount: _posts.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: AppSpacing.md),
                        itemBuilder: (context, i) => PostCard(
                          post: _posts[i],
                          onTap: () => widget.onOpenPost(_posts[i]),
                        ),
                      ),
              ),
      ),
    );
  }
}

/// One post in the feed, with its reactions.
class PostCard extends StatelessWidget {
  const PostCard({super.key, required this.post, this.onTap, this.onComment});

  final SpacePost post;
  final VoidCallback? onTap;

  /// What the comment button does. In the feed it opens the post; on the
  /// post itself it puts the cursor in the composer.
  final VoidCallback? onComment;

  /// "4 hours ago" / "2 days ago" — relative, because a broadcast's age is
  /// what matters, not its timestamp.
  static String ago(DateTime when) {
    final gap = DateTime.now().difference(when);
    if (gap.inMinutes < 1) return 'Just now';
    if (gap.inHours < 1) return '${gap.inMinutes} minutes ago';
    if (gap.inDays < 1) {
      return '${gap.inHours} hour${gap.inHours == 1 ? '' : 's'} ago';
    }
    return '${gap.inDays} day${gap.inDays == 1 ? '' : 's'} ago';
  }

  @override
  Widget build(BuildContext context) {
    return DsCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const DsIconMedallion(
                icon: LucideIcons.sun,
                tone: DsTone.solar,
                size: 36,
                iconSize: 18,
              ),
              const SizedBox(width: AppSpacing.stepMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Crown Solar Energy',
                      style: context.texts.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      ago(post.postedAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: context.palette.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              DsTag(label: post.audience.label),
            ],
          ),
          if (post.image != null) ...[
            const SizedBox(height: AppSpacing.stepMd),
            ClipRRect(
              borderRadius: AppRadii.mdRadius,
              child: Container(
                height: 150,
                width: double.infinity,
                color: context.palette.sunken,
                alignment: Alignment.center,
                padding: const EdgeInsets.all(AppSpacing.lg),
                // A post from the database carries a URL; the bundled seed
                // carries an asset path. A picture that will not load leaves
                // the panel empty rather than showing a broken box.
                child: post.image!.startsWith('http')
                    ? Image.network(
                        post.image!,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => const SizedBox.shrink(),
                      )
                    : Image.asset(post.image!, fit: BoxFit.contain),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.stepMd),
          Text(
            post.title,
            style: context.texts.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          // Collapsed in the feed, in full on the detail screen.
          onTap == null
              ? DsBody(post.body)
              : Text(
                  post.body,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: context.texts.bodyMedium?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
          const SizedBox(height: AppSpacing.stepMd),
          const DsHairline(),
          const SizedBox(height: AppSpacing.stepMd),
          PostActions(post: post, onComment: onComment ?? onTap),
        ],
      ),
    );
  }
}

/// Heart, comment count and share — the row under every post.
class PostActions extends StatelessWidget {
  const PostActions({super.key, required this.post, this.onComment});

  final SpacePost post;
  final VoidCallback? onComment;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () {
            final user = context.read<SessionController>().user;
            if (user == null) return;
            context.read<SpaceRepository>().toggleHeart(
              postId: post.id,
              user: user,
            );
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                post.heartedByMe ? LucideIcons.heart : LucideIcons.heart,
                size: 18,
                // Filled hearts are not in the icon set, so the colour and
                // the count carry the state instead.
                color: post.heartedByMe
                    ? context.colors.error
                    : context.colors.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                '${post.hearts}',
                style: context.texts.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: post.heartedByMe ? context.colors.error : null,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.stepLg),
        GestureDetector(
          onTap: onComment,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                LucideIcons.messageSquare,
                size: 18,
                color: context.colors.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                '${post.commentCount}',
                style: context.texts.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: () => _share(context),
          child: Icon(
            LucideIcons.share2,
            size: 18,
            color: context.palette.textTertiary,
          ),
        ),
      ],
    );
  }

  Future<void> _share(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await SharePlus.instance.share(ShareParams(text: post.shareText));
    } on Object {
      // No share sheet on this device: the text is still worth having.
      await Clipboard.setData(ClipboardData(text: post.shareText));
      messenger.showSnackBar(
        const SnackBar(content: Text('Post copied to the clipboard.')),
      );
    }
  }
}
