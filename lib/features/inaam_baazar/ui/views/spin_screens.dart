import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/ui/ds.dart';
import '../../../home/ui/models/home_demo_data.dart';

/// The prize wheel, drawn as the design shows it: eight segments, the value
/// on each, and a pointer at the top. Nothing about weighting or odds is
/// exposed, because the user cannot influence them.
class SpinWheel extends StatelessWidget {
  const SpinWheel({super.key, this.size = 260});

  final double size;

  static const _values = ['50', '50', '50', '500', '50', '50', '50', '50,000'];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: context.palette.crownGold, width: 6),
              color: context.colors.surface,
            ),
            child: CustomPaint(
              painter: _WheelPainter(
                segments: _values.length,
                line: context.colors.outline,
                highlight: context.palette.accentSoft,
              ),
              child: Stack(
                children: [
                  for (var i = 0; i < _values.length; i++)
                    Align(
                      alignment: Alignment(
                        0.62 * _unit(i, _values.length).dx,
                        0.62 * _unit(i, _values.length).dy,
                      ),
                      child: Text(
                        _values[i],
                        style: TextStyle(
                          fontSize: _values[i].length > 3 ? 13 : 15,
                          fontWeight: FontWeight.w600,
                          color: _values[i] == '50,000'
                              ? context.palette.crownRed
                              : context.colors.onSurface,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: context.colors.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              LucideIcons.sparkles,
              size: 24,
              color: Colors.white,
            ),
          ),
          Positioned(
            top: -6,
            child: Icon(
              LucideIcons.triangle,
              size: 22,
              color: context.palette.crownRed,
            ),
          ),
        ],
      ),
    );
  }

  /// The unit vector pointing at the middle of segment [i] of [n].
  static Offset _unit(int i, int n) {
    final angle = (i + 0.5) * (2 * math.pi / n) - math.pi / 2;
    return Offset(math.cos(angle), math.sin(angle));
  }
}

class _WheelPainter extends CustomPainter {
  _WheelPainter({
    required this.segments,
    required this.line,
    required this.highlight,
  });

  final int segments;
  final Color line;
  final Color highlight;

