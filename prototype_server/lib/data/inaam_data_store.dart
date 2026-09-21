/// One segment of the wheel, as the phone is allowed to see it.
///
/// The weight is deliberately absent. A partner cannot influence the odds,
/// so sending them would only invite the belief that they can.
class SpinSegmentRow {
  const SpinSegmentRow({required this.amountPaisa, required this.position});

  final int amountPaisa;
  final int position;

  Map<String, Object?> toJson() => {
    'amountPaisa': amountPaisa,
    'position': position,
  };
}

/// One spin that has happened.
class SpinRow {
  const SpinRow({
    required this.reference,
    required this.amountPaisa,
    required this.spunAt,
  });

  final String reference;
  final int amountPaisa;
  final DateTime spunAt;

  Map<String, Object?> toJson() => {
    'reference': reference,
    'amountPaisa': amountPaisa,
    'spunAt': spunAt.toUtc().toIso8601String(),
  };
}

/// What the Spin and Win tab shows.
class SpinStateRow {
  const SpinStateRow({
    required this.scansToday,
    required this.scansPerSpin,
    required this.spinsAvailable,
    required this.segments,
    required this.history,
  });

  /// Scans claimed today. The entitlement is derived from this, never
  /// stored, so it cannot drift from the scans that earned it.
  final int scansToday;
  final int scansPerSpin;
  final int spinsAvailable;

  final List<SpinSegmentRow> segments;
  final List<SpinRow> history;

  /// How many more scans earn the next spin. Zero when the wheel has not
  /// been set up: there is then no next spin to count toward.
  int get scansToNextSpin =>
      scansPerSpin == 0 ? 0 : scansPerSpin - (scansToday % scansPerSpin);

  Map<String, Object?> toJson() => {
    'scansToday': scansToday,
    'scansPerSpin': scansPerSpin,
    'spinsAvailable': spinsAvailable,
    'scansToNextSpin': scansToNextSpin,
    'segments': [for (final segment in segments) segment.toJson()],
    'history': [for (final spin in history) spin.toJson()],
  };
}

/// Why a spin could not be taken.
enum SpinRefusal {
  unknownAccount,

  /// Every spin earned today has been used. Not an error — the screen says
  /// how many more scans earn the next one.
  noSpinsAvailable,

  /// Crown Solar has not set the wheel up.
  notConfigured,
}

/// One tier of an item scheme, with what this partner has done toward it.
class SchemeTierRow {
  const SchemeTierRow({
    required this.id,
    required this.name,
    required this.threshold,
    required this.rewardPaisa,
    required this.reached,
  });

  final String id;
  final String name;

  /// Scans, or paisa, depending on the scheme's measure.
  final int threshold;

  final int rewardPaisa;
  final bool reached;

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'threshold': threshold,
    'rewardPaisa': rewardPaisa,
    'reached': reached,
  };
}

/// One item scheme as it stands for one partner.
class ItemSchemeRow {
  const ItemSchemeRow({
    required this.id,
    required this.name,
    required this.measure,
    required this.progress,
    required this.startsOn,
    required this.endsOn,
    required this.tiers,
    this.claimedTierName,
    this.claimedAmountPaisa,
    this.claimedReference,
  });

  final String id;
  final String name;

  /// 'scans' | 'amount'. Never both: a scheme that mixed them would have two
  /// progress bars and one prize.
  final String measure;

  /// Scans counted, or paisa purchased.
  final int progress;

  final DateTime startsOn;
  final DateTime endsOn;
  final List<SchemeTierRow> tiers;

  /// Set once a tier has been taken. One claim per scheme, ever.
  final String? claimedTierName;
  final int? claimedAmountPaisa;
  final String? claimedReference;

  bool get claimed => claimedTierName != null;

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'measure': measure,
    'progress': progress,
    'startsOn': startsOn.toUtc().toIso8601String(),
    'endsOn': endsOn.toUtc().toIso8601String(),
    'tiers': [for (final tier in tiers) tier.toJson()],
    'claimedTierName': claimedTierName,
    'claimedAmountPaisa': claimedAmountPaisa,
    'claimedReference': claimedReference,
  };
}

/// Why a tier could not be claimed.
enum ClaimRefusal {
  unknownAccount,

  /// No such scheme or tier, or the scheme has ended.
  unknownTier,

  /// The target has not been reached.
  notReached,

  /// A tier has already been taken from this scheme. Only one, ever.
  alreadyClaimed,
}

/// One tier of the monthly programme.
class ProgramTierRow {
  const ProgramTierRow({
    required this.name,
    required this.scanTarget,
    required this.bonusPercent,
  });

  final String name;
  final int scanTarget;
  final int bonusPercent;

  Map<String, Object?> toJson() => {
    'name': name,
    'scanTarget': scanTarget,
    'bonusPercent': bonusPercent,
  };
}

/// The Reward Program tab: what was won last month, and how this month is
/// going.
class RewardProgramRow {
  const RewardProgramRow({
    required this.tiers,
    required this.scans,
    this.label,
    this.startsOn,
    this.endsOn,
    this.awardTierName,
    this.awardBonusPercent,
    this.awardAppliesUntil,
  });

  /// The programme running now. Null when Crown Solar has not created one,
  /// which the screen says rather than inventing a month.
  final String? label;
  final DateTime? startsOn;
  final DateTime? endsOn;

  final List<ProgramTierRow> tiers;

  /// Scans of this programme's products inside its window.
  final int scans;

  /// What last month earned, and how long the bonus runs. Null when nothing
  /// was awarded — there is then no bonus, which is not the same as a bonus
  /// of zero.
  final String? awardTierName;
  final int? awardBonusPercent;
  final DateTime? awardAppliesUntil;

  Map<String, Object?> toJson() => {
    'label': label,
    'startsOn': startsOn?.toUtc().toIso8601String(),
    'endsOn': endsOn?.toUtc().toIso8601String(),
    'scans': scans,
    'tiers': [for (final tier in tiers) tier.toJson()],
    'awardTierName': awardTierName,
    'awardBonusPercent': awardBonusPercent,
    'awardAppliesUntil': awardAppliesUntil?.toUtc().toIso8601String(),
  };
}

/// Inaam Baazar's persistence boundary.
///
/// Every prize is paid into the cash wallet. Inaam holds no balance of its
/// own, so nothing here returns one.
abstract interface class InaamDataStore {
  /// The wheel, the entitlement and the history. Null for an unknown number.
  Future<SpinStateRow?> spinState(String mobileNumber);

  /// Takes one spin: picks a prize by weight, records it, and credits the
  /// wallet — all in one transaction, so a prize can never be paid without
  /// the spin that won it, or a spin taken without the money arriving.
  Future<(SpinRow?, SpinRefusal?)> spin(String mobileNumber);

  /// Every active scheme with this partner's progress and claim state.
  Future<List<ItemSchemeRow>?> itemSchemes(String mobileNumber);

  /// Takes the one claim this scheme allows.
  Future<(ItemSchemeRow?, ClaimRefusal?)> claimTier({
    required String mobileNumber,
    required String schemeId,
    required String tierId,
  });

  /// This month's programme and last month's award.
  Future<RewardProgramRow?> rewardProgram(String mobileNumber);
}
