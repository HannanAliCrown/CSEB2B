import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../../core/ui/ds.dart';
import '../../../session/ui/session_controller.dart';
import '../../data/complaints_service.dart';

/// Board 08 · A1 — My Complaints, from the database.
///
/// One ticket per row: its reference, what it is about, when it was raised
/// and how urgent it is.
class ComplaintsScreen extends StatefulWidget {
  const ComplaintsScreen({
    super.key,
    required this.onNewComplaint,
    required this.onOpenComplaint,
  });

  /// Returns the reference of anything raised, so the list can reload.
  final Future<String?> Function() onNewComplaint;
  final Future<void> Function(String reference) onOpenComplaint;

  @override
  State<ComplaintsScreen> createState() => _ComplaintsScreenState();
}

class _ComplaintsScreenState extends State<ComplaintsScreen> {
  ComplaintList? _list;
  bool _reachable = true;
  bool _resolvedTab = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final user = context.read<SessionController>().user;
    if (user == null) return;
    final loaded = await context.read<ComplaintsService>().list(
      user.mobileNumber,
    );
    if (!mounted) return;
    setState(() {
      _list = loaded ?? ComplaintList.empty;
      _reachable = loaded != null;
    });
  }

  /// The tab labels carry the count the design shows on In Progress.
  String get _inProgressLabel => 'In Progress · ${_list?.inProgress ?? 0}';
  static const _resolvedLabel = 'Resolved';

  @override
  Widget build(BuildContext context) {
    final list = _list;

    return Scaffold(
      appBar: DsAppBar(
        title: 'My Complaints',
        onBack: () => Navigator.of(context).maybePop(),
        actions: [
          DsIconButton(
            icon: LucideIcons.plus,
            tooltip: 'New complaint',
            onPressed: () async {
              final raised = await widget.onNewComplaint();
              if (!mounted) return;
              // A new ticket is always in progress, so the list returns to
              // that tab rather than leaving it hidden behind Resolved.
              if (raised != null) setState(() => _resolvedTab = false);
              await _load();
            },
          ),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DsTabs(
              tabs: [_inProgressLabel, _resolvedLabel],
              value: _resolvedTab ? _resolvedLabel : _inProgressLabel,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPadding,
              ),
              onChanged: (tab) =>
                  setState(() => _resolvedTab = tab == _resolvedLabel),
            ),
            Expanded(child: list == null ? _loading : _body(list)),
          ],
        ),
      ),
    );
  }

  Widget get _loading => const Center(child: CircularProgressIndicator());

  Widget _body(ComplaintList list) {
    final visible = [
      for (final complaint in list.complaints)
        if (complaint.resolved == _resolvedTab) complaint,
    ];

    if (visible.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          children: [
            if (!_reachable)
              const DsEmptyState(
                icon: LucideIcons.cloudOff,
                title: 'Could not reach Crown Solar',
                message:
                    'Your complaints are held by Crown Solar, not on this '
                    'phone. Check your connection and pull down to try again.',
              )
            else
              DsEmptyState(
                icon: LucideIcons.lifeBuoy,
                title: _resolvedTab
                    ? 'Nothing resolved yet'
                    : 'No open complaints',
                message: _resolvedTab
                    ? 'Complaints that have been closed appear here.'
                    : 'Raise one with the + above and Crown Solar will '
                          'answer within the stated target.',
              ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        itemCount: visible.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.stepMd),
        itemBuilder: (context, i) => _ComplaintCard(
          complaint: visible[i],
          onTap: () async {
            await widget.onOpenComplaint(visible[i].reference);
            await _load();
          },
        ),
      ),
    );
  }
}

class _ComplaintCard extends StatelessWidget {
  const _ComplaintCard({required this.complaint, required this.onTap});

  final Complaint complaint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return DsCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  complaint.reference,
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 0.06 * 11,
                    fontWeight: FontWeight.w600,
                    color: context.palette.textTertiary,
                  ),
                ),
              ),
              DsTag(
                label: complaint.priority.label,
                tone: priorityTone(complaint.priority),
                uppercase: true,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            complaint.title,
            style: context.texts.bodyLarge?.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              DsTag(
                label: complaint.resolved ? 'Resolved' : 'In Progress',
                tone: complaint.resolved ? DsTone.success : DsTone.info,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: DsCaption(
                  '${complaint.categoryLabel} · raised '
                  '${formatWhen(complaint.raisedAt)}',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The design's priority colours: High reads as a problem, Low as a note.
DsTone priorityTone(ComplaintPriority priority) => switch (priority) {
  ComplaintPriority.high => DsTone.error,
  ComplaintPriority.medium => DsTone.warning,
  ComplaintPriority.low => DsTone.neutral,
};
