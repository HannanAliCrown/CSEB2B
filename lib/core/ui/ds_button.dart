import 'package:flutter/material.dart';

import '../theme/app_palette.dart';
import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';

/// Button variants from the design system (`components/actions/Button.jsx`).
enum DsButtonVariant { primary, secondary, tertiary, destructive, quiet }

enum DsButtonSize { md, sm }

/// The design system's `Button`: 50px tall (38 when `sm`), 13px corners,
/// 16/600 label, optional leading/trailing icon, 0.45 opacity when off.
class DsButton extends StatelessWidget {
  const DsButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = DsButtonVariant.primary,
    this.size = DsButtonSize.md,
    this.icon,
    this.iconAfter,
    this.loading = false,
    this.disabled = false,
    this.fullWidth = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final DsButtonVariant variant;
  final DsButtonSize size;
  final IconData? icon;
  final IconData? iconAfter;
  final bool loading;
  final bool disabled;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final palette = context.palette;
    final off = disabled || loading || onPressed == null;

    final (Color background, Color foreground, Color? border) = switch (variant) {
      DsButtonVariant.primary => (colors.primary, colors.onPrimary, null),
      DsButtonVariant.secondary => (
        colors.surface,
        colors.onSurface,
        colors.outline,
      ),
      DsButtonVariant.tertiary => (Colors.transparent, colors.primary, null),
      DsButtonVariant.destructive => (colors.error, Colors.white, null),
      DsButtonVariant.quiet => (palette.sunken, colors.onSurface, null),
    };

    final height = size == DsButtonSize.sm
        ? AppSpacing.buttonHeightSm
        : AppSpacing.buttonHeight;
    final textStyle = TextStyle(
      fontSize: size == DsButtonSize.sm ? 14 : 16,
      height: size == DsButtonSize.sm ? 20 / 14 : 24 / 16,
      fontWeight: variant == DsButtonVariant.tertiary
          ? FontWeight.w500
          : FontWeight.w600,
      color: foreground,
    );
    final iconSize = size == DsButtonSize.sm ? 18.0 : 20.0;

    final content = loading
        ? SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(
                variant == DsButtonVariant.primary ||
                        variant == DsButtonVariant.destructive
                    ? Colors.white
                    : colors.primary,
              ),
            ),
          )
        : Row(
            mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: iconSize, color: foreground),
                const SizedBox(width: AppSpacing.sm),
              ],
              Flexible(
                child: Text(
                  label,
                  style: textStyle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
              if (iconAfter != null) ...[
                const SizedBox(width: AppSpacing.sm),
                Icon(iconAfter, size: iconSize, color: foreground),
              ],
            ],
          );

    return Opacity(
      opacity: off ? 0.45 : 1,
      child: Material(
        color: background,
        borderRadius: AppRadii.buttonRadius,
        child: InkWell(
          onTap: off ? null : onPressed,
          borderRadius: AppRadii.buttonRadius,
          child: Container(
            height: height,
            width: fullWidth ? double.infinity : null,
            padding: EdgeInsets.symmetric(
              horizontal: size == DsButtonSize.sm ? 14 : 20,
            ),
            decoration: BoxDecoration(
              borderRadius: AppRadii.buttonRadius,
              border: border == null ? null : Border.all(color: border),
            ),
            alignment: Alignment.center,
            child: content,
          ),
        ),
      ),
    );
  }
}

/// The design system's `IconButton`: a 44px square, quiet by default.
class DsIconButton extends StatelessWidget {
  const DsIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.size = 44,
    this.iconSize = 21,
    this.color,
    this.background,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final double size;
  final double iconSize;
  final Color? color;
  final Color? background;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final button = Material(
      color: background ?? Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(
            icon,
            size: iconSize,
            color: color ?? context.colors.onSurfaceVariant,
          ),
        ),
      ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}
