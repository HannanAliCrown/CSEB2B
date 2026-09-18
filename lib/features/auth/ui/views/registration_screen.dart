import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:cse_b2b/core/localization/generated/app_localizations.dart';
import 'package:cse_b2b/core/theme/app_colors.dart';
import 'package:cse_b2b/core/theme/app_spacing.dart';

import '../view_models/registration_view_model.dart';

/// Registration screen (User Story 1): mobile number → registration OTP →
/// initial device binding. A single screen with an internal state
/// transition between the mobile-number and OTP steps, rather than two
/// separate routes — the exact screen/dialog/inline breakdown Claude
/// Design specifies could not be inspected in this environment
/// (`/design-login` requires an interactive session); this is a
/// functional placeholder pending that visual sync (see spec.md §Design
/// Requirements), using the existing `lib/core/theme/` tokens only.
class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _mobileController = TextEditingController();
  final _otpController = TextEditingController();

  @override
  void dispose() {
    _mobileController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final viewModel = context.watch<RegistrationViewModel>();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.registrationTitle)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (viewModel.step == RegistrationStep.enterMobileNumber ||
                  viewModel.step == RegistrationStep.requestingOtp) ...[
                TextField(
                  controller: _mobileController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: l10n.authMobileNumberLabel,
                    hintText: l10n.authMobileNumberHint,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                ElevatedButton(
                  onPressed: viewModel.step == RegistrationStep.requestingOtp
                      ? null
                      : () => viewModel.submitMobileNumber(
                          _mobileController.text,
                        ),
                  child: Text(l10n.authContinueAction),
                ),
              ],
              if (viewModel.step == RegistrationStep.accountNotFound)
                Text(
                  l10n.authAccountNotFound,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              if (viewModel.step == RegistrationStep.alreadyRegistered)
                Text(
                  l10n.registrationAlreadyRegistered,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              if (viewModel.step == RegistrationStep.enterOtp ||
                  viewModel.step == RegistrationStep.verifyingOtp ||
                  viewModel.step == RegistrationStep.invalidOtp) ...[
                Text(l10n.registrationOtpPrompt),
                if (viewModel.prototypeOtpCode != null)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.sm),
                    child: Text(
                      l10n.otpPrototypeCodeNotice(viewModel.prototypeOtpCode!),
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: l10n.otpCodeLabel),
                ),
                if (viewModel.step == RegistrationStep.invalidOtp)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.sm),
                    child: Text(
                      l10n.otpInvalidCode,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ),
                const SizedBox(height: AppSpacing.md),
                ElevatedButton(
                  onPressed: viewModel.step == RegistrationStep.verifyingOtp
                      ? null
                      : () => viewModel.submitOtp(_otpController.text),
                  child: Text(l10n.otpVerifyAction),
                ),
              ],
              if (viewModel.step == RegistrationStep.success)
                Text(
                  l10n.registrationSuccess,
                  style: TextStyle(
                    color: theme.extension<AppStatusColors>()!.success,
                  ),
                ),
              if (viewModel.step == RegistrationStep.failed)
                Text(
                  l10n.registrationFailed,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
