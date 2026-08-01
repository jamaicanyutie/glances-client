import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/server_config.dart';
import '../theme/theme.dart';

/// Dialog for entering or editing the Glances server address.
///
/// Shown automatically on first run (when no server has been saved yet) and
/// from the small top-right reset button on every screen. Accepts
/// `http(s)://host`, `host:port` and bare `ip:port` (which defaults to
/// `http://`).
class ServerConnectDialog extends ConsumerStatefulWidget {
  const ServerConnectDialog({
    super.key,
    this.initialUrl,
    this.dismissible = true,
  });

  /// Pre-fills the address field (used when editing an existing config).
  final String? initialUrl;

  /// When false the dialog cannot be dismissed (first run) — the user must
  /// enter a valid server address.
  final bool dismissible;

  @override
  ConsumerState<ServerConnectDialog> createState() =>
      _ServerConnectDialogState();
}

class _ServerConnectDialogState extends ConsumerState<ServerConnectDialog> {
  late final TextEditingController _controller;
  String? _errorText;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialUrl ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final String? error = ServerConfig.validate(_controller.text);
    if (error != null) {
      setState(() => _errorText = error);
      return;
    }
    setState(() => _saving = true);
    await ref
        .read(serverConfigProvider.notifier)
        .setBaseUrl(_controller.text);
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: widget.dismissible,
      child: AlertDialog(
        title: const Text('Connect to server'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'Enter the address of your Glances server '
              '(http/https + host or IP:port).',
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _controller,
              autofocus: true,
              keyboardType: TextInputType.url,
              autocorrect: false,
              enableSuggestions: false,
              decoration: InputDecoration(
                labelText: 'Server address',
                hintText: 'https://host:61208',
                errorText: _errorText,
                border: const OutlineInputBorder(),
              ),
              onSubmitted: (_) => _save(),
            ),
          ],
        ),
        actions: <Widget>[
          if (widget.dismissible)
            TextButton(
              onPressed: _saving ? null : () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Connect'),
          ),
        ],
      ),
    );
  }
}
