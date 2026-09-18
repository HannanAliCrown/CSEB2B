import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/ui/ds.dart';
import '../../../design_preview/preview_journey.dart';
import '../widgets/registration_scaffold.dart';

/// Board 01 · H1 — Step 8 · Review and submit.
class RegistrationReviewScreen extends StatefulWidget {
  const RegistrationReviewScreen({super.key});

  @override
  State<RegistrationReviewScreen> createState() =>
      _RegistrationReviewScreenState();
}

class _RegistrationReviewScreenState extends State<RegistrationReviewScreen> {
  bool _declared = true;

  static const _rows = [
    ('Mobile number', '+92 300 4821190 · verified'),
    ('Role', 'Installer'),
    ('Full name', 'Muhammad Adnan Shahid'),
    ('Alternate number', '+92 333 1122998'),
    ('Business', 'Adnan Solar Works'),
    ('Business address', 'Shop 14, Bilal Market, Shahdara'),
    ('Market and pin', 'Ravi Road, Lahore · pin outside market, noted for CRM'),
    ('Media', '2 installation video links'),
    ('Buying source', 'Al-Noor Electric Store (verifies) · Hamza Solar House'),
    ('CNIC', 'Front, back, selfie · 35202-7719480-3'),
  ];

  @override
  Widget build(BuildContext context) {
    return RegistrationScaffold(
      title: 'Review and Submit',
      step: 7,
      gap: 14,
      footer: DsFooterBar(
        child: Column(
          children: [
            DsButton(label: 'Submit Registration', onPressed: () => PreviewJourney.next(context)),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Three approvals are needed before your account opens.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                height: 17 / 12,
                color: context.palette.textTertiary,
              ),
            ),
          ],
        ),
      ),
      children: [
        DsCard(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 4,
          ),
          child: Column(
            children: [
              for (var i = 0; i < _rows.length; i++)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.stepMd),
                  decoration: BoxDecoration(
                    border: i == _rows.length - 1
                        ? null
                        : Border(
                            bottom: BorderSide(color: context.palette.sunken),
                          ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 116,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            _rows[i].$1,
                            style: TextStyle(
                              fontSize: 12,
                              color: context.palette.textTertiary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.stepMd),
                      Expanded(
                        child: Text(
                          _rows[i].$2,
                          style: const TextStyle(
                            fontSize: 14,
                            height: 20 / 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'Edit',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: context.colors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        DsCheckbox(
          checked: _declared,
          label:
              'The information and documents I have given are correct, and '
              'Crown Solar may verify them with my buying source.',
          onChanged: (v) => setState(() => _declared = v),
        ),
      ],
    );
  }
}

/// Board 01 · H2 — Submitted · handoff to approval.
class RegistrationSubmittedScreen extends StatelessWidget {
  const RegistrationSubmittedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DsScreen(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      gap: AppSpacing.stepLg,
      crossAxisAlignment: CrossAxisAlignment.center,
      footer: DsFooterBar(
        child: DsButton(
          label: 'See Approval Status',
          iconAfter: LucideIcons.arrowRight,
          onPressed: () => PreviewJourney.next(context),
        ),
      ),
      sections: [
        const Center(
          child: DsIconMedallion(
            icon: LucideIcons.circleCheck,
            tone: DsTone.success,
            size: 88,
            iconSize: 44,
          ),
        ),
        Column(
          children: [
            Text(
              'Registration submitted',
              textAlign: TextAlign.center,
              style: context.texts.headlineSmall,
            ),
            const SizedBox(height: 10),
            const DsBody(
              'Your request has gone to your buying source, the Marketing '
              'Officer for Ravi Road, and Crown Solar CRM. All three must '
              'approve before your account opens.',
              size: 15,
              align: TextAlign.center,
            ),
          ],
        ),
        DsRowGroup(
          children: const [
            DsSettingRow(
              label: 'Reference',
              value: 'CSE-PR-2026-084119',
            ),
            DsSettingRow(label: 'Submitted', value: 'Today, 9:42 AM'),
          ],
        ),
      ],
    );
  }
}

/// Board 01 · H3 — Resume or discard a saved draft.
class RegistrationResumeScreen extends StatelessWidget {
  const RegistrationResumeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DsScreen(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      gap: AppSpacing.stepLg,
      sections: [
        Text(
          'Welcome to Crown Solar',
          style: context.texts.headlineSmall,
          textAlign: TextAlign.center,
        ),
        DsCard(
          padding: const EdgeInsets.all(AppSpacing.stepLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Continue your registration?',
                style: context.texts.titleLarge,
              ),
              const SizedBox(height: AppSpacing.sm),
              const DsBody(
                'You stopped at step 7 of 8 on 07 Sep. Your details and photos '
                'are saved on this phone.',
                size: 14,
              ),
              const SizedBox(height: AppSpacing.md),
              DsButton(label: 'Continue from Step 7', onPressed: () => PreviewJourney.next(context)),
              const SizedBox(height: 10),
              DsButton(
                label: 'Discard and Start Again',
                variant: DsButtonVariant.quiet,
                onPressed: () {},
              ),
            ],
          ),
        ),
        const DsCaption(
          'Discarding deletes the photos and links you captured. You will be '
          'asked to confirm.',
          align: TextAlign.center,
        ),
      ],
    );
  }
}
