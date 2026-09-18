import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/ui/ds.dart';
import '../widgets/scanner_chrome.dart';

/// Board 05 · A1 — Installer and Retailer: both capabilities, as two tabs.
///
/// Scan to Earn is the default for roles that have it; the daily scan count
/// toward the next spin sits under the viewfinder.
class ScanEarnScreen extends StatefulWidget {
  const ScanEarnScreen({super.key});

  @override
  State<ScanEarnScreen> createState() => _ScanEarnScreenState();
}

class _ScanEarnScreenState extends State<ScanEarnScreen> {
  String _tab = 'Scan to Earn';

  @override
  Widget build(BuildContext context) {
    return ScannerScaffold(
      title: 'Scan QR',
      hint: 'Point the camera at the QR code on the product label.',
      tabs: ScannerTabs(
        options: const ['Scan to Earn', 'Authenticity Check'],
        value: _tab,
        onChanged: (tab) => setState(() => _tab = tab),
      ),
      footer: Column(
        children: [
          const TorchControl(),
          const SizedBox(height: AppSpacing.md),
          ScannerNote(
            child: Text.rich(
              TextSpan(
                children: const [
                  TextSpan(text: 'Today: '),
                  TextSpan(
                    text: '7 scans',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  TextSpan(text: ' · 3 more for your next spin'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Board 05 · A2 — Wholesaler and Distributor: one capability, so no tabs
/// are shown rather than a disabled second tab.
class AuthenticityCheckScreen extends StatelessWidget {
  const AuthenticityCheckScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ScannerScaffold(
      title: 'Authenticity Check',
      hint: 'Scan any Crown Solar product label to check it.',
      tabs: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          'Confirm a product is genuine Crown Solar',
          style: TextStyle(
            fontSize: 13,
            color: Colors.white.withValues(alpha: 0.75),
          ),
        ),
      ),
    );
  }
}

/// Board 05 · A3 — Camera denied. The screen's one action is to open
/// Settings; nothing else in the app is affected.
class ScanCameraDeniedScreen extends StatelessWidget {
  const ScanCameraDeniedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DsScreen(
      appBar: DsAppBar(
        title: 'Scan QR',
        onBack: () => Navigator.of(context).maybePop(),
      ),
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      gap: AppSpacing.stepLg,
      sections: [
        DsCard(
          radius: AppRadii.heroRadius,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
          child: Column(
            children: [
              const DsIconMedallion(
                icon: LucideIcons.cameraOff,
                tone: DsTone.neutral,
                size: 64,
                iconSize: 30,
              ),
              const SizedBox(height: 14),
              Text(
                'Camera access is off',
                textAlign: TextAlign.center,
                style: context.texts.titleLarge,
              ),
              const SizedBox(height: 14),
              const DsBody(
                'Scanning needs the camera. Turn it on in Settings to check or '
                'claim a product.',
                size: 14,
                align: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              DsButton(
                label: 'Open Settings',
                icon: LucideIcons.settings,
                onPressed: () {},
              ),
            ],
          ),
        ),
        const DsCaption(
          'The rest of the app keeps working — only scanning is affected.',
        ),
      ],
    );
  }
}

/// Board 05 · A4 — Genuine product: the authenticity result, which never
/// pays anything by itself.
class ScanGenuineScreen extends StatelessWidget {
  const ScanGenuineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DsScreen(
      appBar: DsAppBar(
        title: 'Authenticity Check',
        onBack: () => Navigator.of(context).maybePop(),
      ),
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      gap: 18,
      footer: DsFooterBar(
        child: Column(
          children: [
            DsButton(label: 'Open Product Page', onPressed: () {}),
            const SizedBox(height: 10),
            DsButton(
              label: 'Scan Another',
              variant: DsButtonVariant.secondary,
              icon: LucideIcons.scanLine,
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          ],
        ),
      ),
      sections: [
        DsCard(
          radius: AppRadii.heroRadius,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
          child: Column(
            children: [
              const DsIconMedallion(
                icon: LucideIcons.badgeCheck,
                tone: DsTone.success,
                size: 64,
                iconSize: 30,
              ),
              const SizedBox(height: 14),
              Text(
                'Genuine Crown Solar product',
                textAlign: TextAlign.center,
                style: context.texts.titleLarge,
              ),
              const SizedBox(height: AppSpacing.sm),
              const DsBody(
                'This code matches a product made by Crown Solar.',
                size: 14,
                align: TextAlign.center,
              ),
            ],
          ),
        ),
        DsRowGroup(
          children: const [
            DsSettingRow(label: 'Product', value: 'Crown 8kW Hybrid Inverter'),
            DsSettingRow(label: 'Serial', value: 'CS-8K-2026-447192'),
            DsSettingRow(label: 'Batch', value: 'B-2026-07'),
            DsSettingRow(label: 'Checked', value: 'Today, 9:42 AM'),
            DsSettingRow(
              label: 'Result',
              trailing: DsTag(label: 'Genuine', tone: DsTone.success),
            ),
          ],
        ),
      ],
    );
  }
}

/// Board 05 · B1 — Not recognised. Safe, generic wording: the app does not
/// accuse anyone of selling a fake.
class ScanNotRecognisedScreen extends StatelessWidget {
  const ScanNotRecognisedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DsScreen(
      appBar: DsAppBar(
        title: 'Authenticity Check',
        onBack: () => Navigator.of(context).maybePop(),
      ),
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      gap: 18,
      footer: DsFooterBar(
        child: DsButton(
          label: 'Scan Again',
          icon: LucideIcons.scanLine,
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      sections: [
        DsCard(
          radius: AppRadii.heroRadius,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
          child: Column(
            children: [
              const DsIconMedallion(
                icon: LucideIcons.scanSearch,
                tone: DsTone.neutral,
                size: 64,
                iconSize: 30,
              ),
              const SizedBox(height: 14),
              Text(
                'This code is not recognised',
                textAlign: TextAlign.center,
                style: context.texts.titleLarge,
              ),
              const SizedBox(height: 14),
              const DsBody(
                'We cannot confirm this product from the code that was '
                'scanned. Check that you scanned the Crown Solar label, and '
                'try again in good light.',
                size: 14,
                align: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.stepMd),
              const DsTag(label: 'Scanned: 4Y-99XX-0031'),
            ],
          ),
        ),
        DsCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'If you think the product is fake',
                style: context.texts.bodyLarge?.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              const DsBody(
                'Raise a complaint with the code and a photo. The Crown Solar '
                'team will look into it.',
              ),
              const SizedBox(height: AppSpacing.stepMd),
              DsButton(
                label: 'Raise a Complaint',
                variant: DsButtonVariant.secondary,
                size: DsButtonSize.sm,
                icon: LucideIcons.lifeBuoy,
                onPressed: () {},
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Board 05 · B2 — In processing, blocked, expired: three outcomes that pay
/// nothing, each with its own wording. Grey, never red.
class ScanNonPayingStatesScreen extends StatelessWidget {
  const ScanNonPayingStatesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DsScreen(
      appBar: DsAppBar(
        title: 'Scan Results',
        subtitle: 'Three states, shown together',
        onBack: () => Navigator.of(context).maybePop(),
      ),
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      gap: AppSpacing.stepMd,
      sections: [
        const _OutcomeCard(
          icon: LucideIcons.hourglass,
          tone: DsTone.info,
          title: 'Code is in processing',
          code: 'CS-12K-2026-880431',
          message:
              'This serial has not been linked to a product record yet. Try '
              'again in a day or two — nothing is wrong with the product.',
          payout: 'No payment yet',
          action: 'Check Again',
        ),
        const _OutcomeCard(
          icon: LucideIcons.ban,
          tone: DsTone.neutral,
          title: 'This code is blocked',
          code: 'CS-550W-2026-119032',
          message:
              'Crown Solar has blocked this code. It cannot be used for a '
              'prize. Contact CRM if you believe this is wrong.',
          payout: 'Pays nothing',
          action: 'Contact CRM',
        ),
        const _OutcomeCard(
          icon: LucideIcons.calendarX,
          tone: DsTone.neutral,
          title: 'This code has expired',
          code: 'CS-3K-2025-770118',
          message:
              'The prize on this code ended on 31 Dec 2025. The product is '
              'still genuine.',
          payout: 'Pays nothing',
          action: 'View Product',
        ),
        const DsCaption(
          'Each of these is a separate screen in the product. None of them is '
          'presented as a failure of the app.',
        ),
      ],
    );
  }
}

class _OutcomeCard extends StatelessWidget {
  const _OutcomeCard({
    required this.icon,
    required this.tone,
    required this.title,
    required this.code,
    required this.message,
    required this.payout,
    required this.action,
  });

  final IconData icon;
  final DsTone tone;
  final String title;
  final String code;
  final String message;
  final String payout;
  final String action;

  @override
  Widget build(BuildContext context) {
    return DsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              DsIconMedallion(icon: icon, tone: tone),
              const SizedBox(width: 10),
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
                      code,
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                        color: context.palette.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.stepMd),
          DsBody(message),
          const SizedBox(height: AppSpacing.stepMd),
          Row(
            children: [
              DsTag(label: payout),
              const Spacer(),
              Text(
                action,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: context.colors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
