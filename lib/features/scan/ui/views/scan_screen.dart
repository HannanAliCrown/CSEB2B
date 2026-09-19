import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../../core/ui/ds.dart';
import '../../../session/data/signed_in_user.dart';
import '../../../session/ui/session_controller.dart';
import '../../data/scan_repository.dart';

/// Scan QR: check a product is genuine, and claim anything it wins.
///
/// There is no camera here yet, so the code is entered or picked from the
/// sample list — the verdict comes from [ScanRepository] either way, never
/// from this screen.
class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final _code = TextEditingController();
  bool _busy = false;
  ScanOutcome? _outcome;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _check(SignedInUser user) async {
    final code = _code.text.trim();
    if (code.isEmpty) return;

    setState(() => _busy = true);
    final outcome = await context.read<ScanRepository>().check(
      code: code,
      user: user,
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

    return Scaffold(
      appBar: DsAppBar(
        title: 'Scan QR',
        subtitle: user.role.earnsPrizes
            ? 'Check a product or claim a prize'
            : 'Check a product is genuine',
        onBack: () => Navigator.of(context).maybePop(),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        children: [
          if (outcome == null) ...[
            const DsNotice(
              icon: LucideIcons.camera,
              message:
                  'The camera scanner is not wired up yet. Enter a code from '
                  'the box, or pick one of the samples below.',
            ),
            const SizedBox(height: AppSpacing.md),
            DsInput(
              label: 'Product code',
              placeholder: 'CS-INV-8841',
              controller: _code,
              inputFormatters: [UpperCaseTextFormatter()],
            ),
            const SizedBox(height: AppSpacing.md),
            DsButton(
              label: 'Check This Code',
              icon: LucideIcons.scanLine,
              loading: _busy,
              onPressed: () => _check(user),
            ),
            const SizedBox(height: AppSpacing.lg),
            const DsSectionHeader(title: 'Sample codes'),
            DsRowGroup(
              children: [
                for (final sample in MockScanRepository.sampleCodes)
                  DsSettingRow(
                    label: sample.code,
                    meta: sample.meaning,
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
        ScanVerdict.notReleased => (
          icon: LucideIcons.clock,
          tone: DsTone.warning,
          title: 'Not released yet',
          message:
              'This code exists but the batch has not left the plant. Try '
              'again once the product is on sale.',
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
        if (outcome.hasPrize) ...[
          const SizedBox(height: AppSpacing.md),
          DsNotice(
            icon: LucideIcons.gift,
            tone: DsTone.solar,
            title: 'You won ${outcome.prize}',
            message:
                'PKR ${outcome.prizeCredited!.formatted} has been credited to '
                'your wallet.',
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
