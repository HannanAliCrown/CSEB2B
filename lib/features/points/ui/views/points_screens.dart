import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/ui/ds.dart';
import '../../../home/ui/models/home_demo_data.dart';

/// Board 06 · A1 — Points hub.
///
/// Balance, the two live target meters, and the points ledger — points and
/// currency are deliberately never mixed in one balance.
class PointsHubScreen extends StatelessWidget {
  const PointsHubScreen({super.key});

  static const _ledger = [
    (
      'Purchase accrual',
      'Today, 6:02 AM · SAP INV-77213',
      '+ 18,400',
      '182,400',
      true,
    ),
    (
      'Bilal Traders',
      'Yesterday, 3:14 PM · Sent',
      '− 12,000',
      '164,000',
      false,
    ),
    ('Hamza Solar House', '07 Sep · Received', '+ 25,000', '176,000', true),
    (
      'Reversal · SAP INV-76980',
      '05 Sep · Purchase reversed in SAP',
      '− 4,300',
      '151,000',
      false,
    ),
    (
      'CRM adjustment',
      '02 Sep · Reason: wrong recipient corrected',
      '+ 9,000',
      '155,300',
      true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: DsAppBar(
        title: 'Points',
        onBack: () => Navigator.of(context).maybePop(),
      ),
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.stepLg),
              decoration: BoxDecoration(
                color: context.colors.primary,
                borderRadius: AppRadii.heroRadius,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'POINTS BALANCE',
                    style: TextStyle(
                      fontSize: 12,
                      letterSpacing: 0.06 * 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.75),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const Text(
                    '182,400',
                    style: TextStyle(
                      fontSize: 34,
                      height: 40 / 34,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: const [
                      Expanded(child: _PointsAction(label: 'Send Points')),
                      SizedBox(width: 10),
                      Expanded(child: _PointsAction(label: 'View Targets')),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            const TargetMeterCard(
              label: 'Sep — Dec target · 400,000',
              percent: 0.46,
              note:
                  '217,600 points to go · prize at target is a Honda 125 '
                  'motorcycle',
            ),
            const SizedBox(height: AppSpacing.stepMd),
            const TargetMeterCard(
              label: 'Year total · 1,000,000',
              percent: 0.69,
              note: '686,900 of 1,000,000 for 2026 · 313,100 to go',
            ),
            const SizedBox(height: AppSpacing.lg),
            DsSectionHeader(
              title: 'Points ledger',
              actionLabel: 'See all',
              onAction: () {},
            ),
            DsCard(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Column(
                children: [
                  for (var i = 0; i < _ledger.length; i++) ...[
                    _PointsRow(
                      who: _ledger[i].$1,
                      meta: _ledger[i].$2,
                      amount: _ledger[i].$3,
                      after: _ledger[i].$4,
                      credit: _ledger[i].$5,
                    ),
                    if (i != _ledger.length - 1) const DsHairline(),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: DsBottomNav(
        items: HomeDemo.retailer.nav,
        activeId: 'points',
      ),
    );
  }
}

class _PointsAction extends StatelessWidget {
  const _PointsAction({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}

/// A target meter: label, percentage, bar and the plain-words gap to go.
class TargetMeterCard extends StatelessWidget {
  const TargetMeterCard({
    super.key,
    required this.label,
    required this.percent,
    required this.note,
  });

  final String label;
  final double percent;
  final String note;

  @override
  Widget build(BuildContext context) {
    return DsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: context.texts.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '${(percent * 100).round()}%',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: context.colors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          DsProgressBar(value: percent),
          const SizedBox(height: 10),
          DsCaption(note),
        ],
      ),
    );
  }
}

class _PointsRow extends StatelessWidget {
  const _PointsRow({
    required this.who,
    required this.meta,
    required this.amount,
    required this.after,
    required this.credit,
  });

  final String who;
  final String meta;
  final String amount;
  final String after;
  final bool credit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 13),
      child: Row(
        children: [
          DsIconMedallion(
            icon: credit ? LucideIcons.arrowDownLeft : LucideIcons.arrowUpRight,
            tone: credit ? DsTone.success : DsTone.neutral,
            size: 36,
            iconSize: 17,
            rounded: true,
          ),
          const SizedBox(width: AppSpacing.stepMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  who,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  meta,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    height: 15 / 11,
                    color: context.palette.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                amount,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: credit
                      ? context.status.success
                      : context.colors.onSurface,
                ),
              ),
              Text(
                after,
                style: TextStyle(
                  fontSize: 11,
                  color: context.palette.textTertiary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Board 06 · A2 — Send Points: three paths only. There is deliberately no
/// search-by-number, because points move instantly and cannot be recalled.
class SendPointsRecipientScreen extends StatelessWidget {
  const SendPointsRecipientScreen({super.key});

  static const _recents = [
    ('Bilal Traders', 'Sent 12,000 on 08 Sep', 'Retailer'),
    ('Hamza Solar House', 'Sent 40,000 on 01 Sep', 'Wholesaler'),
    ('Karachi Solar Distributors', 'Sent 75,000 on 21 Aug', 'Distributor'),
    ('Sitara Electronics', 'Sent 6,000 on 14 Aug', 'Retailer'),
  ];

  @override
  Widget build(BuildContext context) {
    return DsScreen(
      appBar: DsAppBar(
        title: 'Send Points',
        subtitle: '182,400 available',
        onBack: () => Navigator.of(context).maybePop(),
      ),
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      gap: AppSpacing.md,
      sections: [
        Row(
          children: const [
            Expanded(
              child: _PathTile(icon: LucideIcons.contact, label: 'Contacts'),
            ),
            SizedBox(width: AppSpacing.stepMd),
            Expanded(
              child: _PathTile(icon: LucideIcons.qrCode, label: 'Scan QR'),
            ),
            SizedBox(width: AppSpacing.stepMd),
            Expanded(
              child: _PathTile(icon: LucideIcons.history, label: 'History'),
            ),
          ],
        ),
        const DsNotice(
          icon: LucideIcons.info,
          message:
              'Points have no search-by-number option. You can send only to '
              'people in your contacts, from your history, or by scanning '
              'their QR in person.',
        ),
        const DsSectionHeader(title: 'Recent recipients'),
        DsCard(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Column(
            children: [
              for (var i = 0; i < _recents.length; i++) ...[
                DsPartyRow(
                  name: _recents[i].$1,
                  meta: _recents[i].$2,
                  trailing: DsTag(label: _recents[i].$3),
                ),
                if (i != _recents.length - 1) const DsHairline(),
              ],
            ],
          ),
        ),
        const DsCaption(
          'Installers hold no points, so they never appear in this list even '
          'if they are in your contacts.',
        ),
      ],
    );
  }
}

class _PathTile extends StatelessWidget {
  const _PathTile({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: AppRadii.mdRadius,
        border: Border.all(color: context.colors.outline),
      ),
      child: Column(
        children: [
          DsIconMedallion(icon: icon, size: 36, iconSize: 19, rounded: true),
          const SizedBox(height: AppSpacing.sm),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

/// Board 06 · A3 — Confirm: points arrive immediately, with no approval step
/// and no way back except a CRM adjustment.
class SendPointsConfirmScreen extends StatelessWidget {
  const SendPointsConfirmScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DsScreen(
      appBar: DsAppBar(
        title: 'Send Points',
        onBack: () => Navigator.of(context).maybePop(),
      ),
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      gap: 18,
      footer: DsFooterBar(
        child: Column(
          children: [
            DsButton(label: 'Send 12,000 Points', onPressed: () {}),
            const SizedBox(height: 10),
            DsButton(
              label: 'Go Back',
              variant: DsButtonVariant.quiet,
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          ],
        ),
      ),
      sections: [
        DsCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: const DsPartyRow(
            name: 'Bilal Traders',
            meta: 'Retailer · Hall Road · +92 321 77·· ··2',
          ),
        ),
        Column(
          children: [
            Text(
              'POINTS TO SEND',
              style: TextStyle(
                fontSize: 12,
                letterSpacing: 0.06 * 12,
                fontWeight: FontWeight.w600,
                color: context.palette.textTertiary,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              '12,000',
              style: TextStyle(
                fontSize: 38,
                height: 44 / 38,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.02 * 38,
              ),
            ),
            const SizedBox(height: 6),
            const DsBody('You will have 170,400 points left'),
          ],
        ),
        DsCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Send 12,000 points?',
                style: context.texts.bodyLarge?.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              const DsBody(
                'Points arrive with Bilal Traders straight away. There is no '
                'approval step and they cannot reject it. If you send to the '
                'wrong person, only Crown Solar CRM can adjust it.',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Board 06 · A4 — Sent, and the four refusals, each stating its own reason.
class SendPointsSentScreen extends StatelessWidget {
  const SendPointsSentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DsScreen(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      gap: AppSpacing.stepMd,
      sections: [
        DsCard(
          radius: AppRadii.heroRadius,
          padding: const EdgeInsets.all(AppSpacing.stepLg),
          child: Column(
            children: [
              const DsIconMedallion(
                icon: LucideIcons.circleCheck,
                tone: DsTone.success,
                size: 64,
                iconSize: 30,
              ),
              const SizedBox(height: 14),
              Text(
                '12,000 points sent',
                textAlign: TextAlign.center,
                style: context.texts.titleLarge,
              ),
              const SizedBox(height: AppSpacing.sm),
              const DsBody(
                'Bilal Traders has them now and has been notified. Ref '
                'PT-2026-77410 · Today, 9:43 AM',
                size: 14,
                align: TextAlign.center,
              ),
            ],
          ),
        ),
        Text(
          'REFUSALS · SHOWN TOGETHER FOR REVIEW',
          style: TextStyle(
            fontSize: 11,
            letterSpacing: 0.06 * 11,
            fontWeight: FontWeight.w600,
            color: context.palette.textTertiary,
          ),
        ),
        const _PointsRefusal(
          title: 'Not enough points',
          message:
              'You are sending 200,000 but hold 182,400. Reduce the '
              'amount.',
        ),
        const _PointsRefusal(
          title: 'You cannot send points to this person',
          message:
              'The Crown Solar team sets which roles may exchange points. This '
              'pair is not permitted.',
        ),
        const _PointsRefusal(
          title: 'Your points transfers are restricted',
          message:
              'Sending is not available on your account. Your balance and '
              'ledger stay visible. Contact Support.',
        ),
        const _PointsRefusal(
          title: 'This person cannot receive points right now',
          message:
              'Their account has a points restriction. Ask them to contact '
              'Crown Solar CRM.',
        ),
      ],
    );
  }
}

class _PointsRefusal extends StatelessWidget {
  const _PointsRefusal({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return DsCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const DsIconMedallion(
            icon: LucideIcons.circleAlert,
            tone: DsTone.warning,
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
                const SizedBox(height: 4),
                DsBody(message),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
