import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../../core/scanner/qr_scanner_screen.dart';
import '../../../../core/ui/ds.dart';
import '../../../profile/data/contacts_repository.dart';
import '../../../session/ui/session_controller.dart';
import '../../data/points_service.dart';

/// Board 06 · A2–A4 — sending points.
///
/// Three ways to choose someone and no fourth: there is deliberately no
/// search-by-number, because points arrive instantly and cannot be recalled,
/// so a mistyped digit is not recoverable by the partner.
class SendPointsScreen extends StatefulWidget {
  const SendPointsScreen({super.key});

  @override
  State<SendPointsScreen> createState() => _SendPointsScreenState();
}

class _SendPointsScreenState extends State<SendPointsScreen> {
  final _amount = TextEditingController();

  PointsLedger? _ledger;
  List<PointRecipient>? _recipients;

  PointRecipient? _chosen;
  PointTransferReceipt? _sent;
  PointTransferFailure? _failure;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final user = context.read<SessionController>().user;
    if (user == null) return;
    final service = context.read<PointsService>();

    final ledger = await service.ledger(user.mobileNumber);
    final recipients = await service.recipients(user.mobileNumber);
    if (!mounted) return;
    setState(() {
      _ledger = ledger ?? PointsLedger.empty;
      _recipients = recipients ?? const [];
    });
  }

  int get _balance => _ledger?.balance ?? 0;
  int get _amountValue => int.tryParse(_amount.text.trim()) ?? 0;

  @override
  Widget build(BuildContext context) {
    final ledger = _ledger;
    if (ledger == null) {
      return Scaffold(
        appBar: DsAppBar(
          title: 'Send Points',
          onBack: () => Navigator.of(context).maybePop(),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_sent != null) return _sentScreen(_sent!);
    if (!ledger.canSend) return _restrictedScreen(ledger);
    if (_chosen != null) return _confirmScreen(_chosen!);
    return _recipientScreen();
  }

  // --- A2 · choosing someone ------------------------------------------------

  Widget _recipientScreen() {
    final recents = [
      for (final recipient in _recipients ?? const <PointRecipient>[])
        if (recipient.sentBefore) recipient,
    ];

    return DsScreen(
      appBar: DsAppBar(
        title: 'Send Points',
        subtitle: '${formatPoints(_balance)} available',
        onBack: () => Navigator.of(context).maybePop(),
      ),
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      gap: AppSpacing.md,
      sections: [
        Row(
          children: [
            Expanded(
              child: _PathTile(
                icon: LucideIcons.contact,
                label: 'Contacts',
                onTap: _pickFromContacts,
              ),
            ),
            const SizedBox(width: AppSpacing.stepMd),
            Expanded(
              child: _PathTile(
                icon: LucideIcons.qrCode,
                label: 'Scan QR',
                onTap: _pickByScanning,
              ),
            ),
            const SizedBox(width: AppSpacing.stepMd),
            Expanded(
              child: _PathTile(
                icon: LucideIcons.history,
                label: 'History',
                onTap: () => _pickFrom(
                  title: 'History',
                  people: recents,
                  empty: 'You have not sent points to anyone yet.',
                ),
              ),
            ),
          ],
        ),
        const DsNotice(
          icon: LucideIcons.info,
          message:
              'Points have no search-by-number option. You can send only to '
              'people in your contacts, from your history, or by scanning '
              'their QR in person.',
        ),
        const DsSectionHeader(title: 'Recent recipients'),
        if (recents.isEmpty)
          const DsEmptyState(
            icon: LucideIcons.history,
            title: 'No history yet',
            message:
                'Partners you send points to appear here, so the next '
                'transfer takes two taps.',
          )
        else
          DsCard(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Column(
              children: [
                for (var i = 0; i < recents.length; i++) ...[
                  DsPartyRow(
                    name: recents[i].name,
                    meta: recents[i].historyLine,
                    trailing: DsTag(label: recents[i].role),
                    onTap: () => _choose(recents[i]),
                  ),
                  if (i != recents.length - 1) const DsHairline(),
                ],
              ],
            ),
          ),
        const DsCaption(
          'Installers hold no points, so they never appear in this list even '
          'if they are in your contacts.',
        ),
      ],
    );
  }

  void _choose(PointRecipient recipient) => setState(() {
    _chosen = recipient;
    _failure = null;
    _amount.clear();
  });

  /// Partners in the phone's synced address book who may also be paid.
  ///
  /// The intersection, not the address book: a contact this partner is not
  /// permitted to send to is not offered and then refused.
  Future<void> _pickFromContacts() async {
    final saved = await context.read<ContactsRepository>().saved();
    if (!mounted) return;

    final permitted = {
      for (final recipient in _recipients ?? const <PointRecipient>[])
        recipient.mobileNumber: recipient,
    };
    final matches = <PointRecipient>[];
    for (final contact in saved) {
      final match = permitted[_digits(contact.mobileNumber)];
      if (match != null && !matches.contains(match)) matches.add(match);
    }

    await _pickFrom(
      title: 'Contacts',
      people: matches,
      empty: saved.isEmpty
          ? 'No contacts synced yet. Sync them from Profile first.'
          : 'None of your synced contacts can receive points from you.',
    );
  }

  /// Reads a partner's profile QR, which carries their mobile number.
  Future<void> _pickByScanning() async {
    final user = context.read<SessionController>().user;
    if (user == null) return;

    final code = await QrScannerScreen.open(
      context,
      title: 'Scan QR',
      instruction: "Point the camera at the partner's profile QR code.",
    );
    if (!mounted || code == null) return;

    final messenger = ScaffoldMessenger.of(context);
    final found = await context.read<PointsService>().lookup(
      mobileNumber: user.mobileNumber,
      recipientNumber: code.trim(),
    );
    if (!mounted) return;

    if (found == null) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'That QR code is not a partner you can send points to.',
          ),
        ),
      );
      return;
    }
    _choose(found);
  }

  Future<void> _pickFrom({
    required String title,
    required List<PointRecipient> people,
    required String empty,
  }) async {
    final chosen = await showModalBottomSheet<PointRecipient>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => DsSheet(
        title: title,
        child: people.isEmpty
            ? Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: DsBody(empty, size: 14),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final person in people)
                    DsPartyRow(
                      name: person.name,
                      meta: person.historyLine ?? person.role,
                      trailing: DsTag(label: person.role),
                      onTap: () => Navigator.of(context).pop(person),
                    ),
                ],
              ),
      ),
    );
    if (chosen != null) _choose(chosen);
  }

  // --- A3 · the amount, and confirming --------------------------------------

  Widget _confirmScreen(PointRecipient recipient) {
    final amount = _amountValue;
    final enough = amount > 0 && amount <= _balance;

    return DsScreen(
      appBar: DsAppBar(
        title: 'Send Points',
        onBack: () => setState(() {
          _chosen = null;
          _failure = null;
        }),
      ),
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      gap: 18,
      footer: DsFooterBar(
        child: Column(
          children: [
            DsButton(
              label: amount == 0
                  ? 'Send Points'
                  : 'Send ${formatPoints(amount)} Points',
              loading: _sending,
              disabled: !enough || _sending,
              onPressed: () => _send(recipient),
            ),
            const SizedBox(height: 10),
            DsButton(
              label: 'Go Back',
              variant: DsButtonVariant.quiet,
              onPressed: () => setState(() {
                _chosen = null;
                _failure = null;
              }),
            ),
          ],
        ),
      ),
      sections: [
        DsCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: DsPartyRow(
            name: recipient.name,
            meta: '${recipient.role} · +92 ${recipient.mobileNumber}',
          ),
        ),
        Column(
          children: [
            Text(
              'POINTS TO SEND',
              style: TextStyle(
                fontSize: 12,
                letterSpacing: 0.06 * 12,
                fontWeight: FontWeight.w600,
                color: context.palette.textTertiary,
              ),
            ),
            const SizedBox(height: 10),
            DsInput(
              controller: _amount,
              placeholder: '0',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (_) => setState(() => _failure = null),
            ),
            const SizedBox(height: 6),
            DsBody(
              amount == 0
                  ? 'You hold ${formatPoints(_balance)} points'
                  : 'You will have ${formatPoints(_balance - amount)} points '
                        'left',
              align: TextAlign.center,
            ),
          ],
        ),
        // The warning is the point of this screen: after the button there is
        // no approval step and no way back.
        DsCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                amount == 0
                    ? 'Send points?'
                    : 'Send ${formatPoints(amount)} points?',
                style: context.texts.bodyLarge?.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              DsBody(
                'Points arrive with ${recipient.name} straight away. There is '
                'no approval step and they cannot reject it. If you send to '
                'the wrong person, only Crown Solar CRM can adjust it.',
              ),
            ],
          ),
        ),
        if (_failure != null) _Refusal(failure: _failure!, balance: _balance),
      ],
    );
  }

  Future<void> _send(PointRecipient recipient) async {
    final user = context.read<SessionController>().user;
    if (user == null) return;

    setState(() {
      _sending = true;
      _failure = null;
    });

    final (receipt, failure) = await context.read<PointsService>().send(
      fromMobileNumber: user.mobileNumber,
      toMobileNumber: recipient.mobileNumber,
      amount: _amountValue,
    );
    if (!mounted) return;

    setState(() {
      _sending = false;
      _sent = receipt;
      _failure = failure;
    });
    // The balance moved, or a refusal named a figure that has to be current.
    await _load();
  }

  // --- A4 · sent ------------------------------------------------------------

  Widget _sentScreen(PointTransferReceipt receipt) {
    final recipient = _chosen;
    return DsScreen(
      appBar: DsAppBar(title: 'Send Points'),
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      gap: AppSpacing.stepMd,
      footer: DsFooterBar(
        child: Column(
          children: [
            DsButton(
              label: 'Done',
              onPressed: () => Navigator.of(context).maybePop(),
            ),
            const SizedBox(height: 10),
            DsButton(
              label: 'Send More Points',
              variant: DsButtonVariant.quiet,
              onPressed: () => setState(() {
                _sent = null;
                _chosen = null;
                _amount.clear();
              }),
            ),
          ],
        ),
      ),
      sections: [
        DsCard(
          radius: AppRadii.heroRadius,
          padding: const EdgeInsets.all(AppSpacing.stepLg),
          child: Column(
            children: [
              const DsIconMedallion(
                icon: LucideIcons.circleCheck,
                tone: DsTone.success,
                size: 64,
                iconSize: 30,
              ),
              const SizedBox(height: 14),
              Text(
                '${formatPoints(receipt.amount)} points sent',
                textAlign: TextAlign.center,
                style: context.texts.titleLarge,
              ),
              const SizedBox(height: AppSpacing.sm),
              DsBody(
                '${recipient?.name ?? 'They'} has them now and has been '
                'notified. Ref ${receipt.reference} · '
                '${formatPointsWhen(receipt.sentAt)}',
                size: 14,
                align: TextAlign.center,
              ),
            ],
          ),
        ),
        DsCard(
          tone: DsCardTone.sunken,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your balance now',
                style: context.texts.bodyLarge?.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              DsBody(
                '${formatPoints(receipt.balance)} points. Points you send out '
                'reduce your balance and do not count toward your target.',
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- The restriction that stops the flow before it starts -----------------

  Widget _restrictedScreen(PointsLedger ledger) => DsScreen(
    appBar: DsAppBar(
      title: 'Send Points',
      onBack: () => Navigator.of(context).maybePop(),
    ),
    padding: const EdgeInsets.all(AppSpacing.screenPadding),
    gap: AppSpacing.md,
    sections: [
      _Refusal(
        failure: PointTransferFailure.senderRestricted,
        balance: ledger.balance,
      ),
      if (ledger.restrictionReason != null)
        DsCard(
          tone: DsCardTone.sunken,
          child: DsBody('Reason given: ${ledger.restrictionReason}'),
        ),
      const DsCaption(
        'Your balance and your ledger are unaffected. Only sending is '
        'stopped.',
      ),
    ],
  );

  /// Ten national digits, so a contact saved as +92 300… matches an account
  /// stored as 300….
  static String _digits(String number) {
    final only = number.replaceAll(RegExp(r'\D'), '');
    if (only.length > 10) return only.substring(only.length - 10);
    return only;
  }
}

class _PathTile extends StatelessWidget {
  const _PathTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.colors.surface,
      borderRadius: AppRadii.mdRadius,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.mdRadius,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: AppRadii.mdRadius,
            border: Border.all(color: context.colors.outline),
          ),
          child: Column(
            children: [
              DsIconMedallion(
                icon: icon,
                size: 36,
                iconSize: 19,
                rounded: true,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One refusal, stating its own reason — because each has its own remedy.
class _Refusal extends StatelessWidget {
  const _Refusal({required this.failure, required this.balance});

  final PointTransferFailure failure;
  final int balance;

  @override
  Widget build(BuildContext context) {
    return DsCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const DsIconMedallion(
            icon: LucideIcons.circleAlert,
            tone: DsTone.warning,
            size: 34,
            iconSize: 17,
          ),
          const SizedBox(width: AppSpacing.stepMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  failure.title,
                  style: context.texts.bodyLarge?.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                DsBody(failure.message(balance)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
