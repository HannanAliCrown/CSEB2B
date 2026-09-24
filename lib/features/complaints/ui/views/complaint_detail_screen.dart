import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../../core/ui/ds.dart';
import '../../../session/ui/session_controller.dart';
import '../../data/complaints_service.dart';

/// Board 08 · A4 — one ticket: what was promised, what has happened, and
/// what the app attached by itself.
class ComplaintDetailScreen extends StatefulWidget {
  const ComplaintDetailScreen({
    super.key,
    required this.reference,
    required this.onMessageCrm,
  });

  final String reference;
  final VoidCallback onMessageCrm;

  @override
  State<ComplaintDetailScreen> createState() => _ComplaintDetailScreenState();
}

class _ComplaintDetailScreenState extends State<ComplaintDetailScreen> {
  Complaint? _complaint;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final user = context.read<SessionController>().user;
    if (user == null) return;
    final loaded = await context.read<ComplaintsService>().detail(
      mobileNumber: user.mobileNumber,
      reference: widget.reference,
    );
    if (!mounted) return;
    setState(() {
      _complaint = loaded;
      _loaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final complaint = _complaint;

    if (!_loaded) {
      return Scaffold(
        appBar: DsAppBar(
          title: widget.reference,
          onBack: () => Navigator.of(context).maybePop(),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (complaint == null) {
      return DsScreen(
        appBar: DsAppBar(
          title: widget.reference,
          onBack: () => Navigator.of(context).maybePop(),
        ),
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        sections: const [
          DsEmptyState(
            icon: LucideIcons.cloudOff,
            title: 'Could not open this complaint',
            message:
                'It is held by Crown Solar, not on this phone. Check your '
                'connection and try again.',
          ),
        ],
      );
    }

    return DsScreen(
      appBar: DsAppBar(
        title: complaint.reference,
        subtitle: '${complaint.categoryLabel} · ${complaint.priority.label}',
        onBack: () => Navigator.of(context).maybePop(),
      ),
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      gap: AppSpacing.md,
      footer: DsFooterBar(
        child: DsButton(
          label: 'Message CRM About This',
          icon: LucideIcons.messageCircle,
          onPressed: widget.onMessageCrm,
        ),
      ),
      sections: [
        Row(
          children: [
            Expanded(child: _responseCard(complaint)),
            const SizedBox(width: AppSpacing.stepMd),
            Expanded(child: _resolutionCard(complaint)),
          ],
        ),
        // Only for a ticket an officer raised through Crown Solar Teams. One
        // the partner raised has no such row at all.
        if (complaint.raisedBy case final officer?)
          DsRowGroup(
            children: [
              DsSettingRow(
                label: 'Raised by',
                value: officer.name,
                meta: officer.roleLabel,
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
              DsTimeline(
                steps: [
                  for (final event in complaint.events)
                    DsTimelineStep(
                      title: event.title,
                      // The step still being waited on has no time of its
                      // own, so it states the target instead.
                      meta: event.active
                          ? 'Resolution target is '
                                '${formatWhen(complaint.resolutionDueAt)}.'
                          : event.line,
                      done: event.done,
                      active: event.active,
                    ),
                ],
              ),
            ],
          ),
        ),
        // Only when something was actually attached. An empty "Attached
        // evidence" card would claim the app gathered something it did not.
        if (complaint.evidenceNote != null)
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
                DsBody(complaint.evidenceNote!),
              ],
            ),
          ),
      ],
    );
  }

  Widget _responseCard(Complaint complaint) {
    final took = complaint.responseTook;
    final (value, tone) = switch (took) {
      final Duration took when complaint.responseMet => (
        'Met · ${formatDuration(took)}',
        DsTone.success,
      ),
      final Duration took => ('Late · ${formatDuration(took)}', DsTone.error),
      _ when complaint.responseOverdue => ('Overdue', DsTone.error),
      _ => ('Waiting', DsTone.info),
    };

    return _TargetCard(
      label: 'RESPONSE',
      value: value,
      note: 'Target ${formatDuration(complaint.responseTarget)}',
      tone: tone,
    );
  }

  Widget _resolutionCard(Complaint complaint) {
    final (value, tone) = switch (complaint) {
      final c when c.resolvedAt != null =>
        c.resolvedAt!.isAfter(c.resolutionDueAt)
            ? ('Resolved late', DsTone.error)
            : ('Resolved', DsTone.success),
      final c when c.resolutionOverdue => ('Overdue', DsTone.error),
      _ => ('In progress', DsTone.info),
    };

    return _TargetCard(
      label: 'RESOLUTION',
      value: value,
      note:
          'Target ${complaint.resolutionTargetWorkingDays == 1 ? '1 working day' : '${complaint.resolutionTargetWorkingDays} working days'}',
      tone: tone,
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
