import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/registration_draft.dart';
import '../registration_scope.dart';
import '../view_models/registration_flow_view_model.dart';
import 'registration_cnic_screens.dart';
import 'registration_review_screens.dart';
import 'registration_source_screens.dart';
import 'registration_wizard_screens.dart';

/// Runs the eight-step registration wizard over the existing screens.
///
/// Each state names a screen that already exists; this widget only decides
/// which one is on screen and keeps the system back button attached to the
/// wizard's own back behaviour, so moving backwards never loses what was
/// entered.
class RegistrationFlowScreen extends StatefulWidget {
  const RegistrationFlowScreen({
    super.key,
    required this.onGoToLogin,
    required this.onSeeApprovalStatus,
  });

  final VoidCallback onGoToLogin;

  /// Opens the real approval screen for the number that was just submitted.
  final ValueChanged<String> onSeeApprovalStatus;

  @override
  State<RegistrationFlowScreen> createState() => _RegistrationFlowScreenState();
}

class _RegistrationFlowScreenState extends State<RegistrationFlowScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RegistrationFlowViewModel>().start();
    });
  }

  @override
  Widget build(BuildContext context) {
    final flow = context.watch<RegistrationFlowViewModel>();

    return RegistrationScope(
      model: flow,
      child: PopScope(
        canPop: flow.step == RegistrationStep.number,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) flow.back();
        },
        child: _screenFor(flow),
      ),
    );
  }

  Widget _screenFor(RegistrationFlowViewModel flow) {
    switch (flow.stage) {
      case RegistrationStage.resume:
        return const RegistrationResumeScreen();

      case RegistrationStage.submitted:
        return RegistrationSubmittedScreen(
          onSeeStatus: () =>
              widget.onSeeApprovalStatus(flow.draft.fullMobileNumber),
        );

      case RegistrationStage.shopPin:
        return const RegistrationPinDropScreen();

      case RegistrationStage.cnicNumber:
        return const CnicNumberScreen();

      case RegistrationStage.wizard:
        return _wizardScreen(flow);
    }
  }

  Widget _wizardScreen(RegistrationFlowViewModel flow) {
    switch (flow.step) {
      case RegistrationStep.number:
        // The number already belonging to an account has its own screen.
        return flow.existingAccount?.exists ?? false
            ? RegistrationNumberTakenScreen(onGoToLogin: widget.onGoToLogin)
            : const RegistrationNumberScreen();

      case RegistrationStep.role:
        return const RegistrationRoleScreen();

      case RegistrationStep.details:
        return const RegistrationDetailsScreen();

      case RegistrationStep.media:
        // Step 4 asks for what the chosen role actually has: an installer's
        // work is video links, a retailer's is shop photos.
        return flow.draft.role == RegistrationRole.retailer
            ? const RegistrationRetailerMediaScreen()
            : const RegistrationInstallerMediaScreen();

      case RegistrationStep.otp:
        return const RegistrationOtpScreen();

      case RegistrationStep.source:
        return const RegistrationSourceScreen();

      case RegistrationStep.cnic:
        // The three captures are listed first, and each one opens the camera
        // only when it is chosen. Confirming the number is a separate stage
        // reached from that list.
        return const CnicReviewScreen();

      case RegistrationStep.review:
        return const RegistrationReviewScreen();
    }
  }
}
