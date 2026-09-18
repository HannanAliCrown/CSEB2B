import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/ui/ds.dart';
import '../models/home_demo_data.dart';
import '../widgets/home_widgets.dart';

/// Board 03 · A1–A4 — Home, for each of the four roles.
///
/// One structure everywhere: header, wallet, merchandising, Scan QR, ticker,
/// then "Everything else". Sections a role has nothing for are removed, never
/// left as empty space.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.demo, this.recentActivity});

  final HomeDemo demo;

  /// The distributor's Home fills the space the slider would take with recent
  /// activity (board 03 · A4).
  final bool? recentActivity;

  @override
  Widget build(BuildContext context) {
    final showActivity =
        recentActivity ?? demo.role == PartnerRole.distributor;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            HomeHeader(businessName: demo.businessName, role: demo.roleLabel),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(top: 10, bottom: AppSpacing.stepLg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.screenPadding,
                      ),
                      child: WalletBalanceCard(
                        amount: demo.balance,
                        hidden: demo.balanceHidden,
                        heldNote: demo.heldNote,
                      ),
                    ),
                    if (demo.promoHeadline != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.screenPadding,
                        ),
                        child: HomePromoSlider(
                          eyebrow: demo.promoEyebrow!,
                          headline: demo.promoHeadline!,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.screenPadding,
                      ),
                      child: ScanQrCta(subtitle: demo.scanSubtitle),
                    ),
                    if (demo.ticker != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      HomeTicker(message: demo.ticker!),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.screenPadding,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Everything else',
                            style: context.texts.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.stepMd),
                          HomeTileGrid(tiles: demo.tiles),
                          if (showActivity) ...[
                            const SizedBox(height: AppSpacing.lg),
                            const _RecentActivity(),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: DsBottomNav(items: demo.nav, activeId: 'home'),
    );
  }
}

class _RecentActivity extends StatelessWidget {
  const _RecentActivity();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const DsSectionHeader(title: 'Recent activity'),
        DsRowGroup(
          children: [
            DsSettingRow(
              label: 'Points posted · SAP INV-77213',
              meta: 'Today, 6:02 AM',
              trailing: Text(
                '+ 18,400',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: context.status.success,
                ),
              ),
            ),
            DsSettingRow(
              label: 'Hamza Solar House',
              meta: 'Yesterday · Currency',
              trailing: Text(
                '− 450,000',
                style: context.texts.bodyLarge?.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const DsSettingRow(
              label: 'Branding · Board Installed',
              meta: '07 Sep',
              trailing: DsTag(label: 'Stage 3', tone: DsTone.accent),
            ),
          ],
        ),
      ],
    );
  }
}

