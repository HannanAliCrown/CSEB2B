import 'package:flutter/widgets.dart';

/// The Crown Solar Energy wordmark, at the design's Login-screen height
/// (Claude Design A1/B3: `<img src="assets/logo.png" style="height:52px">`).
/// Shared by every Login-journey screen that shows a logo, so the asset
/// path and sizing are declared exactly once.
class CrownSolarLogo extends StatelessWidget {
  const CrownSolarLogo({super.key, this.height = 52});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/crown_solar_logo.png',
      height: height,
      alignment: Alignment.centerLeft,
    );
  }
}
