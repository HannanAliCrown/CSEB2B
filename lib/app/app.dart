import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import 'package:cse_b2b/app/router/app_router.dart';
import 'package:cse_b2b/core/localization/app_locales.dart';
import 'package:cse_b2b/core/localization/generated/app_localizations.dart';
import 'package:cse_b2b/core/theme/app_theme.dart';

class CseApp extends StatefulWidget {
  const CseApp({super.key, this.router});

  /// Injected by tests that need to start at a specific location.
  final GoRouter? router;

  @override
  State<CseApp> createState() => _CseAppState();
}

class _CseAppState extends State<CseApp> {
  late final GoRouter _router = widget.router ?? createAppRouter();

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: _router,
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => Directionality(
        textDirection: AppLocales.directionOf(Localizations.localeOf(context)),
        child: child ?? const SizedBox.shrink(),
      ),
    );
  }
}
