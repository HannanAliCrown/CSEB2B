import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/ui/ds.dart';
import '../../../home/ui/models/home_demo_data.dart';
import '../../../home/ui/views/home_screen.dart';
import '../../../home/ui/widgets/home_widgets.dart';

/// Board 12 · A1 — Urdu, mirrored.
///
/// The same Home as board 03, rendered right-to-left with Urdu copy. Numerals
/// stay left-to-right: PKR 1,284,600 never reads backwards.
class UrduHomeScreen extends StatelessWidget {
  const UrduHomeScreen({super.key});

  static const _urdu = HomeDemo(
    businessName: 'النور الیکٹرک اسٹور',
    role: PartnerRole.retailer,
    roleLabel: 'ریٹیلر',
    balance: '1,284,600',
    balanceHidden: false,
    heldNote: 'PKR 46,000 روکے گئے',
    promoEyebrow: null,
    promoHeadline: null,
    scanSubtitle: 'پروڈکٹ چیک کریں یا انعام حاصل کریں',
    ticker: 'اگست کی خریداری کے پوائنٹس ایس اے پی سے پوسٹ ہو گئے ہیں',
    tiles: [
      HomeTile(label: 'کیش بھیجیں', icon: LucideIcons.banknoteArrowUp),
      HomeTile(label: 'کیش درخواست', icon: LucideIcons.handCoins),
      HomeTile(label: 'لیجر', icon: LucideIcons.receiptText),
      HomeTile(label: 'شاپ برانڈنگ', icon: LucideIcons.store),
      HomeTile(label: 'اسکیم', icon: LucideIcons.award),
      HomeTile(label: 'شکایات', icon: LucideIcons.lifeBuoy),
    ],
    nav: [
      DsNavItem(id: 'home', label: 'ہوم', icon: LucideIcons.house),
      DsNavItem(id: 'space', label: 'اسپیس', icon: LucideIcons.messagesSquare),
      DsNavItem(
        id: 'points',
        label: 'پوائنٹس',
        icon: LucideIcons.award,
        badge: 7,
      ),
      DsNavItem(id: 'chat', label: 'چیٹ', icon: LucideIcons.messageCircle),
      DsNavItem(id: 'profile', label: 'پروفائل', icon: LucideIcons.user),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return const Directionality(
      textDirection: TextDirection.rtl,
      child: HomeScreen(demo: _urdu, recentActivity: false),
    );
  }
}

/// Board 12 · A2 — Roman Urdu in dark theme: Latin script, left-to-right, on
/// the dark surface set where shadows are dropped entirely.
class RomanUrduDarkScreen extends StatelessWidget {
  const RomanUrduDarkScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.dark().copyWith(
        colorScheme: Theme.of(context).colorScheme,
      ),
      child: Builder(
        builder: (context) => DsScreen(
          background: const Color(0xFF0B0F14),
          appBar: DsAppBar(
            title: 'Cash Bhejein',
            subtitle: 'Available PKR 184,500',
            onBack: () => Navigator.of(context).maybePop(),
          ),
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          gap: 18,
          footer: DsFooterBar(
            child: DsButton(
              label: 'Review Karein',
              iconAfter: LucideIcons.arrowRight,
              onPressed: () {},
            ),
          ),
          sections: [
            DsCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: const DsPartyRow(
                name: 'Al-Noor Electric Store',
                meta: 'Retailer · Ravi Road',
                trailing: DsStatusPill(
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
                  'RAQAM',
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
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const DsBody('Bhejne ke baad PKR 159,500 bachega'),
              ],
            ),
            const DsNotice(
              icon: LucideIcons.hand,
              tone: DsTone.info,
              message:
                  'PKR 25,000 abhi aap ke wallet se nikal kar rok liye '
                  'jayenge. Recipient approve karega tab hi unhein milega.',
            ),
          ],
        ),
      ),
    );
  }
}

