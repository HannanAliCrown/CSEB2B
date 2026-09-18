import 'package:flutter/material.dart';

import 'package:cse_b2b/core/theme/app_colors.dart';
import 'package:cse_b2b/core/theme/app_radii.dart';
import 'package:cse_b2b/core/theme/app_spacing.dart';

/// The tone of an [AuthInfoBanner] — each maps to one of the design
/// system's soft fill/on-fill pairs (`AppStatusColors`), except [neutral]
/// which uses the plain surface-variant tone: the design deliberately
/// avoids a "status" colour where nothing is wrong (e.g. the device-policy
/// notice on A1, or "your account is fixed to another phone" on B1).
enum AuthBannerTone { neutral, info, success, warning, error }

/// An icon + text banner with a soft coloured fill, matching the small
/// info/notice cards repeated across the Login journey (A1's device-policy
/// notice, A2's "one free move" notice, B2's CRM-authorized banner, B3's
/// session-expired notice). One widget instead of re-declaring the same
/// padding/radius/icon-plus-text row on every screen.
class AuthInfoBanner extends StatelessWidget {
  const AuthInfoBanner({
    super.key,
    required this.message,
    this.tone = AuthBannerTone.neutral,
    this.icon,
    this.title,
    this.radius = AppRadii.md,
    this.padding = const EdgeInsets.all(14),
  });

  final String message;
  final String? title;
  final AuthBannerTone tone;
  final IconData? icon;
  final double radius;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColors = theme.extension<AppStatusColors>()!;
    final (Color fill, Color on, IconData defaultIcon) = switch (tone) {
      AuthBannerTone.neutral => (
        theme.colorScheme.surfaceContainerHighest,
        theme.colorScheme.onSurfaceVariant,
        Icons.info_outline,
      ),
      AuthBannerTone.info => (
        statusColors.infoFill,
        statusColors.info,
        Icons.info_outline,
      ),
      AuthBannerTone.success => (
        statusColors.successFill,
        statusColors.success,
        Icons.verified_outlined,
      ),
      AuthBannerTone.warning => (
        statusColors.warningFill,
        statusColors.warning,
        Icons.schedule_outlined,
      ),
      AuthBannerTone.error => (
        statusColors.errorFill,
        statusColors.error,
        Icons.error_outline,
      ),
    };

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon ?? defaultIcon, size: 18, color: on),
          const SizedBox(width: AppSpacing.sm + 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null) ...[
                  Text(
                    title!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: on,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
                Text(
                  message,
                  style: theme.textTheme.bodyMedium?.copyWith(color: on),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
