import 'package:flutter/material.dart';

import 'ui/navigation/app_router.dart';
import 'ui/theme/theme.dart';

/// Root widget of the Glances client.
///
/// The router is always mounted; the [ServerConfigGate] inside the route tree
/// (see `app_router.dart`) handles the first-run connection flow, so the app
/// Navigator and its dialogs always exist.
class GlancesApp extends StatelessWidget {
  const GlancesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Glances',
      theme: AppTheme.dark,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      routerConfig: AppRouter.router,
      debugShowCheckedModeBanner: false,
    );
  }
}
