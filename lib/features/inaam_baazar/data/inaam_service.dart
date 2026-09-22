// Constructor parameters are named for their public API rather than the
// private fields they populate, so the initializing-formal shorthand the
// linter suggests is not available here.
// ignore_for_file: prefer_initializing_formals

import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

import '../../../core/mock/partner_directory.dart';
import '../../scan/data/scan_repository.dart';

import '../../wallet/data/wallet_repository.dart';

/// One spin that has happened.
class Spin {
  const Spin({
    required this.reference,
    required this.amount,
    required this.spunAt,
  });

  final String reference;
  final Money amount;
  final DateTime spunAt;

  static Spin fromJson(Map<String, dynamic> json) => Spin(
    reference: json['reference'] as String,
    amount: Money((json['amountPaisa'] as num).toInt()),
    spunAt: DateTime.parse(json['spunAt'] as String).toLocal(),
  );
}

/// What the Spin and Win tab shows.
class SpinState {
  const SpinState({
    required this.scansToday,
    required this.scansPerSpin,
    required this.spinsAvailable,
    required this.scansToNextSpin,
    required this.segments,
    required this.history,
  });

  final int scansToday;
  final int scansPerSpin;

  /// Earned by today's scans, less the spins already taken. Never stored —
  /// it cannot drift from the scans that earned it.
  final int spinsAvailable;

  final int scansToNextSpin;

  /// The wheel's segments, in order. The odds are not here: a partner cannot
  /// influence them, so showing them would only suggest they can.
  final List<Money> segments;

  final List<Spin> history;

  bool get configured => scansPerSpin > 0;

  /// How far through the current ten scans they are.
  double get progress =>
      scansPerSpin == 0 ? 0 : (scansToday % scansPerSpin) / scansPerSpin;

  static const empty = SpinState(
    scansToday: 0,
    scansPerSpin: 0,
    spinsAvailable: 0,
    scansToNextSpin: 0,
    segments: [],
    history: [],
  );

  static SpinState fromJson(Map<String, dynamic> json) => SpinState(
    scansToday: (json['scansToday'] as num?)?.toInt() ?? 0,
    scansPerSpin: (json['scansPerSpin'] as num?)?.toInt() ?? 0,
    spinsAvailable: (json['spinsAvailable'] as num?)?.toInt() ?? 0,
    scansToNextSpin: (json['scansToNextSpin'] as num?)?.toInt() ?? 0,
    segments: [
      for (final entry in json['segments'] as List? ?? const [])
        Money(((entry as Map<String, dynamic>)['amountPaisa'] as num).toInt()),
    ],
    history: [
      for (final entry in json['history'] as List? ?? const [])
        Spin.fromJson(entry as Map<String, dynamic>),
    ],
  );
}

/// Why a spin could not be taken.
enum SpinFailure { noSpins, notConfigured, unreachable }

extension SpinFailureX on SpinFailure {
  String get message => switch (this) {
    SpinFailure.noSpins =>
      'That spin has already been used. Scan more to earn another.',
    SpinFailure.notConfigured => 'Crown Solar has not set the wheel up yet.',
    // A dropped connection never costs a spin: the entitlement is counted
    // from scans, so nothing was consumed.
    SpinFailure.unreachable =>
      'The connection dropped mid-spin. Your spin has not been used — try '
          'again when you have signal.',
  };
}

/// One tier of an item scheme.
class SchemeTier {
  const SchemeTier({
    required this.id,
    required this.name,
    required this.threshold,
    required this.reward,
    required this.reached,
  });

  final String id;
  final String name;

  /// Scans, or paisa, depending on the scheme's measure.
  final int threshold;

  final Money reward;
  final bool reached;

  static SchemeTier fromJson(Map<String, dynamic> json) => SchemeTier(
    id: json['id'] as String,
    name: json['name'] as String,
    threshold: (json['threshold'] as num).toInt(),
    reward: Money((json['rewardPaisa'] as num).toInt()),
    reached: json['reached'] == true,
  );
}

