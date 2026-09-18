import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/ui/ds.dart';
import '../../../design_preview/preview_journey.dart';
import '../registration_scope.dart';
import '../widgets/registration_scaffold.dart';

/// Board 01 · G1 — CNIC front · camera only.
///
/// A dark capture surface with a gold-cornered frame; there is no gallery
/// option for identity documents.
class CnicCaptureScreen extends StatelessWidget {
  const CnicCaptureScreen({
    super.key,
    this.capture,
    this.title = 'CNIC — Front',
  });

  /// Which capture the shutter takes. Always the camera.
  final Future<void> Function()? capture;
  final String title;

  @override
  Widget build(BuildContext context) {
    final flow = RegistrationScope.maybeOf(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0B0F14),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenPadding,
                AppSpacing.sm,
                AppSpacing.screenPadding,
                AppSpacing.md,
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).maybePop(),
                    child: const Icon(
                      LucideIcons.chevronLeft,
                      size: 24,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Step 7 of 8 · 1 of 3 captures',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AspectRatio(
                      aspectRatio: 1.58,
                      child: _CaptureFrame(gold: context.palette.crownGold),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Place the front of your CNIC inside the frame.\n'
                      'Keep it flat and avoid glare.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        height: 20 / 14,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, AppSpacing.stepLg, 24, 34),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        LucideIcons.zapOff,
                        size: 20,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'Flash off',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () async {
                      final take = capture ?? flow?.captureCnicFront;
                      if (take == null) return;
                      await take();
                      flow?.openCnicReview();
                    },
                    child: Container(
                      width: 70,
                      height: 70,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.85),
                          width: 4,
                        ),
                      ),
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 70,
                    child: Text(
                      'Camera only',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
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

class _CaptureFrame extends StatelessWidget {
  const _CaptureFrame({required this.gold});

  final Color gold;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: AppRadii.lgRadius,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.9),
              width: 2,
            ),
          ),
        ),
        Positioned(
          top: -1,
          left: -1,
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppRadii.lg),
              ),
              border: Border(
                top: BorderSide(color: gold, width: 4),
                left: BorderSide(color: gold, width: 4),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -1,
          right: -1,
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                bottomRight: Radius.circular(AppRadii.lg),
              ),
              border: Border(
                bottom: BorderSide(color: gold, width: 4),
                right: BorderSide(color: gold, width: 4),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Board 01 · G2 — Review, retake, upload progress.
///
/// All three capture states are shown at once: uploaded, uploading, failed.
class CnicReviewScreen extends StatelessWidget {
  const CnicReviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final flow = RegistrationScope.maybeOf(context);
    final draft = flow?.draft;

    return RegistrationScaffold(
      title: 'Check Your Captures',
      step: 6,
      gap: 14,
      footer: DsFooterBar(
        child: DsButton(
          label: 'Continue',
          onPressed: flow?.closeSubStage ?? () {},
        ),
      ),
      children: flow == null
          ? const [
              DsUploadRow(
                label: 'CNIC front',
                meta: 'Uploaded',
                state: DsUploadState.uploaded,
                icon: LucideIcons.idCard,
              ),
              DsUploadRow(
                label: 'CNIC back',
                meta: 'Uploading · 64%',
                state: DsUploadState.uploading,
                progress: 0.64,
                icon: LucideIcons.idCard,
              ),
              DsUploadRow(
                label: 'Liveness selfie',
                meta: 'Upload failed. Your photo is still saved on this phone.',
                state: DsUploadState.failed,
                icon: LucideIcons.scanFace,
              ),
              DsNotice(
                icon: LucideIcons.shieldCheck,
                message:
                    'Your CNIC images and selfie are encrypted and seen only '
                    'by the Crown Solar approval team.',
              ),
            ]
          : [
              DsUploadRow(
                label: 'CNIC front',
                meta: draft!.cnicFrontPath == null
                    ? 'Not captured'
                    : 'Captured',
                state: draft.cnicFrontPath == null
                    ? DsUploadState.empty
                    : DsUploadState.uploaded,
                icon: LucideIcons.idCard,
                onAction: flow.captureCnicFront,
              ),
              DsUploadRow(
                label: 'CNIC back',
                meta: draft.cnicBackPath == null ? 'Not captured' : 'Captured',
                state: draft.cnicBackPath == null
                    ? DsUploadState.empty
                    : DsUploadState.uploaded,
                icon: LucideIcons.idCard,
                onAction: flow.captureCnicBack,
              ),
              DsUploadRow(
                label: 'Liveness selfie',
                meta: draft.selfiePath == null ? 'Not captured' : 'Captured',
                state: draft.selfiePath == null
                    ? DsUploadState.empty
                    : DsUploadState.uploaded,
                icon: LucideIcons.scanFace,
                onAction: flow.captureSelfie,
              ),
              const DsNotice(
                icon: LucideIcons.shieldCheck,
                message:
                    'Your CNIC images and selfie are encrypted and seen only '
                    'by the Crown Solar approval team.',
              ),
            ],
    );
  }
}

/// Board 01 · G3 — CNIC number · read from the image.
class CnicNumberScreen extends StatefulWidget {
  const CnicNumberScreen({super.key});

  @override
  State<CnicNumberScreen> createState() => _CnicNumberScreenState();
}

class _CnicNumberScreenState extends State<CnicNumberScreen> {
  TextEditingController? _cnic;

  @override
  void dispose() {
    _cnic?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final flow = RegistrationScope.maybeOf(context);
    _cnic ??= TextEditingController(
      text: flow?.draft.cnicNumber ?? '35202-7719480-3',
    );

    return RegistrationScaffold(
      title: 'Confirm CNIC Number',
      step: 6,
      showProgress: false,
      footer: DsFooterBar(
        child: Column(
          children: [
            DsButton(
              label: 'Yes, This Is Correct',
              onPressed: flow == null
                  ? () => PreviewJourney.next(context)
                  : flow.next,
            ),
            const SizedBox(height: 10),
            DsButton(
              label: 'Retake CNIC Photo',
              variant: DsButtonVariant.quiet,
              icon: LucideIcons.camera,
              onPressed: flow?.captureCnicFront ?? () {},
            ),
          ],
        ),
      ),
      children: [
        const DsBody(
          'We read this number from your CNIC photo. Please check every digit '
          'before continuing — a wrong number delays approval.',
          size: 14,
        ),
        DsCard(
          tone: DsCardTone.sunken,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'READ FROM IMAGE',
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 0.06 * 11,
                  fontWeight: FontWeight.w600,
                  color: context.palette.textTertiary,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                '35202-7719480-3',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ),
        DsInput(
          label: 'CNIC number',
          controller: _cnic,
          onChanged: (value) =>
              flow?.updateDraft((d) => d.copyWith(cnicNumber: value)),
          hint: 'Tap to correct any digit that does not match your card.',
          error: flow?.error,
        ),
        const DsCaption(
          'If nothing could be read, this field arrives empty and you type the '
          'number yourself — the flow is never blocked.',
        ),
      ],
    );
  }
}
