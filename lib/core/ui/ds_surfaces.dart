import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/app_palette.dart';
import '../theme/app_radii.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';

enum DsCardTone { surface, sunken, accent }

/// The design system's `Card`: surface fill, hairline border, 16px corners,
/// 18px padding, `--shadow-card`.
class DsCard extends StatelessWidget {
  const DsCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.cardPadding),
    this.radius = AppRadii.lgRadius,
    this.tone = DsCardTone.surface,
    this.onTap,
    this.border,
    this.shadow = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadius radius;
  final DsCardTone tone;
  final VoidCallback? onTap;
  final Color? border;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final background = switch (tone) {
      DsCardTone.surface => context.colors.surface,
      DsCardTone.sunken => palette.sunken,
      DsCardTone.accent => palette.accentSoft,
    };

    final card = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: background,
        borderRadius: radius,
        border: Border.all(color: border ?? context.colors.outline),
        boxShadow: shadow ? AppShadows.card : null,
      ),
      child: child,
    );

    if (onTap == null) return card;
    return InkWell(onTap: onTap, borderRadius: radius, child: card);
  }
}

/// The design system's `SectionHeader`: 18/24/600 title, optional meta and a
/// trailing text action with a chevron.
class DsSectionHeader extends StatelessWidget {
  const DsSectionHeader({
    super.key,
    required this.title,
    this.meta,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? meta;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.stepMd),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Flexible(
            child: Text(
              title,
              style: context.texts.titleLarge,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (meta != null) ...[
            const SizedBox(width: 10),
            Text(
              meta!,
              style: context.texts.bodySmall?.copyWith(
                color: context.palette.textTertiary,
              ),
            ),
          ],
          const Spacer(),
          if (actionLabel != null)
            GestureDetector(
              onTap: onAction,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    actionLabel!,
                    style: context.texts.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: context.colors.primary,
                    ),
                  ),
                  Icon(
                    LucideIcons.chevronRight,
                    size: 16,
                    color: context.colors.primary,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// A labelled block of rows separated by hairlines — the pattern the design
/// uses for settings, summaries and detail lists.
class DsRowGroup extends StatelessWidget {
  const DsRowGroup({super.key, required this.children, this.padding});

  final List<Widget> children;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      rows.add(children[i]);
      if (i != children.length - 1) {
        rows.add(
          Divider(height: 1, thickness: 1, color: context.colors.outline),
        );
      }
    }
    return DsCard(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: rows,
      ),
    );
  }
}

/// The map stand-in the design uses wherever a real map will sit: a ruled
/// grid with a pin, and a caption row carrying the coordinates and action.
class DsMapPlaceholder extends StatelessWidget {
  const DsMapPlaceholder({
    super.key,
    this.height = 96,
    this.coordinates,
    this.actionLabel,
    this.onAction,
    this.pinColor,
  });

  /// A null height fills whatever vertical space the parent allows.
  final double? height;
  final String? coordinates;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color? pinColor;

  @override
  Widget build(BuildContext context) {
    final surface = CustomPaint(
      painter: _MapGridPainter(),
      child: Center(
        child: Icon(
          LucideIcons.mapPin,
          size: 26,
          color: pinColor ?? context.colors.error,
        ),
      ),
    );

    return Container(
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: AppRadii.mdRadius,
        border: Border.all(color: context.colors.outline),
      ),
      child: Column(
        children: [
          if (height == null)
            Expanded(child: SizedBox.expand(child: surface))
          else
            SizedBox(height: height, child: surface),
          if (coordinates != null || actionLabel != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: context.colors.outline)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (coordinates != null)
                    Flexible(
                      child: Text(
                        coordinates!,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: context.colors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  if (actionLabel != null)
                    GestureDetector(
                      onTap: onAction,
                      child: Padding(
                        padding: const EdgeInsets.only(left: AppSpacing.sm),
                        child: Text(
                          actionLabel!,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: context.colors.primary,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFFE8EEF5),
    );
    final line = Paint()
      ..color = const Color(0xFFDCE4EE)
      ..strokeWidth = 1;
    for (var x = 0.0; x < size.width; x += 26) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), line);
    }
    for (var y = 0.0; y < size.height; y += 26) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), line);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// A person/business row: initials avatar, name, meta line and an optional
/// trailing widget. The design repeats this for recents, contacts, cash
/// requests, chat and approvals.
class DsPartyRow extends StatelessWidget {
  const DsPartyRow({
    super.key,
    required this.name,
    this.meta,
    this.initials,
    this.trailing,
    this.onTap,
    this.avatarColor,
  });

  final String name;
  final String? meta;
  final String? initials;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? avatarColor;

  static String initialsOf(String name) {
    final parts = name.trim().split(RegExp(r'[\s-]+'));
    if (parts.length == 1) {
      return parts.first.characters.take(2).toString().toUpperCase();
    }
    return (parts.first.characters.first + parts[1].characters.first)
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: 13),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: avatarColor ?? context.palette.accentSoft,
              shape: BoxShape.circle,
            ),
            child: Text(
              initials ?? initialsOf(name),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: context.colors.primary,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.stepMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (meta != null)
                  Text(
                    meta!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: context.palette.textTertiary,
                    ),
                  ),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: AppSpacing.sm),
            trailing!,
          ],
        ],
      ),
    );
    if (onTap == null) return row;
    return InkWell(onTap: onTap, child: row);
  }
}

/// A key/value row: label on the left, value on the right, optional meta and
/// chevron (`components/forms/SettingRow.jsx`).
class DsSettingRow extends StatelessWidget {
  const DsSettingRow({
    super.key,
    required this.label,
    this.value,
    this.unit,
    this.meta,
    this.leading,
    this.trailing,
    this.onTap,
    this.danger = false,
  });

  final String label;
  final String? value;
  final String? unit;
  final String? meta;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final row = Container(
      constraints: const BoxConstraints(minHeight: 60),
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.stepMd),
      child: Row(
        children: [
          if (leading != null) ...[
            leading!,
            const SizedBox(width: AppSpacing.stepMd),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        label,
                        style: context.texts.bodyLarge?.copyWith(
                          color: danger ? context.colors.error : null,
                        ),
                      ),
                    ),
                  ],
                ),
                if (meta != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      meta!,
                      style: context.texts.bodySmall?.copyWith(
                        color: context.palette.textTertiary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (trailing != null)
            trailing!
          else ...[
            if (value != null)
              Text(
                value!,
                style: context.texts.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            if (unit != null) ...[
              const SizedBox(width: 5),
              Text(
                unit!,
                style: context.texts.bodyMedium?.copyWith(
                  color: context.palette.textTertiary,
                ),
              ),
            ],
            if (onTap != null)
              Padding(
                padding: const EdgeInsets.only(left: AppSpacing.xs),
                child: Icon(
                  LucideIcons.chevronRight,
                  size: 18,
                  color: context.palette.textTertiary,
                ),
              ),
          ],
        ],
      ),
    );

    if (onTap == null) return row;
    return InkWell(onTap: onTap, child: row);
  }
}
