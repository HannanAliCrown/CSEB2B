import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:cse_b2b/core/localization/generated/app_localizations.dart';
import 'package:cse_b2b/core/theme/app_colors.dart';
import 'package:cse_b2b/core/theme/app_radii.dart';
import 'package:cse_b2b/core/theme/app_shadows.dart';
import 'package:cse_b2b/core/theme/app_spacing.dart';

import '../../data/services/auth_service.dart';
import '../view_models/login_view_model.dart';
import '../widgets/auth_info_banner.dart';
import '../widgets/auth_primary_button.dart';
import '../widgets/crown_solar_logo.dart';
import '../widgets/device_conflict_dialog.dart';
import '../widgets/otp_code_input.dart';

/// Login screen (User Stories 2–8): trusted-device sign-in, New/Untrusted
/// detection, the device-conflict confirmation gate (Claude Design A4),
/// the two device-move tiers (A2 second-device / B1+B2 third-or-later),
/// and session restoration (B3). One screen with internal state, driven
/// entirely by [LoginViewModel.step] — no business logic lives here.
///
/// Claude Design screens implemented: A1 (sign in), A2 (new-device OTP),
/// A3 (invalid OTP — plain error styling only, see class doc below), A4
/// (device-conflict dialog), B1 (device move not authorized), B2
/// (CRM-authorized OTP), B3 (session expired).
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.onAuthenticated});

  final void Function(String accountId) onAuthenticated;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _mobileController = TextEditingController();
  final _otpController = TextEditingController();
  bool _conflictDialogShowing = false;

  @override
  void dispose() {
    _mobileController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final viewModel = context.watch<LoginViewModel>();

    if (viewModel.step == LoginStep.trustedSuccess ||
        viewModel.step == LoginStep.rebindingSuccess) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onAuthenticated(viewModel.accountId ?? '');
      });
    }

    // Claude Design A4: shown as a modal dialog OVER the current screen
    // (never a separate page/route), before any OTP is requested, at
    // either device-move tier (FR-013, FR-014).
    if (viewModel.step == LoginStep.deviceConflictConfirmation &&
        !_conflictDialogShowing) {
      _conflictDialogShowing = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final confirmed = await DeviceConflictDialog.show(context);
        _conflictDialogShowing = false;
        if (!mounted) return;
        if (confirmed) {
          await viewModel.confirmDeviceConflict();
        } else {
          viewModel.declineDeviceConflict();
        }
      });
    }

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenPadding,
          ),
          child: _buildBody(context, l10n, viewModel),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AppLocalizations l10n,
    LoginViewModel viewModel,
  ) {
    switch (viewModel.step) {
      case LoginStep.enterMobileNumber:
      case LoginStep.submitting:
      case LoginStep.trustedSuccess:
      case LoginStep.accountNotFound:
      case LoginStep.deviceConflictConfirmation:
        return _SignInView(
          l10n: l10n,
          viewModel: viewModel,
          mobileController: _mobileController,
        );
      case LoginStep.checkingAuthorization:
        return const Padding(
          padding: EdgeInsets.only(top: AppSpacing.xxl),
          child: Center(child: CircularProgressIndicator()),
        );
      case LoginStep.authorizationPending:
      case LoginStep.authorizationNotAuthorized:
        return _DeviceLockedView(l10n: l10n, viewModel: viewModel);
      case LoginStep.enterOtp:
      case LoginStep.verifyingOtp:
      case LoginStep.invalidOtp:
      case LoginStep.completingRebinding:
      case LoginStep.rebindingFailed:
        return _OtpEntryView(
          l10n: l10n,
          viewModel: viewModel,
          otpController: _otpController,
        );
      case LoginStep.rebindingSuccess:
        return const SizedBox.shrink();
    }
  }
}

