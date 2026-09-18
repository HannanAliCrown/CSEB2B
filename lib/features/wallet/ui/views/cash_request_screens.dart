import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/ui/ds.dart';
import '../../../home/ui/models/home_demo_data.dart';

/// Board 04 · B1 — Processing, offline, duplicate-safe.
///
/// The three states of one send attempt, shown together: in flight, lost
/// connection, and why retrying can never send twice.
class SendCashProcessingScreen extends StatelessWidget {
  const SendCashProcessingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DsScreen(
      appBar: DsAppBar(
        title: 'Send Cash',
        onBack: () => Navigator.of(context).maybePop(),
      ),
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      gap: 18,
      sections: [
        DsCard(
          child: Row(
            children: [
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Sending PKR 25,000',
                      style: context.texts.bodyLarge?.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const DsBody(
                      'Do not close the app. This takes a few seconds.',
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
              Row(
                children: [
                  const DsIconMedallion(
                    icon: LucideIcons.wifiOff,
                    tone: DsTone.warning,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'No connection',
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
                'We could not reach Crown Solar. Nothing has left your wallet. '
                'Your recipient and amount are saved — tap retry when you have '
                'signal.',
              ),
              const SizedBox(height: AppSpacing.stepMd),
              DsButton(
                label: 'Retry Sending',
                icon: LucideIcons.refreshCw,
                onPressed: () {},
              ),
            ],
          ),
        ),
        const DsNotice(
          icon: LucideIcons.shieldCheck,
          tone: DsTone.info,
          title: 'Retrying cannot send twice',
          message:
              'If the first attempt did reach us, retry shows you that same '
              'request instead of creating a second one.',
        ),
        const DsCaption(
          'The send button is disabled while processing, and a second tap is '
          'ignored rather than queued.',
        ),
      ],
    );
  }
}

/// Board 04 · B2 — Each refusal names its own reason.
class SendCashRefusalsScreen extends StatelessWidget {
  const SendCashRefusalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DsScreen(
      appBar: DsAppBar(
        title: 'Send Cash',
        subtitle: 'Three refusals, three messages',
        onBack: () => Navigator.of(context).maybePop(),
      ),
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      gap: 18,
      sections: [
        const DsInput(
          label: 'Amount',
          value: 'PKR 220,000',
          error:
              'More than your available balance. You have PKR 184,500, and PKR '
              '12,000 of that is already held for other requests.',
        ),
        _RefusalCard(
          icon: LucideIcons.userX,
          title: 'You cannot send to this person',
          message:
              'As an installer you can send to retailers, wholesalers and '
              'distributors — not to another installer. Choose a different '
              'recipient.',
        ),
        DsCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const DsIconMedallion(
                    icon: LucideIcons.ban,
                    tone: DsTone.neutral,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Cash transactions are restricted',
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
                'Sending is not available on your account right now. Your '
                'balance and ledger are still there to view.',
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: DsButton(
                      label: 'Call CRM',
                      variant: DsButtonVariant.secondary,
                      size: DsButtonSize.sm,
                      icon: LucideIcons.phone,
                      onPressed: () {},
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DsButton(
                      label: 'Chat with CRM',
                      variant: DsButtonVariant.secondary,
                      size: DsButtonSize.sm,
                      icon: LucideIcons.messageCircle,
                      onPressed: () {},
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const DsCaption(
          'Shown stacked here for comparison; in the product each appears '
          'alone at the point it applies.',
        ),
      ],
    );
  }
}

class _RefusalCard extends StatelessWidget {
  const _RefusalCard({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return DsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              DsIconMedallion(icon: icon, tone: DsTone.warning),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: context.texts.bodyLarge?.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.stepMd),
          DsBody(message),
        ],
      ),
    );
  }
}

/// Board 04 · B3 — The sender's view: held, approved, rejected, expired.
///
/// Every row says where the money is right now, in plain words.
class SentRequestsScreen extends StatelessWidget {
  const SentRequestsScreen({super.key});