/// One item scheme as it stands for one partner.
class ItemScheme {
  const ItemScheme({
    required this.id,
    required this.name,
    required this.measure,
    required this.progress,
    required this.startsOn,
    required this.endsOn,
    required this.tiers,
    this.claimedTierName,
    this.claimedAmount,
    this.claimedReference,
  });

  final String id;
  final String name;

  /// 'scans' | 'amount'. Never both.
  final String measure;

  /// Scans counted, or paisa purchased.
  final int progress;

  final DateTime startsOn;
  final DateTime endsOn;
  final List<SchemeTier> tiers;

  final String? claimedTierName;
  final Money? claimedAmount;
  final String? claimedReference;

  bool get claimed => claimedTierName != null;
  bool get byScans => measure == 'scans';

  /// The highest tier reached and still claimable.
  SchemeTier? get claimable {
    if (claimed) return null;
    SchemeTier? best;
    for (final tier in tiers) {
      if (tier.reached) best = tier;
    }
    return best;
  }

  /// The next tier not yet reached, which is what the bar runs toward.
  SchemeTier? get next {
    for (final tier in tiers) {
      if (!tier.reached) return tier;
    }
    return null;
  }

  double get percent {
    final target = next?.threshold ?? tiers.lastOrNull?.threshold ?? 0;
    if (target == 0) return 1;
    return (progress / target).clamp(0.0, 1.0).toDouble();
  }

  static ItemScheme fromJson(Map<String, dynamic> json) => ItemScheme(
    id: json['id'] as String,
    name: json['name'] as String,
    measure: json['measure'] as String,
    progress: (json['progress'] as num).toInt(),
    startsOn: DateTime.parse(json['startsOn'] as String).toLocal(),
    endsOn: DateTime.parse(json['endsOn'] as String).toLocal(),
    tiers: [
      for (final entry in json['tiers'] as List? ?? const [])
        SchemeTier.fromJson(entry as Map<String, dynamic>),
    ],
    claimedTierName: json['claimedTierName'] as String?,
    claimedAmount: json['claimedAmountPaisa'] == null
        ? null
        : Money((json['claimedAmountPaisa'] as num).toInt()),
    claimedReference: json['claimedReference'] as String?,
  );
}

/// Why a tier could not be claimed.
enum ClaimFailure { notReached, alreadyClaimed, unknownTier, unreachable }

extension ClaimFailureX on ClaimFailure {
  String get message => switch (this) {
    ClaimFailure.notReached =>
      'You have not reached that target yet. Keep scanning.',
    ClaimFailure.alreadyClaimed =>
      'You have already claimed from this scheme. Only one tier, ever.',
    ClaimFailure.unknownTier => 'That scheme has closed.',
    ClaimFailure.unreachable =>
      'Could not record that. Nothing has been claimed — try again.',
  };
}

/// One tier of the monthly programme.
class ProgramTier {
  const ProgramTier({
    required this.name,
    required this.scanTarget,
    required this.bonusPercent,
  });

  final String name;
  final int scanTarget;
  final int bonusPercent;

  static ProgramTier fromJson(Map<String, dynamic> json) => ProgramTier(
    name: json['name'] as String,
    scanTarget: (json['scanTarget'] as num).toInt(),
    bonusPercent: (json['bonusPercent'] as num).toInt(),
  );
}

/// The Reward Program tab.
class RewardProgram {
  const RewardProgram({
    required this.tiers,
    required this.scans,
    this.label,
    this.startsOn,
    this.endsOn,
    this.awardTierName,
    this.awardBonusPercent,
    this.awardAppliesUntil,
    this.awardEarnedOn,
  });

  final String? label;
  final DateTime? startsOn;
  final DateTime? endsOn;
  final List<ProgramTier> tiers;
  final int scans;

  /// What last month earned, and how long it runs. Null when nothing was
  /// awarded — which is not the same as a bonus of zero.
  final String? awardTierName;
  final int? awardBonusPercent;
  final DateTime? awardAppliesUntil;

  /// The month that earned it. A tier reached in June pays through July, so
  /// this is not the month the bonus runs in.
  final DateTime? awardEarnedOn;

  bool get running => label != null;
  bool get hasAward => awardTierName != null;

