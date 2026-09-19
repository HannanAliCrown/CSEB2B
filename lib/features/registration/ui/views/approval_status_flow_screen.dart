import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/mock/pending_registrations.dart';
import '../../../../core/ui/ds.dart';

/// Where a submitted registration stands, for the partner who submitted it.
///
/// All three approvals start outstanding. Each one that is still outstanding
/// offers a way to call that approver; once it comes in, the row reads
/// Approved and its call button goes — there is nobody left to chase.
class ApprovalStatusFlowScreen extends StatefulWidget {
  const ApprovalStatusFlowScreen({
    super.key,
    required this.mobileNumber,
    required this.onBack,
  });

  final String mobileNumber;

  /// Leaving this screen always returns to sign-in: there is no app behind it
  /// until the account opens.
  final VoidCallback onBack;

  @override
  State<ApprovalStatusFlowScreen> createState() =>
      _ApprovalStatusFlowScreenState();
}

class _ApprovalStatusFlowScreenState extends State<ApprovalStatusFlowScreen> {
  PendingRegistration? get _pending =>
      PendingRegistrations.find(widget.mobileNumber);

  /// Who to call about an outstanding approval.
  String _detailFor(Approver approver, PendingRegistration pending) =>
      switch (approver) {
        Approver.receiver =>
          pending.verifyingSourceName ?? 'Your first buying source',
        Approver.marketingOfficer => 'Your area Marketing Officer',
        Approver.crm => 'Crown Solar customer relations',
      };

  @override
  Widget build(BuildContext context) {
    final pending = _pending;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) widget.onBack();
      },
      child: DsScreen(
        appBar: DsAppBar(title: 'Approval Status', onBack: widget.onBack),
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        gap: 18,
        sections: pending == null
            ? [
                const DsEmptyState(
                  title: 'No application found',
                  message:
                      'Register first, then come back to watch its '
                      'approvals.',
                  icon: LucideIcons.fileQuestion,
                ),
              ]
            : [
                _Summary(pending: pending),
                DsCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  child: Column(
                    children: [
                      for (final approver in Approver.values) ...[
                        if (approver != Approver.values.first)
                          const DsHairline(),
                        _ApproverRow(
                          title: approver.title,
                          detail: _detailFor(approver, pending),
                          state: pending.approvals[approver]!,
                          // Nobody to chase once they have approved.
                          onCall:
                              pending.approvals[approver] ==
                                  ApprovalState.outstanding
                              ? () => _call(approver)
                              : null,
                        ),
                      ],
                    ],
                  ),
                ),
                const DsCaption(
                  'You will get a notification each time an approval is '
                  'recorded.',
                ),
                _PrototypeControls(
                  pending: pending,
                  onChanged: () => setState(() {}),
                ),
              ],
      ),
    );
  }

  void _call(Approver approver) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Calling ${approver.title} is not wired up yet.')),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.pending});

  final PendingRegistration pending;

  @override
  Widget build(BuildContext context) {
    final received = pending.approvedCount;
    final total = Approver.values.length;

    return DsCard(
      radius: AppRadii.heroRadius,
      padding: const EdgeInsets.all(AppSpacing.stepLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const DsIconMedallion(
                icon: LucideIcons.hourglass,
                tone: DsTone.warning,
                size: 44,
                iconSize: 22,
              ),
              const SizedBox(width: AppSpacing.stepMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Waiting for approval',
                      style: context.texts.titleLarge,
                    ),
                    Text(
                      '$received of $total approvals received',
                      style: context.texts.bodyMedium?.copyWith(
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              for (var i = 0; i < total; i++)
                Expanded(
                  child: Container(
                    height: 6,
                    margin: EdgeInsets.only(right: i == total - 1 ? 0 : 6),
                    decoration: BoxDecoration(
                      color: i < received
                          ? context.status.success
                          : context.colors.outline,
                      borderRadius: BorderRadius.circular(AppRadii.pill),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.stepMd),
          DsBody(
            'All three approvals are needed before your account opens. They '
            'can come in any order.',
          ),
          const SizedBox(height: AppSpacing.sm),
          DsCaption('Reference ${pending.reference}'),
        ],
      ),
    );
  }
}

class _ApproverRow extends StatelessWidget {
  const _ApproverRow({
    required this.title,
    required this.detail,
    required this.state,
    this.onCall,
  });

  final String title;
  final String detail;
  final ApprovalState state;
  final VoidCallback? onCall;

  @override
  Widget build(BuildContext context) {
    final approved = state == ApprovalState.approved;
    final rejected = state == ApprovalState.rejected;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Column(
        children: [
          Row(
            children: [
              DsIconMedallion(
                icon: approved
                    ? LucideIcons.check
                    : rejected
                    ? LucideIcons.x
                    : LucideIcons.clock,
                tone: approved
                    ? DsTone.success
                    : rejected
                    ? DsTone.error
                    : DsTone.neutral,
                size: 34,
                iconSize: 17,
              ),
              const SizedBox(width: AppSpacing.stepMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: context.texts.bodyLarge?.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      detail,
                      style: TextStyle(
                        fontSize: 12,
                        height: 17 / 12,
                        color: context.palette.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              DsTag(
                label: approved
                    ? 'Approved'
                    : rejected
                    ? 'Rejected'
                    : 'Outstanding',
                tone: approved
                    ? DsTone.success
                    : rejected
                    ? DsTone.error
                    : DsTone.neutral,
              ),
            ],
          ),
          if (onCall != null) ...[
            const SizedBox(height: 10),
            DsButton(
              label: 'Call $title',
              variant: DsButtonVariant.secondary,
              size: DsButtonSize.sm,
              icon: LucideIcons.phone,
              onPressed: onCall,
            ),
          ],
        ],
      ),
    );
  }
}

/// Prototype-only: no approver can reach this phone, so the approvals are
/// recorded here instead. This card would not exist in the real app.
class _PrototypeControls extends StatelessWidget {
  const _PrototypeControls({required this.pending, required this.onChanged});

  final PendingRegistration pending;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final outstanding = Approver.values
        .where((a) => pending.approvals[a] == ApprovalState.outstanding)
        .toList();
    if (outstanding.isEmpty) return const SizedBox.shrink();

    return DsCard(
      tone: DsCardTone.sunken,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const DsCaption('PROTOTYPE ONLY · NOT PART OF THE APP'),
          const SizedBox(height: AppSpacing.sm),
          const DsBody(
            'Approvals arrive from Crown Solar in the real app. Record one '
            'here to see what happens next.',
            size: 13,
          ),
          const SizedBox(height: AppSpacing.stepMd),
          for (final approver in outstanding) ...[
            DsButton(
              label: 'Record ${approver.title} approval',
              variant: DsButtonVariant.secondary,
              size: DsButtonSize.sm,
              onPressed: () {
                pending.approvals[approver] = ApprovalState.approved;
                onChanged();
              },
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}
