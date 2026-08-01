import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/server_config.dart';
import '../components/error_view.dart';
import '../components/loading_view.dart';
import '../components/server_connect_dialog.dart';
import 'main_shell.dart';

/// Gates the main shell behind the server configuration.
///
/// Lives inside the route tree (not in `MaterialApp.builder`), so the app
/// Navigator always exists and dialogs can be shown normally. While the server
/// config is unresolved it shows a loading state; on first run (no saved
/// server) it shows a non-dismissible connect dialog; once configured it
/// builds the [MainShell].
class ServerConfigGate extends ConsumerStatefulWidget {
  const ServerConfigGate({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<ServerConfigGate> createState() => _ServerConfigGateState();
}

class _ServerConfigGateState extends ConsumerState<ServerConfigGate> {
  bool _connectDialogShown = false;

  @override
  Widget build(BuildContext context) {
    final AsyncValue<ServerConfig?> config = ref.watch(serverConfigProvider);

    return config.when(
      loading: () => const Scaffold(body: LoadingView()),
      error: (Object error, StackTrace stackTrace) => Scaffold(
        body: ErrorView(
          message: '$error',
          onRetry: () => ref.invalidate(serverConfigProvider),
        ),
      ),
      data: (ServerConfig? server) {
        if (server == null) {
          _showConnectDialogOnce();
          return const Scaffold(body: LoadingView());
        }
        return MainShell(navigationShell: widget.navigationShell);
      },
    );
  }

  /// Shows the first-run connect dialog exactly once, after the first frame,
  /// so the dialog and its text field can get proper focus.
  void _showConnectDialogOnce() {
    if (_connectDialogShown) {
      return;
    }
    _connectDialogShown = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) =>
            const ServerConnectDialog(dismissible: false),
      );
    });
  }
}