/// Board 03 · B1 — Cash transactions blocked.
///
/// The restriction is explained once, at the top; cash tiles dim, and points,
/// scanning and everything else behave normally.
class HomeCashBlockedScreen extends StatelessWidget {
  const HomeCashBlockedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const demo = HomeDemo.retailer;
    final tiles = [
      const HomeTile(
        label: 'Send Cash',
        icon: LucideIcons.banknoteArrowUp,
        dimmed: true,
      ),
      const HomeTile(
        label: 'Cash Request',
        icon: LucideIcons.handCoins,
        dimmed: true,
      ),
      const HomeTile(label: 'View Ledger', icon: LucideIcons.receiptText),
      const HomeTile(label: 'Shop Branding', icon: LucideIcons.store),
      const HomeTile(label: 'Complaints', icon: LucideIcons.lifeBuoy),
    ];

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const HomeHeader(
              businessName: 'Al-Noor Electric Store',
              role: 'Retailer',
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenPadding,
                  10,
                  AppSpacing.screenPadding,
                  AppSpacing.stepLg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DsCard(
                      border: context.status.warning.withValues(alpha: 0.35),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const DsIconMedallion(
                                icon: LucideIcons.ban,
                                tone: DsTone.warning,
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
                            'You cannot send cash or approve cash requests at '
                            'the moment. Your balance, ledger and points are '
                            'not affected. PKR 12,000 that was held for a '
                            'pending request has been returned to the sender.',
                          ),
                          const SizedBox(height: AppSpacing.stepMd),
                          DsButton(
                            label: 'Contact Support',
                            variant: DsButtonVariant.secondary,
                            size: DsButtonSize.sm,
                            icon: LucideIcons.lifeBuoy,
                            onPressed: () {},
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const WalletBalanceCard(
                      label: 'Wallet balance · view only',
                      amount: '1,272,600',
                      showActions: false,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    HomeTileGrid(tiles: tiles),
                    const SizedBox(height: AppSpacing.stepMd),
                    const DsCaption(
                      'Cash tiles are dimmed and explain the restriction when '
                      'tapped. Points, scanning and everything else behave '
                      'normally.',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: DsBottomNav(
        items: demo.nav,
        activeId: 'home',
      ),
    );
  }
}

/// Board 03 · B2 — Points blocked · earning suspended.
///
/// Four distinct restrictions, never one message: each names exactly what
/// stopped and what still works.
class HomePointsBlockedScreen extends StatelessWidget {
  const HomePointsBlockedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DsScreen(
      appBar: DsAppBar(
        title: 'Home',
        onBack: () => Navigator.of(context).maybePop(),
      ),
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      gap: AppSpacing.md,
      sections: [
        DsCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const DsIconMedallion(
                    icon: LucideIcons.arrowRightLeft,
                    tone: DsTone.warning,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Points transfers are restricted',
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
                'You cannot send points, and points sent to you by another '
                'user will not arrive. Points from your purchases still post '
                'from SAP as normal.',
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
                    icon: LucideIcons.gift,
                    tone: DsTone.warning,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Prize claiming is paused',
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
                'Scan to Earn is unavailable while your earning is under '
                'review. Authenticity Check still works normally.',
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: DsButton(
                      label: 'Call CRM',
                      icon: LucideIcons.phone,
                      size: DsButtonSize.sm,
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
      ],
      bottomNav: DsBottomNav(
        items: HomeDemo.retailer.nav,
        activeId: 'home',
      ),
    );
  }
}

/// Board 03 · B3 — First load · skeleton, with the offline banner.
class HomeSkeletonScreen extends StatelessWidget {
  const HomeSkeletonScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              color: context.status.warningFill,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPadding,
                vertical: AppSpacing.stepMd,
              ),
              child: Row(
                children: [
                  Icon(
                    LucideIcons.wifiOff,
                    size: 16,
                    color: context.status.warning,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: DsBody(
                      'No connection. Showing your last known balance from '
                      '8:12 AM.',
                      color: context.status.warning,
                    ),
                  ),
                  Text(
                    'Retry',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: context.status.warning,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.screenPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const DsSkeleton(width: 28, height: 28, radius: 8),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            DsSkeleton(width: 140, height: 14),
                            SizedBox(height: 6),
                            DsSkeleton(width: 70, height: 10),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.stepLg),
                    const DsSkeleton(height: 132, radius: AppRadii.hero),
                    const SizedBox(height: AppSpacing.md),
                    const DsSkeleton(height: 132, radius: AppRadii.lg),
                    const SizedBox(height: AppSpacing.md),
                    const DsSkeleton(height: 76, radius: AppRadii.lg),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: const [
                        Expanded(child: DsSkeleton(height: 94, radius: AppRadii.md)),
                        SizedBox(width: AppSpacing.stepMd),
                        Expanded(child: DsSkeleton(height: 94, radius: AppRadii.md)),
                        SizedBox(width: AppSpacing.stepMd),
                        Expanded(child: DsSkeleton(height: 94, radius: AppRadii.md)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: DsBottomNav(
        items: HomeDemo.installer.nav,
        activeId: 'home',
      ),
    );
  }
}