  /// The highest tier reached this month.
  ProgramTier? get reached {
    ProgramTier? best;
    for (final tier in tiers) {
      if (scans >= tier.scanTarget) best = tier;
    }
    return best;
  }

  ProgramTier? get next {
    for (final tier in tiers) {
      if (scans < tier.scanTarget) return tier;
    }
    return null;
  }

  double get percent {
    final target = tiers.isEmpty ? 0 : tiers.last.scanTarget;
    if (target == 0) return 0;
    return (scans / target).clamp(0.0, 1.0).toDouble();
  }

  /// Days left in the month the bonus runs for.
  int get daysRemaining {
    final until = awardAppliesUntil ?? endsOn;
    if (until == null) return 0;
    final left = until.difference(DateTime.now()).inDays;
    return left < 0 ? 0 : left + 1;
  }

  static const empty = RewardProgram(tiers: [], scans: 0);

  static RewardProgram fromJson(Map<String, dynamic> json) => RewardProgram(
    label: json['label'] as String?,
    startsOn: json['startsOn'] == null
        ? null
        : DateTime.parse(json['startsOn'] as String).toLocal(),
    endsOn: json['endsOn'] == null
        ? null
        : DateTime.parse(json['endsOn'] as String).toLocal(),
    scans: (json['scans'] as num?)?.toInt() ?? 0,
    tiers: [
      for (final entry in json['tiers'] as List? ?? const [])
        ProgramTier.fromJson(entry as Map<String, dynamic>),
    ],
    awardTierName: json['awardTierName'] as String?,
    awardBonusPercent: (json['awardBonusPercent'] as num?)?.toInt(),
    awardAppliesUntil: json['awardAppliesUntil'] == null
        ? null
        : DateTime.parse(json['awardAppliesUntil'] as String).toLocal(),
    awardEarnedOn: json['awardEarnedOn'] == null
        ? null
        : DateTime.parse(json['awardEarnedOn'] as String).toLocal(),
  );
}

/// Inaam Baazar's data boundary.
///
/// [HttpInaamService] reads the database behind `prototype_server`.
/// [MockInaamService] applies the same configuration in memory, counting the
/// same scan claims.
abstract interface class InaamService {
  Future<SpinState?> spinState(String mobileNumber);

  /// Takes one spin. The prize is chosen and paid in one step, so this
  /// returns what was actually credited.
  Future<(Spin?, SpinFailure?)> spin(String mobileNumber);

  Future<List<ItemScheme>?> itemSchemes(String mobileNumber);

  /// Takes the one claim a scheme allows.
  Future<(ItemScheme?, ClaimFailure?)> claim({
    required String mobileNumber,
    required String schemeId,
    required String tierId,
  });

  Future<RewardProgram?> rewardProgram(String mobileNumber);
}

/// Inaam Baazar's data boundary, backed by the database behind
/// `prototype_server`.
class HttpInaamService implements InaamService {
  HttpInaamService({required String baseUrl, http.Client? client})
    : _baseUrl = baseUrl,
      _client = client ?? http.Client();

  final String _baseUrl;
  final http.Client _client;

  @override
  Future<SpinState?> spinState(String mobileNumber) async {
    final body = await _get('/inaam/spin', {'mobileNumber': mobileNumber});
    return body == null ? null : SpinState.fromJson(body);
  }

