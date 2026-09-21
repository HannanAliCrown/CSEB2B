import 'package:prototype_server/data/inaam_data_store.dart';

/// An in-memory [InaamDataStore] for the route tests.
///
/// The wheel here is not weighted: the tests are about what the routes say,
/// and a random prize would make them say something different each run. The
/// prize actually paid is chosen by weight in Postgres, which is where that
/// belongs.
class FakeInaamDataStore implements InaamDataStore {
  final _roles = <String, String>{};
  final _scansToday = <String, int>{};
  final _spins = <String, List<SpinRow>>{};
  final _schemes = <ItemSchemeRow>[];
  final _claims = <String, ({String scheme, String tier})>{};
  final _programs = <String, RewardProgramRow>{};

  int _scansPerSpin = 10;
  List<SpinSegmentRow> _segments = const [
    SpinSegmentRow(amountPaisa: 5000, position: 1),
    SpinSegmentRow(amountPaisa: 50000, position: 2),
    SpinSegmentRow(amountPaisa: 5000000, position: 3),
  ];
  var _nextReference = 1;

  void addAccount({required String mobileNumber, String role = 'installer'}) {
    _roles[mobileNumber] = role;
  }

  void scanned(String mobileNumber, int count) {
    _scansToday[mobileNumber] = count;
  }

  /// Crown Solar has not set the wheel up.
  void unconfigure() {
    _scansPerSpin = 0;
    _segments = const [];
  }

  void addScheme(ItemSchemeRow scheme) => _schemes.add(scheme);

  void setProgram(String mobileNumber, RewardProgramRow program) {
    _programs[mobileNumber] = program;
  }

  @override
  Future<SpinStateRow?> spinState(String mobileNumber) async {
    if (!_roles.containsKey(mobileNumber)) return null;
    if (_scansPerSpin == 0) {
      return const SpinStateRow(
        scansToday: 0,
        scansPerSpin: 0,
        spinsAvailable: 0,
        segments: [],
        history: [],
      );
    }

    final scans = _scansToday[mobileNumber] ?? 0;
    final taken = _spins[mobileNumber]?.length ?? 0;
    final available = scans ~/ _scansPerSpin - taken;

    return SpinStateRow(
      scansToday: scans,
      scansPerSpin: _scansPerSpin,
      spinsAvailable: available < 0 ? 0 : available,
      segments: _segments,
      history: [...?_spins[mobileNumber]].reversed.toList(),
    );
  }

  @override
  Future<(SpinRow?, SpinRefusal?)> spin(String mobileNumber) async {
    if (!_roles.containsKey(mobileNumber)) {
      return (null, SpinRefusal.unknownAccount);
    }
    if (_scansPerSpin == 0) return (null, SpinRefusal.notConfigured);

    final state = (await spinState(mobileNumber))!;
    if (state.spinsAvailable <= 0) return (null, SpinRefusal.noSpinsAvailable);

    final spin = SpinRow(
      reference: 'CS-SPN-${_nextReference++}',
      amountPaisa: _segments.first.amountPaisa,
      spunAt: DateTime.now(),
    );
    (_spins[mobileNumber] ??= []).add(spin);
    return (spin, null);
  }

  @override
  Future<List<ItemSchemeRow>?> itemSchemes(String mobileNumber) async {
    if (!_roles.containsKey(mobileNumber)) return null;
    return [for (final scheme in _schemes) _withClaim(scheme, mobileNumber)];
  }

  ItemSchemeRow _withClaim(ItemSchemeRow scheme, String mobileNumber) {
    final claim = _claims['$mobileNumber/${scheme.id}'];
    if (claim == null) return scheme;

    final tier = scheme.tiers.firstWhere((tier) => tier.id == claim.tier);
    return ItemSchemeRow(
      id: scheme.id,
      name: scheme.name,
      measure: scheme.measure,
      progress: scheme.progress,
      startsOn: scheme.startsOn,
      endsOn: scheme.endsOn,
      tiers: scheme.tiers,
      claimedTierName: tier.name,
      claimedAmountPaisa: tier.rewardPaisa,
      claimedReference: 'CS-SCH-${_nextReference++}',
    );
  }

  @override
  Future<(ItemSchemeRow?, ClaimRefusal?)> claimTier({
    required String mobileNumber,
    required String schemeId,
    required String tierId,
  }) async {
    if (!_roles.containsKey(mobileNumber)) {
      return (null, ClaimRefusal.unknownAccount);
    }

    final scheme = _schemes
        .where((scheme) => scheme.id == schemeId)
        .firstOrNull;
    final tier = scheme?.tiers.where((tier) => tier.id == tierId).firstOrNull;
    if (scheme == null || tier == null) {
      return (null, ClaimRefusal.unknownTier);
    }
    if (_claims.containsKey('$mobileNumber/$schemeId')) {
      return (null, ClaimRefusal.alreadyClaimed);
    }
    if (!tier.reached) return (null, ClaimRefusal.notReached);

    _claims['$mobileNumber/$schemeId'] = (scheme: schemeId, tier: tierId);
    return (_withClaim(scheme, mobileNumber), null);
  }

  @override
  Future<RewardProgramRow?> rewardProgram(String mobileNumber) async {
    if (!_roles.containsKey(mobileNumber)) return null;
    return _programs[mobileNumber] ??
        const RewardProgramRow(tiers: [], scans: 0);
  }
}
