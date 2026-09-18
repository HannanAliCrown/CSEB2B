import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/ui/ds.dart';

/// Board 08 · A1 — My Complaints: one ticket per row, its type, when it was
/// raised and its priority.
class ComplaintsListScreen extends StatefulWidget {
  const ComplaintsListScreen({super.key});

  @override
  State<ComplaintsListScreen> createState() => _ComplaintsListScreenState();
}

class _ComplaintsListScreenState extends State<ComplaintsListScreen> {
  String _tab = 'In Progress · 2';

  static const _complaints = [
    (
      'CMP-2026-5514',
      'Prize not credited for inverter scan',
      'In Progress',
      DsTone.info,
      'QR prize dispute · raised Today, 4:08 PM',
      'HIGH',
      DsTone.error,
    ),
    (
      'CMP-2026-5390',
      'Board installed with wrong shop name',
      'In Progress',
      DsTone.info,
      'Shop branding · raised 04 Sep',
      'MEDIUM',
      DsTone.warning,
    ),
    (
      'CMP-2026-5102',
      'Points missing for August purchase',
      'Resolved',
      DsTone.success,
      'Points · raised 22 Aug',
      'MEDIUM',
      DsTone.warning,
    ),
    (
      'CMP-2026-4977',
      'Cannot sign in on my new phone',
      'Resolved',
      DsTone.success,
      'Account and access · raised 14 Aug',
      'LOW',
      DsTone.neutral,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: DsAppBar(
        title: 'My Complaints',
        onBack: () => Navigator.of(context).maybePop(),
        actions: [DsIconButton(icon: LucideIcons.plus, onPressed: () {})],
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DsTabs(
              tabs: const ['In Progress · 2', 'Resolved'],
              value: _tab,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPadding,
              ),
              onChanged: (tab) => setState(() => _tab = tab),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.screenPadding),
                itemCount: _complaints.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSpacing.stepMd),
                itemBuilder: (context, i) {
                  final c = _complaints[i];
                  return DsCard(
                    onTap: () {},
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                c.$1,
                                style: TextStyle(
                                  fontSize: 11,
                                  letterSpacing: 0.06 * 11,
                                  fontWeight: FontWeight.w600,
                                  color: context.palette.textTertiary,
                                ),
                              ),
                            ),
                            DsTag(label: c.$6, tone: c.$7, uppercase: true),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          c.$2,
                          style: context.texts.bodyLarge?.copyWith(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          children: [
                            DsTag(label: c.$3, tone: c.$4),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(child: DsCaption(c.$5)),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Board 08 · A2 — New complaint: type, sub-type and priority, with the
/// response targets that follow from them stated before submitting.
class NewComplaintScreen extends StatefulWidget {
  const NewComplaintScreen({super.key});

  @override
  State<NewComplaintScreen> createState() => _NewComplaintScreenState();
}

class _NewComplaintScreenState extends State<NewComplaintScreen> {
  String _type = 'QR and prizes';
  String _priority = 'High';

  static const _types = [
    ('QR and prizes', LucideIcons.qrCode),
    ('Wallet and cash', LucideIcons.wallet),
    ('Points', LucideIcons.award),
    ('Shop branding', LucideIcons.store),
    ('Account and access', LucideIcons.userCog),
    ('Something else', LucideIcons.circleHelp),
  ];

  @override
  Widget build(BuildContext context) {
    return DsScreen(
      appBar: DsAppBar(
        title: 'New Complaint',
        subtitle: 'Step 1 of 3',
        onBack: () => Navigator.of(context).maybePop(),
      ),
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      gap: AppSpacing.md,
      footer: DsFooterBar(
        child: DsButton(
          label: 'Continue',
          iconAfter: LucideIcons.arrowRight,
          onPressed: () {},
        ),
      ),
      sections: [
        Text('What is it about?', style: context.texts.titleMedium),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final (label, icon) in _types)
              DsFilterChip(
                label: label,
                icon: icon,
                selected: _type == label,
                onTap: () => setState(() => _type = label),
              ),
          ],
        ),
        const DsSelect(
          label: 'Which part?',
          value: 'Prize not credited after scan',
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How urgent is it?',
              style: context.texts.labelLarge?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            DsSegmentedControl(
              options: const ['Low', 'Medium', 'High'],
              value: _priority,
              onChanged: (v) => setState(() => _priority = v),
            ),
          ],
        ),
        const DsNotice(
          icon: LucideIcons.timer,
          tone: DsTone.info,
          message:
              'For this sub-type at High priority, Crown Solar aims to respond '
              'within 4 hours and resolve within 2 working days. Sample '
              'targets.',
        ),
      ],
    );
  }
}

