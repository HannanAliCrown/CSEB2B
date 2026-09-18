import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/ui/ds.dart';
import '../../../home/ui/models/home_demo_data.dart';

/// One Space post: who posted, when, who it is aimed at, and its reactions.
class _PostCard extends StatelessWidget {
  const _PostCard({
    required this.when,
    required this.audience,
    required this.title,
    required this.body,
    required this.likes,
    required this.comments,
    this.onTap,
  });

  final String when;
  final String audience;
  final String title;
  final String body;
  final int likes;
  final int comments;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return DsCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              DsIconMedallion(
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
                      when,
                      style: TextStyle(
                        fontSize: 12,
                        color: context.palette.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              DsTag(label: audience),
            ],
          ),
          const SizedBox(height: AppSpacing.stepMd),
          Text(
            title,
            style: context.texts.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          DsBody(body),
          const SizedBox(height: AppSpacing.stepMd),
          const DsHairline(),
          const SizedBox(height: AppSpacing.stepMd),
          Row(
            children: [
              _Reaction(icon: LucideIcons.heart, count: '$likes'),
              const SizedBox(width: AppSpacing.stepLg),
              _Reaction(icon: LucideIcons.messageSquare, count: '$comments'),
              const Spacer(),
              Icon(
                LucideIcons.share2,
                size: 18,
                color: context.palette.textTertiary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Reaction extends StatelessWidget {
  const _Reaction({required this.icon, required this.count});

  final IconData icon;
  final String count;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: context.colors.onSurfaceVariant),
        const SizedBox(width: 6),
        Text(
          count,
          style: context.texts.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// Board 10 · A1 — Space feed: a broadcast feed from Crown Solar, kept cheap
/// to load on a low-end phone.
class SpaceFeedScreen extends StatelessWidget {
  const SpaceFeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: DsAppBar(
        title: 'Space',
        onBack: () => Navigator.of(context).maybePop(),
      ),
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          children: [
            _PostCard(
              when: 'Today, 8:30 AM',
              audience: 'Installers and retailers',
              title: 'Dealer meet-up in Lahore on 20 September',
              body:
                  'Doors open at 10 am at Pearl Continental. Bring your '
                  'profile QR for attendance.',
              likes: 48,
              comments: 6,
              onTap: () {},
            ),
            const SizedBox(height: AppSpacing.stepMd),
            _PostCard(
              when: 'Yesterday',
              audience: 'All roles',
              title: 'Crown 12kW Hybrid is now shipping',
              body:
                  'Available from all distributors this week. Scan the label '
                  'to confirm authenticity before installation.',
              likes: 112,
              comments: 23,
              onTap: () {},
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: AppSpacing.stepMd),
                const DsCaption('Loading more posts'),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: DsBottomNav(
        items: HomeDemo.installer.nav,
        activeId: 'space',
      ),
    );
  }
}

/// Board 10 · A2 — Post detail, with comments and replies. Comments post
/// only on confirmation, never optimistically.
class SpacePostDetailScreen extends StatelessWidget {
  const SpacePostDetailScreen({super.key});

  static const _comments = [
    (
      'Adnan Solar Works',
      'Kya installers bhi aa sakte hain?',
      '1 h ago',
      false,
    ),
    (
      'Crown Solar · CRM',
      'Yes, installers are welcome. Bring your profile QR.',
      '45 min ago',
      true,
    ),
    ('Bilal Traders', 'Parking available hai?', '20 min ago', false),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: DsAppBar(
        title: 'Post',
        onBack: () => Navigator.of(context).maybePop(),
      ),
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          children: [
            DsCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dealer meet-up in Lahore on 20 September',
                    style: context.texts.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const DsBody(
                    'Doors open at 10 am at Pearl Continental. Bring your '
                    'profile QR for attendance. Lunch and the new product '
                    'briefing are included.',
                    size: 14,
                  ),
                  const SizedBox(height: AppSpacing.stepMd),
                  const DsHairline(),
                  const SizedBox(height: AppSpacing.stepMd),
                  Row(
                    children: [
                      _Reaction(icon: LucideIcons.heart, count: '48'),
                      const SizedBox(width: AppSpacing.stepLg),
                      const DsCaption('6 comments'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            for (final (name, body, posted, official) in _comments)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.stepMd),
                child: DsCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          DsAvatar(
                            initials: DsPartyRow.initialsOf(name),
                            size: 32,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              name,
                              style: context.texts.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (official)
                            const DsTag(label: 'Admin', tone: DsTone.accent),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      DsBody(body, size: 14),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          DsCaption(posted),
                          const SizedBox(width: AppSpacing.md),
                          Text(
                            'Reply',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: context.colors.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: const _Composer(hint: 'Write a comment'),
    );
  }
}

/// The message/comment composer bar.
class _Composer extends StatelessWidget {
  const _Composer({required this.hint});

  final String hint;

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
                  hint,
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

/// Board 10 · A3 — Space: offline and empty, stated as facts rather than
/// apologies.
class SpaceEmptyStatesScreen extends StatelessWidget {
  const SpaceEmptyStatesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DsScreen(
      appBar: DsAppBar(
        title: 'Space',
        onBack: () => Navigator.of(context).maybePop(),
      ),
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      gap: AppSpacing.md,
      sections: [
        DsNotice(
          icon: LucideIcons.wifiOff,
          tone: DsTone.warning,
          message: 'You are offline. Showing posts saved on this phone.',
          action: DsButton(
            label: 'Retry',
            variant: DsButtonVariant.secondary,
            size: DsButtonSize.sm,
            icon: LucideIcons.refreshCw,
            onPressed: () {},
          ),
        ),
        const DsCard(
          padding: EdgeInsets.zero,
          child: DsEmptyState(
            icon: LucideIcons.megaphone,
            title: 'Nothing Here Yet',
            message:
                'Posts from the Crown Solar team will appear here — events, '
                'new products and scheme news.',
          ),
        ),
        DsCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const DsSkeleton(height: 16, width: 180),
              const SizedBox(height: AppSpacing.sm),
              const DsSkeleton(height: 12),
              const SizedBox(height: 6),
              const DsSkeleton(height: 12, width: 220),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: const [
                  DsSkeleton(height: 12, width: 40),
                  SizedBox(width: AppSpacing.md),
                  DsSkeleton(height: 12, width: 40),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