/// A1 (sign in) and B3 (session expired): both are the same mobile-number
/// entry screen — B3 is simply A1 with the session-expired banner instead
/// of the device-policy notice, per Claude Design's shared layout. There
/// is no separate ViewModel state for "session expired" (`app_router.dart`
/// only ever routes here when no session restores at all, indistinguishable
/// from a fresh sign-in) so this always renders the A1 treatment; see the
/// implementation report for the small addition that would be needed to
/// distinguish the two.
class _SignInView extends StatelessWidget {
  const _SignInView({
    required this.l10n,
    required this.viewModel,
    required this.mobileController,
  });

  final AppLocalizations l10n;
  final LoginViewModel viewModel;
  final TextEditingController mobileController;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Deliberately NOT `|| step == deviceConflictConfirmation`: that step
    // shows the A4 dialog as a modal barrier over this screen, which
    // already blocks interaction with everything below it structurally
    // (`barrierDismissible: false`) — an indeterminate spinner on this
    // button underneath would animate for as long as the dialog is open,
    // which is indefinite until the user chooses, so it must not be tied
    // to a "loading" state here.
    final submitting = viewModel.step == LoginStep.submitting;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.sectionGap),
        const CrownSolarLogo(),
        const SizedBox(height: AppSpacing.lg),
        Text(l10n.authSignInHeading, style: theme.textTheme.headlineSmall),
        const SizedBox(height: AppSpacing.xs + 4),
        Text(
          l10n.authSignInSubtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        TextField(
          controller: mobileController,
          keyboardType: TextInputType.phone,
          enabled: !submitting,
          decoration: InputDecoration(
            labelText: l10n.authMobileNumberLabel,
            hintText: l10n.authMobileNumberHint,
          ),
        ),
        const SizedBox(height: AppSpacing.stepMd + 2),
        Row(
          children: [
            // The Checkbox component is 22x22 (--checkbox-size); Material's
            // default checkbox paints at 18x18 (`Checkbox.width`), so it is
            // scaled up rather than left at the Material default.
            Transform.scale(
              scale: 22 / 18,
              child: Checkbox(
                value: viewModel.keepSignedIn,
                onChanged: submitting
                    ? null
                    : (value) => viewModel.setKeepSignedIn(value ?? false),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(l10n.authKeepSignedIn, style: theme.textTheme.bodyMedium),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        AuthInfoBanner(message: l10n.authDevicePolicyNotice),
        if (viewModel.step == LoginStep.accountNotFound) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.authAccountNotFound,
            style: TextStyle(color: theme.colorScheme.error),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        const Divider(),
        const SizedBox(height: AppSpacing.md),
        AuthPrimaryButton(
          label: l10n.authSignInAction,
          loading: submitting,
          onPressed: () => viewModel.submitMobileNumber(mobileController.text),
        ),
        const SizedBox(height: AppSpacing.md),
        Center(
          child: Wrap(
            children: [
              Text(
                '${l10n.authRegisterPrompt} ',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              InkWell(
                // Literal path rather than importing AppRoutes: app_router.dart
                // already imports this screen, so importing it back here
                // would create a circular dependency for one constant.
                // Registration itself is untouched — this only navigates to
                // the existing route.
                onTap: () => context.push('/register'),
                child: Text(
                  l10n.authRegisterAction,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}

/// B1: the third-or-later-tier refused state, shown for BOTH the Pending
/// and Not Authorized outcomes — Claude Design has one shared "cannot sign
/// in here" treatment for both, grey/neutral rather than error/red, since
/// nothing is wrong with the account itself.
class _DeviceLockedView extends StatelessWidget {
  const _DeviceLockedView({required this.l10n, required this.viewModel});

  final AppLocalizations l10n;
  final LoginViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.lg),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.cardPadding,
            vertical: AppSpacing.lg,
          ),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border.all(color: theme.colorScheme.outline),
            borderRadius: AppRadii.heroRadius,
            boxShadow: AppShadows.card,
          ),
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.smartphone,
                  size: 30,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.stepMd + 2),
              Text(
                l10n.loginDeviceLockedTitle,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.loginDeviceLockedBody,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          padding: const EdgeInsets.all(AppSpacing.cardPadding),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border.all(color: theme.colorScheme.outline),
            borderRadius: AppRadii.lgRadius,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.loginCrmHelpTitle,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.loginCrmHelpBody,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.phone, size: 18),
                label: Text(l10n.loginCallCrmAction),
              ),
            ],
          ),
        ),
        if (viewModel.step == LoginStep.authorizationPending) ...[
          const SizedBox(height: AppSpacing.md),
          Center(
            child: TextButton(
              onPressed: viewModel.checkAuthorizationAndRebindIfPossible,
              child: Text(l10n.loginAuthorizationRetry),
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        Text(
          l10n.loginNoPasswordResetNotice,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}

/// A2 (second-device tier), A3 (invalid code — plain error styling only;
/// no fixed attempt count/lockout/cooldown is implemented, since none is
/// defined by the business — spec.md's Design Note), and B2
/// (third-or-later tier, already authorized) — one shared body so the OTP
/// entry layout is never duplicated between tiers; only the banner above
/// the code boxes differs.
class _OtpEntryView extends StatelessWidget {
  const _OtpEntryView({
    required this.l10n,
    required this.viewModel,
    required this.otpController,
  });

  final AppLocalizations l10n;
  final LoginViewModel viewModel;
  final TextEditingController otpController;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final busy =
        viewModel.step == LoginStep.verifyingOtp ||
        viewModel.step == LoginStep.completingRebinding;
    final hasError = viewModel.step == LoginStep.invalidOtp;
    final isThirdOrLaterTier = viewModel.tier == DeviceMoveTier.thirdOrLater;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.lg),
        Text(l10n.otpEnterCodeTitle, style: theme.textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        if (isThirdOrLaterTier)
          AuthInfoBanner(
            tone: AuthBannerTone.success,
            radius: AppRadii.lg,
            padding: const EdgeInsets.all(16),
            icon: Icons.verified_outlined,
            title: l10n.loginCrmAuthorizedTitle,
            message: l10n.loginCrmAuthorizedBody,
          )
        else
          Text(
            viewModel.mobileNumber == null
                ? l10n.loginNewDeviceNotice
                : l10n.otpSentTo(viewModel.mobileNumber!),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        const SizedBox(height: AppSpacing.md),
        OtpCodeInput(
          controller: otpController,
          hasError: hasError,
          enabled: !busy,
        ),
        if (hasError) ...[
          const SizedBox(height: AppSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.error_outline,
                size: 16,
                color: theme.colorScheme.error,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  l10n.otpInvalidCode,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
            ],
          ),
        ],
        if (viewModel.step == LoginStep.rebindingFailed) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.loginRebindingFailed,
            style: TextStyle(color: theme.colorScheme.error),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: busy ? null : viewModel.resendOtp,
            child: Text(l10n.otpResendAction),
          ),
        ),
        if (viewModel.prototypeOtpCode != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.otpPrototypeCodeNotice(viewModel.prototypeOtpCode!),
            style: theme.textTheme.bodySmall,
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        if (!isThirdOrLaterTier)
          AuthInfoBanner(
            tone: AuthBannerTone.info,
            icon: Icons.smartphone,
            message: l10n.loginSecondDeviceMoveNotice,
          )
        else
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border.all(color: theme.colorScheme.outline),
              borderRadius: AppRadii.mdRadius,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InfoRow(text: l10n.loginOneMoveOnlyNotice),
                const SizedBox(height: AppSpacing.sm),
                _InfoRow(text: l10n.loginOldDeviceSignOutNotice),
              ],
            ),
          ),
        const SizedBox(height: AppSpacing.md),
        const Divider(),
        const SizedBox(height: AppSpacing.md),
        AuthPrimaryButton(
          label: l10n.otpVerifyAndSignInAction,
          loading: busy,
          onPressed: () => viewModel.submitOtp(otpController.text),
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColors = theme.extension<AppStatusColors>()!;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.info_outline, size: 16, color: statusColors.info),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}
