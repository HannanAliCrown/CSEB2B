import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../../core/ui/ds.dart';
import '../../data/wallet_repository.dart';
import '../wallet_view_model.dart';

/// How the partner is choosing who to pay (board 04 · A1).
enum _Path { contacts, scan, history, search }

/// Send Cash, as board 04 lays it out: four ways to choose a recipient, an
/// amount screen with quick amounts, a review sheet that states the held rule
/// before sending, and a result deliberately not called a payment.
class SendCashScreen extends StatefulWidget {
  const SendCashScreen({super.key});

  @override
  State<SendCashScreen> createState() => _SendCashScreenState();
}

class _SendCashScreenState extends State<SendCashScreen> {
  final _search = TextEditingController();
  final _custom = TextEditingController();

  _Path _path = _Path.history;
  bool _customOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<WalletViewModel>().load(),
    );
  }

  @override
  void dispose() {
    _search.dispose();
    _custom.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wallet = context.watch<WalletViewModel>();

    return PopScope(
      canPop: wallet.step == SendCashStep.recipient,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) wallet.back();
      },
      child: switch (wallet.step) {
        SendCashStep.recipient => _recipient(context, wallet),
        SendCashStep.amount => _amount(context, wallet),
        SendCashStep.review => _review(context, wallet),
        SendCashStep.sent => _sent(context, wallet),
      },
    );
  }

  // --- A1 · who to pay ---------------------------------------------------

  static const _paths = [
    (
      _Path.contacts,
      LucideIcons.contact,
      'Contacts',
      'Registered contacts only',
    ),
    (_Path.scan, LucideIcons.qrCode, 'Scan QR', 'Their profile QR code'),
    (_Path.history, LucideIcons.history, 'History', 'Most recent first'),
    (
      _Path.search,
      LucideIcons.search,
      'Search Number',
      'Find by mobile number',
    ),
  ];

  Widget _recipient(BuildContext context, WalletViewModel wallet) {
    return DsScreen(
      appBar: DsAppBar(
        title: 'Send Cash',
        subtitle: 'Available PKR ${wallet.balance.formatted}',
        onBack: () => Navigator.of(context).maybePop(),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        18,
        AppSpacing.screenPadding,
        18,
      ),
      gap: AppSpacing.md,
      sections: [
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: AppSpacing.stepMd,
          mainAxisSpacing: AppSpacing.stepMd,
          mainAxisExtent: 104,
          children: [
            for (final (path, icon, label, meta) in _paths)
              _PathCard(
                icon: icon,
                label: label,
                meta: meta,
                selected: _path == path,
                onTap: () => _choosePath(path),
              ),
          ],
        ),
        if (_path == _Path.search)
          DsInput(
            label: 'Mobile number',
            placeholder: '0300 7781204',
            controller: _search,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9+]')),
              LengthLimitingTextInputFormatter(13),
            ],
            error: wallet.error,
            suffix: GestureDetector(
              onTap: () => wallet.lookupRecipient(_search.text),
              child: Icon(
                LucideIcons.search,
                size: 18,
                color: context.colors.primary,
              ),
            ),
          ),
        DsSectionHeader(title: _path == _Path.contacts ? 'Contacts' : 'Recent'),
        if (wallet.busy && wallet.recipients.isEmpty)
          const Padding(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (wallet.recipients.isEmpty)
          const DsEmptyState(
            title: 'Nobody to pay yet',
            message: 'Partners you can send cash to appear here.',
            icon: LucideIcons.users,
          )
        else
          DsCard(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Column(
              children: [
                for (var i = 0; i < wallet.recipients.length; i++) ...[
                  DsPartyRow(
                    name: wallet.recipients[i].name,
                    meta: wallet.recipients[i].mobileNumber,
                    trailing: DsTag(label: wallet.recipients[i].role),
                    onTap: () => wallet.chooseRecipient(wallet.recipients[i]),
                  ),
                  if (i != wallet.recipients.length - 1) const DsHairline(),
                ],
              ],
            ),
          ),
        const DsNotice(
          message:
              'Only people already registered on Crown Solar Energy appear '
              'here. Numbers with no account are not shown and not saved.',
          dense: true,
        ),
      ],
    );
  }

  void _choosePath(_Path path) {
    if (path == _Path.scan) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Scanning a profile QR code is not wired up yet.'),
        ),
      );
      return;
    }
    setState(() => _path = path);
  }

  // --- A2 · how much -----------------------------------------------------

  /// The quick amounts the design offers, in rupees.
  static const _quickAmounts = [10000, 25000, 50000];

  Widget _amount(BuildContext context, WalletViewModel wallet) {
    final person = wallet.recipient!;
    final entered = wallet.amount;
    final after = wallet.balance - entered;
    final problem = wallet.amountProblem ?? wallet.error;

    return DsScreen(
      appBar: DsAppBar(
        title: 'Amount',
        onBack: () => Navigator.of(context).maybePop(),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        18,
        AppSpacing.screenPadding,
        18,
      ),
      gap: 18,
      footer: DsFooterBar(
        child: DsButton(
          label: 'Review',
          iconAfter: LucideIcons.arrowRight,
          disabled: !wallet.canReview,
          onPressed: wallet.review,
        ),
      ),
      sections: [
        DsCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: DsPartyRow(
            name: person.name,
            meta: '${person.role} · ${person.mobileNumber}',
            trailing: const DsStatusPill(
              label: 'Verified',
              icon: LucideIcons.circleCheck,
              tone: DsTone.success,
              small: true,
            ),
          ),
        ),
        Column(
          children: [
            Text(
              'AMOUNT TO SEND',
              style: TextStyle(
                fontSize: 12,
                letterSpacing: 0.06 * 12,
                fontWeight: FontWeight.w600,
                color: context.palette.textTertiary,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  'PKR',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: context.palette.textTertiary,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      entered.isZero ? '0' : entered.formatted,
                      style: const TextStyle(
                        fontSize: 38,
                        height: 44 / 38,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.02 * 38,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            DsBody(
              problem ?? 'Available after sending · PKR ${after.formatted}',
              color: problem == null ? null : context.status.error,
              align: TextAlign.center,
            ),
          ],
        ),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final value in _quickAmounts)
              _AmountChip(
                label: Money.rupees(value).formatted,
                selected: !_customOpen && entered == Money.rupees(value),
                onTap: () {
                  setState(() => _customOpen = false);
                  wallet.setAmount('$value');
                },
              ),
            _AmountChip(
              label: 'Custom',
              dashed: true,
              icon: LucideIcons.pencil,
              selected: _customOpen,
              onTap: () => setState(() => _customOpen = true),
            ),
          ],
        ),
        if (_customOpen)
          DsInput(
            label: 'Custom amount',
            placeholder: '0',
            prefix: Text('PKR', style: context.texts.bodyLarge),
            controller: _custom,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: wallet.setAmount,
          ),
        DsInput(
          label: 'Note',
          placeholder: 'Optional · what this is for',
          onChanged: wallet.setNote,
        ),
      ],
    );
  }

  // --- A3 · the review sheet ---------------------------------------------

  Widget _review(BuildContext context, WalletViewModel wallet) {
    final person = wallet.recipient!;
    final amount = 'PKR ${wallet.amount.formatted}';

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A).withValues(alpha: 0.45),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            DsSheet(
              title: 'Check before sending',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  DsRowGroup(
                    children: [
                      DsSettingRow(
                        label: 'To',
                        value: '${person.name} · ${person.role}',
                      ),
                      DsSettingRow(label: 'Number', value: person.mobileNumber),
                      DsSettingRow(label: 'Amount', value: amount),
                      if (wallet.note.trim().isNotEmpty)
                        DsSettingRow(label: 'Note', value: wallet.note),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  DsNotice(
                    icon: LucideIcons.hand,
                    tone: DsTone.info,
                    message:
                        '$amount leaves your wallet now and is held. '
                        '${person.name} receives it only after they approve. '
                        'If they reject it, or do not act in time, the money '
                        'comes back to you.',
                  ),
                  if (wallet.error != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    DsNotice(
                      icon: LucideIcons.circleAlert,
                      tone: DsTone.error,
                      message: wallet.error!,
                    ),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  DsButton(
                    label: 'Send $amount',
                    loading: wallet.busy,
                    onPressed: wallet.send,
                  ),
                  const SizedBox(height: 10),
                  DsButton(
                    label: 'Go Back',
                    variant: DsButtonVariant.quiet,
                    onPressed: wallet.back,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- A4 · held, awaiting approval --------------------------------------

  Widget _sent(BuildContext context, WalletViewModel wallet) {
    final entry = wallet.result!.entry!;
    final person = wallet.recipient!;
    final amount = 'PKR ${entry.amount.formatted}';

    return DsScreen(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      gap: AppSpacing.stepLg,
      footer: DsFooterBar(
        child: Column(
          children: [
            DsButton(
              label: 'Done',
              onPressed: () => Navigator.of(context).maybePop(),
            ),
            const SizedBox(height: 10),
            DsButton(
              label: 'Send More Cash',
              variant: DsButtonVariant.secondary,
              onPressed: () {
                _search.clear();
                _custom.clear();
                setState(() => _customOpen = false);
                wallet.reset();
              },
            ),
          ],
        ),
      ),
      sections: [
        const Center(
          child: DsIconMedallion(
            icon: LucideIcons.hand,
            tone: DsTone.info,
            size: 80,
            iconSize: 38,
          ),
        ),
        Column(
          children: [
            Text(
              '$amount is held',
              textAlign: TextAlign.center,
              style: context.texts.headlineSmall,
            ),
            const SizedBox(height: 10),
            DsBody(
              '${person.name} has been notified. The money reaches them when '
              'they approve, and returns to you if they reject it or it '
              'expires.',
              size: 15,
              align: TextAlign.center,
            ),
          ],
        ),
        DsRowGroup(
          children: [
            DsSettingRow(label: 'Reference', value: entry.id),
            DsSettingRow(label: 'To', value: person.name),
            DsSettingRow(label: 'Amount', value: amount),
            DsSettingRow(
              label: 'Balance now',
              value: 'PKR ${wallet.balance.formatted}',
            ),
          ],
        ),
        const DsCaption(
          'This is not a completed payment. Your ledger shows it as held '
          'until the recipient answers.',
          align: TextAlign.center,
        ),
      ],
    );
  }
}

/// One of the four ways to choose a recipient.
class _PathCard extends StatelessWidget {
  const _PathCard({
    required this.icon,
    required this.label,
    required this.meta,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String meta;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? context.palette.accentSoft : context.colors.surface,
          borderRadius: AppRadii.mdRadius,
          border: Border.all(
            color: selected ? context.colors.primary : context.colors.outline,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DsIconMedallion(icon: icon, size: 36, iconSize: 19, rounded: true),
            const SizedBox(height: AppSpacing.sm),
            Text(
              label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            Text(
              meta,
              style: TextStyle(
                fontSize: 11,
                height: 15 / 11,
                color: context.palette.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AmountChip extends StatelessWidget {
  const _AmountChip({
    required this.label,
    this.selected = false,
    this.dashed = false,
    this.icon,
    this.onTap,
  });

  final String label;
  final bool selected;
  final bool dashed;
  final IconData? icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = selected
        ? context.colors.primary
        : dashed
        ? context.colors.onSurfaceVariant
        : context.colors.onSurface;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? context.palette.accentSoft : context.colors.surface,
          borderRadius: BorderRadius.circular(AppRadii.pill),
          border: Border.all(
            color: selected
                ? context.colors.primary
                : dashed
                ? context.palette.borderStrong
                : context.colors.outline,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 13, color: foreground),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: foreground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
