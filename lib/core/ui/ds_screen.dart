import 'package:flutter/material.dart';

import '../theme/app_palette.dart';
import '../theme/app_spacing.dart';

/// The layout every screen in the design shares: an app bar, a scrolling
/// body padded to `--screen-padding`, and an optional sticky footer action
/// and bottom navigation bar.
class DsScreen extends StatelessWidget {
  const DsScreen({
    super.key,
    this.appBar,
    required this.sections,
    this.footer,
    this.bottomNav,
    this.padding = const EdgeInsets.fromLTRB(
      AppSpacing.screenPadding,
      AppSpacing.lg,
      AppSpacing.screenPadding,
      AppSpacing.lg,
    ),
    this.gap = AppSpacing.stepLg,
    this.background,
    this.scrollable = true,
    this.crossAxisAlignment = CrossAxisAlignment.stretch,
  });

  final PreferredSizeWidget? appBar;
  final List<Widget> sections;
  final Widget? footer;
  final Widget? bottomNav;
  final EdgeInsetsGeometry padding;
  final double gap;
  final Color? background;
  final bool scrollable;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    final spaced = <Widget>[];
    for (var i = 0; i < sections.length; i++) {
      spaced.add(sections[i]);
      if (i != sections.length - 1) spaced.add(SizedBox(height: gap));
    }

    final column = Column(
      crossAxisAlignment: crossAxisAlignment,
      mainAxisSize: MainAxisSize.min,
      children: spaced,
    );

    final body = Padding(padding: padding, child: column);

    return Scaffold(
      backgroundColor: background,
      appBar: appBar,
      body: SafeArea(
        top: appBar == null,
        bottom: false,
        child: scrollable
            ? SingleChildScrollView(child: body)
            : SizedBox.expand(child: body),
      ),
      bottomNavigationBar: footer == null && bottomNav == null
          ? null
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [?footer, ?bottomNav],
            ),
    );
  }
}

/// A caption in the design's smallest voice — the grey explanatory line that
/// sits under a control or card.
class DsCaption extends StatelessWidget {
  const DsCaption(this.text, {super.key, this.align = TextAlign.start});

  final String text;
  final TextAlign align;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: align,
      style: TextStyle(
        fontSize: 13,
        height: 19 / 13,
        color: context.palette.textTertiary,
      ),
    );
  }
}

/// Secondary body copy (13/19) in the design's `--text-secondary` colour,
/// used for the explanatory paragraphs under headings.
class DsBody extends StatelessWidget {
  const DsBody(
    this.text, {
    super.key,
    this.align = TextAlign.start,
    this.color,
    this.size = 13,
  });

  final String text;
  final TextAlign align;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: align,
      style: TextStyle(
        fontSize: size,
        height: size == 13 ? 19 / 13 : 20 / 14,
        color: color ?? context.colors.onSurfaceVariant,
      ),
    );
  }
}

/// The 20/26/600 in-body heading the design uses above OTP entry, forms and
/// confirmation steps.
class DsHeading extends StatelessWidget {
  const DsHeading(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: context.texts.titleMedium);
  }
}
