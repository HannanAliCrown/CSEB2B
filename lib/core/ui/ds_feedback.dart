import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/app_palette.dart';
import '../theme/app_radii.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';
import 'ds_button.dart';
import 'ds_status.dart';

/// Severity levels from `components/feedback/Alert.jsx`.
enum DsAlertLevel { info, warning, critical, success }

/// The design system's `Alert` row: a 34px tinted icon tile, title, message,
/// timestamp and an optional inline action.
class DsAlert extends StatelessWidget {
  const DsAlert({
    super.key,
    required this.title,
    this.message,
    this.level = DsAlertLevel.warning,
    this.timestamp,
    this.actionLabel,
    this.onAction,
    this.unread = false,
    this.onTap,
  });

  final String title;
  final String? message;
  final DsAlertLevel level;
  final String? timestamp;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool unread;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final (icon, tone) = switch (level) {
      DsAlertLevel.info => (LucideIcons.info, DsTone.info),
      DsAlertLevel.warning => (LucideIcons.triangleAlert, DsTone.warning),
      DsAlertLevel.critical => (LucideIcons.octagonAlert, DsTone.error),
      DsAlertLevel.success => (LucideIcons.circleCheck, DsTone.success),
    };
    final (fill, foreground) = dsToneColors(context, tone);

