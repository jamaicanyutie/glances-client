import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/server_config.dart';
import 'server_connect_dialog.dart';

/// Small top-right reset button (settings-cog size) on every screen's
/// AppBar. Opens the [ServerConnectDialog] pre-filled with the current server
/// address so the user can point the client at a different Glances instance.
class ServerResetButton extends ConsumerWidget {
  const ServerResetButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String? current = ref.watch(serverConfigProvider).value?.baseUrl;
    return IconButton(
      tooltip: 'Server',
      icon: const Icon(Icons.settings, size: 18),
      visualDensity: VisualDensity.compact,
      onPressed: () {
        showDialog<void>(
          context: context,
          builder: (BuildContext context) =>
              ServerConnectDialog(initialUrl: current),
        );
      },
    );
  }
}