/// Board 08 · A3 — Title, detail and review, with the submission setting
/// expectations honestly.
class ComplaintReviewScreen extends StatelessWidget {
  const ComplaintReviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DsScreen(
      appBar: DsAppBar(
        title: 'New Complaint',
        subtitle: 'Step 3 of 3 · Review',
        onBack: () => Navigator.of(context).maybePop(),
      ),
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      gap: 14,
      footer: DsFooterBar(
        child: DsButton(label: 'Submit Complaint', onPressed: () {}),
      ),
      sections: [
        const DsInput(
          label: 'Title',
          value: 'Prize not credited for inverter scan',
        ),
        const DsInput(
          label: 'Detail',
          value:
              'I scanned a Crown 8kW inverter on 8 September at about 3 pm. '
              'The app showed the prize screen but nothing came into my '
              'wallet.',
          maxLines: 5,
        ),
        DsRowGroup(
          children: const [
            DsSettingRow(label: 'Type', value: 'QR and prizes'),
            DsSettingRow(
              label: 'Sub-type',
              value: 'Prize not credited after scan',
            ),
            DsSettingRow(
              label: 'Priority',
              trailing: DsTag(label: 'High', tone: DsTone.error),
            ),
          ],
        ),
        const DsCaption(
          'A ticket is raised for the Crown Solar team as soon as you submit. '
          'You will be notified on every status change.',
        ),
      ],
    );
  }
}

/// Board 08 · A4 — Complaint detail: history, visible targets, and the
/// evidence that was attached automatically.
class ComplaintDetailScreen extends StatelessWidget {
  const ComplaintDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DsScreen(
      appBar: DsAppBar(
        title: 'CMP-2026-5514',
        subtitle: 'QR prize dispute · High',
        onBack: () => Navigator.of(context).maybePop(),
      ),
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      gap: AppSpacing.md,
      footer: DsFooterBar(
        child: DsButton(
          label: 'Message CRM About This',
          icon: LucideIcons.messageCircle,
          onPressed: () {},
        ),
      ),
      sections: [
        Row(
          children: [
            Expanded(
              child: _TargetCard(
                label: 'RESPONSE',
                value: 'Met · 1 h 12 m',
                note: 'Target 4 h',
                tone: DsTone.success,
              ),
            ),
            const SizedBox(width: AppSpacing.stepMd),
            Expanded(
              child: _TargetCard(
                label: 'RESOLUTION',
                value: 'In progress',
                note: 'Target 2 working days',
                tone: DsTone.info,
              ),
            ),
          ],
        ),
        DsCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'History',
                style: context.texts.bodyLarge?.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              const DsTimeline(
                steps: [
                  DsTimelineStep(
                    title: 'Complaint raised',
                    meta:
                        'Submitted by you with attached scan evidence. · '
                        'Today, 4:08 PM',
                    done: true,
                  ),
                  DsTimelineStep(
                    title: 'Ticket assigned',
                    meta: 'Assigned to CRM prize desk. · Today, 4:20 PM',
                    done: true,
                  ),
                  DsTimelineStep(
                    title: 'First response',
                    meta:
                        '"We are checking both scans against the installation '
                        'record." · Today, 5:20 PM · response target met',
                    done: true,
                  ),
                  DsTimelineStep(
                    title: 'Awaiting resolution',
                    meta: 'Resolution target is tomorrow, 5:20 PM.',
                    active: true,
                  ),
                ],
              ),
            ],
          ),
        ),
        DsCard(
          tone: DsCardTone.sunken,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    LucideIcons.paperclip,
                    size: 16,
                    color: context.colors.onSurfaceVariant,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'Attached evidence',
                    style: context.texts.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const DsBody(
                'QR code CS-6K-2026-338201 · previous claimant M. Zubair Solar '
                '· both timestamps · your location at the time of the scan.',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TargetCard extends StatelessWidget {
  const _TargetCard({
    required this.label,
    required this.value,
    required this.note,
    required this.tone,
  });

  final String label;
  final String value;
  final String note;
  final DsTone tone;

  @override
  Widget build(BuildContext context) {
    final (fill, foreground) = dsToneColors(context, tone);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(color: fill, borderRadius: AppRadii.lgRadius),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              letterSpacing: 0.06 * 11,
              fontWeight: FontWeight.w600,
              color: foreground,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: foreground,
            ),
          ),
          Text(note, style: TextStyle(fontSize: 12, color: foreground)),
        ],
      ),
    );
  }
}