  static const _requests = [
    (
      'Al-Noor Electric Store',
      'Today, 9:43 AM',
      'Held',
      DsTone.warning,
      'PKR 25,000',
      'Out of your wallet',
      'Waiting for Al-Noor Electric Store to approve.',
    ),
    (
      'Hamza Solar House',
      'Yesterday, 4:10 PM',
      'Approved',
      DsTone.success,
      'PKR 60,000',
      'Settled',
      'Approved yesterday at 6:02 PM. This request is complete.',
    ),
    (
      'Bilal Traders',
      '07 Sep',
      'Rejected',
      DsTone.error,
      'PKR 9,500',
      'Back in your wallet',
      'Rejected on 07 Sep. PKR 9,500 was returned to you the same day.',
    ),
    (
      'Sitara Electronics',
      '28 Aug',
      'Expired',
      DsTone.neutral,
      'PKR 4,000',
      'Back in your wallet',
      'No answer within the allowed period, so the money came back '
          'automatically.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return DsScreen(
      appBar: DsAppBar(
        title: 'My Sent Requests',
        onBack: () => Navigator.of(context).maybePop(),
      ),
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      gap: AppSpacing.stepMd,
      sections: [
        for (final r in _requests)
          DsCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            r.$1,
                            style: context.texts.bodyLarge?.copyWith(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            r.$2,
                            style: TextStyle(
                              fontSize: 12,
                              color: context.palette.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    DsTag(label: r.$3, tone: r.$4),
                  ],
                ),
                const SizedBox(height: AppSpacing.stepMd),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      r.$5,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Flexible(
                      child: Text(
                        r.$6,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: context.palette.textTertiary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                DsBody(r.$7),
              ],
            ),
          ),
      ],
    );
  }
}

/// Board 04 · B4 — The recipient's inbox: approve or reject, with the money
/// already out of the sender's wallet and waiting.
class CashRequestInboxScreen extends StatefulWidget {
  const CashRequestInboxScreen({super.key});

  @override
  State<CashRequestInboxScreen> createState() => _CashRequestInboxScreenState();
}

class _CashRequestInboxScreenState extends State<CashRequestInboxScreen> {
  String _tab = 'Waiting · 2';

  static const _requests = [
    (
      'Adnan Solar Works',
      'Installer · Today, 9:43 AM',
      '2 days left',
      'PKR 25,000',
    ),
    (
      'Bilal Traders',
      'Retailer · Yesterday, 5:20 PM',
      '1 day left',
      'PKR 14,200',
    ),
    ('M. Zubair Solar', 'Installer · 07 Sep', 'Expires today', 'PKR 6,800'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: DsAppBar(
        title: 'Cash Requests',
        subtitle: '2 waiting for you',
        onBack: () => Navigator.of(context).maybePop(),
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DsTabs(
              tabs: const ['Waiting · 2', 'Approved', 'Rejected'],
              value: _tab,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPadding,
              ),
              onChanged: (tab) => setState(() => _tab = tab),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.screenPadding),
                children: [
                  for (final r in _requests) ...[
                    DsCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DsPartyRow(
                            name: r.$1,
                            meta: r.$2,
                            trailing: DsTag(
                              label: r.$3,
                              tone: r.$3 == 'Expires today'
                                  ? DsTone.error
                                  : DsTone.neutral,
                            ),
                          ),
                          const DsHairline(),
                          const SizedBox(height: AppSpacing.stepMd),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              DsCaption('Amount'),
                              Text(
                                r.$4,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Row(
                            children: [
                              Expanded(
                                child: DsButton(
                                  label: 'Approve',
                                  size: DsButtonSize.sm,
                                  icon: LucideIcons.check,
                                  onPressed: () {},
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: DsButton(
                                  label: 'Reject',
                                  variant: DsButtonVariant.secondary,
                                  size: DsButtonSize.sm,
                                  icon: LucideIcons.x,
                                  onPressed: () {},
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.stepMd),
                  ],
                  const DsCaption(
                    'Approving moves the held money into your wallet. '
                    'Rejecting sends it back to the person who sent it. Either '
                    'way they are notified.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: DsBottomNav(
        items: HomeDemo.retailer.nav,
        activeId: 'home',
      ),
    );
  }
}
