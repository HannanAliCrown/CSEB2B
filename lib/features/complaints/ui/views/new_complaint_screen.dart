import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../../core/ui/ds.dart';
import '../../../session/ui/session_controller.dart';
import '../../data/complaints_service.dart';

/// Board 08 · A2 and A3 — raising a complaint, in the three steps the
/// design's headers count off.
///
/// Step 1 is what it is about, step 2 is what happened, step 3 is the review
/// that states the targets before anything is sent.
class NewComplaintScreen extends StatefulWidget {
  const NewComplaintScreen({super.key});

  @override
  State<NewComplaintScreen> createState() => _NewComplaintScreenState();
}

class _NewComplaintScreenState extends State<NewComplaintScreen> {
  final _title = TextEditingController();
  final _detail = TextEditingController();

  List<ComplaintCategory>? _catalogue;
  ComplaintCategory? _category;
  ComplaintPriority _priority = ComplaintPriority.high;

  int _step = 1;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _title.dispose();
    _detail.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final loaded = await context.read<ComplaintsService>().catalogue();
    if (!mounted) return;
    setState(() {
      _catalogue = loaded;
      // The first category is chosen for them, as the design shows one
      // already selected.
      _category = loaded.isEmpty ? null : loaded.first;
      if (_title.text.isEmpty) {
        _title.text = 'Prize not credited for inverter scan';
      }
      if (_detail.text.isEmpty) {
        _detail.text =
            'I scanned a Crown 8kW inverter at about 3 pm. The app showed '
            'the prize screen but nothing came into my wallet.';
      }
    });
  }

  ComplaintTarget? get _target => _category?.targetFor(_priority);

  /// What each step needs before Continue does anything.
  bool get _stepComplete => switch (_step) {
    1 => _category != null && _target != null && _title.text.trim().isNotEmpty,
    2 => _detail.text.trim().isNotEmpty,
    _ => true,
  };

  @override
  Widget build(BuildContext context) {
    final catalogue = _catalogue;
    if (catalogue == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (catalogue.isEmpty) return _unreachable;

    return switch (_step) {
      1 => _aboutStep(catalogue),
      2 => _detailStep,
      _ => _reviewStep,
    };
  }

  Widget get _unreachable => DsScreen(
    appBar: DsAppBar(
      title: 'New Complaint',
      onBack: () => Navigator.of(context).maybePop(),
    ),
    padding: const EdgeInsets.all(AppSpacing.screenPadding),
    sections: [
      const DsEmptyState(
        icon: LucideIcons.cloudOff,
        title: 'Could not reach Crown Solar',
        message:
            'The list of complaint types comes from Crown Solar. Check your '
            'connection and try again.',
      ),
    ],
  );

  // --- Step 1 · what it is about -------------------------------------------

  Widget _aboutStep(List<ComplaintCategory> catalogue) => DsScreen(
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
        disabled: !_stepComplete,
        onPressed: () => setState(() => _step = 2),
      ),
    ),
    sections: [
      Text('What is it about?', style: context.texts.titleMedium),
      Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: [
          for (final category in catalogue)
            DsFilterChip(
              label: category.label,
              icon: _iconFor(category.code),
              selected: _category?.code == category.code,
              onTap: () => setState(() => _category = category),
            ),
        ],
      ),
      // In place of a second dropdown. A list of labels can only ever come
      // close to the problem; the partner's own sentence names it.
      DsInput(
        label: 'What is the complaint?',
        controller: _title,
        placeholder: 'Write it in your own words',
        onChanged: (_) => setState(() {}),
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
            options: [
              for (final priority in ComplaintPriority.values) priority.label,
            ],
            value: _priority.label,
            onChanged: (value) => setState(() {
              _priority = ComplaintPriority.values.firstWhere(
                (p) => p.label == value,
              );
            }),
          ),
        ],
      ),
      // Only once there is something to promise. Stating a target before the
      // category is chosen would be inventing one.
      if (_target != null)
        DsNotice(
          icon: LucideIcons.timer,
          tone: DsTone.info,
          message:
              'For this category at ${_priority.label} priority, Crown Solar '
              'aims to respond within '
              '${formatDurationWords(Duration(minutes: _target!.responseMinutes))} '
              'and resolve within '
              '${_workingDays(_target!.resolutionWorkingDays)}.',
        ),
    ],
  );

  // --- Step 2 · what happened ----------------------------------------------

  Widget get _detailStep => DsScreen(
    appBar: DsAppBar(
      title: 'New Complaint',
      subtitle: 'Step 2 of 3 · Details',
      onBack: () => setState(() => _step = 1),
    ),
    padding: const EdgeInsets.all(AppSpacing.screenPadding),
    gap: 14,
    footer: DsFooterBar(
      child: DsButton(
        label: 'Continue',
        iconAfter: LucideIcons.arrowRight,
        disabled: !_stepComplete,
        onPressed: () => setState(() => _step = 3),
      ),
    ),
    sections: [
      DsInput(
        label: 'Detail',
        controller: _detail,
        placeholder:
            'What happened, when, and anything Crown Solar needs to look up',
        maxLines: 6,
        onChanged: (_) => setState(() {}),
      ),
      const DsCaption(
        'Say when it happened and which product or transfer it concerns. '
        'That is what the team looks up first.',
      ),
    ],
  );

  // --- Step 3 · review ------------------------------------------------------

  Widget get _reviewStep => DsScreen(
    appBar: DsAppBar(
      title: 'New Complaint',
      subtitle: 'Step 3 of 3 · Review',
      onBack: () => setState(() => _step = 2),
    ),
    padding: const EdgeInsets.all(AppSpacing.screenPadding),
    gap: 14,
    footer: DsFooterBar(
      child: DsButton(
        label: 'Submit Complaint',
        loading: _submitting,
        disabled: _submitting,
        onPressed: _submit,
      ),
    ),
    sections: [
      // Still editable, as the design draws them: the last chance to fix a
      // word should not mean going back two screens.
      DsInput(label: 'What is the complaint?', controller: _title),
      DsInput(label: 'Detail', controller: _detail, maxLines: 6),
      DsRowGroup(
        children: [
          DsSettingRow(label: 'Type', value: _category?.label ?? ''),
          DsSettingRow(
            label: 'Priority',
            trailing: DsTag(
              label: _priority.label,
              tone: switch (_priority) {
                ComplaintPriority.high => DsTone.error,
                ComplaintPriority.medium => DsTone.warning,
                ComplaintPriority.low => DsTone.neutral,
              },
            ),
          ),
        ],
      ),
      if (_error != null)
        DsNotice(
          icon: LucideIcons.triangleAlert,
          tone: DsTone.error,
          message: _error!,
        ),
      const DsCaption(
        'A ticket is raised for the Crown Solar team as soon as you submit. '
        'You will be notified on every status change.',
      ),
    ],
  );

  Future<void> _submit() async {
    final user = context.read<SessionController>().user;
    final category = _category;
    if (user == null || category == null) return;

    setState(() {
      _submitting = true;
      _error = null;
    });

    final raised = await context.read<ComplaintsService>().raise(
      mobileNumber: user.mobileNumber,
      typeId: category.id,
      priority: _priority,
      title: _title.text,
      detail: _detail.text,
    );
    if (!mounted) return;

    if (raised == null) {
      setState(() {
        _submitting = false;
        _error =
            'Could not raise the complaint. Nothing has been sent — check '
            'your connection and try again.';
      });
      return;
    }

    // The reference travels back so the list can say which ticket is new.
    Navigator.of(context).pop(raised.reference);
  }
}

/// The design's icon for each category. The database holds the category, not
/// its picture — an icon belongs to the drawing.
IconData _iconFor(String code) => switch (code) {
  'qr_and_prizes' => LucideIcons.qrCode,
  'wallet_and_cash' => LucideIcons.wallet,
  'points' => LucideIcons.award,
  'shop_branding' => LucideIcons.store,
  'account_and_access' => LucideIcons.userCog,
  _ => LucideIcons.circleHelp,
};

String _workingDays(int days) =>
    days == 1 ? '1 working day' : '$days working days';
