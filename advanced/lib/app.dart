import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'config/app_settings.dart';
import 'ui/navigation/app_router.dart';
import 'ui/theme/theme.dart';

/// Root widget of the Glances client.
class GlancesApp extends ConsumerWidget {
  const GlancesApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(settingsProvider); // Ensure settings are loaded

    return MaterialApp.router(
      title: 'Glances',
      theme: AppTheme.amoled,
      darkTheme: AppTheme.amoled,
      themeMode: ThemeMode.dark,
      routerConfig: AppRouter.router,
      debugShowCheckedModeBanner: false,
    );
  }
}
