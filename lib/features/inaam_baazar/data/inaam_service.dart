// Constructor parameters are named for their public API rather than the
// private fields they populate, so the initializing-formal shorthand the
// linter suggests is not available here.
// ignore_for_file: prefer_initializing_formals

import 'dart:convert';

import 'package:http/http.dart' as http;

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
  );
}

/// Inaam Baazar's data boundary, backed by the database behind
/// `prototype_server`.
///
/// There is deliberately no in-memory implementation. A prize won and then
/// forgotten on restart is worse than one that plainly fails to be paid.
class InaamService {
  InaamService({required String baseUrl, http.Client? client})
    : _baseUrl = baseUrl,
      _client = client ?? http.Client();

  final String _baseUrl;
  final http.Client _client;

  Future<SpinState?> spinState(String mobileNumber) async {
    final body = await _get('/inaam/spin', {'mobileNumber': mobileNumber});
    return body == null ? null : SpinState.fromJson(body);
  }

  /// Takes one spin. The prize is chosen and paid by the server, inside one
  /// transaction, so this returns what was actually credited.
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

  /// Takes the one claim a scheme allows.
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
