import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

import '../../../../core/ui/ds.dart';
import '../../../session/data/signed_in_user.dart';
import '../../../session/ui/session_controller.dart';
import '../../data/contacts_repository.dart';

/// Board 11 · 1 — Profile: the facts that came from registration, then the
/// settings that belong to this phone.
class ProfileTab extends StatefulWidget {
  const ProfileTab({
    super.key,
    required this.onShowQrCode,
    required this.onSyncContacts,
    required this.onSignOut,
  });

  final VoidCallback onShowQrCode;
  final VoidCallback onSyncContacts;
  final VoidCallback onSignOut;

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  int _syncedCount = 0;
  DateTime? _syncedAt;
  String _version = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final repository = context.read<ContactsRepository>();
    final saved = await repository.saved();
    final at = await repository.lastSyncedAt();
    final info = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() {
      _syncedCount = saved.length;
      _syncedAt = at;
      _version = info.version;
    });
  }

  /// "AS" from "Adnan Solar Works".
  String _initials(String name) {
    final words = name.trim().split(RegExp(r'\s+'));
    if (words.isEmpty || words.first.isEmpty) return '?';
    if (words.length == 1) return words.first[0].toUpperCase();
    return '${words[0][0]}${words[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<SessionController>().user;
    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      appBar: DsAppBar(
        title: 'Profile',
        actions: [
          DsIconButton(
            icon: LucideIcons.qrCode,
            onPressed: widget.onShowQrCode,
          ),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            children: [
              DsCard(
                radius: AppRadii.heroRadius,
                padding: const EdgeInsets.all(AppSpacing.stepLg),
                child: Row(
                  children: [
                    DsAvatar(initials: _initials(user.businessName), size: 56),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            user.contactName,
                            style: context.texts.titleLarge,
                          ),
                          Text(
                            user.businessName,
                            style: context.texts.bodyMedium?.copyWith(
                              color: context.colors.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Row(
                            children: [
                              DsTag(label: user.role.label, uppercase: true),
                              const SizedBox(width: 6),
                              DsTag(
                                label: user.approved ? 'Active' : 'Pending',
                                tone: user.approved
                                    ? DsTone.success
                                    : DsTone.warning,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              DsRowGroup(
                children: [
                  DsSettingRow(label: 'Mobile', value: user.mobileNumber),
                  DsSettingRow(label: 'Business', value: user.businessName),
                  DsSettingRow(label: 'Role', value: user.role.label),
                  DsSettingRow(label: 'Market', value: user.market),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              const DsCaption(
                'Name, market and role come from your registration. Contact '
                'CRM to change them.',
              ),
              const SizedBox(height: AppSpacing.md),
              DsRowGroup(
                children: [
                  _SettingsRow(
                    icon: LucideIcons.contact,
                    label: 'Sync Contacts',
                    meta: _syncedCount == 0
                        ? 'Not synced yet'
                        : '$_syncedCount matched'
                              '${_syncedAt == null ? '' : ' · synced ${_day(_syncedAt!)}'}',
                    onTap: widget.onSyncContacts,
                  ),
                  _SettingsRow(
                    icon: LucideIcons.lockKeyhole,
                    label: 'App Security',
                    meta: 'Not built yet',
                    onTap: () => _notBuilt('App Security'),
                  ),
                  _SettingsRow(
                    icon: LucideIcons.languages,
                    label: 'Language',
                    meta: 'Not built yet',
                    onTap: () => _notBuilt('Language'),
                  ),
                  _SettingsRow(
                    icon: LucideIcons.palette,
                    label: 'Colour Theme',
                    meta: 'Light',
                    onTap: () => _notBuilt('Colour Theme'),
                  ),
                  _SettingsRow(
                    icon: LucideIcons.info,
                    label: 'About App',
                    meta: _version.isEmpty ? '' : 'Version $_version',
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              DsCard(
                onTap: _confirmSignOut,
                child: Row(
                  children: [
                    DsIconMedallion(
                      icon: LucideIcons.logOut,
                      tone: DsTone.error,
                      size: 36,
                      iconSize: 18,
                      rounded: true,
                    ),
                    const SizedBox(width: AppSpacing.stepMd),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Sign Out',
                            style: context.texts.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: context.status.error,
                            ),
                          ),
                          const DsCaption(
                            'You will need your mobile number again',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Board 11 · 11 — signing out is confirmed first, because it costs the
  /// partner their session and nothing on this screen warns them otherwise.
  Future<void> _confirmSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: const Color(0xFF0F172A).withValues(alpha: 0.45),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.all(AppSpacing.lg),
        child: DsDialogCard(
          icon: LucideIcons.logOut,
          tone: DsTone.error,
          title: 'Sign out of Crown Solar?',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              const DsBody(
                'You will need your mobile number to sign in again. Your '
                'phone stays the one your account is fixed to, so no SMS '
                'code is needed.',
                size: 14,
              ),
              const SizedBox(height: AppSpacing.md),
              DsButton(
                label: 'Sign Out',
                variant: DsButtonVariant.destructive,
                onPressed: () => Navigator.of(context).pop(true),
              ),
              const SizedBox(height: 10),
              DsButton(
                label: 'Stay Signed In',
                variant: DsButtonVariant.quiet,
                onPressed: () => Navigator.of(context).pop(false),
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed == true) widget.onSignOut();
  }

  void _notBuilt(String what) =>
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('$what is not built yet.')));

  String _day(DateTime when) {
    final gap = DateTime.now().difference(when);
    if (gap.inDays == 0) return 'today';
    if (gap.inDays == 1) return 'yesterday';
    return '${gap.inDays} days ago';
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.label,
    required this.meta,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String meta;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => DsSettingRow(
    label: label,
    meta: meta,
    onTap: onTap,
    leading: DsIconMedallion(icon: icon, size: 36, iconSize: 18, rounded: true),
    trailing: Icon(
      LucideIcons.chevronRight,
      size: 18,
      color: context.palette.textTertiary,
    ),
  );
}
