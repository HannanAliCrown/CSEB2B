import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/ui/ds.dart';

/// The reward-tier palette board 09 draws its medals and tier cards with.
///
/// These are illustration colours rather than semantic tokens: a medal is
/// silver, gold or platinum because of what it is called, not because of a
/// status it carries, so `lib/core/theme` has no slot for them. They are
/// read from the approved board and used only inside Inaam Baazar.
abstract final class InaamTierColors {
  static const silverFill = Color(0xFFB0B7C3);
  static const silverInk = Color(0xFF2B3240);
  static const goldInk = Color(0xFF3F3312);
  static const platinumFill = Color(0xFFEEF3FA);
  static const platinumInk = Color(0xFF1B2A4A);

  /// The pale wedge between the gold ones on the prize wheel.
  static const wheelLight = Color(0xFFF4F6FA);
}

/// Which medal a tier wears. Named tiers keep their own metal; anything
/// Crown Solar configures under another name falls back to its position in
/// the ladder, so a fourth tier still renders.
enum InaamMetal { silver, gold, platinum }

InaamMetal inaamMetalFor(String name, int index) =>
    switch (name.trim().toLowerCase()) {
      'silver' => InaamMetal.silver,
      'gold' => InaamMetal.gold,
      'platinum' => InaamMetal.platinum,
      _ => switch (index) {
        0 => InaamMetal.silver,
        1 => InaamMetal.gold,
        _ => InaamMetal.platinum,
      },
    };

/// The uppercase micro-label the board puts above every value.
class InaamCapsLabel extends StatelessWidget {
  const InaamCapsLabel(
    this.text, {
    super.key,
    this.size = 12,
    this.color,
    this.opacity = 1,
  });

  final String text;
  final double size;
  final Color? color;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: size,
        letterSpacing: 0.06 * size,
        fontWeight: FontWeight.w600,
        color: (color ?? context.palette.textTertiary).withValues(
          alpha: opacity,
        ),
      ),
    );
  }
}

/// The navy card the board opens both Inaam tabs with: `--c-primary`, hero
/// corners and 20px of padding.
class InaamHeroCard extends StatelessWidget {
  const InaamHeroCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.stepLg),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: context.colors.primary,
        borderRadius: AppRadii.heroRadius,
      ),
      child: child,
    );
  }
}

/// A translucent panel inset into a navy card — the board's way of putting a
/// second reading inside the first without a second card.
class InaamInsetPanel extends StatelessWidget {
  const InaamInsetPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.stepMd),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: AppRadii.mdRadius,
      ),
      child: child,
    );
  }
}

/// Board 09 · A1 — spins waiting, with the scans that earn the next one
/// folded into the same card.
class InaamSpinsCard extends StatelessWidget {
  const InaamSpinsCard({
    super.key,
    required this.spins,
    required this.scansToday,
    required this.scansTarget,
    required this.progress,
    required this.note,
  });

  final int spins;
  final int scansToday;
  final int scansTarget;
  final double progress;
  final String note;

