import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_palette.dart';
import '../theme/app_radii.dart';

/// Tonal families available to [DsTag] (`components/status/Tag.jsx`).
enum DsTone { neutral, accent, success, warning, error, info, solar }

/// Resolves a tone to its (fill, foreground) pair from the status tokens.
(Color, Color) dsToneColors(BuildContext context, DsTone tone) {
  final status = context.status;
  final palette = context.palette;
  return switch (tone) {
    DsTone.neutral => (status.neutralFill, status.neutral),
    DsTone.accent => (palette.accentSoft, context.colors.primary),
    DsTone.success => (status.successFill, status.success),
    DsTone.warning => (status.warningFill, status.warning),
    DsTone.error => (status.errorFill, status.error),
    DsTone.info => (status.infoFill, status.info),
    DsTone.solar => (palette.solar.withValues(alpha: 0.14), palette.solar),
  };
}

/// The design system's `Tag`: a pill with 11/600 text, optional uppercase
/// treatment with caps tracking.
class DsTag extends StatelessWidget {
  const DsTag({
    super.key,
    required this.label,
    this.tone = DsTone.neutral,
    this.uppercase = false,
    this.icon,
  });

  final String label;
  final DsTone tone;
  final bool uppercase;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final (fill, foreground) = dsToneColors(context, tone);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: foreground),
            const SizedBox(width: 4),
          ],
          Text(
            uppercase ? label.toUpperCase() : label,
            style: TextStyle(
              fontSize: 11,
              height: 14 / 11,
              fontWeight: FontWeight.w600,
              letterSpacing: uppercase ? 0.06 * 11 : 0,
              color: foreground,
            ),
          ),
        ],
      ),
    );
  }
}

/// The design system's `StatusBadge` in its `pill` variant: soft fill, icon
/// and 14/500 label.
class DsStatusPill extends StatelessWidget {
  const DsStatusPill({
    super.key,
    required this.label,
    required this.icon,
    this.tone = DsTone.neutral,
    this.small = false,
  });

  final String label;
  final IconData icon;
  final DsTone tone;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final (fill, foreground) = dsToneColors(context, tone);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 9 : 11,
        vertical: small ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: small ? 13 : 15, color: foreground),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: small ? 12 : 14,
              height: small ? 16 / 12 : 20 / 14,
              fontWeight: FontWeight.w500,
              color: foreground,
            ),
          ),
        ],
      ),
    );
  }
}

/// The `dot` variant of `StatusBadge`: an 8px coloured dot with secondary
/// text.
class DsStatusDot extends StatelessWidget {
  const DsStatusDot({
    super.key,
    required this.label,
    required this.color,
    this.small = false,
  });

  final String label;
  final Color color;
  final bool small;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 7),
        Text(
          label,
          style: (small ? context.texts.bodySmall : context.texts.bodyMedium)
              ?.copyWith(
                fontWeight: FontWeight.w500,
                color: context.colors.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}

/// The design system's `FilterChip`: 34px pill, accent-filled when selected.
class DsFilterChip extends StatelessWidget {
  const DsFilterChip({
    super.key,
    required this.label,
    this.selected = false,
    this.count,
    this.icon,
    this.onTap,
  });

  final String label;
  final bool selected;
  final int? count;
  final IconData? icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = selected
        ? context.colors.onPrimary
        : context.colors.onSurfaceVariant;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.pill),
      child: Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: selected ? context.colors.primary : context.colors.surface,
          borderRadius: BorderRadius.circular(AppRadii.pill),
          border: Border.all(
            color: selected ? context.colors.primary : context.colors.outline,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 15, color: foreground),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: context.texts.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: foreground,
              ),
            ),
            if (count != null) ...[
              const SizedBox(width: 6),
              Text(
                '$count',
                style: context.texts.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: foreground.withValues(alpha: 0.65),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A circular icon medallion — the design's repeated "icon in a soft round
/// fill" motif for card headers and empty states.
class DsIconMedallion extends StatelessWidget {
  const DsIconMedallion({
    super.key,
    required this.icon,
    this.tone = DsTone.accent,
    this.size = 36,
    this.iconSize = 18,
    this.rounded = false,
  });

  final IconData icon;
  final DsTone tone;
  final double size;
  final double iconSize;
  final bool rounded;

  @override
  Widget build(BuildContext context) {
    final (fill, foreground) = dsToneColors(context, tone);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: fill,
        shape: rounded ? BoxShape.rectangle : BoxShape.circle,
        borderRadius: rounded ? AppRadii.mdRadius : null,
      ),
      child: Icon(icon, size: iconSize, color: foreground),
    );
  }
}

/// An avatar bubble with initials, used across Space, Chat and Profile.
class DsAvatar extends StatelessWidget {
  const DsAvatar({
    super.key,
    required this.initials,
    this.size = 40,
    this.color,
  });

  final String initials;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final background = color ?? context.palette.accentSoft;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: background, shape: BoxShape.circle),
      child: Text(
        initials,
        style: TextStyle(
          fontSize: size * 0.36,
          fontWeight: FontWeight.w600,
          color: color == null
              ? context.colors.primary
              : AppColors.lightSurface,
        ),
      ),
    );
  }
}

/// A thin progress meter (`--radius-pill` track) used by targets, schemes and
/// upload progress.
class DsProgressBar extends StatelessWidget {
  const DsProgressBar({
    super.key,
    required this.value,
    this.height = 8,
    this.color,
    this.track,
  });

  final double value;
  final double height;
  final Color? color;
  final Color? track;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadii.pill),
      child: LinearProgressIndicator(
        value: value.clamp(0, 1),
        minHeight: height,
        backgroundColor: track ?? context.palette.sunken,
        valueColor: AlwaysStoppedAnimation(color ?? context.colors.primary),
      ),
    );
  }
}

/// A hairline divider matching `--border-hairline`, for use inside cards.
class DsHairline extends StatelessWidget {
  const DsHairline({super.key, this.vertical = 0});

  final double vertical;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: vertical),
      child: Container(height: 1, color: context.colors.outline),
    );
  }
}
