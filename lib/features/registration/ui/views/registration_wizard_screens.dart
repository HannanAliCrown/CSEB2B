import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/ui/ds.dart';
import '../../../design_preview/preview_journey.dart';
import '../widgets/registration_scaffold.dart';

Widget _continueFooter(BuildContext context, {String label = 'Continue'}) {
  return DsFooterBar(
    child: DsButton(
      label: label,
      iconAfter: LucideIcons.arrowRight,
      onPressed: () => PreviewJourney.next(context),
    ),
  );
}

/// Board 01 · B1 — Step 1 · Mobile number.
class RegistrationNumberScreen extends StatelessWidget {
  const RegistrationNumberScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return RegistrationScaffold(
      title: 'Register',
      step: 0,
      footer: _continueFooter(context),
      children: const [
        RegistrationPrompt(
          question: 'What is your mobile number?',
          detail:
              'This becomes your login. We will validate it with a code later '
              'in this form.',
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            SizedBox(
              width: 96,
              child: DsInput(label: 'Code', value: '+92'),
            ),
            SizedBox(width: 10),
            Expanded(
              child: DsInput(
                label: 'Mobile number',
                value: '300 4821190',
                keyboardType: TextInputType.phone,
              ),
            ),
          ],
        ),
        DsNotice(
          icon: LucideIcons.info,
          message:
              'One account per number. If this number is already registered we '
              'will take you to Login instead.',
        ),
      ],
    );
  }
}

/// Board 01 · B2 — the number already has an account.
class RegistrationNumberTakenScreen extends StatelessWidget {
  const RegistrationNumberTakenScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return RegistrationScaffold(
      title: 'Register',
      step: 0,
      footer: _continueFooter(context),
      children: [
        const RegistrationPrompt(question: 'What is your mobile number?'),
        const Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            SizedBox(width: 96, child: DsInput(label: 'Code', value: '+92')),
            SizedBox(width: 10),
            Expanded(
              child: DsInput(
                label: 'Mobile number',
                value: '321 7745002',
                keyboardType: TextInputType.phone,
              ),
            ),
          ],
        ),
        DsCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const DsIconMedallion(
                    icon: LucideIcons.userCheck,
                    tone: DsTone.info,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'This number already has a Crown Solar account.',
                      style: context.texts.bodyLarge?.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.stepMd),
              const DsBody(
                '+92 321 7745002 is registered to a Retailer account.',
              ),
              const SizedBox(height: AppSpacing.stepMd),
              DsButton(
                label: 'Go to Login',
                icon: LucideIcons.logIn,
                size: DsButtonSize.sm,
                onPressed: () => PreviewJourney.next(context),
              ),
            ],
          ),
        ),
        const DsCaption(
          'Using a different number? Edit the field above and continue.',
        ),
      ],
    );
  }
}

/// Board 01 · B3 — Step 2 · Role selection.
class RegistrationRoleScreen extends StatefulWidget {
  const RegistrationRoleScreen({super.key});

  @override
  State<RegistrationRoleScreen> createState() => _RegistrationRoleScreenState();
}

class _RegistrationRoleScreenState extends State<RegistrationRoleScreen> {
  String _role = 'Installer';

  @override
  Widget build(BuildContext context) {
    return RegistrationScaffold(
      title: 'Register',
      step: 1,
      gap: AppSpacing.md,
      footer: DsFooterBar(
        child: DsButton(
          label: 'Continue as $_role',
          iconAfter: LucideIcons.arrowRight,
          onPressed: () => PreviewJourney.next(context),
        ),
      ),
      children: [
        const RegistrationPrompt(
          question: 'How do you work with Crown Solar?',
          detail:
              'This decides what the app shows you. It can be changed later '
              'only by CRM.',
        ),
        Column(
          children: [
            DsOptionCard(
              title: 'Installer',
              description:
                  'I install solar systems for customers. Scan products to '
                  'earn prizes and spins.',
              icon: LucideIcons.hardHat,
              selected: _role == 'Installer',
              onTap: () => setState(() => _role = 'Installer'),
            ),
            const SizedBox(height: AppSpacing.stepMd),
            DsOptionCard(
              title: 'Retailer',
              description:
                  'I sell Crown Solar products from a shop. Earn points, sign '
                  'schemes, approve cash requests.',
              icon: LucideIcons.store,
              selected: _role == 'Retailer',
              onTap: () => setState(() => _role = 'Retailer'),
            ),
          ],
        ),
        const DsNotice(
          icon: LucideIcons.info,
          message:
              'Wholesaler and Distributor accounts are set up by Crown Solar '
              'CRM. Register as Retailer and CRM will change your class if it '
              'applies to you.',
        ),
      ],
    );
  }
}

