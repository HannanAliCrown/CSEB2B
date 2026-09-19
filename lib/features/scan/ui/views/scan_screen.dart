import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../../core/scanner/qr_scanner_screen.dart';
import '../../../../core/ui/ds.dart';
import '../../../session/data/signed_in_user.dart';
import '../../../session/ui/session_controller.dart';
import '../../data/scan_repository.dart';

/// Scan QR: two jobs behind one camera.
///
/// Authenticity Check answers whether a product is really Crown Solar's and
/// changes nothing. Scan to Win claims the code and pays what it is worth,
/// so only the roles that earn from a scan see that tab at all.
class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final _code = TextEditingController();
  bool _busy = false;
  ScanOutcome? _outcome;

  /// Set from the signed-in role on the first build: a wholesaler or
  /// distributor only ever checks authenticity.
  ScanMode? _mode;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  ScanMode _modeFor(SignedInUser user) =>
      _mode ??= MockScanRepository.prizeFor(user.role) == null
      ? ScanMode.authenticity
      : ScanMode.win;

  /// Reads the code off the product with the camera, then checks it exactly
  /// as a sample code is checked.
  Future<void> _scanWithCamera(SignedInUser user) async {
    final code = await QrScannerScreen.open(
      context,
      title: _modeFor(user).label,
      instruction:
          'Point the camera at the Crown Solar QR code printed on the box.',
    );
    if (!mounted || code == null) return;

    _code.text = code.trim();
    await _check(user);
  }

  Future<void> _check(SignedInUser user) async {
    final code = _code.text.trim();
    if (code.isEmpty) return;

    final mode = _modeFor(user);
    setState(() => _busy = true);
    final outcome = await context.read<ScanRepository>().check(
      code: code,
      user: user,
      mode: mode,
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      _outcome = outcome;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<SessionController>().user;
    if (user == null) return const SizedBox.shrink();

    final outcome = _outcome;
    final mode = _modeFor(user);
    final canWin = MockScanRepository.prizeFor(user.role) != null;

    return Scaffold(
      appBar: DsAppBar(
        title: 'Scan QR',
        subtitle: canWin
            ? 'Check a product or claim a prize'
            : 'Check a product is genuine',
        onBack: () => Navigator.of(context).maybePop(),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        children: [
          if (outcome == null) ...[
            // Roles that cannot win see no tabs rather than a dead one.
            if (canWin) ...[
              DsSegmentedControl(
                options: [ScanMode.authenticity.label, ScanMode.win.label],
                value: mode.label,
                onChanged: (value) => setState(
                  () => _mode = value == ScanMode.win.label
                      ? ScanMode.win
                      : ScanMode.authenticity,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            DsButton(
              label: 'Open Camera',
              icon: LucideIcons.camera,
              onPressed: () => _scanWithCamera(user),
            ),
            const SizedBox(height: AppSpacing.md),
            DsNotice(
              icon: LucideIcons.info,
              message: switch (mode) {
                ScanMode.authenticity =>
                  'Point the camera at the QR code on the box to check the '
                      'product is genuine. Checking does not use up the code.',
                ScanMode.win =>
                  'Point the camera at the QR code on the box. A genuine code '
                      'you claim first pays '
                      'PKR ${MockScanRepository.prizeFor(user.role)!.formatted} '
                      'straight into your wallet.',
              },
            ),
            if (_busy) ...[
              const SizedBox(height: AppSpacing.md),
              const Center(child: CircularProgressIndicator()),
            ],
            const SizedBox(height: AppSpacing.lg),
            // No meta here: the header squeezes its title to fit one, and
            // the notice above already explains what these are for.
            const DsSectionHeader(title: 'Sample codes'),
            DsRowGroup(
              children: [
                for (final sample in MockScanRepository.sampleCodes)
                  DsSettingRow(
                    label: sample.code,
                    meta: mode == ScanMode.authenticity
                        ? _authenticityMeaning(sample.code)
                        : sample.meaning,
                    onTap: () {
                      _code.text = sample.code;
                      _check(user);
                    },
                  ),
              ],
            ),
          ] else
            _Result(
              outcome: outcome,
              onScanAgain: () => setState(() {
                _outcome = null;
                _code.clear();
              }),
            ),
        ],
      ),
    );
  }

  /// A prize and a claim mean nothing on this tab, so the samples say what an
  /// authenticity check will actually return.
  String _authenticityMeaning(String code) =>
      code.startsWith('CS-BAT') ? 'Blocked batch' : 'Genuine product';
}

class _Result extends StatelessWidget {
  const _Result({required this.outcome, required this.onScanAgain});

  final ScanOutcome outcome;
  final VoidCallback onScanAgain;

  ({IconData icon, DsTone tone, String title, String message}) get _verdict =>
      switch (outcome.verdict) {
        ScanVerdict.genuine => (
          icon: LucideIcons.badgeCheck,
          tone: DsTone.success,
          title: 'Genuine Crown Solar product',
          message: 'This code matches Crown Solar\'s factory records.',
        ),
        ScanVerdict.alreadyScanned => (
          icon: LucideIcons.circleAlert,
          tone: DsTone.warning,
          title: 'Already scanned',
          message:
              'This product is genuine, but its code has already been '
              'claimed. If you believe this is wrong, raise a complaint.',
        ),
        ScanVerdict.notRecognised => (
          icon: LucideIcons.circleX,
          tone: DsTone.error,
          title: 'Not recognised',
          message:
              'We cannot match this code. Check you scanned the Crown Solar '
              'label, and contact the team if it keeps failing.',
        ),
        ScanVerdict.blocked => (
          icon: LucideIcons.octagonAlert,
          tone: DsTone.error,
          title: 'Batch withdrawn',
          message:
              'Crown Solar has blocked this batch. Do not install it — '
              'contact the team for a replacement.',
        ),
      };

  @override
  Widget build(BuildContext context) {
    final verdict = _verdict;
    final product = outcome.product;
    final checking = outcome.mode == ScanMode.authenticity;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(child: DsTag(label: outcome.mode.label, uppercase: true)),
        const SizedBox(height: AppSpacing.md),
        Center(
          child: DsIconMedallion(
            icon: verdict.icon,
            tone: verdict.tone,
            size: 72,
            iconSize: 36,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Center(child: Text(verdict.title, style: context.texts.headlineSmall)),
        const SizedBox(height: AppSpacing.sm),
        DsBody(verdict.message, size: 14),
        if (product != null) ...[
          const SizedBox(height: AppSpacing.lg),
          DsCard(
            child: Column(
              children: [
                DsSettingRow(label: 'Product', value: product.name),
                DsSettingRow(label: 'Code', value: outcome.code),
                DsSettingRow(label: 'Origin', value: product.madeOn),
              ],
            ),
          ),
        ],
        if (outcome.claim != null) ...[
          const SizedBox(height: AppSpacing.md),
          DsCard(
            tone: DsCardTone.sunken,
            child: Column(
              children: [
                const DsSectionHeader(title: 'Claimed by'),
                DsSettingRow(label: 'Partner', value: outcome.claim!.name),
                DsSettingRow(label: 'Role', value: outcome.claim!.role),
                DsSettingRow(
                  label: 'Scanned on',
                  value: _dayOf(outcome.claim!.claimedAt),
                ),
              ],
            ),
          ),
        ],
        if (outcome.hasPrize) ...[
          const SizedBox(height: AppSpacing.md),
          DsCard(
            tone: DsCardTone.sunken,
            child: Column(
              children: [
                const DsCaption('YOU WON'),
                const SizedBox(height: 4),
                Text(
                  'PKR ${outcome.prizeCredited!.formatted}',
                  style: context.texts.headlineSmall?.copyWith(
                    color: context.status.success,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                const DsBody(
                  'Paid into your wallet now. It appears in your ledger as a '
                  'scan prize.',
                  size: 13,
                  align: TextAlign.center,
                ),
              ],
            ),
          ),
        ] else if (outcome.isGenuine && checking) ...[
          const SizedBox(height: AppSpacing.md),
          const DsNotice(
            icon: LucideIcons.info,
            message:
                'Nothing has been claimed. This code can still be scanned on '
                'the Scan to Win tab.',
          ),
        ] else if (outcome.isGenuine) ...[
          const SizedBox(height: AppSpacing.md),
          const DsNotice(
            icon: LucideIcons.info,
            message:
                'No prize on this one. Every genuine scan still counts '
                'towards your spin.',
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        DsButton(
          label: 'Scan Another',
          icon: LucideIcons.scanLine,
          onPressed: onScanAgain,
        ),
      ],
    );
  }
}

/// Product codes are printed in capitals, so they are typed that way too.
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) => TextEditingValue(
    text: newValue.text.toUpperCase(),
    selection: newValue.selection,
  );
}

/// "15 Sep 2026" — enough to place a claim without a full timestamp.
String _dayOf(DateTime when) {
  const months = [
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
  return '${when.day} ${months[when.month - 1]} ${when.year}';
}
