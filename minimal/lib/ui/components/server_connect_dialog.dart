import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/server_config.dart';
import '../theme/theme.dart';

/// Dialog for entering or editing the Glances server address and optional
/// HTTP Basic-auth credentials.
///
/// Shown automatically on first run (when no server has been saved yet) and
/// from the small top-right reset button on every screen. Accepts
/// `http(s)://host`, `host:port` and bare `ip:port` (which defaults to
/// `http://`). Username and password are optional and sent with every request
/// when provided.
class ServerConnectDialog extends ConsumerStatefulWidget {
  const ServerConnectDialog({
    super.key,
    this.initialUrl,
    this.initialUsername,
    this.initialPassword,
    this.dismissible = true,
  });

  /// Pre-fills the address field (used when editing an existing config).
  final String? initialUrl;

  /// Pre-fills the username field (used when editing an existing config).
  final String? initialUsername;

  /// Pre-fills the password field (used when editing an existing config).
  final String? initialPassword;

  /// When false the dialog cannot be dismissed (first run) — the user must
  /// enter a valid server address.
  final bool dismissible;

  @override
  ConsumerState<ServerConnectDialog> createState() =>
      _ServerConnectDialogState();
}

class _ServerConnectDialogState extends ConsumerState<ServerConnectDialog> {
  late final TextEditingController _controller;
  late final TextEditingController _usernameController;
  late final TextEditingController _passwordController;
  String? _errorText;
  bool _saving = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialUrl ?? '');
    _usernameController =
        TextEditingController(text: widget.initialUsername ?? '');
    _passwordController =
        TextEditingController(text: widget.initialPassword ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
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
        .setServerConfig(
          _controller.text,
          username: _usernameController.text,
          password: _passwordController.text,
        );
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
              '(http/https + host or IP:port). Username and password are '
              'only needed if the server protects its API with Basic auth.',
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              key: const Key('server_address_field'),
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
            const SizedBox(height: AppSpacing.sm),
            TextField(
              key: const Key('server_username_field'),
              controller: _usernameController,
              autocorrect: false,
              enableSuggestions: false,
              decoration: const InputDecoration(
                labelText: 'Username (optional)',
                hintText: 'admin',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              key: const Key('server_password_field'),
              controller: _passwordController,
              obscureText: _obscurePassword,
              autocorrect: false,
              enableSuggestions: false,
              decoration: InputDecoration(
                labelText: 'Password (optional)',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),
                  onPressed: () => setState(
                    () => _obscurePassword = !_obscurePassword,
                  ),
                ),
              ),
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