/// Board 01 · C1 — Step 3 · Details form.
class RegistrationDetailsScreen extends StatelessWidget {
  const RegistrationDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return RegistrationScaffold(
      title: 'Your Details',
      step: 2,
      gap: 14,
      footer: _continueFooter(context),
      children: [
        const DsInput(label: 'Full name', value: 'Muhammad Adnan Shahid'),
        const DsInput(
          label: 'Alternate mobile number',
          placeholder: 'Optional · a second way to reach you',
        ),
        const DsInput(label: 'Business name', value: 'Adnan Solar Works'),
        const DsInput(
          label: 'Business address',
          value: 'Shop 14, Bilal Market, Shahdara',
        ),
        const DsSelect(label: 'Market', value: 'Ravi Road, Lahore'),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Shop location on the map',
              style: context.texts.labelLarge?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            const DsMapPlaceholder(
              coordinates: '31.5871° N, 74.3142° E',
              actionLabel: 'Drop pin on map',
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'The pin can be different from where your phone is right now, '
              'and from the business address you typed above.',
              style: context.texts.bodySmall?.copyWith(
                height: 17 / 12,
                color: context.palette.textTertiary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Board 01 · C2 — Pin drop · market mismatch, non-blocking.
class RegistrationPinDropScreen extends StatelessWidget {
  const RegistrationPinDropScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: DsAppBar(
        title: 'Pin Your Shop',
        onBack: () => Navigator.of(context).maybePop(),
      ),
      body: Column(
        children: [
          const Expanded(child: DsMapPlaceholder(height: null)),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            child: DsNotice(
              icon: LucideIcons.triangleAlert,
              tone: DsTone.warning,
              message:
                  'Your pin is outside Ravi Road, Lahore, and different from '
                  'where your phone is right now. Both are fine — you can '
                  'still continue, and Crown Solar CRM will check the location '
                  'with you.',
              action: DsButton(
                label: 'Confirm This Location',
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Board 01 · D1 — Step 4 · Installer · installation video links.
class RegistrationInstallerMediaScreen extends StatelessWidget {
  const RegistrationInstallerMediaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return RegistrationScaffold(
      title: 'Installation Videos',
      step: 3,
      subtitleSuffix: ' · Installer',
      gap: 14,
      footer: _continueFooter(context),
      children: const [
        DsBody(
          'Share links to three videos of installations you have done — '
          'YouTube, Google Drive or WhatsApp links all work.',
          size: 14,
        ),
        DsInput(
          label: 'Installation video 1',
          value: 'youtu.be/8k-install-lhr01',
          hint: 'Required',
        ),
        DsInput(
          label: 'Installation video 2',
          placeholder: 'Paste a video link',
          hint: 'Required',
        ),
        DsInput(
          label: 'Installation video 3',
          placeholder: 'Paste a video link',
          hint: 'Optional',
        ),
        DsNotice(
          icon: LucideIcons.info,
          message:
              'Two links are required to continue. The third is optional and '
              'helps your approval move faster.',
        ),
      ],
    );
  }
}

/// Board 01 · D2 — Step 4 · Retailer · Shop Board, Stock, Image.
class RegistrationRetailerMediaScreen extends StatelessWidget {
  const RegistrationRetailerMediaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return RegistrationScaffold(
      title: 'Shop Images',
      step: 3,
      subtitleSuffix: ' · Retailer',
      gap: 14,
      footer: _continueFooter(context),
      children: const [
        DsBody(
          'Add three photos of your shop. Shop Board and Shop Image are '
          'required; Shop Stock is optional.',
          size: 14,
        ),
        DsUploadRow(
          label: 'Shop Board',
          meta: 'Required · not added',
          state: DsUploadState.empty,
        ),
        DsUploadRow(
          label: 'Shop Stock',
          meta: 'Optional · not added',
          state: DsUploadState.empty,
        ),
        DsUploadRow(
          label: 'Shop Image',
          meta: 'Uploaded',
          state: DsUploadState.uploaded,
        ),
        DsNotice(
          icon: LucideIcons.camera,
          message:
              'Camera or gallery for these photos. Shop Stock can be added '
              'later from Profile if you skip it now.',
        ),
      ],
    );
  }
}

/// Board 01 · E1 — Step 5 · Verify your number.
class RegistrationOtpScreen extends StatelessWidget {
  const RegistrationOtpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return RegistrationScaffold(
      title: 'Verify Your Number',
      step: 4,
      footer: DsFooterBar(
        child: DsButton(label: 'Verify and Continue', onPressed: () => PreviewJourney.next(context)),
      ),
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            DsHeading('Enter the 6-digit code'),
            SizedBox(height: AppSpacing.sm),
            DsBody('Sent by SMS to +92 300 4821190.', size: 14),
          ],
        ),
        const DsOtpBoxes(digits: '4812', focusedIndex: 4),
        DsResendRow(countdown: '00:24'),
        const DsNotice(
          icon: LucideIcons.save,
          tone: DsTone.info,
          message:
              'Your details and photos from the last two steps are already '
              'saved. Verifying just confirms this number is really yours.',
        ),
      ],
    );
  }
}

/// Board 01 · E2 — Wrong code, then rate limit.
class RegistrationOtpLockedScreen extends StatelessWidget {
  const RegistrationOtpLockedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return RegistrationScaffold(
      title: 'Verify Your Number',
      step: 4,
      showProgress: false,
      footer: const DsFooterBar(
        child: DsButton(label: 'Verify and Continue', disabled: true),
      ),
      children: [
        const DsHeading('Enter the 6-digit code'),
        const DsOtpBoxes(digits: '904176', error: true),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(LucideIcons.circleAlert, size: 16, color: context.colors.error),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: DsBody(
                'That code is not correct. 2 attempts left before verification '
                'is paused.',
                color: context.status.error,
              ),
            ),
          ],
        ),
        DsCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const DsIconMedallion(
                    icon: LucideIcons.clockAlert,
                    tone: DsTone.warning,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Verification paused',
                      style: context.texts.bodyLarge?.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.stepMd),
              const DsBody(
                'Too many incorrect codes. Try again at 10:02 AM. Your '
                'progress in this registration is saved either way.',
              ),
            ],
          ),
        ),
      ],
    );
  }
}
