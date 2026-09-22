import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../../core/ui/ds.dart';
import '../../../session/ui/session_controller.dart';
import '../../data/branding_service.dart';
import 'shop_branding_screen.dart' show statusLabel, statusTone;

/// Board 07 · A7 — Past Requests: every request this partner has ever made,
/// newest first, each with its own reference and outcome.
class BrandingRequestsScreen extends StatefulWidget {
  const BrandingRequestsScreen({super.key, required this.onOpenRequest});

  final Future<void> Function(String reference) onOpenRequest;

  @override
  State<BrandingRequestsScreen> createState() => _BrandingRequestsScreenState();
}

class _BrandingRequestsScreenState extends State<BrandingRequestsScreen> {
  List<BrandingRequest>? _requests;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final user = context.read<SessionController>().user;
    if (user == null) return;

    final landing = await context.read<BrandingService>().landing(
      user.mobileNumber,
    );
    if (!mounted) return;
    setState(() => _requests = landing?.requests ?? const []);
  }

  @override
  Widget build(BuildContext context) {
    final requests = _requests;

    return Scaffold(
      appBar: DsAppBar(
        title: 'Past Requests',
        onBack: () => Navigator.of(context).maybePop(),
      ),
      body: SafeArea(
        bottom: false,
        child: requests == null
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _load,
                child: requests.isEmpty
                    ? ListView(
                        children: const [
                          DsEmptyState(
                            icon: LucideIcons.store,
                            title: 'No requests yet',
                            message:
                                'Your branding requests will be listed here '
                                'once you make one.',
                          ),
                        ],
                      )
                    : ListView(
                        padding: const EdgeInsets.all(AppSpacing.screenPadding),
                        children: [
                          DsCard(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                            ),
                            child: Column(
                              children: [
                                for (var i = 0; i < requests.length; i++) ...[
                                  DsSettingRow(
                                    label: requests[i].boardSummary,
                                    meta: requests[i].reference,
                                    trailing: DsTag(
                                      label: statusLabel(requests[i]),
                                      tone: statusTone(requests[i]),
                                    ),
                                    onTap: () async {
                                      await widget.onOpenRequest(
                                        requests[i].reference,
                                      );
                                      await _load();
                                    },
                                  ),
                                  if (i != requests.length - 1)
                                    const DsHairline(),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
              ),
      ),
    );
  }
}
