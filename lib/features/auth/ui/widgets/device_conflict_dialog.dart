import 'package:flutter/material.dart';

import 'package:cse_b2b/core/localization/generated/app_localizations.dart';
import 'package:cse_b2b/core/theme/app_colors.dart';
import 'package:cse_b2b/core/theme/app_radii.dart';
import 'package:cse_b2b/core/theme/app_shadows.dart';
import 'package:cse_b2b/core/theme/app_spacing.dart';

/// Claude Design A4: the takeover-confirmation dialog shown whenever the
/// requested device is currently Active for a *different* account —
/// always **before** any OTP is requested, at either device-move tier
/// (FR-013, FR-014; `LoginStep.deviceConflictConfirmation`). Declining
/// calls nothing; confirming is reported back to the caller, which drives
/// `LoginViewModel.confirmDeviceConflict()` — this dialog carries no
/// business logic of its own.
///
/// The design's "this phone now / after you continue" comparison names
/// both accounts by display name and role. The current `evaluateLogin`
/// contract only reports the other account's opaque id (see
/// `contracts/auth-service.md`), so that comparison table is not
/// reproduced pixel-for-pixel here — see the implementation report for
/// the small contract addition that would be needed to show it.
class DeviceConflictDialog extends StatelessWidget {
  const DeviceConflictDialog({super.key});

  /// Shows the dialog and resolves to `true` only if the user tapped
  /// "Continue and Verify"; `false`/`null` (including back-button
  /// dismissal) means decline — the caller must not proceed past that.
  static Future<bool> show(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const DeviceConflictDialog(),
    );
    return confirmed ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final statusColors = theme.extension<AppStatusColors>()!;

    return Dialog(
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: AppRadii.lgRadius),
      elevation: 0,
      insetPadding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
        decoration: const BoxDecoration(
          borderRadius: AppRadii.lgRadius,
          boxShadow: AppShadows.dialog,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: statusColors.warningFill,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.phone_android,
                color: statusColors.warning,
                size: 24,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.loginDeviceConflictTitle,
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.loginDeviceConflictBody,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(l10n.loginDeviceConflictConfirm),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  side: BorderSide.none,
                ),
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(l10n.loginDeviceConflictCancel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
