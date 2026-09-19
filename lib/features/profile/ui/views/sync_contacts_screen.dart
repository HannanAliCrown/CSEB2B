import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../../../../core/ui/ds.dart';
import '../../data/contacts_repository.dart';

/// Board 11 · 3 — Sync Contacts: what it does, what it keeps, and what it
/// throws away.
///
/// Only numbers that already belong to a Crown Solar partner are kept.
/// Everything else is compared in memory and discarded — the screen says so
/// before the partner agrees, and again afterwards with the real count.
class SyncContactsScreen extends StatefulWidget {
  const SyncContactsScreen({super.key});

  @override
  State<SyncContactsScreen> createState() => _SyncContactsScreenState();
}

class _SyncContactsScreenState extends State<SyncContactsScreen> {
  bool _busy = false;
  SyncResult? _result;
  List<SyncedContact> _saved = const [];
  DateTime? _syncedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadSaved());
  }

  Future<void> _loadSaved() async {
    final repository = context.read<ContactsRepository>();
    final saved = await repository.saved();
    final at = await repository.lastSyncedAt();
    if (!mounted) return;
    setState(() {
      _saved = saved;
      _syncedAt = at;
    });
  }

  Future<void> _sync() async {
    setState(() => _busy = true);
    final result = await context.read<ContactsRepository>().sync();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _result = result;
    });
    if (result.outcome == SyncOutcome.synced) await _loadSaved();
  }

  Future<void> _forget() async {
    await context.read<ContactsRepository>().forget();
    if (!mounted) return;
    setState(() => _result = null);
    await _loadSaved();
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;

    return DsScreen(
      appBar: DsAppBar(
        title: 'Sync Contacts',
        onBack: () => Navigator.of(context).maybePop(),
      ),
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      gap: AppSpacing.md,
      footer: DsFooterBar(
        child: Column(
          children: [
            DsButton(
              label: _saved.isEmpty ? 'Sync Contacts' : 'Sync Again',
              icon: LucideIcons.refreshCw,
              loading: _busy,
              onPressed: _sync,
            ),
            if (_saved.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.stepMd),
              DsButton(
                label: 'Forget Synced Contacts',
                variant: DsButtonVariant.quiet,
                onPressed: _forget,
              ),
            ],
          ],
        ),
      ),
      sections: [
        const DsNotice(
          icon: LucideIcons.shieldCheck,
          title: 'What happens to your contacts',
          message:
              'Your address book is read on this phone and compared with '
              'Crown Solar\'s partner records. Only numbers that already '
              'have a Crown Solar account are kept. Every other number is '
              'discarded straight away — nothing is uploaded.',
        ),
        if (result?.outcome == SyncOutcome.permissionRefused)
          DsNotice(
            icon: LucideIcons.circleAlert,
            tone: DsTone.warning,
            title: 'Contacts access is off',
            message:
                'Syncing needs permission to read your contacts. Turn it on '
                'for Crown Solar and try again.',
            action: DsButton(
              label: 'Open Settings',
              variant: DsButtonVariant.secondary,
              size: DsButtonSize.sm,
              onPressed: openAppSettings,
            ),
          ),
        if (result?.outcome == SyncOutcome.failed)
          const DsNotice(
            icon: LucideIcons.circleAlert,
            tone: DsTone.error,
            message: 'Your contacts could not be read. Try again.',
          ),
        if (result?.outcome == SyncOutcome.synced)
          DsNotice(
            icon: LucideIcons.circleCheck,
            tone: DsTone.success,
            title: '${result!.matched.length} partners matched',
            message:
                '${result.scanned} numbers were checked. '
                '${result.discarded} did not have a Crown Solar account and '
                'were discarded.',
          ),
        if (_saved.isEmpty)
          const DsEmptyState(
            title: 'No partners synced yet',
            message: 'Sync to find which of your contacts are on Crown Solar.',
            icon: LucideIcons.contact,
          )
        else ...[
          DsSectionHeader(
            title: '${_saved.length} matched partners',
            meta: _syncedAt == null ? null : 'Synced ${_ago(_syncedAt!)}',
          ),
          DsCard(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Column(
              children: [
                for (var i = 0; i < _saved.length; i++) ...[
                  DsPartyRow(
                    name: _saved[i].businessName,
                    meta:
                        '${_saved[i].mobileNumber} · saved as '
                        '${_saved[i].phoneName}',
                    trailing: DsTag(label: _saved[i].role),
                  ),
                  if (i != _saved.length - 1) const DsHairline(),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  /// "just now" / "2 hours ago" / "3 days ago".
  String _ago(DateTime when) {
    final gap = DateTime.now().difference(when);
    if (gap.inMinutes < 1) return 'just now';
    if (gap.inHours < 1) return '${gap.inMinutes} minutes ago';
    if (gap.inDays < 1) return '${gap.inHours} hours ago';
    return '${gap.inDays} days ago';
  }
}
