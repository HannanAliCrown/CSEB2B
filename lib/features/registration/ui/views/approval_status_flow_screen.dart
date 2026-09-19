import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/ui/ds.dart';
import '../../data/repositories/registration_repository.dart';
import '../../data/services/registration_service.dart';

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
    required this.repository,
  });

  final String mobileNumber;

  /// Where the application is read from — the bundled store, or the database
  /// behind the server. The screen never knows which.
  final RegistrationRepository repository;

  /// Leaving this screen always returns to sign-in: there is no app behind it
  /// until the account opens.
  final VoidCallback onBack;

  @override
  State<ApprovalStatusFlowScreen> createState() =>
      _ApprovalStatusFlowScreenState();
}

/// The three approvals, in the order the screen lists them.
enum _Approver { buyingSource, marketingOfficer, crm }

extension _ApproverX on _Approver {
  String get title => switch (this) {
    _Approver.buyingSource => 'Buying Source',
    _Approver.marketingOfficer => 'Marketing Officer',
    _Approver.crm => 'CRM',
  };
}

class _ApprovalStatusFlowScreenState extends State<ApprovalStatusFlowScreen> {
  RegistrationSubmission? _submission;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final submission = await widget.repository.latestSubmission(
      widget.mobileNumber,
    );
    if (!mounted) return;
    setState(() {
      _submission = submission;
      _loaded = true;
    });
  }

  RegistrationApprovalState _stateOf(
    _Approver approver,
    RegistrationSubmission submission,
  ) => switch (approver) {
    _Approver.buyingSource => submission.buyingSourceState,
    _Approver.marketingOfficer => submission.marketingOfficerState,
    _Approver.crm => submission.crmState,
  };

  /// Who to call about an outstanding approval.
  String _detailFor(_Approver approver, RegistrationSubmission submission) =>
      switch (approver) {
        _Approver.buyingSource =>
          submission.verifyingSourceName ?? 'Your first buying source',
        _Approver.marketingOfficer => 'Your area Marketing Officer',
        _Approver.crm => 'Crown Solar customer relations',
      };

  @override
  Widget build(BuildContext context) {
    final submission = _submission;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) widget.onBack();
      },
      child: DsScreen(
        appBar: DsAppBar(title: 'Approval Status', onBack: widget.onBack),
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        gap: 18,
        sections: !_loaded
            ? [const Center(child: CircularProgressIndicator())]
            : submission == null
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
                _Summary(submission: submission),
                DsCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  child: Column(
                    children: [
                      for (final approver in _Approver.values) ...[
                        if (approver != _Approver.values.first)
                          const DsHairline(),
                        _ApproverRow(
                          title: approver.title,
                          detail: _detailFor(approver, submission),
                          state: _stateOf(approver, submission),
                          // Nobody to chase once they have approved.
                          onCall:
                              _stateOf(approver, submission) ==
                                  RegistrationApprovalState.outstanding
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
              ],
      ),
    );
  }

  void _call(_Approver approver) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Calling ${approver.title} is not wired up yet.')),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.submission});

  final RegistrationSubmission submission;

  @override
  Widget build(BuildContext context) {
    final received = submission.approvalsReceived;
    final total = _Approver.values.length;

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
          DsCaption('Reference ${submission.reference}'),
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
  final RegistrationApprovalState state;
  final VoidCallback? onCall;

  @override
  Widget build(BuildContext context) {
    final approved = state == RegistrationApprovalState.approved;
    final rejected = state == RegistrationApprovalState.rejected;

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
