import 'package:flutter/material.dart';

/// The Crown Solar Energy lockup. The reverse (white) lockup is used on the
/// navy splash and brand surfaces; the primary lockup everywhere else.
class CrownWordmark extends StatelessWidget {
  const CrownWordmark({
    super.key,
    this.height,
    this.width,
    this.reverse = false,
  });

  final double? height;
  final double? width;
  final bool reverse;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      reverse
          ? 'assets/images/crown_logo_reverse.png'
          : 'assets/images/crown_solar_logo.png',
      height: width == null ? (height ?? 52) : null,
      width: width,
      fit: BoxFit.contain,
    );
  }
}