  @override
  void paint(Canvas canvas, Size size) {
    final centre = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final stroke = Paint()
      ..color = line
      ..strokeWidth = 1;
    final fill = Paint()..color = highlight;

    for (var i = 0; i < segments; i++) {
      final start = i * (2 * math.pi / segments) - math.pi / 2;
      final sweep = 2 * math.pi / segments;
      if (i.isEven) {
        canvas.drawArc(
          Rect.fromCircle(center: centre, radius: radius),
          start,
          sweep,
          true,
          fill,
        );
      }
      canvas.drawLine(
        centre,
        centre + Offset(radius * math.cos(start), radius * math.sin(start)),
        stroke,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Board 09 · A1 — Inaam hub: spins waiting, how the next one is earned, and
/// the wheel itself.
class InaamHubScreen extends StatelessWidget {
  const InaamHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: DsAppBar(
        title: 'Inaam Baazar',
        onBack: () => Navigator.of(context).maybePop(),
      ),
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          children: [
            const DsSegmentedControl(
              options: ['Spin and Win', 'Reward Program', 'Item Scheme'],
              value: 'Spin and Win',
            ),
            const SizedBox(height: AppSpacing.md),
            DsCard(
              tone: DsCardTone.accent,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'SPINS AVAILABLE',
                          style: TextStyle(
                            fontSize: 11,
                            letterSpacing: 0.06 * 11,
                            fontWeight: FontWeight.w600,
                            color: context.colors.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              '2',
                              style: TextStyle(
                                fontSize: 34,
                                fontWeight: FontWeight.w600,
                                color: context.colors.primary,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            const Flexible(
                              child: DsBody('spins ready to use', size: 14),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const DsTag(label: 'Today', tone: DsTone.accent),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.stepMd),
            DsCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Scans today',
                          style: context.texts.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const DsCaption('24 of 30 for the next spin'),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const DsProgressBar(value: 24 / 30),
                  const SizedBox(height: 10),
                  const DsCaption(
                    '6 more scans earns another spin. There is no limit on how '
                    'many you can earn in a day.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const Center(child: SpinWheel()),
            const SizedBox(height: AppSpacing.md),
            const DsCaption(
              'Prizes range from Rs. 50 to Rs. 50,000 and are credited to your '
              'wallet.',
              align: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            DsButton(
              label: 'Spin Now',
              icon: LucideIcons.sparkles,
              onPressed: () {},
            ),
            const SizedBox(height: AppSpacing.lg),
            DsSectionHeader(
              title: 'Spin history',
              actionLabel: 'See all',
              onAction: () {},
            ),
            DsCard(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Column(
                children: const [
                  _SpinRow(prize: 'Rs. 50', when: 'Today, 5:31 PM'),
                  DsHairline(),
                  _SpinRow(prize: 'Rs. 200', when: '07 Sep, 7:14 PM'),
                  DsHairline(),
                  _SpinRow(prize: 'Rs. 1,000', when: '05 Sep, 4:48 PM'),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: DsBottomNav(
        items: HomeDemo.installer.nav,
        activeId: 'inaam',
      ),
    );
  }
}

class _SpinRow extends StatelessWidget {
  const _SpinRow({required this.prize, required this.when});

  final String prize;
  final String when;

  @override
  Widget build(BuildContext context) {
    return DsSettingRow(
      label: prize,
      meta: when,
      leading: const DsIconMedallion(
        icon: LucideIcons.sparkles,
        tone: DsTone.solar,
        size: 34,
        iconSize: 16,
      ),
      trailing: const DsTag(label: 'Credited', tone: DsTone.success),
    );
  }
}

/// Board 09 · A2 — Result: the prize is revealed and credited to the wallet
/// in the same breath, with the reference for the ledger row.
class SpinResultScreen extends StatelessWidget {
  const SpinResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DsScreen(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      gap: AppSpacing.md,
      footer: DsFooterBar(
        child: Column(
          children: [
            DsButton(
              label: 'Use Your Second Spin',
              icon: LucideIcons.sparkles,
              onPressed: () {},
            ),
            const SizedBox(height: 10),
            DsButton(
              label: 'Done',
              variant: DsButtonVariant.quiet,
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          ],
        ),
      ),
      sections: [
        const Center(child: SpinWheel(size: 200)),
        Container(
          padding: const EdgeInsets.all(AppSpacing.stepLg),
          decoration: BoxDecoration(
            color: context.status.successFill,
            borderRadius: AppRadii.heroRadius,
          ),
          child: Column(
            children: [
              Text(
                'YOU WON',
                style: TextStyle(
                  fontSize: 12,
                  letterSpacing: 0.06 * 12,
                  fontWeight: FontWeight.w600,
                  color: context.status.success,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Rs. 50',
                style: TextStyle(
                  fontSize: 38,
                  height: 44 / 38,
                  fontWeight: FontWeight.w600,
                  color: context.status.success,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              DsBody(
                'Rs. 50 added to your wallet. Your balance is now PKR 184,550. '
                'Ref SPN-2026-44192 · Today, 5:31 PM',
                align: TextAlign.center,
                color: context.status.success,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Board 09 · A3 — No spins, already used, and a mid-spin connection drop —
/// the three ways a spin can be unavailable, and why a retry is safe.
class SpinUnavailableScreen extends StatelessWidget {
  const SpinUnavailableScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DsScreen(
      appBar: DsAppBar(
        title: 'Spin and Win',
        onBack: () => Navigator.of(context).maybePop(),
      ),
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      gap: AppSpacing.md,
      sections: [
        DsCard(
          padding: EdgeInsets.zero,
          child: DsEmptyState(
            icon: LucideIcons.sparkles,
            title: 'No Spins Right Now',
            message:
                'You have 4 scans today. Reach 10 scans in one day to earn a '
                'spin.',
            actionLabel: 'Open Scanner',
            onAction: () {},
          ),
        ),
        const DsNotice(
          icon: LucideIcons.circleCheck,
          title: 'This spin has already been used',
          message:
              'You won Rs. 50 on it at 5:31 PM yesterday. It cannot be spun '
              'again.',
        ),
        DsCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const DsIconMedallion(
                    icon: LucideIcons.wifiOff,
                    tone: DsTone.warning,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Spin could not be completed',
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
                'The connection dropped mid-spin. Your spin has not been used. '
                'Try again when you have signal.',
              ),
              const SizedBox(height: AppSpacing.stepMd),
              DsButton(
                label: 'Try Again',
                variant: DsButtonVariant.secondary,
                size: DsButtonSize.sm,
                icon: LucideIcons.refreshCw,
                onPressed: () {},
              ),
            ],
          ),
        ),
        const DsCaption(
          'A retried spin never consumes two entitlements or pays two prizes.',
        ),
      ],
    );
  }
}