  @override
  Widget build(BuildContext context) {
    return InaamHeroCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Flexible(
                child: InaamCapsLabel(
                  'Spins available',
                  color: Colors.white,
                  opacity: 0.78,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                ),
                child: const Text(
                  'Today',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$spins',
                style: const TextStyle(
                  fontSize: 44,
                  height: 48 / 44,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  spins == 1 ? 'spin ready to use' : 'spins ready to use',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          InaamInsetPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Scans today',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ),
                    Flexible(
                      child: Text(
                        '$scansToday of $scansTarget for the next spin',
                        textAlign: TextAlign.end,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                DsProgressBar(
                  value: progress,
                  height: 6,
                  color: context.palette.crownGold,
                  track: Colors.white.withValues(alpha: 0.22),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  note,
                  style: TextStyle(
                    fontSize: 12,
                    height: 17 / 12,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The prize wheel: eight wedges in the Crown golds, a navy rim, the value on
/// each wedge and a pointer at the top. Nothing about weighting or odds is
/// drawn, because a partner cannot influence them.
class InaamSpinWheel extends StatelessWidget {
  const InaamSpinWheel({super.key, this.size = 212, this.labels, this.centre});

  final double size;

  /// The wedge labels, in order. Null keeps the board's own eight so the
  /// design screens are unchanged; the live tab passes what Crown Solar
  /// configured.
  final List<String>? labels;

  /// What sits in the hub. Null draws the resting gift badge; the result
  /// screen passes the prize it landed on.
  final Widget? centre;

  static const _defaults = [
    '50',
    '50',
    '50',
    '500',
    '50',
    '50',
    '50',
    '50,000',
  ];

  @override
  Widget build(BuildContext context) {
    final given = labels;
    final wedges = (given == null || given.isEmpty) ? _defaults : given;
    final radius = size / 2;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: context.colors.primary, width: 8),
            ),
            child: ClipOval(
              child: CustomPaint(
                painter: _WheelPainter(
                  wedges: wedges.length,
                  gold: context.palette.crownGold,
                  amber: context.palette.crownAmber,
                  light: InaamTierColors.wheelLight,
                ),
                child: Stack(
                  children: [
                    for (var i = 0; i < wedges.length; i++)
                      Transform.rotate(
                        angle: (i + 0.5) * (2 * math.pi / wedges.length),
                        child: Align(
                          // The board seats a label 14px in from the rim,
                          // rotated with its wedge rather than upright.
                          alignment: Alignment(0, -(radius - 14) / radius),
                          child: Text(
                            wedges[i],
                            style: const TextStyle(
                              fontSize: 10,
                              height: 12 / 10,
                              fontWeight: FontWeight.w700,
                              color: InaamTierColors.goldInk,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          centre ??
              Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: context.colors.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: context.colors.outline),
                ),
                child: Icon(
                  LucideIcons.gift,
                  size: 26,
                  color: context.colors.primary,
                ),
              ),
          Positioned(
            top: -14,
            child: CustomPaint(
              size: const Size(20, 16),
              painter: _PointerPainter(colour: context.palette.crownRed),
            ),
          ),
        ],
      ),
    );
  }
}

/// The hub of the result wheel: what was won, named in the middle of the
/// thing that chose it.
class InaamWheelPrize extends StatelessWidget {
  const InaamWheelPrize({super.key, required this.amount});

  final String amount;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 104,
      height: 104,
      decoration: BoxDecoration(
        color: context.colors.surface,
        shape: BoxShape.circle,
        border: Border.all(color: context.colors.outline),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const InaamCapsLabel('You won', size: 11),
          const SizedBox(height: 2),
          Text(
            amount,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _WheelPainter extends CustomPainter {
  _WheelPainter({
    required this.wedges,
    required this.gold,
    required this.amber,
    required this.light,
  });

  final int wedges;
  final Color gold;
  final Color amber;
  final Color light;

  @override
  void paint(Canvas canvas, Size size) {
    final box = Offset.zero & size;
    final sweep = 2 * math.pi / wedges;
    for (var i = 0; i < wedges; i++) {
      // Gold, pale, amber, pale — the four-wedge cycle the board repeats
      // around the rim.
      final fill = switch (i % 4) {
        0 => gold,
        2 => amber,
        _ => light,
      };
      canvas.drawArc(
        box,
        i * sweep - math.pi / 2,
        sweep,
        true,
        Paint()..color = fill,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WheelPainter old) =>
      old.wedges != wedges || old.gold != gold || old.amber != amber;
}

class _PointerPainter extends CustomPainter {
  _PointerPainter({required this.colour});

  final Color colour;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = colour);
  }

  @override
  bool shouldRepaint(covariant _PointerPainter old) => old.colour != colour;
}

/// One row of the spin history: what was won, when, and that it was paid.
class InaamSpinRow extends StatelessWidget {
  const InaamSpinRow({
    super.key,
    required this.prize,
    required this.when,
    this.last = false,
  });

  final String prize;
  final String when;

  /// The board rules every row but the last one.
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.stepMd),
      decoration: last
          ? null
          : BoxDecoration(
              border: Border(bottom: BorderSide(color: context.colors.outline)),
            ),
      child: Row(
        children: [
          const DsIconMedallion(
            icon: LucideIcons.gift,
            tone: DsTone.solar,
            size: 34,
            iconSize: 17,
            rounded: true,
          ),
          const SizedBox(width: AppSpacing.stepMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  prize,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  when,
                  style: TextStyle(
                    fontSize: 11,
                    color: context.palette.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            'Credited',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: context.status.success,
            ),
          ),
        ],
      ),
    );
  }
}

/// Board 09 · A4 — the bonus already running: what it is worth, how long it
/// lasts, and the medal that earned it.
class InaamRewardBanner extends StatelessWidget {
  const InaamRewardBanner({
    super.key,
    required this.title,
    required this.remaining,
    required this.endDate,
    required this.tierName,
    required this.bonus,
  });

  final String title;
  final String remaining;
  final String endDate;
  final String tierName;
  final String bonus;

  @override
  Widget build(BuildContext context) {
    final (medalFill, medalInk) = _medalColours(
      inaamMetalFor(tierName, 0),
      context,
    );

    return InaamHeroCard(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: AppSpacing.stepMd),
                Row(
                  children: [
                    Expanded(
                      child: _HeroStat(label: 'Remaining', value: remaining),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _HeroStat(label: 'End date', value: endDate),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          SizedBox(
            width: 84,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: medalFill,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(LucideIcons.award, size: 26, color: medalInk),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  tierName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Inaam',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
                Text(
                  bonus,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: context.palette.crownGold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return InaamInsetPanel(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          InaamCapsLabel(label, size: 10, color: Colors.white, opacity: 0.8),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

/// The sunken strip of dates the board rules down the middle.
class InaamDateStrip extends StatelessWidget {
  const InaamDateStrip({
    super.key,
    required this.startLabel,
    required this.startValue,
    required this.endLabel,
    required this.endValue,
  });

  final String startLabel;
  final String startValue;
  final String endLabel;
  final String endValue;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.stepMd),
      decoration: BoxDecoration(
        color: context.palette.sunken,
        borderRadius: AppRadii.mdRadius,
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              child: _Cell(label: startLabel, value: startValue),
            ),
            Container(width: 1, color: context.colors.outline),
            Expanded(
              child: _Cell(label: endLabel, value: endValue),
            ),
          ],
        ),
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InaamCapsLabel(label, size: 10),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

/// One milestone on the Reward Program track.
class InaamMilestone {
  const InaamMilestone({
    required this.name,
    required this.target,
    required this.reached,
  });

  final String name;

  /// The scan count that reaches this tier.
  final int target;

  final bool reached;
}

/// Board 09 · A4 — the tier ladder drawn as medals over a rail, with the
/// partner's own position marked on it.
class InaamMilestoneTrack extends StatelessWidget {
  const InaamMilestoneTrack({
    super.key,
    required this.milestones,
    required this.scans,
  });

  final List<InaamMilestone> milestones;

  /// This month's qualifying scans. The rail moves with it from the very
  /// first one.
  final int scans;

  static const _gap = 10.0;
  static const _medal = 34.0;
  static const _rail = 8.0;
  static const _railTop = 46.0;

  /// Where the partner sits on the rail, in logical pixels from its left
  /// end.
  ///
  /// The rail is a piecewise scale, not a single ratio: it runs from zero
  /// scans at the left edge, through each medal at the scan count that
  /// reaches it, to the last medal. So a partner below the first tier still
  /// sees the bar move with every scan, and the marker lands exactly on a
  /// medal the moment that tier is reached — which a single first-to-last
  /// ratio could not do, since it would read empty until the first tier and
  /// would drift off the middle medals whenever the targets are unevenly
  /// spaced.
  static double _offsetFor({
    required List<InaamMilestone> milestones,
    required int scans,
    required double cell,
    required double gap,
  }) {
    double centre(int i) => i * (cell + gap) + cell / 2;

    var previousScans = 0;
    var previousX = 0.0;

    for (var i = 0; i < milestones.length; i++) {
      final target = milestones[i].target;
      final x = centre(i);
      if (scans < target) {
        final span = target - previousScans;
        if (span <= 0) return x;
        final within = (scans - previousScans) / span;
        return previousX + (x - previousX) * within.clamp(0.0, 1.0);
      }
      previousScans = target;
      previousX = x;
    }

    // Every tier reached: the marker rests on the last medal.
    return previousX;
  }

  @override
  Widget build(BuildContext context) {
    if (milestones.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 58,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final count = milestones.length;
          final cell = (constraints.maxWidth - _gap * (count - 1)) / count;
          // The rail ends under the middle of the last medal, but starts at
          // the very left rather than under the first: the run up to the
          // first tier is progress too, and the board's own rail had nowhere
          // to show it.
          final span = (count - 1) * (cell + _gap) + cell / 2;
          final offset = _offsetFor(
            milestones: milestones,
            scans: scans,
            cell: cell,
            gap: _gap,
          );
          final fraction = span <= 0 ? 0.0 : (offset / span).clamp(0.0, 1.0);

          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                child: Row(
                  children: [
                    for (var i = 0; i < count; i++) ...[
                      if (i != 0) const SizedBox(width: _gap),
                      Expanded(
                        child: _Medal(tier: milestones[i], index: i),
                      ),
                    ],
                  ],
                ),
              ),
              Positioned(
                left: 0,
                width: span,
                top: _railTop,
                height: _rail,
                child: DsProgressBar(value: fraction, height: _rail),
              ),
              Positioned(
                left: offset - 9,
                top: _railTop + _rail / 2 - 9,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: context.colors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: context.colors.surface, width: 3),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                top: _railTop + _rail / 2 - 7,
                child: Row(
                  children: [
                    for (var i = 0; i < count; i++) ...[
                      if (i != 0) const SizedBox(width: _gap),
                      Expanded(
                        child: Center(
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: milestones[i].reached
                                  ? context.colors.primary
                                  : context.colors.surface,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: milestones[i].reached
                                    ? context.colors.surface
                                    : context.palette.borderStrong,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Medal extends StatelessWidget {
  const _Medal({required this.tier, required this.index});

  final InaamMilestone tier;
  final int index;

  @override
  Widget build(BuildContext context) {
    final metal = inaamMetalFor(tier.name, index);
    final (fill, ink) = _medalColours(metal, context);
    return Center(
      child: Container(
        width: InaamMilestoneTrack._medal,
        height: InaamMilestoneTrack._medal,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: fill,
          shape: BoxShape.circle,
          border: metal == InaamMetal.platinum
              ? Border.all(color: context.colors.primary, width: 2)
              : null,
        ),
        child: Icon(LucideIcons.award, size: 18, color: ink),
      ),
    );
  }
}

(Color, Color) _medalColours(InaamMetal metal, BuildContext context) =>
    switch (metal) {
      InaamMetal.silver => (
        InaamTierColors.silverFill,
        InaamTierColors.silverInk,
      ),
      InaamMetal.gold => (context.palette.crownGold, InaamTierColors.goldInk),
      InaamMetal.platinum => (
        InaamTierColors.platinumFill,
        InaamTierColors.platinumInk,
      ),
    };

/// One of the three Reward Program tier cards: the metal, what it takes and
/// what it adds to next month's scanning.
class InaamRewardTierCard extends StatelessWidget {
  const InaamRewardTierCard({
    super.key,
    required this.name,
    required this.requirement,
    required this.bonus,
    required this.index,
  });

  final String name;
  final String requirement;
  final String bonus;
  final int index;

  @override
  Widget build(BuildContext context) {
    final metal = inaamMetalFor(name, index);
    final (medalFill, medalInk) = switch (metal) {
      InaamMetal.silver => (
        InaamTierColors.silverFill,
        InaamTierColors.silverInk,
      ),
      InaamMetal.gold => (
        Colors.white.withValues(alpha: 0.55),
        InaamTierColors.goldInk,
      ),
      InaamMetal.platinum => (
        InaamTierColors.platinumFill,
        InaamTierColors.platinumInk,
      ),
    };
    final (cardFill, ink, pillFill) = switch (metal) {
      InaamMetal.silver => (
        context.palette.sunken,
        context.colors.onSurface,
        context.colors.onSurface.withValues(alpha: 0.08),
      ),
      InaamMetal.gold => (
        context.palette.crownGold,
        InaamTierColors.goldInk,
        Colors.black.withValues(alpha: 0.16),
      ),
      InaamMetal.platinum => (
        context.colors.primary,
        Colors.white,
        Colors.white.withValues(alpha: 0.18),
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
      decoration: BoxDecoration(
        color: cardFill,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: medalFill, shape: BoxShape.circle),
            child: Icon(LucideIcons.award, size: 20, color: medalInk),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            name.toUpperCase(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              letterSpacing: 0.04 * 12,
              fontWeight: FontWeight.w600,
              color: ink,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: pillFill,
              borderRadius: BorderRadius.circular(AppRadii.pill),
            ),
            child: Text(
              requirement,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: ink,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            bonus,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: ink,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Extra bonus',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              height: 13 / 10,
              color: ink.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }
}

/// Board 09 · B1 · B2 — what a scheme counts and how far along it is.
class InaamMeasureCard extends StatelessWidget {
  const InaamMeasureCard({
    super.key,
    required this.label,
    required this.value,
    required this.percent,
    required this.note,
    this.prefix,
    this.suffix,
  });

  final String label;
  final String value;

  /// "PKR" ahead of an amount, or nothing ahead of a scan count.
  final String? prefix;

  /// "scans so far" after a scan count.
  final String? suffix;

  final double percent;
  final String note;

  @override
  Widget build(BuildContext context) {
    return DsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InaamCapsLabel(label),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              if (prefix != null) ...[
                Text(
                  prefix!,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: context.palette.textTertiary,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 34,
                      height: 40 / 34,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.02 * 34,
                    ),
                  ),
                ),
              ),
              if (suffix != null) ...[
                const SizedBox(width: AppSpacing.sm),
                Text(
                  suffix!,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: context.palette.textTertiary,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          DsProgressBar(value: percent),
          const SizedBox(height: 10),
          Text(
            note,
            style: TextStyle(
              fontSize: 12,
              height: 17 / 12,
              color: context.colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Board 09 · B1 · B2 · B4 — one scheme tier as its own card: what it pays,
/// what it takes, and whether it is open, locked or closed.
class InaamTierCard extends StatelessWidget {
  const InaamTierCard({
    super.key,
    required this.name,
    required this.prize,
    required this.target,
    this.state,
    this.claimable = false,
    this.dimmed = false,
  });

  final String name;
  final String prize;
  final String target;

  /// "Claim now", "Locked" — omitted on a closed tier, which the dimming
  /// already says.
  final String? state;

  final bool claimable;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final (fill, ink) = dsToneColors(
      context,
      claimable ? DsTone.success : DsTone.neutral,
    );

    return Opacity(
      opacity: dimmed ? 0.55 : 1,
      child: DsCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        border: claimable ? context.status.success : null,
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: fill,
                borderRadius: AppRadii.mdRadius,
              ),
              child: Icon(
                claimable ? LucideIcons.medal : LucideIcons.lock,
                size: claimable ? 21 : 19,
                color: ink,
              ),
            ),
            const SizedBox(width: AppSpacing.stepMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Flexible(
                        child: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Flexible(
                        child: Text(
                          prize,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    target,
                    style: TextStyle(
                      fontSize: 12,
                      height: 17 / 12,
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (state != null) ...[
              const SizedBox(width: AppSpacing.sm),
              Text(
                state!,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: ink,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Board 09 · B4 — the tier that was claimed, and what it paid.
class InaamClaimedCard extends StatelessWidget {
  const InaamClaimedCard({
    super.key,
    required this.title,
    required this.reference,
    required this.note,
  });

  final String title;
  final String reference;
  final String note;

  @override
  Widget build(BuildContext context) {
    return DsCard(
      radius: AppRadii.heroRadius,
      padding: const EdgeInsets.all(AppSpacing.stepLg),
      border: context.status.success,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: context.status.successFill,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  LucideIcons.circleCheckBig,
                  size: 24,
                  color: context.status.success,
                ),
              ),
              const SizedBox(width: AppSpacing.stepMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      reference,
                      style: TextStyle(
                        fontSize: 12,
                        color: context.palette.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.stepMd),
          Text(
            note,
            style: TextStyle(
              fontSize: 13,
              height: 19 / 13,
              color: context.colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// The quiet sunken panel the board closes a scheme screen with — a rule
/// restated, carrying no action.
class InaamSoftNote extends StatelessWidget {
  const InaamSoftNote(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: context.palette.sunken,
        borderRadius: AppRadii.mdRadius,
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          height: 17 / 12,
          color: context.colors.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// The accent-filled line that names the next thing to reach.
class InaamNextUp extends StatelessWidget {
  const InaamNextUp(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: context.palette.accentSoft,
        borderRadius: AppRadii.mdRadius,
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 13,
          height: 19 / 13,
          color: context.colors.primary,
        ),
      ),
    );
  }
}
