import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/ui/ds.dart';
import '../../../login/ui/widgets/crown_wordmark.dart';

/// The Home header: brand mark, business name, role caption and the bell.
class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
    required this.businessName,
    required this.role,
    this.hasUnread = true,
  });

  final String businessName;
  final String role;
  final bool hasUnread;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        10,
        AppSpacing.screenPadding,
        6,
      ),
      child: Row(
        children: [
          const CrownWordmark(height: 28),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  businessName,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 18 / 15,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  role.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 0.06 * 11,
                    fontWeight: FontWeight.w600,
                    color: context.palette.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          Stack(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: context.colors.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: context.colors.outline),
                ),
                child: Icon(
                  LucideIcons.bell,
                  size: 20,
                  color: context.colors.onSurfaceVariant,
                ),
              ),
              if (hasUnread)
                Positioned(
                  top: 8,
                  right: 9,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: context.colors.error,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: context.colors.surface,
                        width: 2,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The navy wallet card: balance (hidden or revealed), an optional held-amount
/// line and the two cash actions.
class WalletBalanceCard extends StatelessWidget {
  const WalletBalanceCard({
    super.key,
    required this.amount,
    this.hidden = false,
    this.heldNote,
    this.label = 'Wallet balance',
    this.showActions = true,
    this.onToggleHidden,
    this.onSendCash,
    this.onViewLedger,
  });

  final String amount;
  final bool hidden;
  final String? heldNote;
  final String label;
  final bool showActions;
  final VoidCallback? onToggleHidden;
  final VoidCallback? onSendCash;
  final VoidCallback? onViewLedger;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.stepLg),
      decoration: BoxDecoration(
        color: context.colors.primary,
        borderRadius: AppRadii.heroRadius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  letterSpacing: 0.06 * 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.75),
                ),
              ),
              GestureDetector(
                onTap: onToggleHidden,
                child: Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    hidden ? LucideIcons.eyeOff : LucideIcons.eye,
                    size: 18,
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
                'PKR',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    hidden ? '••••••' : amount,
                    style: TextStyle(
                      fontSize: 30,
                      height: 36 / 30,
                      fontWeight: FontWeight.w600,
                      letterSpacing: hidden ? 2 : 0,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (heldNote != null) ...[
            const SizedBox(height: 6),
            Text(
              heldNote!,
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.75),
              ),
            ),
          ],
          if (showActions) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _WalletAction(label: 'Send Cash', onTap: onSendCash),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _WalletAction(
                    label: 'View Ledger',
                    onTap: onViewLedger,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _WalletAction extends StatelessWidget {
  const _WalletAction({required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

/// The promotional slider card and its dot indicator.
/// One slide's copy, so this widget stays independent of the data layer.
typedef PromoCopy = ({String eyebrow, String headline});

class HomePromoSlider extends StatefulWidget {
  const HomePromoSlider({
    super.key,
    required this.eyebrow,
    required this.headline,
    this.slideCount = 3,
    this.slides,
    this.onSlideTap,
  });

  final String eyebrow;
  final String headline;
  final int slideCount;

  /// Every slide to cycle through. With none, the single [eyebrow] and
  /// [headline] are shown as a static card — which is how the design preview
  /// renders it.
  final List<PromoCopy>? slides;

  final ValueChanged<int>? onSlideTap;

  @override
  State<HomePromoSlider> createState() => _HomePromoSliderState();
}

class _HomePromoSliderState extends State<HomePromoSlider> {
  /// How long each slide rests before the next one moves in.
  static const _dwell = Duration(seconds: 5);

  final _pages = PageController();
  Timer? _advance;
  int _current = 0;

  List<PromoCopy> get _slides =>
      widget.slides ?? [(eyebrow: widget.eyebrow, headline: widget.headline)];

  @override
  void initState() {
    super.initState();
    _restartAutoAdvance();
  }

  @override
  void didUpdateWidget(HomePromoSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.slides?.length != widget.slides?.length) {
      _restartAutoAdvance();
    }
  }

  /// Slides advance on their own only when there is more than one, so the
  /// design preview never animates.
  void _restartAutoAdvance() {
    _advance?.cancel();
    if (_slides.length < 2) return;
    _advance = Timer.periodic(_dwell, (_) {
      if (!mounted || !_pages.hasClients) return;
      _pages.animateToPage(
        (_current + 1) % _slides.length,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _advance?.cancel();
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final slides = _slides;

    return Column(
      children: [
        if (slides.length > 1)
          SizedBox(
            height: 132,
            child: PageView.builder(
              controller: _pages,
              itemCount: slides.length,
              onPageChanged: (page) => setState(() => _current = page),
              itemBuilder: (context, i) => GestureDetector(
                onTap: widget.onSlideTap == null
                    ? null
                    : () => widget.onSlideTap!(i),
                child: _PromoCard(
                  eyebrow: slides[i].eyebrow,
                  headline: slides[i].headline,
                ),
              ),
            ),
          )
        else
          _PromoCard(
            eyebrow: slides.first.eyebrow,
            headline: slides.first.headline,
          ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            slides.length > 1 ? slides.length : widget.slideCount,
            (i) {
              final active = i == _current;
              return Container(
                width: active ? 18 : 6,
                height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: active
                      ? context.colors.primary
                      : const Color(0xFFC9D2E0),
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _PromoCard extends StatelessWidget {
  const _PromoCard({required this.eyebrow, required this.headline});

  final String eyebrow;
  final String headline;

  @override
  Widget build(BuildContext context) {
    // Full width, so the slider lines up with the wallet card above it. The
    // card used to shrink-wrap its headline and sit centred, which left it
    // noticeably narrower than everything else on the screen.
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 132),
      padding: const EdgeInsets.all(AppSpacing.stepLg),
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        borderRadius: AppRadii.lgRadius,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1B1E8C), Color(0xFF04037E)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -24,
            bottom: -24,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: context.palette.crownGold.withValues(alpha: 0.22),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Padding(
            // Room for the gold disc in the corner, so the headline does not
            // run across it now that the card is full width.
            padding: const EdgeInsets.only(right: 72),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  eyebrow.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 0.06 * 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  headline,
                  style: const TextStyle(
                    fontSize: 18,
                    height: 24 / 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
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

/// The gold Scan QR call to action.
class ScanQrCta extends StatelessWidget {
  const ScanQrCta({super.key, required this.subtitle, this.onTap});

  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF0F172A);
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadii.lgRadius,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: context.palette.crownGold,
          borderRadius: AppRadii.lgRadius,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: ink.withValues(alpha: 0.14),
                borderRadius: AppRadii.mdRadius,
              ),
              child: const Icon(LucideIcons.scanLine, size: 24, color: ink),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Scan QR',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: ink,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF3F3312),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(LucideIcons.chevronRight, size: 22, color: ink),
          ],
        ),
      ),
    );
  }
}

/// The accent-tinted announcement ticker.
class HomeTicker extends StatefulWidget {
  const HomeTicker({super.key, required this.message, this.messages});

  final String message;

  /// Every announcement to scroll through, joined into one running line.
  /// With none, [message] is shown still — which is how the design preview
  /// renders it.
  final List<String>? messages;

  @override
  State<HomeTicker> createState() => _HomeTickerState();
}

class _HomeTickerState extends State<HomeTicker>
    with SingleTickerProviderStateMixin {
  /// Reading speed, in logical pixels per second.
  static const _pixelsPerSecond = 40.0;

  final _scroll = ScrollController();
  Ticker? _ticker;
  Duration _last = Duration.zero;

  String get _line => widget.messages == null || widget.messages!.isEmpty
      ? widget.message
      : widget.messages!.join('   ·   ');

  @override
  void initState() {
    super.initState();
    // A still line needs no animation, so the design preview never ticks.
    if (widget.messages == null || widget.messages!.length < 2) return;
    _ticker = createTicker(_onTick)..start();
  }

  void _onTick(Duration elapsed) {
    if (!_scroll.hasClients) {
      _last = elapsed;
      return;
    }
    final seconds = (elapsed - _last).inMicroseconds / 1e6;
    _last = elapsed;

    final extent = _scroll.position.maxScrollExtent;
    if (extent <= 0) return;

    // One continuous loop: the line is drawn twice, so running past the first
    // copy and wrapping never shows a gap.
    final next = _scroll.offset + _pixelsPerSecond * seconds;
    _scroll.jumpTo(next >= extent ? 0 : next);
  }

  @override
  void dispose() {
    _ticker?.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final running = _ticker != null;
    final style = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      color: context.colors.primary,
    );

    return Container(
      width: double.infinity,
      color: context.palette.accentSoft,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: SingleChildScrollView(
        controller: running ? _scroll : null,
        scrollDirection: Axis.horizontal,
        physics: running ? const NeverScrollableScrollPhysics() : null,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenPadding,
        ),
        child: running
            ? Row(
                children: [
                  Text(_line, maxLines: 1, style: style),
                  const SizedBox(width: AppSpacing.xl),
                  Text(_line, maxLines: 1, style: style),
                ],
              )
            : Text(_line, maxLines: 1, style: style),
      ),
    );
  }
}

/// One module tile in the "Everything else" grid.
class HomeTile {
  const HomeTile({
    required this.label,
    required this.icon,
    this.badge,
    this.dimmed = false,
    this.onTap,
  });

  final String label;
  final IconData icon;
  final int? badge;
  final bool dimmed;

  /// What opening this module does. A tile with nothing behind it yet is
  /// left without an action rather than pretending to work.
  final VoidCallback? onTap;
}

class HomeTileGrid extends StatelessWidget {
  const HomeTileGrid({super.key, required this.tiles});

  final List<HomeTile> tiles;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: tiles.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: AppSpacing.stepMd,
        mainAxisSpacing: AppSpacing.stepMd,
        mainAxisExtent: 108,
      ),
      itemBuilder: (context, i) {
        final tile = tiles[i];
        return Opacity(
          opacity: tile.dimmed ? 0.45 : 1,
          child: GestureDetector(
            onTap: tile.dimmed ? null : tile.onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
              decoration: BoxDecoration(
                color: context.colors.surface,
                borderRadius: AppRadii.mdRadius,
                border: Border.all(color: context.colors.outline),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      DsIconMedallion(
                        icon: tile.icon,
                        size: 40,
                        iconSize: 20,
                        rounded: true,
                      ),
                      if (tile.badge != null)
                        Positioned(
                          top: -4,
                          right: -6,
                          child: Container(
                            width: 18,
                            height: 18,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: context.colors.error,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: context.colors.surface,
                                width: 2,
                              ),
                            ),
                            child: Text(
                              '${tile.badge}',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Flexible(
                    child: Text(
                      tile.label,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        height: 15 / 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