/// Board 12 · A3 — The largest system font on a 5.5-inch screen: type scales,
/// cards grow, and nothing is clipped.
class LargeFontScreen extends StatelessWidget {
  const LargeFontScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MediaQuery.withClampedTextScaling(
      minScaleFactor: 1.6,
      maxScaleFactor: 1.6,
      child: DsScreen(
        appBar: DsAppBar(
          title: 'Send Cash',
          onBack: () => Navigator.of(context).maybePop(),
        ),
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        gap: 18,
        footer: DsFooterBar(
          child: DsButton(label: 'Review', onPressed: () {}),
        ),
        sections: [
          DsCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: const DsPartyRow(
              name: 'Al-Noor Electric Store',
              meta: 'Retailer · Ravi Road',
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const DsCaption('AMOUNT TO SEND'),
              const SizedBox(height: AppSpacing.sm),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  const Text('PKR', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: AppSpacing.sm),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: const Text(
                        '25,000',
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          DsRowGroup(
            children: const [
              DsSettingRow(
                label: 'Available after sending',
                value: 'PKR 159,500',
              ),
            ],
          ),
          const DsBody(
            'This amount is held until Al-Noor Electric Store approves it.',
            size: 14,
          ),
          const DsCaption(
            'At the largest system font the layout reflows and truncates '
            'nothing: type scales, cards grow, the sticky CTA stays reachable, '
            'and secondary detail moves to a second line rather than being '
            'clipped.',
          ),
        ],
      ),
    );
  }
}

/// Board 12 · A4 — The accessibility rules the whole app is built to, shown
/// as rules rather than as a screen.
class AccessibilityRulesScreen extends StatelessWidget {
  const AccessibilityRulesScreen({super.key});

  static const _rules = [
    (
      LucideIcons.touchpad,
      'Touch targets',
      '48px minimum everywhere; PIN keys are 64px, primary buttons 50px.',
    ),
    (
      LucideIcons.tag,
      'Semantics and labels',
      'Icon-only controls carry a label: the eye toggle announces "Show wallet '
          'balance", not "button".',
    ),
    (
      LucideIcons.listOrdered,
      'Focus order',
      'Follows reading order, and mirrors with the locale. Sticky CTAs come '
          'last, not first.',
    ),
    (
      LucideIcons.hash,
      'Tabular numerals',
      'Amounts never shift width as they change, so a live balance does not '
          'jitter.',
    ),
    (
      LucideIcons.gauge,
      'Motion restraint',
      '180–500ms, no bounce, no particles. Long or heavy animation is avoided '
          'for low-end handsets.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return DsScreen(
      appBar: DsAppBar(
        title: 'Accessibility',
        subtitle: 'Design rules, not a screen',
        onBack: () => Navigator.of(context).maybePop(),
      ),
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      gap: AppSpacing.stepMd,
      sections: [
        DsCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Status never depends on colour',
                style: context.texts.bodyLarge?.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.stepMd),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: const [
                  DsStatusPill(
                    label: 'Held',
                    icon: LucideIcons.hand,
                    tone: DsTone.warning,
                    small: true,
                  ),
                  DsStatusPill(
                    label: 'Approved',
                    icon: LucideIcons.circleCheck,
                    tone: DsTone.success,
                    small: true,
                  ),
                  DsStatusPill(
                    label: 'Rejected',
                    icon: LucideIcons.circleX,
                    tone: DsTone.error,
                    small: true,
                  ),
                  DsStatusPill(
                    label: 'Expired',
                    icon: LucideIcons.calendarX,
                    tone: DsTone.neutral,
                    small: true,
                  ),
                  DsStatusPill(
                    label: 'Blocked',
                    icon: LucideIcons.ban,
                    tone: DsTone.neutral,
                    small: true,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.stepMd),
              const DsCaption(
                'Icon + word + colour, always all three. In greyscale every '
                'chip is still readable.',
              ),
            ],
          ),
        ),
        for (final (icon, title, body) in _rules)
          DsCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DsIconMedallion(
                  icon: icon,
                  size: 36,
                  iconSize: 18,
                  rounded: true,
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
                      DsBody(body),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
