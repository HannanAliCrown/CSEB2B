import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/ui/ds.dart';

/// Board 05 · B3 — Prize credited. The amount, where it went, and the fact
/// that this code will never pay again.
class ScanPrizeCreditedScreen extends StatelessWidget {
  const ScanPrizeCreditedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DsScreen(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      gap: 18,
      footer: DsFooterBar(
        child: Column(
          children: [
            DsButton(
              label: 'Scan Next Product',
              icon: LucideIcons.scanLine,
              onPressed: () => Navigator.of(context).maybePop(),
            ),
            const SizedBox(height: 10),
            DsButton(
              label: 'Go to Wallet',
              variant: DsButtonVariant.secondary,
              onPressed: () {},
            ),
          ],
        ),
      ),
      sections: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: context.status.successFill,
            borderRadius: AppRadii.heroRadius,
          ),
          child: Column(
            children: [
              DsIconMedallion(
                icon: LucideIcons.gift,
                tone: DsTone.success,
                size: 56,
                iconSize: 28,
              ),
              const SizedBox(height: AppSpacing.stepMd),
              Text(
                'PRIZE CREDITED',
                style: TextStyle(
                  fontSize: 12,
                  letterSpacing: 0.06 * 12,
                  fontWeight: FontWeight.w600,
                  color: context.status.success,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    'PKR',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: context.status.success,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    '1,500',
                    style: TextStyle(
                      fontSize: 38,
                      height: 44 / 38,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.02 * 38,
                      color: context.status.success,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              DsBody(
                'Added to your wallet now. Your balance is PKR 184,500.',
                align: TextAlign.center,
                color: context.status.success,
              ),
            ],
          ),
        ),
        DsRowGroup(
          children: const [
            DsSettingRow(label: 'Product', value: 'Crown 6kW Hybrid Inverter'),
            DsSettingRow(label: 'Code', value: 'CS-6K-2026-338201'),
            DsSettingRow(label: 'Claimed as', value: 'Installer prize'),
            DsSettingRow(label: 'Reference', value: 'QR-CLM-2026-33207'),
          ],
        ),
        const DsCaption(
          'This code has now paid what it will ever pay you — a repeat scan '
          'credits nothing further.',
        ),
      ],
    );
  }
}

/// Board 05 · B4 — Held for review: a claim that needs a CRM check, worded
/// so it never reads as a refusal.
class ScanHeldForReviewScreen extends StatelessWidget {
  const ScanHeldForReviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DsScreen(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      gap: 18,
      footer: DsFooterBar(
        child: DsButton(
          label: 'Scan Next Product',
          icon: LucideIcons.scanLine,
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      sections: [
        DsCard(
          radius: AppRadii.heroRadius,
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              const DsIconMedallion(
                icon: LucideIcons.searchCheck,
                tone: DsTone.info,
                size: 64,
                iconSize: 30,
              ),
              const SizedBox(height: 14),
              Text(
                'Your prize is under review',
                textAlign: TextAlign.center,
                style: context.texts.titleLarge,
              ),
              const SizedBox(height: 14),
              const DsBody(
                'This claim needs a check by the Crown Solar CRM team before '
                'it is paid. Nothing is wrong with your account and nothing '
                'has been refused.',
                size: 14,
                align: TextAlign.center,
              ),
            ],
          ),
        ),
        DsRowGroup(
          children: const [
            DsSettingRow(label: 'Claim reference', value: 'QR-CLM-2026-33218'),
            DsSettingRow(label: 'Scanned', value: 'Today, 1:44 PM'),
            DsSettingRow(
              label: 'Status',
              trailing: DsTag(label: 'Under review', tone: DsTone.info),
            ),
          ],
        ),
        const DsCaption(
          'You will get a notification when it is decided. You can keep '
          'scanning other products in the meantime.',
        ),
      ],
    );
  }
}

