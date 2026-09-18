import 'package:flutter/material.dart';

import 'view_models/registration_flow_view_model.dart';

/// Makes the wizard's ViewModel available to the existing registration
/// screens without changing how any of them look.
///
/// A screen asks for it with [maybeOf]. Outside the flow — in the design
/// preview, where each screen is opened on its own — there is no scope, the
/// lookup returns null, and the screen renders its design content exactly as
/// before.
class RegistrationScope extends InheritedNotifier<RegistrationFlowViewModel> {
  const RegistrationScope({
    super.key,
    required RegistrationFlowViewModel model,
    required super.child,
  }) : super(notifier: model);

  static RegistrationFlowViewModel? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<RegistrationScope>()
        ?.notifier;
  }
}
