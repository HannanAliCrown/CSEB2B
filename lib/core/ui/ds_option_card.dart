import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/app_palette.dart';
import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';

/// A large selectable card with an icon tile, title, description and a radio —
/// the pattern the design uses for role selection, board types, recipient
/// paths and scheme tiers.
class DsOptionCard extends StatelessWidget {
  const DsOptionCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    this.selected = false,
    this.enabled = true,
    this.trailing,
    this.onTap,
    this.badge,
  });

  final String title;
  final String description;
  final IconData icon;
  final bool selected;
  final bool enabled;

  /// Replaces the radio when the card is not a single-choice option.
  final Widget? trailing;
  final VoidCallback? onTap;
  final Widget? badge;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: AppRadii.lgRadius,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.cardPadding),
          decoration: BoxDecoration(
            color: selected
                ? context.palette.accentSoft
                : context.colors.surface,
            borderRadius: AppRadii.lgRadius,
            border: Border.all(
              color: selected ? context.colors.primary : context.colors.outline,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected
                      ? context.colors.primary
                      : context.palette.sunken,
                  borderRadius: AppRadii.mdRadius,
                ),
                child: Icon(
                  icon,
                  size: 22,
                  color: selected
                      ? context.colors.onPrimary
                      : context.colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style: context.texts.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (badge != null) ...[
                          const SizedBox(width: AppSpacing.sm),
                          badge!,
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 13,
                        height: 19 / 13,
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.stepMd),
              trailing ??
                  Container(
                    width: 22,
                    height: 22,
                    margin: const EdgeInsets.only(top: 2),
                    decoration: BoxDecoration(
                      color: selected ? Colors.white : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected
                            ? context.colors.primary
                            : context.palette.borderStrong,
                        width: selected ? 6 : 1.5,
                      ),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Status of one capture/upload slot in the registration and complaint flows.
enum DsUploadState { empty, uploading, uploaded, failed }

/// A media slot row: thumbnail, label, state line and the action that matches
/// the state (Add / Retake / Retry).
class DsUploadRow extends StatelessWidget {
  const DsUploadRow({
    super.key,
    required this.label,
    required this.state,
    this.meta,
    this.progress,
    this.icon = LucideIcons.image,
    this.onAction,
  });

  final String label;
  final DsUploadState state;
  final String? meta;
  final double? progress;
  final IconData icon;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final (String actionLabel, Color tint) = switch (state) {
      DsUploadState.empty => ('Add', context.colors.primary),
      DsUploadState.uploading => ('', context.colors.primary),
      DsUploadState.uploaded => ('Retake', context.colors.primary),
      DsUploadState.failed => ('Retry', context.colors.error),
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: AppRadii.mdRadius,
        border: Border.all(
          color: state == DsUploadState.failed
              ? context.colors.error
              : context.colors.outline,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: context.palette.sunken,
              borderRadius: AppRadii.smRadius,
            ),
            child: Icon(
              state == DsUploadState.uploaded ? LucideIcons.check : icon,
              size: 22,
              color: state == DsUploadState.uploaded
                  ? context.status.success
                  : context.palette.textTertiary,
            ),
          ),
          const SizedBox(width: AppSpacing.stepMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: context.texts.bodyLarge?.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (meta != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      meta!,
                      style: TextStyle(
                        fontSize: 12,
                        height: 17 / 12,
                        color: state == DsUploadState.failed
                            ? context.status.error
                            : context.palette.textTertiary,
                      ),
                    ),
                  ),
                if (progress != null)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.sm),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 4,
                      backgroundColor: context.palette.sunken,
                      valueColor: AlwaysStoppedAnimation(context.colors.primary),
                    ),
                  ),
              ],
            ),
          ),
          if (actionLabel.isNotEmpty)
            GestureDetector(
              onTap: onAction,
              child: Padding(
                padding: const EdgeInsets.only(left: AppSpacing.stepMd),
                child: Text(
                  actionLabel,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: tint,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