/// Board 05 · C1 — Already claimed for your class: someone got there first,
/// with the option to have both claims checked.
class ScanAlreadyClaimedScreen extends StatelessWidget {
  const ScanAlreadyClaimedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DsScreen(
      appBar: DsAppBar(
        title: 'Already Scanned',
        onBack: () => Navigator.of(context).maybePop(),
      ),
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      gap: 18,
      sections: [
        DsCard(
          radius: AppRadii.heroRadius,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
          child: Column(
            children: [
              const DsIconMedallion(
                icon: LucideIcons.userCheck,
                tone: DsTone.neutral,
                size: 64,
                iconSize: 30,
              ),
              const SizedBox(height: 14),
              Text(
                'This prize has already been claimed',
                textAlign: TextAlign.center,
                style: context.texts.titleLarge,
              ),
              const SizedBox(height: 14),
              const DsBody(
                'The installer prize on this code was paid to another '
                'installer. A code pays only one installer prize, ever.',
                size: 14,
                align: TextAlign.center,
              ),
            ],
          ),
        ),
        DsRowGroup(
          children: const [
            DsSettingRow(label: 'Claimed by', value: 'M. Zubair Solar'),
            DsSettingRow(label: 'Role', value: 'Installer · Badami Bagh'),
            DsSettingRow(label: 'Claimed on', value: '07 Sep 2026, 11:20 AM'),
            DsSettingRow(label: 'Your scan', value: 'Today, 4:07 PM'),
          ],
        ),
        DsCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Was this your installation?',
                style: context.texts.bodyLarge?.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              const DsBody(
                'Report the scan and the Crown Solar team will check both '
                'claims. They may award the prize to you.',
              ),
              const SizedBox(height: AppSpacing.stepMd),
              DsButton(label: 'Report This Scan', onPressed: () {}),
              const SizedBox(height: 10),
              DsButton(
                label: 'Scan Another',
                variant: DsButtonVariant.secondary,
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Board 05 · C2 — Dispute complaint, pre-filled: the evidence is attached
/// already, so nothing is retyped.
class ScanDisputeScreen extends StatelessWidget {
  const ScanDisputeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DsScreen(
      appBar: DsAppBar(
        title: 'Report This Scan',
        subtitle: 'Complaint · QR dispute',
        onBack: () => Navigator.of(context).maybePop(),
      ),
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      gap: AppSpacing.md,
      footer: DsFooterBar(
        child: DsButton(label: 'Submit Report', onPressed: () {}),
      ),
      sections: [
        const DsNotice(
          icon: LucideIcons.paperclip,
          tone: DsTone.info,
          message:
              'We have attached the evidence already. You do not need to type '
              'any of it again.',
        ),
        DsRowGroup(
          children: const [
            DsSettingRow(label: 'QR code', value: 'CS-6K-2026-338201'),
            DsSettingRow(
              label: 'Previous claimant',
              value: 'M. Zubair Solar · Installer',
            ),
            DsSettingRow(
              label: 'Previous claim time',
              value: '07 Sep 2026, 11:20 AM',
            ),
            DsSettingRow(label: 'Your scan time', value: 'Today, 4:07 PM'),
            DsSettingRow(
              label: 'Your location now',
              value: '31.5204° N, 74.3587° E',
              meta: 'Model Town, Lahore',
            ),
            DsSettingRow(
              label: 'Complaint type',
              trailing: DsTag(
                label: 'QR prize dispute · High',
                tone: DsTone.error,
              ),
            ),
          ],
        ),
        const DsInput(
          label: 'Anything else the team should know',
          placeholder: 'Optional',
          maxLines: 4,
        ),
        const DsCaption(
          'Priority and target response time are set by the complaint '
          'sub-type. Sample values shown on board 08.',
        ),
      ],
    );
  }
}

/// Board 05 · C3 — Dispute submitted, and exactly what happens next.
class ScanDisputeSubmittedScreen extends StatelessWidget {
  const ScanDisputeSubmittedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DsScreen(
      appBar: DsAppBar(
        title: 'Report Submitted',
        onBack: () => Navigator.of(context).maybePop(),
      ),
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      gap: 18,
      sections: [
        DsCard(
          radius: AppRadii.heroRadius,
          padding: const EdgeInsets.all(AppSpacing.stepLg),
          child: Row(
            children: [
              const DsIconMedallion(
                icon: LucideIcons.circleCheck,
                tone: DsTone.success,
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
                      'Ticket CMP-2026-5514 raised',
                      style: context.texts.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    const DsBody(
                      'The Crown Solar team will review both claims and let '
                      'you know the outcome.',
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
                'What happens next',
                style: context.texts.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              const DsTimeline(
                steps: [
                  DsTimelineStep(
                    title: 'CRM reviews both claims',
                    meta:
                        'They compare locations, times and installation '
                        'records.',
                    active: true,
                  ),
                  DsTimelineStep(
                    title: 'They may contact you',
                    meta: 'Through Chat or a phone call, if they need more '
                        'detail.',
                  ),
                  DsTimelineStep(
                    title: 'A decision is recorded',
                    meta: 'The complaint shows the outcome and its reason.',
                  ),
                  DsTimelineStep(
                    title: 'You are notified',
                    meta:
                        'If the prize is awarded to you, it is credited to '
                        'your wallet.',
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
              Text(
                'RESOLUTION NOTIFICATION · SAMPLE',
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 0.06 * 11,
                  fontWeight: FontWeight.w600,
                  color: context.palette.textTertiary,
                ),
              ),
              const SizedBox(height: 6),
              const DsBody(
                '"Your scan dispute has been resolved. PKR 1,500 has been '
                'credited to your wallet." Tapping it opens the complaint.',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Board 05 · C4 — Duplicate submission and retry: the claim is saved on the
/// phone, and sending again can never pay twice.
class ScanRetrySafeScreen extends StatelessWidget {
  const ScanRetrySafeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DsScreen(
      appBar: DsAppBar(
        title: 'Scan to Earn',
        onBack: () => Navigator.of(context).maybePop(),
      ),
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      gap: 18,
      sections: [
        DsCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const DsIconMedallion(
                    icon: LucideIcons.wifiOff,
                    tone: DsTone.warning,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Claim not sent',
                      style: context.texts.bodyLarge?.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.stepMd),
              const DsBody(
                'Your scan is saved on this phone. Nothing has been paid or '
                'lost. Send it again when you have signal.',
              ),
              const SizedBox(height: AppSpacing.stepMd),
              DsButton(
                label: 'Send Claim Again',
                icon: LucideIcons.refreshCw,
                onPressed: () {},
              ),
            ],
          ),
        ),
        const DsNotice(
          icon: LucideIcons.shieldCheck,
          tone: DsTone.info,
          title: 'You cannot be paid twice',
          message:
              'If the first attempt did reach Crown Solar, sending again shows '
              'you that same result instead of paying a second prize.',
        ),
        DsCard(
          tone: DsCardTone.sunken,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ALREADY SENT · SAME RESULT RETURNED',
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 0.06 * 11,
                  fontWeight: FontWeight.w600,
                  color: context.palette.textTertiary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'PKR 1,500 credited at 1:42 PM',
                style: context.texts.bodyLarge?.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const DsCaption('Ref QR-CLM-2026-33207 · one payment only'),
            ],
          ),
        ),
      ],
    );
  }
}
