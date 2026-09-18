import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/ui/ds.dart';
import '../widgets/home_widgets.dart';

/// The four partner roles. Home is the same structure for all of them; only
/// the destinations, tiles and merchandising differ (board 03 · A1–A4).
enum PartnerRole { installer, retailer, wholesaler, distributor }

/// Static demo content for the Home screens — stand-in data only, so the
/// layout and states can be reviewed before any service exists.
class HomeDemo {
  const HomeDemo({
    required this.businessName,
    required this.role,
    required this.roleLabel,
    required this.balance,
    required this.balanceHidden,
    required this.heldNote,
    required this.promoEyebrow,
    required this.promoHeadline,
    required this.scanSubtitle,
    required this.ticker,
    required this.tiles,
    required this.nav,
  });

  final String businessName;
  final PartnerRole role;
  final String roleLabel;
  final String balance;
  final bool balanceHidden;
  final String? heldNote;
  final String? promoEyebrow;
  final String? promoHeadline;
  final String scanSubtitle;
  final String? ticker;
  final List<HomeTile> tiles;
  final List<DsNavItem> nav;

  static const _installerNav = [
    DsNavItem(id: 'home', label: 'Home', icon: LucideIcons.house),
    DsNavItem(id: 'space', label: 'Space', icon: LucideIcons.messagesSquare),
    DsNavItem(id: 'inaam', label: 'Inaam', icon: LucideIcons.gift, badge: 3),
    DsNavItem(id: 'chat', label: 'Chat', icon: LucideIcons.messageCircle),
    DsNavItem(id: 'profile', label: 'Profile', icon: LucideIcons.user),
  ];

  static const _pointsNav = [
    DsNavItem(id: 'home', label: 'Home', icon: LucideIcons.house),
    DsNavItem(id: 'space', label: 'Space', icon: LucideIcons.messagesSquare),
    DsNavItem(id: 'points', label: 'Points', icon: LucideIcons.award, badge: 7),
    DsNavItem(id: 'chat', label: 'Chat', icon: LucideIcons.messageCircle),
    DsNavItem(id: 'profile', label: 'Profile', icon: LucideIcons.user),
  ];

  static const _installerTiles = [
    HomeTile(label: 'Send Cash', icon: LucideIcons.banknoteArrowUp),
    HomeTile(label: 'View Ledger', icon: LucideIcons.receiptText),
    HomeTile(label: 'Shop Branding', icon: LucideIcons.store),
    HomeTile(label: 'Complaints', icon: LucideIcons.lifeBuoy),
  ];

  static const _tradeTiles = [
    HomeTile(label: 'Send Cash', icon: LucideIcons.banknoteArrowUp),
    HomeTile(label: 'Cash Request', icon: LucideIcons.handCoins, badge: 2),
    HomeTile(label: 'View Ledger', icon: LucideIcons.receiptText),
    HomeTile(label: 'Shop Branding', icon: LucideIcons.store),
    HomeTile(label: 'New Profile', icon: LucideIcons.userPlus, badge: 1),
    HomeTile(label: 'Complaints', icon: LucideIcons.lifeBuoy),
  ];

  static const _plainTradeTiles = [
    HomeTile(label: 'Send Cash', icon: LucideIcons.banknoteArrowUp),
    HomeTile(label: 'Cash Request', icon: LucideIcons.handCoins),
    HomeTile(label: 'View Ledger', icon: LucideIcons.receiptText),
    HomeTile(label: 'Shop Branding', icon: LucideIcons.store),
    HomeTile(label: 'New Profile', icon: LucideIcons.userPlus),
    HomeTile(label: 'Complaints', icon: LucideIcons.lifeBuoy),
  ];

  /// A1 · Installer — balance hidden, slider and ticker both present.
  static const installer = HomeDemo(
    businessName: 'Adnan Solar Works',
    role: PartnerRole.installer,
    roleLabel: 'Installer',
    balance: '184,500',
    balanceHidden: true,
    heldNote: null,
    promoEyebrow: 'Crown Solar',
    promoHeadline: 'Scan 10 products today to earn a spin',
    scanSubtitle: 'Check a product or claim a prize',
    ticker:
        'Eid scheme live until 30 September · Frontlit board requests open for '
        'installers who scanned this week · Call 042 111 276 963 for support',
    tiles: _installerTiles,
    nav: _installerNav,
  );

  /// A2 · Retailer — balance revealed, with the held amount named.
  static const retailer = HomeDemo(
    businessName: 'Al-Noor Electric Store',
    role: PartnerRole.retailer,
    roleLabel: 'Retailer',
    balance: '1,284,600',
    balanceHidden: false,
    heldNote: 'PKR 46,000 held · 3 requests',
    promoEyebrow: 'Q3 Scheme',
    promoHeadline: 'Hit 250,000 points by 30 Sep for the quarterly prize',
    scanSubtitle: 'Check a product or claim a prize',
    ticker:
        'Points for August purchases have been posted from SAP · Customer Care '
        'Branding now open at 100,000 points',
    tiles: _tradeTiles,
    nav: _pointsNav,
  );

  /// A3 · Wholesaler — ticker only, no slider targeted this week.
  static const wholesaler = HomeDemo(
    businessName: 'Hamza Solar House',
    role: PartnerRole.wholesaler,
    roleLabel: 'Wholesaler',
    balance: '6,410,250',
    balanceHidden: false,
    heldNote: null,
    promoEyebrow: null,
    promoHeadline: null,
    scanSubtitle: 'Check whether a product is genuine',
    ticker:
        'Customer Care Branding available at 100,000 points · September '
        'dispatch schedule shared with distributors',
    tiles: _plainTradeTiles,
    nav: _pointsNav,
  );

  /// A4 · Distributor — neither slider nor ticker; recent activity instead.
  static const distributor = HomeDemo(
    businessName: 'Karachi Solar Distributors',
    role: PartnerRole.distributor,
    roleLabel: 'Distributor',
    balance: '18,742,000',
    balanceHidden: false,
    heldNote: null,
    promoEyebrow: null,
    promoHeadline: null,
    scanSubtitle: 'Check whether a product is genuine',
    ticker: null,
    tiles: _plainTradeTiles,
    nav: _pointsNav,
  );
}
