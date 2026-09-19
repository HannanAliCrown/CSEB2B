// Constructor parameters are named for their public API rather than the
// private fields they populate, so the initializing-formal shorthand the
// linter suggests is not available here.
// ignore_for_file: prefer_initializing_formals

import '../../session/data/signed_in_user.dart';
import '../../wallet/data/wallet_repository.dart';

/// One merchandising slide on Home.
class PromoSlide {
  const PromoSlide({
    required this.id,
    required this.eyebrow,
    required this.headline,
  });

  final String id;
  final String eyebrow;
  final String headline;
}

/// What Home shows for the signed-in partner.
class Dashboard {
  const Dashboard({
    required this.balance,
    required this.heldNote,
    required this.slides,
    required this.tickerMessages,
    required this.scanSubtitle,
  });

  final Money balance;

  /// Set when part of the balance cannot be spent yet.
  final String? heldNote;

  final List<PromoSlide> slides;

  /// Each announcement the ticker cycles through.
  final List<String> tickerMessages;

  final String scanSubtitle;
}

/// Home's data boundary. The mock below stands in until a dashboard API
/// exists; nothing above this line changes when it does.
abstract interface class DashboardRepository {
  Future<Dashboard> load(SignedInUser user);
}

/// Deterministic dashboard content, chosen by role.
class MockDashboardRepository implements DashboardRepository {
  MockDashboardRepository({required WalletRepository wallet})
    : _wallet = wallet;

  final WalletRepository _wallet;

  static const _latency = Duration(milliseconds: 200);

  @override
  Future<Dashboard> load(SignedInUser user) async {
    await Future<void>.delayed(_latency);

    final balance = await _wallet.balance(user);
    final held = await _wallet.heldTotal(user);

    return Dashboard(
      balance: balance,
      heldNote: held.paisa == 0
          ? null
          : '${held.formatted} held until the receiver accepts it',
      slides: _slidesFor(user.role),
      tickerMessages: _tickerFor(user.role),
      scanSubtitle: user.role.earnsPrizes
          ? 'Check a product or claim a prize'
          : 'Check a product is genuine',
    );
  }

  List<PromoSlide> _slidesFor(PartnerRole role) => switch (role) {
    PartnerRole.installer => const [
      PromoSlide(
        id: 'spin',
        eyebrow: 'CROWN SOLAR',
        headline: 'Scan 10 products today to earn a spin',
      ),
      PromoSlide(
        id: 'eid',
        eyebrow: 'EID SCHEME',
        headline: 'Double prizes on every inverter until 30 September',
      ),
      PromoSlide(
        id: 'training',
        eyebrow: 'TRAINING',
        headline: 'Free installer certification in Lahore this month',
      ),
    ],
    PartnerRole.retailer => const [
      PromoSlide(
        id: 'points',
        eyebrow: 'CROWN SOLAR',
        headline: 'Earn 2x points on every panel this week',
      ),
      PromoSlide(
        id: 'board',
        eyebrow: 'SHOP BRANDING',
        headline: 'Frontlit board requests are open until 30 September',
      ),
    ],
    PartnerRole.wholesaler || PartnerRole.distributor => const [
      PromoSlide(
        id: 'targets',
        eyebrow: 'QUARTERLY TARGET',
        headline: 'Hit 80% by 30 September to unlock the annual bonus',
      ),
    ],
  };

  List<String> _tickerFor(PartnerRole role) => switch (role) {
    PartnerRole.installer => const [
      'Eid scheme live until 30 September',
      'Scan any Crown Solar box to check it is genuine',
      'Cash sent before 4pm is settled the same day',
    ],
    PartnerRole.retailer => const [
      'Eid scheme live until 30 September',
      'Frontlit board requests open',
      'Points expire 90 days after they are earned',
    ],
    PartnerRole.wholesaler || PartnerRole.distributor => const [
      'Quarterly targets close 30 September',
      'New partner profiles need CRM approval',
    ],
  };
}
