import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/ui/ds.dart';
import '../../../design_preview/preview_journey.dart';
import '../../../login/ui/widgets/crown_wordmark.dart';

/// The navy splash the first-launch prompts sit on top of. Also shown on
/// its own while an OS permission dialog is up.
class BrandSplash extends StatelessWidget {
  const BrandSplash({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: context.colors.primary,
      child: const Center(
        child: Opacity(
          opacity: 0.95,
          child: CrownWordmark(reverse: true, width: 180),
        ),
      ),
    );
  }
}

/// Board 01 · A1 — the OS notification prompt over the splash.
class NotificationPromptScreen extends StatelessWidget {
  const NotificationPromptScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: BrandSplash()),
          Positioned.fill(
            child: ColoredBox(
              color: const Color(0xFF0F172A).withValues(alpha: 0.45),
              child: Center(
                child: Container(
                  width: 270,
                  clipBehavior: Clip.hardEdge,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F2F5),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Padding(
                        padding: EdgeInsets.fromLTRB(18, 20, 18, 16),
                        child: Column(
                          children: [
                            Text(
                              '"Crown Solar" Would Like to Send You '
                              'Notifications',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Notifications may include alerts, sounds and '
                              'icon badges. These can be configured in '
                              'Settings.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                height: 18 / 13,
                                color: Color(0xFF3C3C43),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1, color: Color(0xFFC6C6C8)),
                      IntrinsicHeight(
                        child: Row(
                          children: [
                            Expanded(
                              child: _SystemAction(
                                "Don't Allow",
                                onTap: () => PreviewJourney.next(context),
                              ),
                            ),
                            const VerticalDivider(
                              width: 1,
                              color: Color(0xFFC6C6C8),
                            ),
                            Expanded(
                              child: _SystemAction(
                                'Allow',
                                bold: true,
                                onTap: () => PreviewJourney.next(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SystemAction extends StatelessWidget {
  const _SystemAction(this.label, {this.bold = false, this.onTap});

  final String label;
  final bool bold;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 17,
            color: const Color(0xFF007AFF),
            fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

/// Board 01 · A2 — Select Language, as a sheet over the splash.
class SelectLanguageScreen extends StatefulWidget {
  const SelectLanguageScreen({
    super.key,
    this.language,
    this.remember,
    this.onLanguageChanged,
    this.onRememberChanged,
    this.onConfirm,
  });

  /// The language the flow already holds ('English', 'اردو', 'Roman Urdu').
  final String? language;
  final bool? remember;
  final ValueChanged<String>? onLanguageChanged;
  final ValueChanged<bool>? onRememberChanged;
  final VoidCallback? onConfirm;

  @override
  State<SelectLanguageScreen> createState() => _SelectLanguageScreenState();
}

class _SelectLanguageScreenState extends State<SelectLanguageScreen> {
  late String _language = widget.language ?? 'English';
  late bool _remember = widget.remember ?? true;

  void _select(String language) {
    setState(() => _language = language);
    widget.onLanguageChanged?.call(language);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: BrandSplash()),
          Positioned.fill(
            child: ColoredBox(
              color: const Color(0xFF0F172A).withValues(alpha: 0.45),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: DsSheet(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Select Language', style: context.texts.titleLarge),
                      const SizedBox(height: 4),
                      const DsBody(
                        'You can change this later in Profile.',
                        size: 14,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _LanguageOption(
                        label: 'English',
                        selected: _language == 'English',
                        onTap: () => _select('English'),
                      ),
                      const SizedBox(height: 10),
                      _LanguageOption(
                        label: 'اردو',
                        rtl: true,
                        selected: _language == 'اردو',
                        onTap: () => _select('اردو'),
                      ),
                      const SizedBox(height: 10),
                      _LanguageOption(
                        label: 'Roman Urdu',
                        selected: _language == 'Roman Urdu',
                        onTap: () => _select('Roman Urdu'),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      DsCheckbox(
                        checked: _remember,
                        label: 'Remember my choice',
                        onChanged: (v) {
                          setState(() => _remember = v);
                          widget.onRememberChanged?.call(v);
                        },
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      DsButton(
                        label: 'Confirm',
                        onPressed:
                            widget.onConfirm ??
                            () => PreviewJourney.next(context),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  const _LanguageOption({
    required this.label,
    required this.selected,
    this.rtl = false,
    this.onTap,
  });

  final String label;
  final bool selected;
  final bool rtl;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadii.mdRadius,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: selected ? context.palette.accentSoft : context.colors.surface,
          borderRadius: AppRadii.mdRadius,
          border: Border.all(
            color: selected ? context.colors.primary : context.colors.outline,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: selected ? Colors.white : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected
                      ? context.colors.primary
                      : context.palette.borderStrong,
                  width: selected ? 6 : 1.5,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.stepMd),
            Expanded(
              child: Text(
                label,
                textAlign: rtl ? TextAlign.right : TextAlign.left,
                style: TextStyle(
                  fontSize: rtl ? 18 : 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Board 01 · A3 — Current location, asked once up front.
class LocationPermissionScreen extends StatelessWidget {
  const LocationPermissionScreen({super.key, this.onAllow, this.onNotNow});

  final VoidCallback? onAllow;
  final VoidCallback? onNotNow;

  @override
  Widget build(BuildContext context) {
    return DsScreen(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      gap: 18,
      footer: DsFooterBar(
        child: Column(
          children: [
            DsButton(
              label: 'Allow Location',
              onPressed: onAllow ?? () => PreviewJourney.next(context),
            ),
            const SizedBox(height: 10),
            DsButton(
              label: 'Not now',
              variant: DsButtonVariant.quiet,
              onPressed: onNotNow ?? () => PreviewJourney.next(context),
            ),
          ],
        ),
      ),
      sections: [
        const Align(
          alignment: AlignmentDirectional.centerStart,
          child: DsIconMedallion(
            icon: LucideIcons.mapPin,
            size: 56,
            iconSize: 28,
            rounded: true,
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Allow location access', style: context.texts.headlineSmall),
            const SizedBox(height: AppSpacing.sm),
            Text.rich(
              TextSpan(
                style: context.texts.bodyLarge?.copyWith(
                  fontSize: 15,
                  height: 22 / 15,
                  color: context.colors.onSurfaceVariant,
                ),
                children: const [
                  TextSpan(text: "We use your phone's "),
                  TextSpan(
                    text: 'current location',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  TextSpan(
                    text:
                        ' to help route your registration to the right market '
                        'and Marketing Officer, and to speed up sign-in later. '
                        'It is asked for once, here, before you reach Login.',
                  ),
                ],
              ),
            ),
          ],
        ),
        DsCard(
          radius: AppRadii.mdRadius,
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: const [
              _AssuranceLine(
                'This is where your phone is now — not necessarily your shop. '
                'You will place your shop separately, later in the wizard.',
              ),
              SizedBox(height: 10),
              _AssuranceLine('Not tracked in the background.'),
            ],
          ),
        ),
      ],
    );
  }
}

class _AssuranceLine extends StatelessWidget {
  const _AssuranceLine(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(LucideIcons.check, size: 16, color: context.status.success),
        const SizedBox(width: 10),
        Expanded(child: DsBody(text)),
      ],
    );
  }
}

/// Board 01 · A4 — Location off, explained.
class LocationOffScreen extends StatelessWidget {
  const LocationOffScreen({
    super.key,
    this.onOpenSettings,
    this.onContinueWithout,
    this.onBack,
  });

  final VoidCallback? onOpenSettings;
  final VoidCallback? onContinueWithout;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return DsScreen(
      appBar: DsAppBar(
        title: 'Location Needed',
        onBack: onBack ?? () => Navigator.of(context).maybePop(),
      ),
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      gap: AppSpacing.stepLg,
      sections: [
        DsCard(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
          child: Column(
            children: [
              const DsIconMedallion(
                icon: LucideIcons.mapPinOff,
                tone: DsTone.warning,
                size: 64,
                iconSize: 30,
              ),
              const SizedBox(height: 14),
              Text(
                'Location is switched off',
                style: context.texts.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
              const DsBody(
                'Your current location helps route your registration '
                'correctly. Turn location on in Settings and return here.',
                size: 14,
                align: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              DsButton(
                label: 'Open Settings',
                icon: LucideIcons.settings,
                onPressed: onOpenSettings ?? () {},
              ),
              const SizedBox(height: 10),
              DsButton(
                label: 'Continue without location',
                variant: DsButtonVariant.tertiary,
                onPressed:
                    onContinueWithout ?? () => PreviewJourney.next(context),
              ),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: DsCaption(
            'The rest of the app stays usable. Only the shop pin step later '
            'waits for permission.',
          ),
        ),
      ],
    );
  }
}
