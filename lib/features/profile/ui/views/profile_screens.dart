import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/ui/ds.dart';
import '../../../home/ui/models/home_demo_data.dart';

/// Board 11 · 1 — Profile: the registration facts, then the settings that
/// belong to this phone.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: DsAppBar(
        title: 'Profile',
        onBack: () => Navigator.of(context).maybePop(),
        actions: [DsIconButton(icon: LucideIcons.qrCode, onPressed: () {})],
      ),
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          children: [
            DsCard(
              radius: AppRadii.heroRadius,
              padding: const EdgeInsets.all(AppSpacing.stepLg),
              child: Row(
                children: [
                  const DsAvatar(initials: 'AN', size: 56),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Ali Nawaz Butt', style: context.texts.titleLarge),
                        Text(
                          'Al-Noor Electric Store',
                          style: context.texts.bodyMedium?.copyWith(
                            color: context.colors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          children: const [
                            DsTag(label: 'Retailer', uppercase: true),
                            SizedBox(width: 6),
                            DsTag(label: 'Active', tone: DsTone.success),
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
              children: const [
                DsSettingRow(label: 'Mobile', value: '+92 300 8842119'),
                DsSettingRow(label: 'CNIC', value: '35202-44·····-1'),
                DsSettingRow(label: 'Market', value: 'Ravi Road, Lahore'),
                DsSettingRow(
                  label: 'Buying source',
                  value: 'Hamza Solar House',
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            const DsCaption(
              'Name, CNIC, market and role come from your registration. '
              'Contact CRM to change them.',
            ),
            const SizedBox(height: AppSpacing.md),
            DsRowGroup(
              children: [
                _SettingsRow(
                  icon: LucideIcons.contact,
                  label: 'Sync Contacts',
                  meta: '27 matched · synced today',
                ),
                _SettingsRow(
                  icon: LucideIcons.lockKeyhole,
                  label: 'App Security',
                  meta: '4-digit PIN is on',
                ),
                _SettingsRow(
                  icon: LucideIcons.languages,
                  label: 'Language',
                  meta: 'English · remembered',
                ),
                _SettingsRow(
                  icon: LucideIcons.palette,
                  label: 'Colour Theme',
                  meta: 'Light',
                ),
                _SettingsRow(
                  icon: LucideIcons.phone,
                  label: 'Call Support',
                  meta: '042 111 276 963',
                ),
                _SettingsRow(
                  icon: LucideIcons.info,
                  label: 'About App',
                  meta: 'Version 1.0.0',
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            DsCard(
              onTap: () {},
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
      bottomNavigationBar: DsBottomNav(
        items: HomeDemo.retailer.nav,
        activeId: 'profile',
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.label,
    required this.meta,
  });

  final IconData icon;
  final String label;
  final String meta;

  @override
  Widget build(BuildContext context) {
    return DsSettingRow(
      label: label,
      meta: meta,
      leading: DsIconMedallion(
        icon: icon,
        size: 36,
        iconSize: 18,
        rounded: true,
      ),
      onTap: () {},
    );
  }
}

/// Board 11 · 2 — My QR code, and precisely what scanning it does.
class MyQrCodeScreen extends StatelessWidget {
  const MyQrCodeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DsScreen(
      appBar: DsAppBar(
        title: 'My QR Code',
        onBack: () => Navigator.of(context).maybePop(),
      ),
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      gap: AppSpacing.md,
      footer: DsFooterBar(
        child: DsButton(
          label: 'Share',
          icon: LucideIcons.share2,
          onPressed: () {},
        ),
      ),
      sections: [
        DsCard(
          radius: AppRadii.heroRadius,
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              Container(
                width: 200,
                height: 200,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: context.palette.sunken,
                  borderRadius: AppRadii.lgRadius,
                ),
                child: Icon(
                  LucideIcons.qrCode,
                  size: 120,
                  color: context.colors.onSurface,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Al-Noor Electric Store',
                style: context.texts.titleLarge,
                textAlign: TextAlign.center,
              ),
              const DsCaption(
                'Retailer · Ravi Road, Lahore',
                align: TextAlign.center,
              ),
            ],
          ),
        ),
        DsCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Others can scan this to',
                style: context.texts.bodyLarge?.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.stepMd),
              const _UseLine(
                icon: LucideIcons.messageCircle,
                text: 'Start a chat with you',
              ),
              const _UseLine(
                icon: LucideIcons.banknoteArrowUp,
                text: 'Send cash to you',
              ),
              const _UseLine(
                icon: LucideIcons.award,
                text: 'Send points to you',
              ),
              const _UseLine(
                icon: LucideIcons.calendarCheck,
                text: 'Mark your attendance at an event',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _UseLine extends StatelessWidget {
  const _UseLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: context.colors.primary),
          const SizedBox(width: 10),
          Expanded(child: DsBody(text, size: 14)),
        ],
      ),
    );
  }
}

/// Board 11 · 3 — Sync Contacts: permission, progress, and the privacy
/// promise that unmatched numbers are discarded.
class SyncContactsScreen extends StatelessWidget {
  const SyncContactsScreen({super.key});

  static const _matches = [
    ('Al-Noor Electric Store', '+92 300 88·· ··9', 'Retailer'),
    ('Hamza Solar House', '+92 321 55·· ··2', 'Wholesaler'),
    ('Karachi Solar Distributors', '+92 333 99·· ··8', 'Distributor'),
    ('Bilal Traders', '+92 321 77·· ··2', 'Retailer'),
    ('M. Zubair Solar', '+92 300 12·· ··4', 'Installer'),
    ('Sitara Electronics', '+92 302 44·· ··7', 'Retailer'),
  ];

  @override
  Widget build(BuildContext context) {
    return DsScreen(
      appBar: DsAppBar(
        title: 'Sync Contacts',
        onBack: () => Navigator.of(context).maybePop(),
      ),
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      gap: AppSpacing.md,
      sections: [
        DsCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Find people you already know',
                style: context.texts.bodyLarge?.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              const DsBody(
                'Syncing checks your phone contacts against Crown Solar '
                'accounts, so you can send cash, send points and start chats '
                'without typing numbers.',
              ),
              const SizedBox(height: AppSpacing.stepMd),
              const DsNotice(
                icon: LucideIcons.shieldCheck,
                tone: DsTone.success,
                message:
                    'Numbers with no Crown Solar account are not saved. Only '
                    'matches are kept.',
                dense: true,
              ),
              const SizedBox(height: AppSpacing.stepMd),
              DsButton(label: 'Sync My Contacts', onPressed: () {}),
            ],
          ),
        ),
        DsCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Syncing',
                      style: context.texts.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const DsCaption('318 of 640 checked'),
                ],
              ),
              const SizedBox(height: 10),
              const DsProgressBar(value: 318 / 640),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '27 contacts matched',
              style: context.texts.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const DsCaption(
              'Out of 640 on your phone. Last synced Today, 9:45 AM. The other '
              '613 numbers were discarded.',
            ),
          ],
        ),
        DsCard(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Column(
            children: [
              for (var i = 0; i < _matches.length; i++) ...[
                DsPartyRow(
                  name: _matches[i].$1,
                  meta: _matches[i].$2,
                  trailing: DsTag(label: _matches[i].$3),
                ),
                if (i != _matches.length - 1) const DsHairline(),
              ],
            ],
          ),
        ),
        DsCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const DsIconMedallion(
                    icon: LucideIcons.contactRound,
                    tone: DsTone.neutral,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Contacts access is off',
                      style: context.texts.bodyLarge?.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.stepMd),
              const DsBody(
                'Without it you can still send cash by Search Number, and '
                'start chats from Departments or by scanning a QR.',
              ),
              const SizedBox(height: AppSpacing.stepMd),
              DsButton(
                label: 'Open Settings',
                variant: DsButtonVariant.secondary,
                size: DsButtonSize.sm,
                icon: LucideIcons.settings,
                onPressed: () {},
              ),
            ],
          ),
        ),
      ],
    );
  }
}
