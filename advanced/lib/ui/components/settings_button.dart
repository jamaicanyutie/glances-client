import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Small settings-cog button on every screen's AppBar.
///
/// Pushes the [/settings] route (top-level, covers the shell) where the user
/// manages the server address, mDNS discovery, TLS trust, theme, refresh
/// intervals and the app updater.
class SettingsButton extends StatelessWidget {
  const SettingsButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Settings',
      icon: const Icon(Icons.settings, size: 18),
      visualDensity: VisualDensity.compact,
      onPressed: () => context.push('/settings'),
    );
  }
}
