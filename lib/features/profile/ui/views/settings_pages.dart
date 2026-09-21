import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/ui/ds.dart';
import '../../../session/ui/session_controller.dart';
import '../../data/profile_settings_service.dart';
import '../app_settings_controller.dart';

/// Board 11 · 4 — Language: the same three choices as first launch, reachable
/// any time.
///
/// The choice is applied to the running app and saved against the account, so
/// it follows the partner to their next sign-in rather than living on one
/// handset.
class LanguagePage extends StatefulWidget {
  const LanguagePage({super.key});

  @override
  State<LanguagePage> createState() => _LanguagePageState();
}

class _LanguagePageState extends State<LanguagePage> {
  AppLanguage _language = AppLanguage.english;
  bool _remember = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final user = context.read<SessionController>().user;
    if (user == null) return;
    final settings = await context.read<ProfileSettingsService>().read(
      user.mobileNumber,
    );
    if (!mounted || settings == null) return;
    setState(() {
      _language = settings.language ?? AppLanguage.english;
      _remember = settings.languageRemembered ?? true;
    });
  }

  Future<void> _confirm() async {
    final user = context.read<SessionController>().user;
    if (user == null) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    final saved = await context.read<ProfileSettingsService>().update(
      mobileNumber: user.mobileNumber,
      language: _language,
      languageRemembered: _remember,
    );
    if (!mounted) return;

    if (saved == null) {
      setState(() {
        _saving = false;
        _error =
            'Could not save. Check your connection and try again — nothing '
            'has changed.';
      });
      return;
    }

    // Only once the database has it does the app switch, so what is on screen
    // always matches what was saved.
    context.read<AppSettingsController>().setLanguage(_language);
    if (mounted) Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    return DsScreen(
      appBar: DsAppBar(
        title: 'Language',
        onBack: () => Navigator.of(context).maybePop(),
      ),
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      gap: AppSpacing.stepMd,
      footer: DsFooterBar(
        child: DsButton(
          label: _saving ? 'Saving…' : 'Confirm',
          onPressed: _saving ? null : _confirm,
        ),
      ),
      sections: [
        for (final language in AppLanguage.values)
          DsRadio(
            selected: _language == language,
            label: language.label,
            onTap: () => setState(() => _language = language),
          ),
        DsCheckbox(
          checked: _remember,
          label: 'Remember my choice',
          onChanged: (value) => setState(() => _remember = value),
        ),
        if (_error != null)
          DsNotice(
            icon: LucideIcons.circleAlert,
            tone: DsTone.error,
            message: _error!,
          ),
      ],
    );
  }
}

/// Board 11 · 5 — Colour Theme, with the note that dark drops shadows
/// entirely and separates by contrast instead.
class ThemePage extends StatefulWidget {
  const ThemePage({super.key});

  @override
  State<ThemePage> createState() => _ThemePageState();
}

class _ThemePageState extends State<ThemePage> {
  String? _error;

  Future<void> _choose(ThemeMode mode) async {
    final user = context.read<SessionController>().user;
    if (user == null) return;

    // Applied at once: a theme that waits for a round trip feels broken.
    // If the save fails it is put back, so the screen never keeps a choice
    // the database refused.
    final settings = context.read<AppSettingsController>();
    final previous = settings.themeMode;
    settings.setThemeMode(mode);
    setState(() => _error = null);

    final saved = await context.read<ProfileSettingsService>().update(
      mobileNumber: user.mobileNumber,
      themeMode: mode,
    );
    if (!mounted || saved != null) return;

    settings.setThemeMode(previous);
    setState(() => _error = 'Could not save that. Your theme is unchanged.');
  }

  @override
  Widget build(BuildContext context) {
    final mode = context.watch<AppSettingsController>().themeMode;
    final chosen = switch (mode) {
      ThemeMode.dark => 'Dark',
      ThemeMode.light => 'Light',
      ThemeMode.system => 'System',
    };

    return DsScreen(
      appBar: DsAppBar(
        title: 'Colour Theme',
        onBack: () => Navigator.of(context).maybePop(),
      ),
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      gap: AppSpacing.md,
      sections: [
        DsSegmentedControl(
          options: const ['System', 'Light', 'Dark'],
          value: chosen,
          onChanged: (value) => _choose(switch (value) {
            'Light' => ThemeMode.light,
            'Dark' => ThemeMode.dark,
            _ => ThemeMode.system,
          }),
        ),
        Row(
          children: [
            Expanded(
              child: _ThemePreview(
                label: 'Light',
                background: const Color(0xFFF8FAFC),
                surface: Colors.white,
                border: const Color(0xFFE2E8F0),
                text: const Color(0xFF0F172A),
                selected: mode == ThemeMode.light,
              ),
            ),
            const SizedBox(width: AppSpacing.stepMd),
            Expanded(
              child: _ThemePreview(
                label: 'Dark',
                background: const Color(0xFF0B0F14),
                surface: const Color(0xFF111827),
                border: const Color(0xFF374151),
                text: const Color(0xFFF8FAFC),
                selected: mode == ThemeMode.dark,
              ),
            ),
          ],
        ),
        const DsCaption(
          'System follows your phone. Dark theme drops shadows entirely — '
          'separation comes from surface contrast and hairlines.',
        ),
        if (_error != null)
          DsNotice(
            icon: LucideIcons.circleAlert,
            tone: DsTone.error,
            message: _error!,
          ),
      ],
    );
  }
}