  @override
  Future<(Spin?, SpinFailure?)> spin(String mobileNumber) async {
    final http.Response response;
    try {
      response = await _client.post(
        Uri.parse('$_baseUrl/inaam/spin'),
        headers: const {'content-type': 'application/json'},
        body: jsonEncode({'mobileNumber': mobileNumber}),
      );
    } on Object {
      return (null, SpinFailure.unreachable);
    }

    if (response.statusCode == 201) {
      return (
        Spin.fromJson(jsonDecode(response.body) as Map<String, dynamic>),
        null,
      );
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return (
      null,
      switch (body['error']) {
        'no_spins_available' => SpinFailure.noSpins,
        'not_configured' => SpinFailure.notConfigured,
        _ => SpinFailure.unreachable,
      },
    );
  }

  @override
  Future<List<ItemScheme>?> itemSchemes(String mobileNumber) async {
    final body = await _get('/inaam/item-schemes', {
      'mobileNumber': mobileNumber,
    });
    if (body == null) return null;
    return [
      for (final entry in body['schemes'] as List? ?? const [])
        ItemScheme.fromJson(entry as Map<String, dynamic>),
    ];
  }

  @override
  Future<(ItemScheme?, ClaimFailure?)> claim({
    required String mobileNumber,
    required String schemeId,
    required String tierId,
  }) async {
    final http.Response response;
    try {
      response = await _client.post(
        Uri.parse('$_baseUrl/inaam/item-schemes/claim'),
        headers: const {'content-type': 'application/json'},
        body: jsonEncode({
          'mobileNumber': mobileNumber,
          'schemeId': schemeId,
          'tierId': tierId,
        }),
      );
    } on Object {
      return (null, ClaimFailure.unreachable);
    }

    if (response.statusCode == 201) {
      return (
        ItemScheme.fromJson(jsonDecode(response.body) as Map<String, dynamic>),
        null,
      );
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return (
      null,
      switch (body['error']) {
        'not_reached' => ClaimFailure.notReached,
        'already_claimed' => ClaimFailure.alreadyClaimed,
        'unknown_tier' => ClaimFailure.unknownTier,
        _ => ClaimFailure.unreachable,
      },
    );
  }

  @override
  Future<RewardProgram?> rewardProgram(String mobileNumber) async {
    final body = await _get('/inaam/reward-program', {
      'mobileNumber': mobileNumber,
    });
    return body == null ? null : RewardProgram.fromJson(body);
  }

  Future<Map<String, dynamic>?> _get(
    String path,
    Map<String, String> query,
  ) async {
    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl$path').replace(queryParameters: query),
      );
      if (response.statusCode != 200) return null;
      return jsonDecode(response.body) as Map<String, dynamic>;
    } on Object {
      return null;
    }
  }
}

/// One segment of the wheel, with the weight that decides how often it lands.
class _SeededSegment {
  const _SeededSegment({required this.amountPaisa, required this.weight});

  final int amountPaisa;
  final int weight;
}

/// One tier of an item scheme.
class _SeededTier {
  const _SeededTier({
    required this.name,
    required this.threshold,
    required this.rewardPaisa,
  });

  final String name;

  /// Scans, or paisa, depending on the scheme's measure.
  final int threshold;

  final int rewardPaisa;
}

/// One item scheme, and the product codes that count toward it.
class _SeededScheme {
  const _SeededScheme({
    required this.id,
    required this.name,
    required this.measure,
    required this.codePrefix,
    required this.startsOn,
    required this.endsOn,
    required this.tiers,
  });

  final String id;
  final String name;

  /// 'scans' | 'amount'. Never both.
  final String measure;

  /// `item_scheme_products` joins products by their code prefix.
  final String codePrefix;

  final DateTime startsOn;
  final DateTime endsOn;
  final List<_SeededTier> tiers;
}

/// A claim already taken on a scheme.
class _TakenClaim {
  const _TakenClaim({
    required this.tierName,
    required this.amountPaisa,
    required this.reference,
  });

  final String tierName;
  final int amountPaisa;
  final String reference;
}

/// Inaam Baazar's data boundary, held in memory.
///
/// The wheel, its odds, the two item schemes and the monthly programme
/// `db/seed/009_inaam_baazar.sql` writes.
///
/// Scans are counted from [MockScanRepository]'s claims rather than held
/// here, so ten scans in a day earn a spin exactly as they do through the
/// database, and a prize is credited to [MockWalletRepository] in the same
/// step the spin is taken.
class MockInaamService implements InaamService {
  MockInaamService({
    required MockScanRepository scans,
    required MockWalletRepository wallet,
  }) : _scans = scans,
       _wallet = wallet;

  final MockScanRepository _scans;
  final MockWalletRepository _wallet;

  /// Spins taken, newest last, by partner.
  final Map<String, List<Spin>> _spins = {};

  /// The one claim each scheme allows, by partner then scheme.
  final Map<String, Map<String, _TakenClaim>> _claims = {};

