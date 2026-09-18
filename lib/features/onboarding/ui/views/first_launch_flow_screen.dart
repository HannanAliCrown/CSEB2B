import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../registration/ui/views/first_launch_screens.dart';
import '../view_models/first_launch_view_model.dart';

/// Hosts the existing first-launch screens and shows whichever one the
/// current step calls for.
///
/// The screens themselves are unchanged: this widget only decides which is
/// on screen and passes the callbacks they now accept. The notification and
/// location prompts are the platform's own dialogs, shown over the brand
/// splash — the app never draws an imitation of them.
class FirstLaunchFlowScreen extends StatefulWidget {
  const FirstLaunchFlowScreen({super.key, required this.onComplete});

  final VoidCallback onComplete;

  @override
  State<FirstLaunchFlowScreen> createState() => _FirstLaunchFlowScreenState();
}

class _FirstLaunchFlowScreenState extends State<FirstLaunchFlowScreen> {
  bool _handedOff = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FirstLaunchViewModel>().start();
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<FirstLaunchViewModel>();

    if (viewModel.step == FirstLaunchStep.complete && !_handedOff) {
      _handedOff = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => widget.onComplete());
    }

    return switch (viewModel.step) {
      // While an OS dialog is up, the design's navy splash is what shows
      // behind it.
      FirstLaunchStep.starting ||
      FirstLaunchStep.requestingNotifications ||
      FirstLaunchStep.requestingLocation ||
      FirstLaunchStep.complete => const Scaffold(body: BrandSplash()),

      FirstLaunchStep.language => SelectLanguageScreen(
        language: _labelFor(viewModel.selectedLanguage),
        remember: viewModel.rememberLanguage,
        onLanguageChanged: (label) => viewModel.selectLanguage(_codeFor(label)),
        onRememberChanged: (remember) =>
            viewModel.setRememberLanguage(remember: remember),
        onConfirm: viewModel.confirmLanguage,
      ),

      FirstLaunchStep.locationEducation => LocationPermissionScreen(
        onAllow: viewModel.allowLocation,
        onNotNow: viewModel.skipLocation,
      ),

      FirstLaunchStep.locationOff => LocationOffScreen(
        onOpenSettings: viewModel.openSystemSettings,
        onContinueWithout: viewModel.continueWithoutLocation,
        onBack: viewModel.continueWithoutLocation,
      ),
    };
  }

  /// The modal labels the design uses, mapped to the locale codes the app
  /// stores.
  static String _labelFor(String code) => switch (code) {
    'ur' => 'اردو',
    'ur_Latn' => 'Roman Urdu',
    _ => 'English',
  };

  static String _codeFor(String label) => switch (label) {
    'اردو' => 'ur',
    'Roman Urdu' => 'ur_Latn',
    _ => 'en',
  };
}
