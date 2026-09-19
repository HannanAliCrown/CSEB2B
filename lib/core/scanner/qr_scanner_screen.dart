import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

import '../ui/ds.dart';

/// A full-screen camera that reads one QR code and returns its value.
///
/// Push it and await the result: a code, or null when the partner backs out
/// or the camera is not available. Nothing is interpreted here — what a code
/// means is the caller's business.
class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({
    super.key,
    required this.title,
    required this.instruction,
  });

  final String title;
  final String instruction;

  /// Opens the scanner and returns the code that was read, if any.
  static Future<String?> open(
    BuildContext context, {
    required String title,
    required String instruction,
  }) => Navigator.of(context).push<String>(
    MaterialPageRoute<String>(
      builder: (_) => QrScannerScreen(title: title, instruction: instruction),
    ),
  );

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: const [BarcodeFormat.qrCode],
  );

  /// Null while the permission is still being decided.
  bool? _allowed;

  /// The first code wins; later frames are ignored while the route closes.
  bool _handled = false;

  @override
  void initState() {
    super.initState();
    _askForCamera();
  }

  Future<void> _askForCamera() async {
    final status = await Permission.camera.request();
    if (!mounted) return;
    setState(() => _allowed = status.isGranted);
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    final value = capture.barcodes
        .map((barcode) => barcode.rawValue)
        .firstWhere((raw) => raw != null && raw.isNotEmpty, orElse: () => null);
    if (value == null) return;

    _handled = true;
    Navigator.of(context).pop(value);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allowed = _allowed;

    return Scaffold(
      backgroundColor: const Color(0xFF0B0F14),
      appBar: DsAppBar(
        title: widget.title,
        onBack: () => Navigator.of(context).pop(),
      ),
      body: switch (allowed) {
        null => const Center(child: CircularProgressIndicator()),
        false => _CameraRefused(onRetry: _askForCamera),
        true => Stack(
          fit: StackFit.expand,
          children: [
            MobileScanner(controller: _controller, onDetect: _onDetect),
            _ScannerFrame(instruction: widget.instruction),
          ],
        ),
      },
    );
  }
}

/// The viewfinder: a gold-cornered window over the camera, matching the CNIC
/// capture screen's framing.
class _ScannerFrame extends StatelessWidget {
  const _ScannerFrame({required this.instruction});

  final String instruction;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: SizedBox(
                width: 240,
                height: 240,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: AppRadii.lgRadius,
                    border: Border.all(
                      color: context.palette.crownGold,
                      width: 3,
                    ),
                  ),
                ),
              ),
            ),
          ),
          // A scrim behind the caption: white text alone disappears against a
          // bright scene.
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0),
                  Colors.black.withValues(alpha: 0.75),
                ],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
              child: Text(
                instruction,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  height: 20 / 14,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CameraRefused extends StatelessWidget {
  const _CameraRefused({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const DsIconMedallion(
            icon: LucideIcons.cameraOff,
            tone: DsTone.warning,
            size: 64,
            iconSize: 30,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Camera access is off',
            textAlign: TextAlign.center,
            style: context.texts.titleLarge?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Scanning needs the camera. Turn it on for Crown Solar and try '
            'again, or type the code instead.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 20 / 14,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          DsButton(label: 'Try Again', onPressed: onRetry),
          const SizedBox(height: 10),
          DsButton(
            label: 'Open Settings',
            variant: DsButtonVariant.secondary,
            onPressed: openAppSettings,
          ),
        ],
      ),
    );
  }
}