  final _random = Random();

  int _nextReference = 1;

  static const _scansPerSpin = 10;

  /// Eight segments, as the design draws them. The weights are what make the
  /// smallest prize the usual outcome, and they never leave this class.
  static const _segments = <_SeededSegment>[
    _SeededSegment(amountPaisa: 5000, weight: 156),
    _SeededSegment(amountPaisa: 5000, weight: 156),
    _SeededSegment(amountPaisa: 5000, weight: 156),
    _SeededSegment(amountPaisa: 50000, weight: 60),
    _SeededSegment(amountPaisa: 5000, weight: 156),
    _SeededSegment(amountPaisa: 5000, weight: 156),
    _SeededSegment(amountPaisa: 5000, weight: 156),
    _SeededSegment(amountPaisa: 5000000, weight: 4),
  ];

  static final _schemes = <_SeededScheme>[
    _SeededScheme(
      id: 'inverter-scan-scheme',
      name: 'Inverter Scan Scheme',
      measure: 'scans',
      codePrefix: 'CS-INV-',
      startsOn: DateTime(2026, 7),
      endsOn: DateTime(2026, 12, 31),
      tiers: const [
        _SeededTier(name: 'Silver', threshold: 150, rewardPaisa: 1400000),
        _SeededTier(name: 'Gold', threshold: 300, rewardPaisa: 2500000),
        _SeededTier(name: 'Platinum', threshold: 500, rewardPaisa: 4000000),
      ],
    ),
    _SeededScheme(
      id: 'panel-purchase-scheme',
      name: 'Panel Purchase Scheme',
      measure: 'amount',
      codePrefix: 'CS-PNL-',
      startsOn: DateTime(2026, 7),
      endsOn: DateTime(2026, 12, 31),
      tiers: const [
        _SeededTier(name: 'Silver', threshold: 120000000, rewardPaisa: 1400000),
        _SeededTier(name: 'Gold', threshold: 250000000, rewardPaisa: 2500000),
        _SeededTier(
          name: 'Platinum',
          threshold: 400000000,
          rewardPaisa: 4000000,
        ),
      ],
    ),
  ];

  /// What SAP has posted against the amount-measured scheme. Scans the app
  /// counts itself; rupees it does not.
  static const _amountProgress = <String, Map<String, int>>{
    '3004821190': {'panel-purchase-scheme': 131040000},
  };

  /// The monthly programme's tiers, the same on every month.
  static const _programTiers = <ProgramTier>[
    ProgramTier(name: 'SILVER', scanTarget: 10, bonusPercent: 25),
    ProgramTier(name: 'GOLD', scanTarget: 25, bonusPercent: 50),
    ProgramTier(name: 'PLATINUM', scanTarget: 40, bonusPercent: 100),
  ];

  /// The programme the reward tab is about, and the one before it that the
  /// month-end job has already decided.
  static final _currentProgram = (
    label: 'September 2026',
    startsOn: DateTime(2026, 9),
    endsOn: DateTime(2026, 9, 30),
  );

  /// What the month-end job decided for August: Silver, so a +25% bonus runs
  /// through September.
  static const _awardNumber = '3004821190';

  /// Codes counting toward the monthly programme.
  static const _programCodePrefix = 'CS-INV-';

  /// This partner's claims, from the scan repository that holds them.
  Iterable<({String code, DateTime claimedAt})> _claimsOf(String mobileNumber) {
    final account = PartnerDirectory.find(mobileNumber);
    if (account == null) return const [];
    return _scans.claimsBy(account.displayName);
  }

  /// Claims taken today. An authenticity check takes no claim and so earns
  /// no spin — checking stock on a shelf is not scanning a product.
  int _scansToday(String mobileNumber) {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    var scans = 0;
    for (final claim in _claimsOf(mobileNumber)) {
      if (!claim.claimedAt.isBefore(startOfDay)) scans++;
    }
    return scans;
  }

  int _spinsToday(String mobileNumber) {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final taken = _spins[PartnerDirectory.normalise(mobileNumber)];
    if (taken == null) return 0;
    var spins = 0;
    for (final spin in taken) {
      if (!spin.spunAt.isBefore(startOfDay)) spins++;
    }
    return spins;
  }

