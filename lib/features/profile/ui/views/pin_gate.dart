import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/ui/ds.dart';
import '../../../login/ui/widgets/crown_wordmark.dart';
import '../../../session/data/signed_in_user.dart';
import '../../../session/ui/session_controller.dart';
import '../../data/profile_settings_service.dart';
import '../app_settings_controller.dart';

/// Whether the app has been unlocked since it started.
///
/// Held once for the whole app rather than per screen, so the PIN is asked
/// for when the app opens and not again on every navigation.
class PinLock extends ChangeNotifier {
  bool _unlocked = false;

  bool get unlocked => _unlocked;

  void unlock() {
    if (_unlocked) return;
    _unlocked = true;
    notifyListeners();
  }

  /// Signing out re-locks, so the next partner is asked for their own PIN.
  void relock() {
    if (!_unlocked) return;
    _unlocked = false;
    notifyListeners();
  }
}

/// Stands in front of the signed-in app when a PIN is on.
///
/// App Security promises the PIN is asked for the next time the app opens.
/// This is what keeps that promise — without it the switch would be theatre.
///
/// A PIN that cannot be checked does not lock the partner out: if the server
/// is unreachable the app opens, because a convenience lock should never cost
/// someone access to their own wallet.
class PinGate extends StatefulWidget {
  const PinGate({super.key, required this.child});

  final Widget child;

  @override
  State<PinGate> createState() => _PinGateState();
}

class _PinGateState extends State<PinGate> {
  bool _checked = false;
  bool _required = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  Future<void> _check() async {
    final lock = context.read<PinLock>();
    if (lock.unlocked) {
      setState(() => _checked = true);
      return;
    }

    final user = context.read<SessionController>().user;
    if (user == null) {
      setState(() => _checked = true);
      return;
    }

    final settings = await context.read<ProfileSettingsService>().read(
      user.mobileNumber,
    );
    if (!mounted) return;

    // The partner's saved theme and language follow their account, so they
    // are put into effect here — the first point after sign-in where the
    // settings are known. Without this the app would open on the phone's
    // defaults however many times they had chosen otherwise.
    if (settings != null) context.read<AppSettingsController>().apply(settings);

    // No settings means the server could not be reached. Open the app.
    final required = settings?.pinEnabled ?? false;
    if (!required) lock.unlock();
    setState(() {
      _required = required;
      _checked = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_checked) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!_required) return widget.child;

    return _UnlockScreen(
      onUnlocked: () {
        context.read<PinLock>().unlock();
        setState(() => _required = false);
      },
    );
  }
}

/// Board 02 · C1 — PIN unlock.
class _UnlockScreen extends StatefulWidget {
  const _UnlockScreen({required this.onUnlocked});

  final VoidCallback onUnlocked;

  @override
  State<_UnlockScreen> createState() => _UnlockScreenState();
}

class _UnlockScreenState extends State<_UnlockScreen> {
  String _pin = '';
  bool _checking = false;
  String? _error;

  Future<void> _digit(String digit) async {
    if (_pin.length >= 4 || _checking) return;
    setState(() {
      _pin += digit;
      _error = null;
    });
    if (_pin.length == 4) await _verify();
  }

  Future<void> _verify() async {
    final user = context.read<SessionController>().user;
    if (user == null) return;

    setState(() => _checking = true);
    final correct = await context.read<ProfileSettingsService>().verifyPin(
      mobileNumber: user.mobileNumber,
      pin: _pin,
    );
    if (!mounted) return;

    if (correct) {
      widget.onUnlocked();
      return;
    }
    setState(() {
      _pin = '';
      _checking = false;
      _error = 'That PIN is not right.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<SessionController>().user;

    return DsScreen(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
      gap: 22,
      crossAxisAlignment: CrossAxisAlignment.center,
      sections: [
        const CrownWordmark(height: 44),
        Column(
          children: [
            const DsHeading('Enter your PIN'),
            const SizedBox(height: 6),
            DsBody(
              user == null ? '' : '${user.businessName} · ${user.role.label}',
              size: 14,
              align: TextAlign.center,
            ),
          ],
        ),
        DsPinDots(filled: _pin.length),
        // The row is always there, empty or not: if it appeared only on a
        // wrong PIN the keypad would jump under the partner's thumb exactly
        // when they are retyping.
        SizedBox(
          height: 18,
          child: _error == null
              ? null
              : Text(
                  _error!,
                  style: TextStyle(fontSize: 13, color: context.status.error),
                ),
        ),
        DsKeypad(
          onDigit: _digit,
          onBackspace: () => setState(() {
            if (_pin.isNotEmpty) _pin = _pin.substring(0, _pin.length - 1);
          }),
        ),
        Center(
          child: GestureDetector(
            onTap: _forgotPin,
            child: Text(
              'Forgot PIN?',
              style: context.texts.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: context.colors.primary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// There is no way to recover a PIN from this screen, and no honest one to
  /// invent: nothing here can tell the account's owner from whoever is
  /// holding the phone. So it says who can clear it, and offers to call
  /// them — which is something the partner can actually act on.
  Future<void> _forgotPin() async {
    final messenger = ScaffoldMessenger.of(context);
    final user = context.read<SessionController>().user;
    if (user == null) return;

    final contacts = await context
        .read<ProfileSettingsService>()
        .supportContacts(user.mobileNumber);
    if (!mounted) return;

    final helpline = contacts.isEmpty ? null : contacts.first;

    final call = await showDialog<bool>(
      context: context,
      barrierColor: const Color(0xFF0F172A).withValues(alpha: 0.45),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.all(AppSpacing.lg),
        child: DsDialogCard(
          icon: LucideIcons.keyRound,
          title: 'Forgot your PIN?',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              DsBody(
                'The PIN protects this phone only — it is not your Crown '
                'Solar password, and signing in again will not clear it. '
                '${helpline == null ? 'Crown Solar support' : helpline.label} '
                'can remove it for you.',
                size: 14,
              ),
              const SizedBox(height: AppSpacing.md),
              if (helpline != null) ...[
                DsButton(
                  label: 'Call ${ltrText(helpline.phoneNumber)}',
                  icon: LucideIcons.phone,
                  onPressed: () => Navigator.of(context).pop(true),
                ),
                const SizedBox(height: 10),
              ],
              DsButton(
                label: 'Back',
                variant: DsButtonVariant.quiet,
                onPressed: () => Navigator.of(context).pop(false),
              ),
            ],
          ),
        ),
      ),
    );

    if (call != true || helpline == null) return;

    // `tel:` opens the dialler with the number in it — it does not ring.
    final opened = await launchUrl(
      Uri(scheme: 'tel', path: helpline.phoneNumber.replaceAll(' ', '')),
    );
    if (opened) return;

    messenger.showSnackBar(
      SnackBar(
        content: Text('No dialler on this device. ${helpline.phoneNumber}'),
      ),
    );
  }
}
