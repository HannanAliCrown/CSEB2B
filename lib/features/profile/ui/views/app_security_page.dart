import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../../core/ui/ds.dart';
import '../../../session/ui/session_controller.dart';
import '../../data/profile_settings_service.dart';

/// Board 02 · C3 — where the PIN is set: Profile → App Security.
///
/// The PIN locks this app on this handset. It never affects device binding,
/// and it is not a second password: four digits is a convenience lock over
/// the phone's own screen lock.
class AppSecurityPage extends StatefulWidget {
  const AppSecurityPage({super.key});

  @override
  State<AppSecurityPage> createState() => _AppSecurityPageState();
}

class _AppSecurityPageState extends State<AppSecurityPage> {
  ProfileSettings? _settings;
  bool _loaded = false;

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
    if (!mounted) return;
    setState(() {
      _settings = settings;
      _loaded = true;
    });
  }

  /// Turning the PIN on: choose it, then confirm it. Turning it off: prove
  /// you know it first, so a borrowed phone cannot unlock itself.
  Future<void> _toggle(bool on) async {
    final user = context.read<SessionController>().user;
    final service = context.read<ProfileSettingsService>();
    if (user == null) return;

    if (!on) {
      final pin = await PinEntryPage.ask(
        context,
        title: 'Turn off App PIN',
        prompt: 'Enter your current PIN',
        note: 'The PIN stays off until you turn it back on.',
      );
      if (pin == null || !mounted) return;

      final failure = await service.disablePin(
        mobileNumber: user.mobileNumber,
        pin: pin,
      );
      if (!mounted) return;
      if (failure != null) {
        _say(failure.message);
        return;
      }
      await _load();
      if (mounted) await PinResultPage.show(context, enabled: false);
      return;
    }

    // Already chosen once — turning it back on need not ask for a new one.
    final existing = _settings?.pinSet ?? false;
    final chosen = await PinEntryPage.ask(
      context,
      title: existing ? 'Turn on App PIN' : 'Set your PIN',
      prompt: existing ? 'Enter your PIN' : 'Choose a four-digit PIN',
      note: existing
          ? 'The PIN you set before.'
          : 'You will enter this each time the app opens.',
    );
    if (chosen == null || !mounted) return;

    if (!existing) {
      final again = await PinEntryPage.ask(
        context,
        title: 'Set your PIN',
        subtitle: 'Step 2 of 2',
        prompt: 'Confirm your PIN',
        note: 'Enter the same four digits, to make sure they match.',
      );
      if (again == null || !mounted) return;
      if (again != chosen) {
        _say('Those did not match. Nothing has changed.');
        return;
      }
    }

    final failure = await service.setPin(
      mobileNumber: user.mobileNumber,
      pin: chosen,
      currentPin: existing ? chosen : null,
    );
    if (!mounted) return;
    if (failure != null) {
      _say(failure.message);
      return;
    }
    await _load();
    if (mounted) await PinResultPage.show(context, enabled: true);
  }

  Future<void> _changePin() async {
    final user = context.read<SessionController>().user;
    final service = context.read<ProfileSettingsService>();
    if (user == null) return;

    final current = await PinEntryPage.ask(
      context,
      title: 'Change PIN',
      subtitle: 'Step 1 of 2',
      prompt: 'Enter your current PIN',
      note: 'Nothing changes until this is correct.',
    );
    if (current == null || !mounted) return;

    // Checked before asking for the new one, so a wrong current PIN is caught
    // straight away rather than after two more screens.
    final correct = await service.verifyPin(
      mobileNumber: user.mobileNumber,
      pin: current,
    );
    if (!mounted) return;
    if (!correct) {
      _say(PinFailure.wrongPin.message);
      return;
    }

    final fresh = await PinEntryPage.ask(
      context,
      title: 'Change PIN',
      subtitle: 'Step 2 of 2',
      prompt: 'Choose your new PIN',
      note: 'Four digits you will remember.',
    );
    if (fresh == null || !mounted) return;

    final again = await PinEntryPage.ask(
      context,
      title: 'Change PIN',
      subtitle: 'Step 2 of 2',
      prompt: 'Confirm your new PIN',
      note: 'Enter the same four digits you just chose.',
    );
    if (again == null || !mounted) return;
    if (again != fresh) {
      _say('Those did not match. Your PIN is unchanged.');
      return;
    }

    final failure = await service.setPin(
      mobileNumber: user.mobileNumber,
      pin: fresh,
      currentPin: current,
    );
    if (!mounted) return;
    _say(failure?.message ?? 'PIN changed.');
    await _load();
  }

  void _say(String message) =>
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));

  @override
  Widget build(BuildContext context) {
    final settings = _settings;
    final enabled = settings?.pinEnabled ?? false;

    return DsScreen(
      appBar: DsAppBar(
        title: 'App Security',
        onBack: () => Navigator.of(context).maybePop(),
      ),
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      gap: 18,
      sections: [
        if (!_loaded)
          const Center(child: CircularProgressIndicator())
        else if (settings == null)
          const DsNotice(
            icon: LucideIcons.circleAlert,
            tone: DsTone.error,
            message:
                'Could not reach Crown Solar, so your PIN settings cannot be '
                'shown or changed right now.',
          )
        else ...[
          DsCard(
            child: Row(
              children: [
                const DsIconMedallion(
                  icon: LucideIcons.lockKeyhole,
                  size: 40,
                  iconSize: 20,
                  rounded: true,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'App PIN',
                        style: context.texts.bodyLarge?.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Ask for a 4-digit PIN when the app opens',
                        style: context.texts.bodySmall?.copyWith(
                          color: context.palette.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
                DsSwitch(checked: enabled, onChanged: _toggle),
              ],
            ),
          ),
          if (enabled)
            DsCard(
              onTap: _changePin,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              child: Row(
                children: [
                  Icon(
                    LucideIcons.keyRound,
                    size: 20,
                    color: context.colors.onSurfaceVariant,
                  ),
                  const SizedBox(width: AppSpacing.stepMd),
                  Expanded(
                    child: Text(
                      'Change PIN',
                      style: context.texts.bodyLarge?.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Icon(
                    LucideIcons.chevronRight,
                    size: 18,
                    color: context.palette.textTertiary,
                  ),
                ],
              ),
            ),
          const DsCaption(
            'The PIN locks this app on this phone. It does not change which '
            'phone your account is fixed to, and it is not your sign-in.',
          ),
        ],
      ],
    );
  }
}

/// Board 11 · 7 and 8 — entering four digits.
///
/// Returns the digits to whoever pushed it, or null if the partner backed
/// out. It never decides anything itself: checking and saving belong to the
/// screen that asked.
class PinEntryPage extends StatefulWidget {
  const PinEntryPage({
    super.key,
    required this.title,
    required this.prompt,
    required this.note,
    this.subtitle,
  });

  final String title;
  final String prompt;
  final String note;
  final String? subtitle;

  /// Pushes the keypad and waits for four digits.
  static Future<String?> ask(
    BuildContext context, {
    required String title,
    required String prompt,
    required String note,
    String? subtitle,
  }) => Navigator.of(context).push<String>(
    MaterialPageRoute<String>(
      builder: (_) => PinEntryPage(
        title: title,
        prompt: prompt,
        note: note,
        subtitle: subtitle,
      ),
    ),
  );

  @override
  State<PinEntryPage> createState() => _PinEntryPageState();
}

class _PinEntryPageState extends State<PinEntryPage> {
  String _pin = '';

  void _digit(String digit) {
    if (_pin.length >= 4) return;
    setState(() => _pin += digit);
    // Four digits is the whole PIN, so there is nothing to confirm — hand it
    // back the moment it is complete.
    if (_pin.length == 4) {
      Navigator.of(context).pop(_pin);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DsScreen(
      appBar: DsAppBar(
        title: widget.title,
        subtitle: widget.subtitle,
        onBack: () => Navigator.of(context).maybePop(),
      ),
      padding: const EdgeInsets.fromLTRB(24, AppSpacing.lg, 24, AppSpacing.lg),
      gap: AppSpacing.stepLg,
      crossAxisAlignment: CrossAxisAlignment.center,
      sections: [
        Column(
          children: [
            DsHeading(widget.prompt),
            const SizedBox(height: 6),
            DsCaption(widget.note, align: TextAlign.center),
          ],
        ),
        DsPinDots(filled: _pin.length),
        DsKeypad(
          onDigit: _digit,
          onBackspace: () => setState(() {
            if (_pin.isNotEmpty) _pin = _pin.substring(0, _pin.length - 1);
          }),
        ),
      ],
    );
  }
}

/// Board 11 · 9 and 10 — PIN removed / PIN enabled, each stating what will
/// happen the next time the app opens.
class PinResultPage extends StatelessWidget {
  const PinResultPage({super.key, required this.enabled});

  final bool enabled;

  static Future<void> show(BuildContext context, {required bool enabled}) =>
      Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => PinResultPage(enabled: enabled),
        ),
      );

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
                  ? 'You will be asked for this PIN the next time you open '
                        'the app. You can change or remove it any time from '
                        'App Security.'
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
