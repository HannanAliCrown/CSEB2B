import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/ui/ds.dart';

/// Board 04 · A1 — Choose a recipient · four paths.
///
/// Every path ends at the same Amount screen; only registered Crown Solar
/// accounts ever appear.
class SendCashRecipientScreen extends StatelessWidget {
  const SendCashRecipientScreen({super.key});

  static const _paths = [
    (LucideIcons.contact, 'Contacts', 'Registered contacts only'),
    (LucideIcons.qrCode, 'Scan QR', 'Their profile QR code'),
    (LucideIcons.history, 'History', 'Most recent first'),
    (LucideIcons.search, 'Search Number', 'Find by mobile number'),
  ];

  static const _recents = [
    ('Al-Noor Electric Store', 'Last sent 07 Sep · PKR 18,000', 'Retailer'),
    ('Hamza Solar House', 'Last sent 02 Sep · PKR 60,000', 'Wholesaler'),
    (
      'Karachi Solar Distributors',
      'Last sent 28 Aug · PKR 240,000',
      'Distributor',
    ),
    ('Bilal Traders', 'Last sent 21 Aug · PKR 9,500', 'Retailer'),
  ];

  @override
  Widget build(BuildContext context) {
    return DsScreen(
      appBar: DsAppBar(
        title: 'Send Cash',
        subtitle: 'Available PKR 184,500',
        onBack: () => Navigator.of(context).maybePop(),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        18,
        AppSpacing.screenPadding,
        18,
      ),
      gap: AppSpacing.md,
      sections: [
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: AppSpacing.stepMd,
          mainAxisSpacing: AppSpacing.stepMd,
          mainAxisExtent: 104,
          children: [
            for (final (icon, label, meta) in _paths)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: context.colors.surface,
                  borderRadius: AppRadii.mdRadius,
                  border: Border.all(color: context.colors.outline),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DsIconMedallion(
                      icon: icon,
                      size: 36,
                      iconSize: 19,
                      rounded: true,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      meta,
                      style: TextStyle(
                        fontSize: 11,
                        height: 15 / 11,
                        color: context.palette.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        DsSectionHeader(title: 'Recent', actionLabel: 'See all', onAction: () {}),
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
        const DsNotice(
          message:
              'Only people already registered on Crown Solar Energy appear '
              'here. Numbers with no account are not shown and not saved.',
          dense: true,
        ),
      ],
    );
  }
}

/// Board 04 · A1a — Contacts: matched against the phone's address book.
class SendCashContactsScreen extends StatelessWidget {
  const SendCashContactsScreen({super.key});

  static const _contacts = [
    ('Al-Noor Electric Store', '+92 300 88·· ··9', 'Retailer'),
    ('Hamza Solar House', '+92 321 55·· ··2', 'Wholesaler'),
    ('Karachi Solar Distributors', '+92 333 99·· ··8', 'Distributor'),
    ('Bilal Traders', '+92 321 77·· ··2', 'Retailer'),
    ('M. Zubair Solar', '+92 300 12·· ··4', 'Installer'),
    ('Sitara Electronics', '+92 302 44·· ··7', 'Retailer'),
  ];

  @override
  Widget build(BuildContext context) {
    return DsScreen(
      appBar: DsAppBar(
        title: 'Contacts',
        onBack: () => Navigator.of(context).maybePop(),
      ),
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      gap: AppSpacing.stepMd,
      sections: [
        Text(
          '27 MATCHED CONTACTS',
          style: TextStyle(
            fontSize: 11,
            letterSpacing: 0.06 * 11,
            fontWeight: FontWeight.w600,
            color: context.palette.textTertiary,
          ),
        ),
        DsCard(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Column(
            children: [
              for (var i = 0; i < _contacts.length; i++) ...[
                DsPartyRow(
                  name: _contacts[i].$1,
                  meta: _contacts[i].$2,
                  trailing: DsTag(label: _contacts[i].$3),
                  onTap: () {},
                ),
                if (i != _contacts.length - 1) const DsHairline(),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Board 04 · A1b — Scan the recipient's profile QR code.
class SendCashScanScreen extends StatelessWidget {
  const SendCashScanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0F14),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.screenPadding),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).maybePop(),
                    child: const Icon(
                      LucideIcons.chevronLeft,
                      size: 24,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Text(
                    'Scan Their QR Code',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 240,
                        height: 240,
                        decoration: BoxDecoration(
                          borderRadius: AppRadii.heroRadius,
                          border: Border.all(
                            color: context.palette.crownGold,
                            width: 3,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        "Point the camera at the recipient's profile QR code, "
                        'shown from their Profile.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          height: 20 / 14,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 34),
              child: Text(
                'Enter number instead',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: context.palette.crownGold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Board 04 · A1c — History: everyone you have sent cash to.
class SendCashHistoryScreen extends StatelessWidget {
  const SendCashHistoryScreen({super.key});

  static const _history = [
    ('Al-Noor Electric Store', 'Last sent 07 Sep · PKR 18,000'),
    ('Hamza Solar House', 'Last sent 02 Sep · PKR 60,000'),
    ('Karachi Solar Distributors', 'Last sent 28 Aug · PKR 240,000'),
    ('Bilal Traders', 'Last sent 21 Aug · PKR 9,500'),
  ];

  @override
  Widget build(BuildContext context) {
    return DsScreen(
      appBar: DsAppBar(
        title: 'Send Again',
        subtitle: 'Everyone you have sent cash to',
        onBack: () => Navigator.of(context).maybePop(),
      ),
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      sections: [
        DsCard(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Column(
            children: [
              for (var i = 0; i < _history.length; i++) ...[
                DsPartyRow(
                  name: _history[i].$1,
                  meta: _history[i].$2,
                  trailing: Text(
                    'Send Again',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: context.colors.primary,
                    ),
                  ),
                ),
                if (i != _history.length - 1) const DsHairline(),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Board 04 · A1d — Search Number: the name is looked up, never typed.
class SendCashSearchScreen extends StatelessWidget {
  const SendCashSearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DsScreen(
      appBar: DsAppBar(
        title: 'Search Number',
        onBack: () => Navigator.of(context).maybePop(),
      ),
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      gap: AppSpacing.md,
      footer: DsFooterBar(
        child: DsButton(
          label: 'Continue',
          iconAfter: LucideIcons.arrowRight,
          onPressed: () {},
        ),
      ),
      sections: [
        const DsInput(
          label: 'Mobile number',
          value: '+92 300 8812349',
          keyboardType: TextInputType.phone,
        ),
        DsCard(
          child: DsPartyRow(
            name: 'Al-Noor Electric Store',
            meta: 'Retailer · Ravi Road · found automatically',
            trailing: DsStatusPill(
              label: 'Verified',
              icon: LucideIcons.circleCheck,
              tone: DsTone.success,
              small: true,
            ),
          ),
        ),
        const DsCaption(
          'If no Crown Solar account matches this number, no result appears '
          'and nothing is saved from it.',
        ),
      ],
    );
  }
}

/// Board 04 · A2 — Amount, with the after-sending balance always visible.
class SendCashAmountScreen extends StatelessWidget {
  const SendCashAmountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DsScreen(
      appBar: DsAppBar(
        title: 'Amount',
        onBack: () => Navigator.of(context).maybePop(),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        18,
        AppSpacing.screenPadding,
        18,
      ),
      gap: 18,
      footer: DsFooterBar(
        child: DsButton(
          label: 'Review',
          iconAfter: LucideIcons.arrowRight,
          onPressed: () {},
        ),
      ),
      sections: [
        DsCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: DsPartyRow(
            name: 'Al-Noor Electric Store',
            meta: 'Retailer · Ravi Road · +92 300 88·· ··9',
            trailing: const DsStatusPill(
              label: 'Verified',
              icon: LucideIcons.circleCheck,
              tone: DsTone.success,
              small: true,
            ),
          ),
        ),
        Column(
          children: [
            Text(
              'AMOUNT TO SEND',
              style: TextStyle(
                fontSize: 12,
                letterSpacing: 0.06 * 12,
                fontWeight: FontWeight.w600,
                color: context.palette.textTertiary,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  'PKR',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: context.palette.textTertiary,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                const Text(
                  '25,000',
                  style: TextStyle(
                    fontSize: 38,
                    height: 44 / 38,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.02 * 38,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const DsBody('Available after sending · PKR 159,500'),
          ],
        ),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            _AmountChip(label: '10,000'),
            _AmountChip(label: '25,000', selected: true),
            _AmountChip(label: '50,000'),
            _AmountChip(label: 'Custom', dashed: true, icon: LucideIcons.pencil),
          ],
        ),
      ],
    );
  }
}

class _AmountChip extends StatelessWidget {
  const _AmountChip({
    required this.label,
    this.selected = false,
    this.dashed = false,
    this.icon,
  });

  final String label;
  final bool selected;
  final bool dashed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final foreground = selected
        ? context.colors.primary
        : dashed
        ? context.colors.onSurfaceVariant
        : context.colors.onSurface;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: selected ? context.palette.accentSoft : context.colors.surface,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(
          color: selected
              ? context.colors.primary
              : dashed
              ? context.palette.borderStrong
              : context.colors.outline,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: foreground),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: foreground,
            ),
          ),
        ],
      ),
    );
  }
}

/// Board 04 · A3 — Review sheet, with the held rule stated before sending.
class SendCashReviewScreen extends StatelessWidget {
  const SendCashReviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A).withValues(alpha: 0.45),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            DsSheet(
              title: 'Check before sending',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  DsRowGroup(
                    children: const [
                      DsSettingRow(
                        label: 'To',
                        value: 'Al-Noor Electric Store · Retailer',
                      ),
                      DsSettingRow(label: 'Number', value: '+92 300 88·· ··9'),
                      DsSettingRow(label: 'Amount', value: 'PKR 25,000'),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const DsNotice(
                    icon: LucideIcons.hand,
                    tone: DsTone.info,
                    message:
                        'PKR 25,000 leaves your wallet now and is held. '
                        'Al-Noor Electric Store receives it only after they '
                        'approve. If they reject it, or do not act in time, '
                        'the money comes back to you.',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  DsButton(label: 'Send PKR 25,000', onPressed: () {}),
                  const SizedBox(height: 10),
                  DsButton(
                    label: 'Go Back',
                    variant: DsButtonVariant.quiet,
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Board 04 · A4 — Sent: held, awaiting approval. Deliberately not phrased
/// as a completed payment.
class SendCashSentScreen extends StatelessWidget {
  const SendCashSentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DsScreen(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      gap: AppSpacing.stepLg,
      footer: DsFooterBar(
        child: Column(
          children: [
            DsButton(
              label: 'Done',
              onPressed: () => Navigator.of(context).maybePop(),
            ),
            const SizedBox(height: 10),
            DsButton(
              label: 'View in Ledger',
              variant: DsButtonVariant.secondary,
              onPressed: () {},
            ),
          ],
        ),
      ),
      sections: [
        const Center(
          child: DsIconMedallion(
            icon: LucideIcons.hand,
            tone: DsTone.info,
            size: 80,
            iconSize: 38,
          ),
        ),
        Column(
          children: [
            Text(
              'PKR 25,000 is held',
              textAlign: TextAlign.center,
              style: context.texts.headlineSmall,
            ),
            const SizedBox(height: 10),
            const DsBody(
              'Al-Noor Electric Store has been notified. The money reaches '
              'them when they approve, and returns to you if they reject it '
              'or it expires.',
              size: 15,
              align: TextAlign.center,
            ),
          ],
        ),
        DsRowGroup(
          children: const [
            DsSettingRow(label: 'Reference', value: 'CSE-CR-2026-119402'),
            DsSettingRow(label: 'To', value: 'Al-Noor Electric Store'),
            DsSettingRow(label: 'Amount', value: 'PKR 25,000'),
            DsSettingRow(label: 'Sent', value: 'Today, 9:43 AM'),
          ],
        ),
        const DsCaption(
          'This is not a completed payment. Your ledger shows it as held '
          'until the recipient answers.',
          align: TextAlign.center,
        ),
      ],
    );
  }
}
