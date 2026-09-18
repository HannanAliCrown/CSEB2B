import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/ui/ds.dart';
import '../login/ui/widgets/crown_wordmark.dart';
import 'preview_catalog.dart';
import 'preview_journey.dart';

/// An index of every screen built from the approved Claude Design document,
/// so the UI can be reviewed end to end before any of it is wired up.
class PreviewGalleryScreen extends StatelessWidget {
  const PreviewGalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenCount = previewBoards.fold<int>(
      0,
      (total, board) => total + board.screens.length,
    );

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          children: [
            const CrownWordmark(height: 44),
            const SizedBox(height: AppSpacing.md),
            Text('Design preview', style: context.texts.headlineSmall),
            const SizedBox(height: AppSpacing.sm),
            DsBody(
              '$screenCount screens from the approved Crown Solar Energy '
              'design, with static content. Nothing here calls a service.',
              size: 14,
            ),
            const SizedBox(height: AppSpacing.lg),
            for (final board in previewBoards) ...[
              DsSectionHeader(
                title: '${board.number} · ${board.title}',
                meta: '${board.screens.length}',
              ),
              if (board.journey.isNotEmpty) ...[
                DsButton(
                  label: 'Walk the journey',
                  icon: LucideIcons.play,
                  variant: DsButtonVariant.secondary,
                  size: DsButtonSize.sm,
                  onPressed: () => PreviewJourney.start(context, board.journey),
                ),
                const SizedBox(height: AppSpacing.stepMd),
              ],
              DsRowGroup(
                children: [
                  for (final screen in board.screens)
                    DsSettingRow(
                      label: screen.title,
                      leading: SizedBox(
                        width: 34,
                        child: Text(
                          screen.id,
                          style: context.texts.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: context.colors.primary,
                          ),
                        ),
                      ),
                      onTap: () => Navigator.of(
                        context,
                      ).push(MaterialPageRoute<void>(builder: screen.builder)),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
            Row(
              children: [
                Icon(
                  LucideIcons.info,
                  size: 16,
                  color: context.palette.textTertiary,
                ),
                const SizedBox(width: AppSpacing.sm),
                const Expanded(
                  child: DsCaption(
                    'Light and dark both follow the system setting.',
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
