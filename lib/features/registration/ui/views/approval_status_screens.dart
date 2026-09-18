import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/ui/ds.dart';
import '../../../design_preview/preview_journey.dart';

/// One of the three approvers, and where its decision currently stands.
class _Approver extends StatelessWidget {
  const _Approver({
    required this.role,
    required this.detail,
    required this.approved,
    this.showStatus = true,
  });

  final String role;
  final String detail;
  final bool approved;
  final bool showStatus;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          DsIconMedallion(
            icon: approved ? LucideIcons.check : LucideIcons.clock,
            tone: approved ? DsTone.success : DsTone.neutral,
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
                  role,
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
          if (showStatus)
            DsTag(
              label: approved ? 'Approved' : 'Outstanding',
              tone: approved ? DsTone.success : DsTone.neutral,
            ),
        ],
      ),
    );
  }
}

/// Board 01 · I1 — Pending · 1 of 3 approvals.
class ApprovalPendingScreen extends StatelessWidget {
  const ApprovalPendingScreen({super.key, this.received = 1});

  final int received;

  @override
  Widget build(BuildContext context) {
    final sourceApproved = received >= 2;
    return DsScreen(
      appBar: DsAppBar(
        title: 'Approval Status',
        onBack: () => Navigator.of(context).maybePop(),
      ),
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      gap: 18,
      sections: [
        DsCard(
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
                          '$received of 3 approvals received',
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
                  for (var i = 0; i < 3; i++)
                    Expanded(
                      child: Container(
                        height: 6,
                        margin: EdgeInsets.only(right: i == 2 ? 0 : 6),
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
                received >= 2
                    ? 'Only CRM is left. Your account opens the next time you '
                          'sign in after that.'
                    : 'All three approvals are needed before your account '
                          'opens. They can come in any order.',
              ),
            ],
          ),
        ),
        DsCard(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Column(
            children: [
              _Approver(
                role: 'Buying Source',
                detail: sourceApproved
                    ? 'Al-Noor Electric Store · Approved 07 Sep'
                    : 'Al-Noor Electric Store · notified Today, 9:42 AM',
                approved: sourceApproved,
              ),
              DsHairline(),
              _Approver(
                role: 'Marketing Officer',
                detail: sourceApproved
                    ? 'Kashif Mehmood · Approved Yesterday'
                    : 'Kashif Mehmood · Approved Today, 10:15 AM',
                approved: true,
              ),
              const DsHairline(),
              const _Approver(
                role: 'CRM',
                detail: 'Crown Solar customer relations',
                approved: false,
              ),
              const DsHairline(),
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 14, 0, AppSpacing.md),
                child: Column(
                  children: [
                    if (!sourceApproved) ...[
                      DsButton(
                        label: 'Call Buying Source',
                        variant: DsButtonVariant.secondary,
                        size: DsButtonSize.sm,
                        icon: LucideIcons.phone,
                        onPressed: () {},
                      ),
                      const SizedBox(height: 10),
                    ],
                    DsButton(
                      label: 'Call CRM',
                      variant: DsButtonVariant.secondary,
                      size: DsButtonSize.sm,
                      icon: LucideIcons.phone,
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (!sourceApproved)
          const DsCaption(
            'You will get a notification each time an approval is recorded.',
          ),
      ],
    );
  }
}

/// Board 01 · I3 — Activated: all three approvals are in.
class ApprovalActivatedScreen extends StatelessWidget {
  const ApprovalActivatedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DsScreen(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      gap: AppSpacing.stepLg,
      footer: DsFooterBar(
        child: DsButton(
          label: 'Go to Home',
          iconAfter: LucideIcons.arrowRight,
          onPressed: () => PreviewJourney.next(context),
        ),
      ),
      sections: [
        const Center(
          child: DsIconMedallion(
            icon: LucideIcons.partyPopper,
            tone: DsTone.success,
            size: 80,
            iconSize: 38,
          ),
        ),
        Column(
          children: [
            Text(
              'Your account is open',
              textAlign: TextAlign.center,
              style: context.texts.headlineSmall,
            ),
            const SizedBox(height: 10),
            const DsBody(
              'All three approvals are in. Your wallet, scanning and Inaam '
              'Baazar are ready to use.',
              size: 15,
              align: TextAlign.center,
            ),
          ],
        ),
        DsCard(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Column(
            children: const [
              _Approver(
                role: 'Buying Source',
                detail: 'Al-Noor Electric Store · 07 Sep',
                approved: true,
                showStatus: false,
              ),
              DsHairline(),
              _Approver(
                role: 'Marketing Officer',
                detail: 'Kashif Mehmood · 08 Sep',
                approved: true,
                showStatus: false,
              ),
              DsHairline(),
              _Approver(
                role: 'CRM',
                detail: 'Crown Solar CRM · Today, 7:28 AM',
                approved: true,
                showStatus: false,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Board 01 · I4 — Rejected, with the reason given.
class ApprovalRejectedScreen extends StatelessWidget {
  const ApprovalRejectedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DsScreen(
      appBar: DsAppBar(
        title: 'Approval Status',
        onBack: () => Navigator.of(context).maybePop(),
      ),
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      gap: 18,
      sections: [
        DsCard(
          radius: AppRadii.heroRadius,
          padding: const EdgeInsets.all(AppSpacing.stepLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const DsIconMedallion(
                    icon: LucideIcons.circleX,
                    tone: DsTone.error,
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
                          'Registration not approved',
                          style: context.texts.titleLarge,
                        ),
                        Text(
                          'Rejected by CRM · Today, 11:40 AM',
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
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: context.status.errorFill,
                  borderRadius: AppRadii.mdRadius,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'REASON GIVEN',
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 0.06 * 11,
                        fontWeight: FontWeight.w600,
                        color: context.status.error,
                      ),
                    ),
                    const SizedBox(height: 6),
                    DsBody(
                      'The CNIC photo does not match the name entered. Please '
                      'register again with a clear photo of your own CNIC.',
                      color: context.status.error,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        DsCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'What you can do',
                style: context.texts.bodyLarge?.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              const DsBody(
                'Start a fresh registration with the corrected documents, or '
                'speak to CRM first if you think this is a mistake.',
              ),
              const SizedBox(height: AppSpacing.md),
              DsButton(label: 'Register Again', onPressed: () {}),
              const SizedBox(height: 10),
              DsButton(
                label: 'Call CRM',
                variant: DsButtonVariant.secondary,
                icon: LucideIcons.phone,
                onPressed: () {},
              ),
            ],
          ),
        ),
        const DsCaption(
          'Your earlier approvals do not carry over — a new request goes to '
          'all three approvers again.',
        ),
      ],
    );
  }
}
