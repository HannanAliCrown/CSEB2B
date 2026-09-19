import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/ui/ds.dart';
import '../../../session/data/signed_in_user.dart';
import '../../../session/ui/session_controller.dart';

/// Board 11 · 2 — the partner's own QR code, and what scanning it does.
///
/// The code carries the mobile number, because that is what every other
/// journey already resolves a partner by: chat, cash and points all look a
/// number up in the directory.
class MyQrCodeScreen extends StatelessWidget {
  const MyQrCodeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<SessionController>().user;
    if (user == null) return const SizedBox.shrink();

    return DsScreen(
      appBar: DsAppBar(
        title: 'My QR Code',
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
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: AppRadii.lgRadius,
                ),
                child: QrImageView(
                  data: user.mobileNumber,
                  size: 200,
                  backgroundColor: Colors.white,
                  // A scanner reading this off a phone screen needs the
                  // stronger error correction.
                  errorCorrectionLevel: QrErrorCorrectLevel.H,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                user.businessName,
                style: context.texts.titleLarge,
                textAlign: TextAlign.center,
              ),
              DsCaption(
                '${user.role.label} · ${user.market}',
                align: TextAlign.center,
              ),
              const SizedBox(height: 4),
              DsCaption(user.mobileNumber, align: TextAlign.center),
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
              if (user.role != PartnerRole.installer)
                const _UseLine(
                  icon: LucideIcons.banknoteArrowUp,
                  text: 'Send cash to you',
                ),
              const _UseLine(
                icon: LucideIcons.award,
                text: 'Send points to you',
              ),
            ],
          ),
        ),
        const DsCaption(
          'The code holds your mobile number and nothing else. It cannot be '
          'used to sign in as you.',
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
