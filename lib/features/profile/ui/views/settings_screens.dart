import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/ui/ds.dart';

/// Board 11 · 4 — Language: the same three choices as first launch, reachable
/// any time.
class LanguageSettingScreen extends StatefulWidget {
  const LanguageSettingScreen({super.key});

  @override
  State<LanguageSettingScreen> createState() => _LanguageSettingScreenState();
}

class _LanguageSettingScreenState extends State<LanguageSettingScreen> {
  String _language = 'English';
  bool _remember = true;

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
          label: 'Confirm',
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      sections: [
        for (final language in const ['English', 'اردو', 'Roman Urdu'])
          DsRadio(
            selected: _language == language,
            label: language,
            onTap: () => setState(() => _language = language),
          ),
        DsCheckbox(
          checked: _remember,
          label: 'Remember my choice',
          onChanged: (v) => setState(() => _remember = v),
        ),
      ],
    );
  }
}

/// Board 11 · 5 — Colour Theme, with the note that dark drops shadows
/// entirely and separates by contrast instead.
class ThemeSettingScreen extends StatefulWidget {
  const ThemeSettingScreen({super.key});

  @override
  State<ThemeSettingScreen> createState() => _ThemeSettingScreenState();
}

class _ThemeSettingScreenState extends State<ThemeSettingScreen> {
  String _theme = 'Light';

  @override
  Widget build(BuildContext context) {
    return DsScreen(
      appBar: DsAppBar(
        title: 'Colour Theme',
        onBack: () => Navigator.of(context).maybePop(),
      ),
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      gap: AppSpacing.md,
      sections: [
        DsSegmentedControl(
          options: const ['Light', 'Dark'],
          value: _theme,
          onChanged: (v) => setState(() => _theme = v),
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
                selected: _theme == 'Light',
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
                selected: _theme == 'Dark',
              ),
            ),
          ],
        ),
        const DsCaption(
          'Dark theme drops shadows entirely — separation comes from surface '
          'contrast and hairlines, per board 12.',
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 34,
            decoration: BoxDecoration(
              color: surface,
              borderRadius: AppRadii.smRadius,
              border: Border.all(color: border),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            height: 18,
            decoration: BoxDecoration(
              color: surface,
              borderRadius: AppRadii.smRadius,
              border: Border.all(color: border),
            ),
          ),
          const SizedBox(height: AppSpacing.stepMd),
          Text(
            label,
            textAlign: TextAlign.center,
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

/// Board 11 · 7 — Confirm the current PIN. This gate guards both changing
/// and removing the PIN; nothing happens until it is correct.
class ConfirmPinScreen extends StatelessWidget {
  const ConfirmPinScreen({
    super.key,
    this.title = 'Confirm Your PIN',
    this.prompt = 'Enter your current PIN',
    this.note =
        'Opened from Change PIN, or from turning App PIN off. Nothing changes '
        'until this is correct.',
    this.subtitle,
    this.filled = 0,
  });

  final String title;
  final String prompt;
  final String note;
  final String? subtitle;
  final int filled;

  @override
  Widget build(BuildContext context) {
    return DsScreen(
      appBar: DsAppBar(
        title: title,
        subtitle: subtitle,
        onBack: () => Navigator.of(context).maybePop(),
      ),
      padding: const EdgeInsets.fromLTRB(24, AppSpacing.lg, 24, AppSpacing.lg),
      gap: AppSpacing.stepLg,
      crossAxisAlignment: CrossAxisAlignment.center,
      sections: [
        Column(
          children: [
            DsHeading(prompt),
            const SizedBox(height: 6),
            DsCaption(note, align: TextAlign.center),
          ],
        ),
        DsPinDots(filled: filled),
        DsKeypad(onDigit: (_) {}, onBackspace: () {}),
        Center(
          child: Text(
            'Forgot PIN?',
            style: context.texts.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: context.colors.primary,
            ),
          ),
        ),
      ],
    );
  }
}

/// Board 11 · 8 — Set PIN: the new PIN, entered twice.
class SetPinScreen extends StatelessWidget {
  const SetPinScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ConfirmPinScreen(
      title: 'Change PIN',
      subtitle: 'Step 2 of 2',
      prompt: 'Confirm your new PIN',
      note:
          'Enter the same four digits you just chose, to make sure they '
          'match.',
      filled: 2,
    );
  }
}

/// Board 11 · 9 and 10 — PIN removed / PIN enabled, each stating what will
/// happen the next time the app opens.
class PinResultScreen extends StatelessWidget {
  const PinResultScreen({super.key, required this.enabled});

  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return DsScreen(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      gap: AppSpacing.stepLg,
      crossAxisAlignment: CrossAxisAlignment.center,
      footer: DsFooterBar(
        child: DsButton(
          label: 'Done',
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      sections: [
        DsIconMedallion(
          icon: enabled ? LucideIcons.lockKeyhole : LucideIcons.lockKeyholeOpen,
          tone: DsTone.success,
          size: 80,
          iconSize: 38,
        ),
        Column(
          children: [
            Text(
              enabled ? 'PIN enabled' : 'PIN removed',
              textAlign: TextAlign.center,
              style: context.texts.headlineSmall,
            ),
            const SizedBox(height: 10),
            DsBody(
              enabled
                  ? 'You will be asked for this PIN the next time you open the '
                        'app. You can change or remove it any time from App '
                        'Security.'
                  : 'Opening the app will go straight to your dashboard from '
                        'now on. You can turn the PIN back on any time from '
                        'App Security.',
              size: 15,
              align: TextAlign.center,
            ),
          ],
        ),
      ],
    );
  }
}

/// Board 11 · 11 — Sign out, with the device-binding consequence spelled out:
/// signing out changes nothing about which phone the account is fixed to.
class SignOutScreen extends StatelessWidget {
  const SignOutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A).withValues(alpha: 0.45),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
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
                    onPressed: () {},
                  ),
                  const SizedBox(height: 10),
                  DsButton(
                    label: 'Stay Signed In',
                    variant: DsButtonVariant.quiet,
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
