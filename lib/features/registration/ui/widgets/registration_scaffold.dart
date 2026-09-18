import 'package:flutter/material.dart';

import '../../../../core/ui/ds.dart';

/// The eight named steps of the registration wizard, as the design's progress
/// meter labels them.
const registrationSteps = [
  'Number',
  'Role',
  'Details',
  'Media',
  'OTP',
  'Source',
  'CNIC',
  'Review',
];

/// Every wizard step shares this frame: a titled app bar carrying "Step n of
/// 8", the progress meter beneath it, the step's content, and a sticky
/// primary action.
class RegistrationScaffold extends StatelessWidget {
  const RegistrationScaffold({
    super.key,
    required this.title,
    required this.step,
    required this.children,
    this.subtitleSuffix,
    this.footer,
    this.gap = AppSpacing.stepLg,
    this.showProgress = true,
  });

  final String title;

  /// Zero-based index into [registrationSteps].
  final int step;
  final List<Widget> children;

  /// e.g. ` · Installer` on the media step, or ` · 1 of 3 captures`.
  final String? subtitleSuffix;
  final Widget? footer;
  final double gap;
  final bool showProgress;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: DsAppBar(
        title: title,
        subtitle: 'Step ${step + 1} of 8${subtitleSuffix ?? ''}',
        onBack: () => Navigator.of(context).maybePop(),
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showProgress)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenPadding,
                  AppSpacing.stepMd,
                  AppSpacing.screenPadding,
                  0,
                ),
                child: DsProgressSteps(
                  steps: registrationSteps,
                  current: step,
                ),
              ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.screenPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < children.length; i++) ...[
                      children[i],
                      if (i != children.length - 1) SizedBox(height: gap),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: footer,
    );
  }
}

/// The heading pair every wizard step opens with: a 24/30/600 question and a
/// 14/20 explanation.
class RegistrationPrompt extends StatelessWidget {
  const RegistrationPrompt({super.key, required this.question, this.detail});

  final String question;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(question, style: context.texts.headlineSmall),
        if (detail != null) ...[
          const SizedBox(height: AppSpacing.sm),
          DsBody(detail!, size: 14),
        ],
      ],
    );
  }
}
