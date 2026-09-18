import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/ui/ds.dart';

/// Board 08 · B1 — Push banners on the lock screen. Each one says what
/// happened and where tapping it lands.
class PushBannersScreen extends StatelessWidget {
  const PushBannersScreen({super.key});

  static const _banners = [
    (
      'now',
      'Cash request from Adnan Solar Works',
      'PKR 25,000 · currency. Approve or reject it in the app.',
    ),
    (
      '2 min ago',
      'PKR 1,500 prize credited',
      'Your scan of a Crown 6kW inverter has been paid to your wallet.',
    ),
    (
      '1 h ago',
      'Your profile is fully activated',
      'All three approvals are in. Sign in to open your dashboard.',
    ),
    (
      '3 h ago',
      'Branding update · Board Installed',
      'Rehman Signs has installed your Backlit board.',
    ),
    (
      'Yesterday',
      '25,000 points received',
      'From Hamza Solar House. Your balance is 182,400.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0F14),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            const SizedBox(height: AppSpacing.stepLg),
            Text(
              'Tuesday, 9 September',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.white.withValues(alpha: 0.75),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              '9:41',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 56,
                height: 64 / 56,
                fontWeight: FontWeight.w300,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            for (final (time, title, body) in _banners)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _LockScreenBanner(time: time, title: title, body: body),
              ),
          ],
        ),
      ),
    );
  }
}

class _LockScreenBanner extends StatelessWidget {
  const _LockScreenBanner({
    required this.time,
    required this.title,
    required this.body,
  });

  final String time;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: AppRadii.lgRadius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 20,
                height: 20,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: context.palette.crownGold,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: const Icon(
                  LucideIcons.sun,
                  size: 13,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Crown Solar',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ),
              Text(
                time,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.65),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            body,
            style: TextStyle(
              fontSize: 13,
              height: 18 / 13,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }
}

/// Board 08 · B2 — The optional notification centre. The mandatory behaviour
/// is the push banner plus the badge on the destination; this list is an
/// extension of that pattern, not a requirement.
class NotificationCentreScreen extends StatelessWidget {
  const NotificationCentreScreen({super.key});

  static const _items = [
    (
      LucideIcons.undo2,
      'Cash request expired and returned',
      'PKR 4,000 you sent to Sitara Electronics came back to your wallet.',
      'Today, 8:02 AM · opens Ledger entry',
      true,
    ),
    (
      LucideIcons.searchCheck,
      'Prize held for review',
      'Your claim on CS-6K-2026-338201 is with CRM.',
      'Yesterday · opens Claim detail',
      true,
    ),
    (
      LucideIcons.sparkles,
      'Spin entitlement earned',
      'You scanned 10 products today. One spin is waiting.',
      'Yesterday · opens Inaam Baazar · Spin and Win',
      false,
    ),
    (
      LucideIcons.circleCheck,
      'Complaint CMP-2026-5102 resolved',
      'Points for your August purchase have been posted.',
      '22 Aug · opens Complaint detail',
      false,
    ),
    (
      LucideIcons.megaphone,
      'New post in Space',
      'Crown Solar shared: Eid scheme for retailers.',
      '20 Aug · opens Post detail',
      false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return DsScreen(
      appBar: DsAppBar(
        title: 'Notifications',
        subtitle: 'Optional extension · annotated',
        onBack: () => Navigator.of(context).maybePop(),
      ),
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      gap: AppSpacing.stepMd,
      sections: [
        const DsNotice(
          icon: LucideIcons.info,
          message:
              'The FSD does not require an in-app notification centre. This '
              'screen is offered as an optional extension of the existing '
              'pattern — the mandatory behaviour is the push banner plus the '
              'badge on the destination.',
        ),
        for (final (icon, title, body, meta, unread) in _items)
          DsAlert(
            title: title,
            message: body,
            timestamp: meta,
            unread: unread,
            level: icon == LucideIcons.circleCheck
                ? DsAlertLevel.success
                : DsAlertLevel.info,
            onTap: () {},
          ),
      ],
    );
  }
}
