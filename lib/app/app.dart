import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:cse_b2b/app/router/app_router.dart';
import 'package:cse_b2b/core/localization/app_locales.dart';
import 'package:cse_b2b/core/localization/generated/app_localizations.dart';
import 'package:cse_b2b/core/theme/app_theme.dart';
import 'package:cse_b2b/features/profile/ui/app_settings_controller.dart';

class CseApp extends StatefulWidget {
  const CseApp({super.key, this.router});

  /// Injected by tests that need to start at a specific location.
  final GoRouter? router;

  @override
  State<CseApp> createState() => _CseAppState();
}

class _CseAppState extends State<CseApp> {
  late final GoRouter _router = widget.router ?? createAppRouter();

  /// Theme and language live above MaterialApp, so changing either rebuilds
  /// the whole app at once rather than screen by screen.
  final _settings = AppSettingsController();

  @override
  void dispose() {
    _settings.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AppSettingsController>.value(
      value: _settings,
      child: Consumer<AppSettingsController>(
        builder: (context, settings, _) => MaterialApp.router(
          routerConfig: _router,
          onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: settings.themeMode,
          locale: settings.locale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => Directionality(
            textDirection: AppLocales.directionOf(
              Localizations.localeOf(context),
            ),
            child: child ?? const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }
}
