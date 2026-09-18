import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/app_palette.dart';
import '../theme/app_spacing.dart';
import 'ds_button.dart';

/// The design system's `AppBar`: 56px minimum, 18/600 title, optional
/// subtitle, a 26px back chevron and trailing 40px icon actions.
class DsAppBar extends StatelessWidget implements PreferredSizeWidget {
  const DsAppBar({
    super.key,
    this.title,
    this.subtitle,
    this.onBack,
    this.actions = const [],
    this.transparent = false,
    this.titleWidget,
  });

  final String? title;
  final String? subtitle;
  final VoidCallback? onBack;
  final List<Widget> actions;
  final bool transparent;
  final Widget? titleWidget;

  /// 56px per the design, plus the hairline border and the subtitle's own
  /// line so a two-line app bar is not 1px short of its content.
  @override
  Size get preferredSize => Size.fromHeight(subtitle == null ? 57 : 60);

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 56),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: transparent ? Colors.transparent : context.colors.surface,
        border: transparent
            ? null
            : Border(bottom: BorderSide(color: context.colors.outline)),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            if (onBack != null)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: DsIconButton(
                  icon: LucideIcons.chevronLeft,
                  iconSize: 26,
                  size: 36,
                  color: context.colors.onSurface,
                  onPressed: onBack,
                ),
              ),
            Expanded(
              child:
                  titleWidget ??
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (title != null)
                        Text(
                          title!,
                          style: context.texts.titleLarge,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          style: context.texts.bodySmall?.copyWith(
                            color: context.palette.textTertiary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
            ),
            ...actions,
          ],
        ),
      ),
    );
  }
}

/// The sticky footer the design puts a screen's primary action in: a hairline
/// top border over the surface colour, 16/20/30 padding.
class DsFooterBar extends StatelessWidget {
  const DsFooterBar({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.md,
        AppSpacing.screenPadding,
        AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: context.colors.surface,
        border: Border(top: BorderSide(color: context.colors.outline)),
      ),
      child: SafeArea(top: false, child: child),
    );
  }
}
