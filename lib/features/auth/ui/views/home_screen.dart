import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:cse_b2b/core/localization/generated/app_localizations.dart';
import 'package:cse_b2b/core/theme/app_spacing.dart';

import '../view_models/home_view_model.dart';

/// Minimal authenticated placeholder (User Story 9: Logout). Not final
/// CSE product UI — a real dashboard is a separate, future feature.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.onLoggedOut});

  final VoidCallback onLoggedOut;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final viewModel = context.watch<HomeViewModel>();

    if (viewModel.loggedOut) {
      WidgetsBinding.instance.addPostFrameCallback((_) => onLoggedOut());
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.appTitle)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.homeWelcomeMessage),
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton(
                onPressed: () => context.read<HomeViewModel>().logout(),
                child: Text(l10n.homeLogoutAction),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
