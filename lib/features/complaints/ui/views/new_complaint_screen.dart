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
  ComplaintSubtype? _subtype;
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
      // already selected — but never a sub-type, because "which part" is a
      // question only the partner can answer.
      _category = loaded.isEmpty ? null : loaded.first;
    });
  }

  ComplaintTarget? get _target => _subtype?.targetFor(_priority);

  /// What each step needs before Continue does anything.
  bool get _stepComplete => switch (_step) {
    1 => _subtype != null && _target != null,
    2 => _title.text.trim().isNotEmpty && _detail.text.trim().isNotEmpty,
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
              // Changing the category drops the sub-type: keeping one from
              // the old category would carry the wrong targets with it.
              onTap: () => setState(() {
                _category = category;
                _subtype = null;
              }),
            ),
        ],
      ),
      DsSelect(
        label: 'Which part?',
        value: _subtype?.label,
        placeholder: 'Choose the closest one',
        onTap: _category == null ? null : _pickSubtype,
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
      // sub-type is chosen would be inventing one.
      if (_target != null)
        DsNotice(
          icon: LucideIcons.timer,
          tone: DsTone.info,
          message:
              'For this sub-type at ${_priority.label} priority, Crown Solar '
              'aims to respond within '
              '${formatDurationWords(Duration(minutes: _target!.responseMinutes))} '
              'and resolve within '
              '${_workingDays(_target!.resolutionWorkingDays)}.',
        ),
    ],
  );

  Future<void> _pickSubtype() async {
    final category = _category;
    if (category == null) return;

    final chosen = await showModalBottomSheet<ComplaintSubtype>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => DsSheet(
        title: category.label,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final subtype in category.subtypes)
              DsRadio(
                selected: _subtype?.id == subtype.id,
                label: subtype.label,
                onTap: () => Navigator.of(context).pop(subtype),
              ),
          ],
        ),
      ),
    );
    if (chosen != null) setState(() => _subtype = chosen);
  }

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
        label: 'Title',
        controller: _title,
        placeholder: 'One line: what went wrong',
        onChanged: (_) => setState(() {}),
      ),
      DsInput(
        label: 'Detail',
        controller: _detail,
        placeholder:
            'What happened, when, and anything Crown Solar needs to look up',
        maxLines: 5,
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
      DsInput(label: 'Title', controller: _title),
      DsInput(label: 'Detail', controller: _detail, maxLines: 5),
      DsRowGroup(
        children: [
          DsSettingRow(label: 'Type', value: _category?.label ?? ''),
          DsSettingRow(label: 'Sub-type', value: _subtype?.label ?? ''),
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
    final subtype = _subtype;
    if (user == null || subtype == null) return;

    setState(() {
      _submitting = true;
      _error = null;
    });

    final raised = await context.read<ComplaintsService>().raise(
      mobileNumber: user.mobileNumber,
      subtypeId: subtype.id,
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