    return InkWell(
      onTap: onTap,
      borderRadius: AppRadii.lgRadius,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: AppRadii.lgRadius,
          border: Border.all(color: context.colors.outline),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: fill,
                borderRadius: AppRadii.smRadius,
              ),
              child: Icon(icon, size: 18, color: foreground),
            ),
            const SizedBox(width: AppSpacing.stepMd),
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
                      if (unread) ...[
                        const SizedBox(width: AppSpacing.sm),
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: context.colors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (message != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text(
                        message!,
                        style: context.texts.bodyMedium?.copyWith(
                          color: context.colors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  if (timestamp != null || actionLabel != null)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.sm),
                      child: Row(
                        children: [
                          if (timestamp != null)
                            Text(
                              timestamp!,
                              style: context.texts.bodySmall?.copyWith(
                                color: context.palette.textTertiary,
                              ),
                            ),
                          if (timestamp != null && actionLabel != null)
                            const SizedBox(width: 14),
                          if (actionLabel != null)
                            GestureDetector(
                              onTap: onAction,
                              child: Text(
                                actionLabel!,
                                style: context.texts.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: context.colors.primary,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A full-width notice card: tinted fill, icon, title and body. The design
/// uses this for the device-policy notice, refusals and "what happens next"
/// explanations.
class DsNotice extends StatelessWidget {
  const DsNotice({
    super.key,
    required this.message,
    this.title,
    this.icon,
    this.tone = DsTone.neutral,
    this.action,
    this.dense = false,
  });

  final String message;
  final String? title;
  final IconData? icon;
  final DsTone tone;
  final Widget? action;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final (fill, foreground) = dsToneColors(context, tone);
    return Container(
      padding: EdgeInsets.all(dense ? AppSpacing.stepMd : AppSpacing.md),
      decoration: BoxDecoration(color: fill, borderRadius: AppRadii.mdRadius),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: foreground),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (title != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Text(
                      title!,
                      style: context.texts.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: foreground,
                      ),
                    ),
                  ),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 13,
                    height: 19 / 13,
                    color: foreground,
                  ),
                ),
                if (action != null)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.stepMd),
                    child: action!,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The design system's `EmptyState`: a 72px sunken circle, title, message and
/// an optional action.
class DsEmptyState extends StatelessWidget {
  const DsEmptyState({
    super.key,
    required this.title,
    this.message,
    this.icon = LucideIcons.inbox,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            margin: const EdgeInsets.only(bottom: AppSpacing.stepMd),
            decoration: BoxDecoration(
              color: context.palette.sunken,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 30, color: context.palette.textTertiary),
          ),
          Text(
            title,
            style: context.texts.titleLarge,
            textAlign: TextAlign.center,
          ),
          if (message != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 260),
                child: Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: context.texts.bodyMedium?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          if (actionLabel != null)
            Padding(
              padding: const EdgeInsets.only(top: 18),
              child: SizedBox(
                width: 260,
                child: DsButton(label: actionLabel!, onPressed: onAction),
              ),
            ),
        ],
      ),
    );
  }
}

/// The design system's horizontal `ProgressSteps`: an equal-width 4px meter
/// with the current step named below it.
class DsProgressSteps extends StatelessWidget {
  const DsProgressSteps({
    super.key,
    required this.steps,
    required this.current,
  });

  final List<String> steps;
  final int current;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: List.generate(steps.length, (i) {
            return Expanded(
              child: Container(
                height: 4,
                margin: EdgeInsets.only(right: i == steps.length - 1 ? 0 : 6),
                decoration: BoxDecoration(
                  color: i <= current
                      ? context.colors.primary
                      : context.colors.outline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              steps[current],
              style: context.texts.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              'Step ${current + 1} of ${steps.length}',
              style: context.texts.bodySmall?.copyWith(
                color: context.palette.textTertiary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// The vertical variant: a numbered/ticked rail with a connector line, used
/// for approval chains and complaint timelines.
class DsTimelineStep {
  const DsTimelineStep({
    required this.title,
    this.meta,
    this.done = false,
    this.active = false,
    this.tone,
  });

  final String title;
  final String? meta;
  final bool done;
  final bool active;
  final DsTone? tone;
}

class DsTimeline extends StatelessWidget {
  const DsTimeline({super.key, required this.steps});

  final List<DsTimelineStep> steps;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(steps.length, (i) {
        final step = steps[i];
        final isLast = i == steps.length - 1;
        final circleColor = step.done
            ? context.status.success
            : step.active
            ? context.colors.primary
            : context.palette.sunken;
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: circleColor,
                      shape: BoxShape.circle,
                    ),
                    child: step.done
                        ? const Icon(
                            LucideIcons.check,
                            size: 14,
                            color: Colors.white,
                          )
                        : Text(
                            '${i + 1}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: step.active
                                  ? Colors.white
                                  : context.palette.textTertiary,
                            ),
                          ),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        constraints: const BoxConstraints(minHeight: 22),
                        color: step.done
                            ? context.status.success
                            : context.colors.outline,
                      ),
                    ),
                ],
              ),
              const SizedBox(width: AppSpacing.stepMd),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        step.title,
                        style: context.texts.bodyLarge?.copyWith(
                          fontWeight: step.active
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: step.done || step.active
                              ? context.colors.onSurface
                              : context.palette.textTertiary,
                        ),
                      ),
                      if (step.meta != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            step.meta!,
                            style: context.texts.bodySmall?.copyWith(
                              color: context.palette.textTertiary,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

/// The design system's `Skeleton` block.
class DsSkeleton extends StatelessWidget {
  const DsSkeleton({
    super.key,
    this.width,
    this.height = 14,
    this.radius = AppRadii.sm,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: context.palette.sunken,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// The design system's `Snackbar`: a dark floating bar with a text action.
class DsSnackbar extends StatelessWidget {
  const DsSnackbar({
    super.key,
    required this.message,
    this.actionLabel,
    this.icon,
  });

  final String message;
  final String? actionLabel;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: AppRadii.mdRadius,
        boxShadow: AppShadows.raised,
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: Colors.white),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 14,
                height: 20 / 14,
                color: Colors.white,
              ),
            ),
          ),
          if (actionLabel != null)
            Padding(
              padding: const EdgeInsets.only(left: 14),
              child: Text(
                actionLabel!,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: context.colors.primary.withValues(alpha: 1),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// A modal card rendered inline over a dimmed backdrop — the design's
/// `Dialog` (e.g. the A4 takeover confirmation).
class DsDialogCard extends StatelessWidget {
  const DsDialogCard({
    super.key,
    required this.title,
    required this.child,
    this.icon,
    this.tone = DsTone.warning,
  });

  final String title;
  final Widget child;
  final IconData? icon;
  final DsTone tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: AppRadii.sheetRadius,
        boxShadow: AppShadows.dialog,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.stepMd),
              child: DsIconMedallion(
                icon: icon!,
                tone: tone,
                size: 44,
                iconSize: 22,
              ),
            ),
          Text(title, style: context.texts.titleMedium),
          const SizedBox(height: AppSpacing.stepMd),
          child,
        ],
      ),
    );
  }
}

/// A bottom sheet body with the design's 24px top corners and grab handle.
class DsSheet extends StatelessWidget {
  const DsSheet({super.key, required this.child, this.title});

  final Widget child;
  final String? title;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadii.sheet),
        ),
        boxShadow: AppShadows.raised,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              decoration: BoxDecoration(
                color: context.colors.outline,
                borderRadius: BorderRadius.circular(AppRadii.pill),
              ),
            ),
          ),
          if (title != null) ...[
            Text(title!, style: context.texts.titleLarge),
            const SizedBox(height: AppSpacing.md),
          ],
          child,
        ],
      ),
    );
  }
}
