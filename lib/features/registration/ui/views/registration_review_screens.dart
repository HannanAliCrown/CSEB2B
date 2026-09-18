import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/ui/ds.dart';
import '../../../design_preview/preview_journey.dart';
import '../../data/models/registration_draft.dart';
import '../registration_scope.dart';
import '../view_models/registration_flow_view_model.dart';
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

  static const _sampleRows = [
    ('Mobile number', '+92 300 4821190 · verified', RegistrationStep.number),
    ('Role', 'Installer', RegistrationStep.role),
    ('Full name', 'Muhammad Adnan Shahid', RegistrationStep.details),
    ('Alternate number', '+92 333 1122998', RegistrationStep.details),
    ('Business', 'Adnan Solar Works', RegistrationStep.details),
    (
      'Business address',
      'Shop 14, Bilal Market, Shahdara',
      RegistrationStep.details,
    ),
    (
      'Market and pin',
      'Ravi Road, Lahore · pin outside market, noted for CRM',
      RegistrationStep.details,
    ),
    ('Media', '2 installation video links', RegistrationStep.media),
    (
      'Buying source',
      'Al-Noor Electric Store (verifies) · Hamza Solar House',
      RegistrationStep.source,
    ),
    ('CNIC', 'Front, back, selfie · 35202-7719480-3', RegistrationStep.cnic),
  ];

  /// The application as entered, in the order the design lists it.
  List<(String, String, RegistrationStep)> _rowsFor(
    RegistrationFlowViewModel flow,
  ) {
    final draft = flow.draft;
    final media = draft.role == RegistrationRole.installer
        ? '${draft.videoLinks.where((l) => l.trim().isNotEmpty).length} '
              'installation video links'
        : '${draft.shopImagePaths.length} shop photos';
    final sources = draft.buyingSources.isEmpty
        ? 'Not added'
        : [
            '${draft.buyingSources.first.summary} (verifies)',
            ...draft.buyingSources.skip(1).map((s) => s.summary),
          ].join(' · ');
    final cnicCaptures = [
      if (draft.cnicFrontPath != null) 'front',
      if (draft.cnicBackPath != null) 'back',
      if (draft.selfiePath != null) 'selfie',
    ].join(', ');

    return [
      (
        'Mobile number',
        '${draft.fullMobileNumber}${draft.mobileVerified ? ' · verified' : ''}',
        RegistrationStep.number,
      ),
      ('Role', draft.role?.label ?? 'Not chosen', RegistrationStep.role),
      ('Full name', draft.fullName, RegistrationStep.details),
      (
        'Alternate number',
        draft.alternateNumber.isEmpty ? 'Not given' : draft.alternateNumber,
        RegistrationStep.details,
      ),
      ('Business', draft.businessName, RegistrationStep.details),
      ('Business address', draft.businessAddress, RegistrationStep.details),
      (
        'Market and pin',
        draft.hasShopPin
            ? '${draft.market ?? ''} · pin placed'
            : '${draft.market ?? ''} · no pin placed',
        RegistrationStep.details,
      ),
      ('Media', media, RegistrationStep.media),
      ('Buying source', sources, RegistrationStep.source),
      (
        'CNIC',
        cnicCaptures.isEmpty
            ? draft.cnicNumber
            : '$cnicCaptures · ${draft.cnicNumber}',
        RegistrationStep.cnic,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final flow = RegistrationScope.maybeOf(context);
    final rows = flow == null ? _sampleRows : _rowsFor(flow);

    return RegistrationScaffold(
      title: 'Review and Submit',
      step: 7,
      gap: 14,
      footer: DsFooterBar(
        child: Column(
          children: [
            DsButton(
              label: 'Submit Registration',
              loading: flow?.busy ?? false,
              disabled: flow != null && !_declared,
              onPressed: flow == null
                  ? () => PreviewJourney.next(context)
                  : flow.submitRegistration,
            ),
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
              for (var i = 0; i < rows.length; i++)
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.stepMd,
                  ),
                  decoration: BoxDecoration(
                    border: i == rows.length - 1
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
                            rows[i].$1,
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
                          rows[i].$2,
                          style: const TextStyle(
                            fontSize: 14,
                            height: 20 / 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      GestureDetector(
                        onTap: flow == null
                            ? null
                            : () => flow.editStep(rows[i].$3),
                        child: Text(
                          'Edit',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: context.colors.primary,
                          ),
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
  const RegistrationSubmittedScreen({super.key, this.onSeeStatus});

  final VoidCallback? onSeeStatus;

  @override
  Widget build(BuildContext context) {
    final flow = RegistrationScope.maybeOf(context);
    final submission = flow?.submission;

    return DsScreen(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      gap: AppSpacing.stepLg,
      crossAxisAlignment: CrossAxisAlignment.center,
      footer: DsFooterBar(
        child: DsButton(
          label: 'See Approval Status',
          iconAfter: LucideIcons.arrowRight,
          onPressed: onSeeStatus ?? () => PreviewJourney.next(context),
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
          children: [
            DsSettingRow(
              label: 'Reference',
              value: submission?.reference ?? 'CSE-PR-2026-084119',
            ),
            DsSettingRow(
              label: 'Submitted',
              value: submission == null
                  ? 'Today, 9:42 AM'
                  : 'Today, ${TimeOfDay.fromDateTime(submission.submittedAt).format(context)}',
            ),
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
    final flow = RegistrationScope.maybeOf(context);
    final draft = flow?.draft;
    final stoppedAt = draft == null
        ? 7
        : RegistrationStep.values[draft.stepIndex].number;
    final savedOn = draft?.updatedAt;

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
              DsBody(
                flow == null
                    ? 'You stopped at step 7 of 8 on 07 Sep. Your details and '
                          'photos are saved on this phone.'
                    : 'You stopped at step $stoppedAt of 8'
                          '${savedOn == null ? '' : ' on ${savedOn.day} '
                                    '${_month(savedOn.month)}'}. Your details and '
                          'photos are saved on this phone.',
                size: 14,
              ),
              const SizedBox(height: AppSpacing.md),
              DsButton(
                label: 'Continue from Step $stoppedAt',
                onPressed: flow?.resumeDraft ?? () {},
              ),
              const SizedBox(height: 10),
              DsButton(
                label: 'Discard and Start Again',
                variant: DsButtonVariant.quiet,
                onPressed: flow?.discardDraft ?? () {},
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

/// Short month names for the resume screen's "saved on" line.
String _month(int month) => const [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
][month - 1];