class _ThemePreview extends StatelessWidget {
  const _ThemePreview({
    required this.label,
    required this.background,
    required this.surface,
    required this.border,
    required this.text,
    required this.selected,
  });

  final String label;
  final Color background;
  final Color surface;
  final Color border;
  final Color text;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.stepMd),
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppRadii.lgRadius,
        border: Border.all(
          color: selected ? context.colors.primary : border,
          width: selected ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < 3; i++) ...[
            Container(
              height: 12,
              width: i == 2 ? 60 : double.infinity,
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: border),
              ),
            ),
            const SizedBox(height: 6),
          ],
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: text,
            ),
          ),
        ],
      ),
    );
  }
}

/// Board 11 — Call Support.
///
/// Tapping a number opens the phone's dialler with it filled in. The app
/// never places a call itself: dialling is the partner's decision, made on
/// their own keypad.
class CallSupportPage extends StatefulWidget {
  const CallSupportPage({super.key});

  @override
  State<CallSupportPage> createState() => _CallSupportPageState();
}

class _CallSupportPageState extends State<CallSupportPage> {
  List<SupportContact> _contacts = const [];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final user = context.read<SessionController>().user;
    if (user == null) return;
    final contacts = await context
        .read<ProfileSettingsService>()
        .supportContacts(user.mobileNumber);
    if (!mounted) return;
    setState(() {
      _contacts = contacts;
      _loaded = true;
    });
  }

  Future<void> _dial(SupportContact contact) async {
    final messenger = ScaffoldMessenger.of(context);
    // `tel:` opens the dialler with the number in it — it does not ring.
    final opened = await launchUrl(
      Uri(scheme: 'tel', path: contact.phoneNumber.replaceAll(' ', '')),
    );
    if (opened) return;

    messenger.showSnackBar(
      SnackBar(
        content: Text('No dialler on this device. ${contact.phoneNumber}'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DsScreen(
      appBar: DsAppBar(
        title: 'Call Support',
        onBack: () => Navigator.of(context).maybePop(),
      ),
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      gap: AppSpacing.md,
      sections: [
        if (!_loaded)
          const Center(child: CircularProgressIndicator())
        else if (_contacts.isEmpty)
          const DsEmptyState(
            icon: LucideIcons.phoneOff,
            title: 'No numbers to show',
            message:
                'Support numbers could not be loaded. Check your connection '
                'and try again.',
          )
        else
          DsCard(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Column(
              children: [
                for (var i = 0; i < _contacts.length; i++) ...[
                  DsSettingRow(
                    label: _contacts[i].label,
                    meta: [
                      _contacts[i].phoneNumber,
                      if (_contacts[i].description != null)
                        _contacts[i].description!,
                    ].join(' · '),
                    leading: const DsIconMedallion(
                      icon: LucideIcons.phone,
                      size: 36,
                      iconSize: 18,
                      rounded: true,
                    ),
                    onTap: () => _dial(_contacts[i]),
                  ),
                  if (i != _contacts.length - 1) const DsHairline(),
                ],
              ],
            ),
          ),
        const DsCaption(
          'Tapping a number opens your phone\'s dialler with it entered. '
          'Nothing is dialled until you press call.',
        ),
      ],
    );
  }
}

/// Board 11 — About App.
///
/// The version comes from the installed binary, not the database: a row on a
/// server could disagree with what is actually running on this phone.
class AboutAppPage extends StatefulWidget {
  const AboutAppPage({super.key});

  @override
  State<AboutAppPage> createState() => _AboutAppPageState();
}

class _AboutAppPageState extends State<AboutAppPage> {
  Map<String, String> _info = const {};
  String _version = '';
  String _build = '';
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final info = await context.read<ProfileSettingsService>().appInfo();
    final package = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() {
      _info = info;
      _version = package.version;
      _build = package.buildNumber;
      _loaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return DsScreen(
      appBar: DsAppBar(
        title: 'About App',
        onBack: () => Navigator.of(context).maybePop(),
      ),
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      gap: AppSpacing.md,
      sections: [
        DsCard(
          radius: AppRadii.heroRadius,
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              const DsIconMedallion(
                icon: LucideIcons.sun,
                tone: DsTone.solar,
                size: 64,
                iconSize: 30,
              ),
              const SizedBox(height: AppSpacing.stepMd),
              Text(
                'Crown Solar Energy',
                style: context.texts.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              DsCaption(
                _version.isEmpty
                    ? 'Reading version…'
                    : 'Version $_version (build $_build)',
                align: TextAlign.center,
              ),
            ],
          ),
        ),
        if (!_loaded)
          const Center(child: CircularProgressIndicator())
        else if (_info.isEmpty)
          const DsNotice(
            icon: LucideIcons.info,
            message:
                'Company details could not be loaded. The version above is '
                'read from this phone and is correct.',
          )
        else
          DsRowGroup(
            children: [
              if (_info['company'] != null)
                DsSettingRow(label: 'Company', value: _info['company']!),
              if (_info['address'] != null)
                DsSettingRow(label: 'Address', value: _info['address']!),
              if (_info['website'] != null)
                DsSettingRow(label: 'Website', value: _info['website']!),
              if (_info['email'] != null)
                DsSettingRow(label: 'Email', value: _info['email']!),
            ],
          ),
        if (_info['legal'] != null) DsCaption(_info['legal']!),
      ],
    );
  }
}