  /// Claims on codes with this prefix, inside a window that runs to the end
  /// of its last day.
  int _claimsInWindow(
    String mobileNumber,
    String prefix,
    DateTime startsOn,
    DateTime endsOn,
  ) {
    final end = DateTime(
      endsOn.year,
      endsOn.month,
      endsOn.day,
    ).add(const Duration(days: 1));
    var scans = 0;
    for (final claim in _claimsOf(mobileNumber)) {
      if (!claim.code.startsWith(prefix)) continue;
      if (claim.claimedAt.isBefore(startsOn)) continue;
      if (!claim.claimedAt.isBefore(end)) continue;
      scans++;
    }
    return scans;
  }

  @override
  Future<SpinState?> spinState(String mobileNumber) async {
    if (PartnerDirectory.find(mobileNumber) == null) return null;

    final scansToday = _scansToday(mobileNumber);
    final history =
        _spins[PartnerDirectory.normalise(mobileNumber)] ?? const <Spin>[];

    return SpinState(
      scansToday: scansToday,
      scansPerSpin: _scansPerSpin,
      // Earned, less taken. Never negative: moving the threshold up must not
      // put a partner into a debt of spins.
      spinsAvailable: max(
        0,
        scansToday ~/ _scansPerSpin - _spinsToday(mobileNumber),
      ),
      scansToNextSpin: _scansPerSpin - (scansToday % _scansPerSpin),
      segments: [for (final segment in _segments) Money(segment.amountPaisa)],
      history: history.reversed.take(20).toList(),
    );
  }

  @override
  Future<(Spin?, SpinFailure?)> spin(String mobileNumber) async {
    if (PartnerDirectory.find(mobileNumber) == null) {
      return (null, SpinFailure.unreachable);
    }

    final earned = _scansToday(mobileNumber) ~/ _scansPerSpin;
    if (earned - _spinsToday(mobileNumber) <= 0) {
      return (null, SpinFailure.noSpins);
    }

    // Weighted pick. The weights never leave this method.
    var total = 0;
    for (final segment in _segments) {
      total += segment.weight;
    }
    var roll = _random.nextInt(total);
    var won = _segments.first;
    for (final segment in _segments) {
      roll -= segment.weight;
      if (roll < 0) {
        won = segment;
        break;
      }
    }

    final reference = 'SPN-${_nextReference++}';
    final spin = Spin(
      reference: reference,
      amount: Money(won.amountPaisa),
      spunAt: DateTime.now(),
    );

    // The prize and the wallet entry are written together, so what the wheel
    // showed is what the balance moved by.
    await _wallet.creditSpinPrize(
      mobileNumber: mobileNumber,
      amount: spin.amount,
      reference: reference,
    );
    (_spins[PartnerDirectory.normalise(mobileNumber)] ??= []).add(spin);
    return (spin, null);
  }

  int _progressOf(String mobileNumber, _SeededScheme scheme) {
    if (scheme.measure == 'amount') {
      final number = PartnerDirectory.normalise(mobileNumber);
      return _amountProgress[number]?[scheme.id] ?? 0;
    }
    return _claimsInWindow(
      mobileNumber,
      scheme.codePrefix,
      scheme.startsOn,
      scheme.endsOn,
    );
  }

  ItemScheme _schemeFrom(String mobileNumber, _SeededScheme scheme) {
    final progress = _progressOf(mobileNumber, scheme);
    final taken = _claims[PartnerDirectory.normalise(mobileNumber)]?[scheme.id];

    return ItemScheme(
      id: scheme.id,
      name: scheme.name,
      measure: scheme.measure,
      progress: progress,
      startsOn: scheme.startsOn,
      endsOn: scheme.endsOn,
      tiers: [
        for (final tier in scheme.tiers)
          SchemeTier(
            id: '${scheme.id}:${tier.name.toLowerCase()}',
            name: tier.name,
            threshold: tier.threshold,
            reward: Money(tier.rewardPaisa),
            reached: progress >= tier.threshold,
          ),
      ],
      claimedTierName: taken?.tierName,
      claimedAmount: taken == null ? null : Money(taken.amountPaisa),
      claimedReference: taken?.reference,
    );
  }

