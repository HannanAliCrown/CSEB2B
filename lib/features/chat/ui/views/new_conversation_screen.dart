import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../../core/scanner/qr_scanner_screen.dart';
import '../../../../core/ui/ds.dart';
import '../../../profile/data/contacts_repository.dart';
import '../../data/chat_repository.dart';

/// Board 10 · B1 — three ways to start a conversation.
///
/// Contacts are the partners found by syncing the address book; Scan QR reads
/// a partner's profile code; Departments are the Crown Solar teams every
/// partner can reach without knowing anyone's number.
class NewConversationScreen extends StatefulWidget {
  const NewConversationScreen({super.key, required this.onOpenThread});

  final ValueChanged<ChatParty> onOpenThread;

  @override
  State<NewConversationScreen> createState() => _NewConversationScreenState();
}

class _NewConversationScreenState extends State<NewConversationScreen> {
  String _path = 'Departments';
  final _number = TextEditingController();

  List<SyncedContact> _contacts = const [];
  bool _contactsLoaded = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadContacts());
  }

  @override
  void dispose() {
    _number.dispose();
    super.dispose();
  }

  Future<void> _loadContacts() async {
    final saved = await context.read<ContactsRepository>().saved();
    if (!mounted) return;
    setState(() {
      _contacts = saved;
      _contactsLoaded = true;
    });
  }

  Future<void> _openNumber(String mobileNumber) async {
    final party = await context.read<ChatRepository>().partyForNumber(
      mobileNumber,
    );
    if (!mounted) return;
    if (party == null) {
      setState(() => _error = 'No Crown Solar account uses this number.');
      return;
    }
    setState(() => _error = null);
    widget.onOpenThread(party);
  }

  Future<void> _scan() async {
    final code = await QrScannerScreen.open(
      context,
      title: 'Scan Profile QR',
      instruction:
          'Point the camera at the partner\'s Crown Solar profile QR code.',
    );
    if (!mounted || code == null) return;
    await _openNumber(code);
  }

  @override
  Widget build(BuildContext context) {
    return DsScreen(
      appBar: DsAppBar(
        title: 'New Conversation',
        onBack: () => Navigator.of(context).maybePop(),
      ),
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      gap: AppSpacing.md,
      sections: [
        DsSegmentedControl(
          options: const ['Contacts', 'Scan QR', 'Departments'],
          value: _path,
          onChanged: (value) {
            setState(() {
              _path = value;
              _error = null;
            });
            if (value == 'Scan QR') _scan();
          },
        ),
        ...switch (_path) {
          'Contacts' => _contactsSection(context),
          'Scan QR' => _scanSection(context),
          _ => _departmentsSection(context),
        },
        const DsCaption(
          'Only contacts already registered on Crown Solar Energy appear '
          'under Contacts. Numbers without an account are never stored.',
        ),
      ],
    );
  }

  List<Widget> _contactsSection(BuildContext context) => [
    DsSectionHeader(title: '${_contacts.length} matched contacts'),
    if (!_contactsLoaded)
      const Center(child: CircularProgressIndicator())
    else if (_contacts.isEmpty)
      const DsEmptyState(
        icon: LucideIcons.contact,
        title: 'No contacts synced yet',
        message:
            'Sync your contacts from Profile to find which of them are on '
            'Crown Solar.',
      )
    else
      DsCard(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: Column(
          children: [
            for (var i = 0; i < _contacts.length; i++) ...[
              DsPartyRow(
                name: _contacts[i].businessName,
                meta: '${_contacts[i].role} · ${_contacts[i].mobileNumber}',
                onTap: () => _openNumber(_contacts[i].mobileNumber),
              ),
              if (i != _contacts.length - 1) const DsHairline(),
            ],
          ],
        ),
      ),
  ];

  List<Widget> _scanSection(BuildContext context) => [
    DsButton(label: 'Open Camera', icon: LucideIcons.camera, onPressed: _scan),
    const DsNotice(
      icon: LucideIcons.info,
      message:
          'Scanning a partner\'s profile QR opens a chat with them. You can '
          'also type their number below.',
    ),
    DsInput(
      label: 'Mobile number',
      placeholder: '0300 7781204',
      controller: _number,
      keyboardType: TextInputType.phone,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9+]')),
        LengthLimitingTextInputFormatter(13),
      ],
      error: _error,
      suffix: GestureDetector(
        onTap: () => _openNumber(_number.text),
        child: Icon(
          LucideIcons.search,
          size: 18,
          color: context.colors.primary,
        ),
      ),
    ),
  ];

  List<Widget> _departmentsSection(BuildContext context) => [
    const DsSectionHeader(title: 'Crown Solar departments'),
    DsCard(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(
        children: [
          for (var i = 0; i < Department.values.length; i++) ...[
            DsSettingRow(
              label: Department.values[i].title,
              meta: Department.values[i].purpose,
              leading: DsIconMedallion(
                icon: switch (Department.values[i]) {
                  Department.crm => LucideIcons.headset,
                  Department.branding => LucideIcons.store,
                  Department.technicalSupport => LucideIcons.wrench,
                  Department.accounts => LucideIcons.wallet,
                },
                size: 36,
                iconSize: 18,
                rounded: true,
              ),
              onTap: () => widget.onOpenThread(
                ChatParty.department(Department.values[i]),
              ),
            ),
            if (i != Department.values.length - 1) const DsHairline(),
          ],
        ],
      ),
    ),
  ];
}