  @override
  Future<List<ItemScheme>?> itemSchemes(String mobileNumber) async {
    if (PartnerDirectory.find(mobileNumber) == null) return null;
    return [for (final scheme in _schemes) _schemeFrom(mobileNumber, scheme)];
  }

  @override
  Future<(ItemScheme?, ClaimFailure?)> claim({
    required String mobileNumber,
    required String schemeId,
    required String tierId,
  }) async {
    if (PartnerDirectory.find(mobileNumber) == null) {
      return (null, ClaimFailure.unreachable);
    }

    _SeededScheme? scheme;
    for (final candidate in _schemes) {
      if (candidate.id == schemeId) scheme = candidate;
    }
    if (scheme == null) return (null, ClaimFailure.unknownTier);

    _SeededTier? tier;
    for (final candidate in scheme.tiers) {
      if ('${scheme.id}:${candidate.name.toLowerCase()}' == tierId) {
        tier = candidate;
      }
    }
    if (tier == null) return (null, ClaimFailure.unknownTier);

    final number = PartnerDirectory.normalise(mobileNumber);
    // One claim to a scheme, which is what makes the choice of tier matter.
    if (_claims[number]?[scheme.id] != null) {
      return (null, ClaimFailure.alreadyClaimed);
    }
    if (_progressOf(mobileNumber, scheme) < tier.threshold) {
      return (null, ClaimFailure.notReached);
    }

    final reference = 'CLM-${_nextReference++}';
    (_claims[number] ??= {})[scheme.id] = _TakenClaim(
      tierName: tier.name,
      amountPaisa: tier.rewardPaisa,
      reference: reference,
    );
    // The reward is Crown Solar's own money: nobody has to accept it.
    await _wallet.creditSpinPrize(
      mobileNumber: mobileNumber,
      amount: Money(tier.rewardPaisa),
      reference: reference,
    );
    return (_schemeFrom(mobileNumber, scheme), null);
  }

  @override
  Future<RewardProgram?> rewardProgram(String mobileNumber) async {
    if (PartnerDirectory.find(mobileNumber) == null) return null;

    final scans = _claimsInWindow(
      mobileNumber,
      _programCodePrefix,
      _currentProgram.startsOn,
      _currentProgram.endsOn,
    );

    // What last month earned, and how long it runs. A tier reached in August
    // pays through September, so the month that earned it is not the month
    // the bonus runs in.
    final awarded = PartnerDirectory.normalise(mobileNumber) == _awardNumber;

    return RewardProgram(
      label: _currentProgram.label,
      startsOn: _currentProgram.startsOn,
      endsOn: _currentProgram.endsOn,
      tiers: _programTiers,
      scans: scans,
      awardTierName: awarded ? 'SILVER' : null,
      awardBonusPercent: awarded ? 25 : null,
      awardAppliesUntil: awarded ? DateTime(2026, 9, 30) : null,
      awardEarnedOn: awarded ? DateTime(2026, 8) : null,
    );
  }
}

const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// "31 Jul".
String formatInaamDate(DateTime at) => '${at.day} ${_months[at.month - 1]}';

/// "July" — the month on its own, as the Reward Program card titles it.
String formatInaamMonth(DateTime at) => _monthNames[at.month - 1];

/// "Today, 5:31 PM", then "07 Sep, 7:14 PM".
String formatSpinWhen(DateTime at) {
  final now = DateTime.now();
  final days = DateTime(
    now.year,
    now.month,
    now.day,
  ).difference(DateTime(at.year, at.month, at.day)).inDays;

  final hour = at.hour % 12 == 0 ? 12 : at.hour % 12;
  final time =
      '$hour:${at.minute.toString().padLeft(2, '0')} '
      '${at.hour < 12 ? 'AM' : 'PM'}';

  if (days == 0) return 'Today, $time';
  return '${at.day.toString().padLeft(2, '0')} '
      '${_months[at.month - 1]}, $time';
}

const _monthNames = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];
