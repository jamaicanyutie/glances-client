import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/app_settings.dart';
import '../../../config/server_config.dart';
import '../../../data/discovery/discovered_server.dart';
import '../../../data/discovery/discovery_providers.dart';
import '../../../data/discovery/server_probe.dart';
import '../../../data/update/github_release.dart';
import '../../../data/update/update_providers.dart';
import '../../theme/colors.dart';
import '../../theme/theme.dart';

/// Settings screen — replicates the phone app's Settings feature set.
///
/// Sections:
/// * **Server** — address field (with placeholder), mDNS discovery with
///   "Scan again", TLS trust toggle, and a connection test.
/// * **Refresh intervals** — dashboard poll cadence and CPU-history cadence.
/// * **App update** — checks the GitHub latest release and installs it.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late final TextEditingController _addressController;
  late final FocusNode _addressFocus;
  late final TextEditingController _usernameController;
  late final TextEditingController _passwordController;

  /// The address the user last probed (or saved) — drives the inline
  /// connection-test result. Null until the first probe.
  String? _testedUrl;

  /// Whether the password field masks its input.
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _addressController = TextEditingController();
    _addressFocus = FocusNode();
    _usernameController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _addressController.dispose();
    _addressFocus.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppSettings settings =
        ref.watch(settingsProvider).value ?? AppSettings.defaults();
    _addressController.text = settings.serverUrl ?? '';
    _usernameController.text = settings.authUsername ?? '';
    _passwordController.text = settings.authPassword ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: <Widget>[
          _SectionHeader(title: 'Server', icon: Icons.dns),
          const SizedBox(height: AppSpacing.sm),
          _SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                TextField(
                  controller: _addressController,
                  focusNode: _addressFocus,
                  keyboardType: TextInputType.url,
                  autocorrect: false,
                  decoration: const InputDecoration(
                    labelText: 'Server address',
                    hintText:
                        'https://glances.example.com  or  192.168.1.50:61209',
                    prefixIcon: Icon(Icons.link),
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _saveAddress(),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _saveAddress,
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('Save'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _testConnection,
                        icon: const Icon(Icons.network_check, size: 18),
                        label: const Text('Test'),
                      ),
                    ),
                  ],
                ),
                if (_testedUrl != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  _ConnectionTestResult(url: _testedUrl!),
                ],
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Accept self-signed or untrusted '
                      'certificates'),
                  subtitle: const Text('Required for Tailscale and LAN-only '
                      'servers.'),
                  value: settings.allowInsecureTls,
                  onChanged: (bool value) => ref
                      .read(settingsProvider.notifier)
                      .setAllowInsecureTls(value),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const _DiscoverySection(),
          const SizedBox(height: AppSpacing.lg),
          _SectionHeader(title: 'Authentication', icon: Icons.lock),
          const SizedBox(height: AppSpacing.sm),
          _SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                TextField(
                  controller: _usernameController,
                  autocorrect: false,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    hintText: 'Leave empty for an open server',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  autocorrect: false,
                  enableSuggestions: false,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    hintText: 'Optional',
                    prefixIcon: const Icon(Icons.key),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        size: 20,
                      ),
                      onPressed: () => setState(
                        () => _obscurePassword = !_obscurePassword,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _saveAuth,
                        icon: const Icon(Icons.save_outlined, size: 18),
                        label: const Text('Save credentials'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _clearAuth,
                        icon: const Icon(Icons.delete_outline, size: 18),
                        label: const Text('Clear'),
                      ),
                    ),
                  ],
                ),
                if (settings.hasAuth) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: <Widget>[
                      const Icon(
                        Icons.check_circle,
                        size: 16,
                        color: AppColors.success,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          'Credentials saved for '
                          '${settings.authUsername ?? 'this server'}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _SectionHeader(title: 'Refresh intervals', icon: Icons.refresh),
          const SizedBox(height: AppSpacing.sm),
          _SectionCard(
            child: Column(
              children: <Widget>[
                _IntervalTile(
                  title: 'Update interval',
                  subtitle: 'How often the dashboard refreshes.',
                  seconds: settings.pollingIntervalSeconds,
                  onChanged: (int seconds) => ref
                      .read(settingsProvider.notifier)
                      .setPollingIntervalSeconds(seconds),
                ),
                const Divider(height: AppSpacing.lg),
                _IntervalTile(
                  title: 'History interval',
                  subtitle: 'How often the CPU history chart refreshes.',
                  seconds: settings.historyRefreshIntervalSeconds,
                  onChanged: (int seconds) => ref
                      .read(settingsProvider.notifier)
                      .setHistoryRefreshIntervalSeconds(seconds),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _SectionHeader(title: 'App update', icon: Icons.system_update),
          const SizedBox(height: AppSpacing.sm),
          const _UpdateSection(),
        ],
      ),
    );
  }

  /// Probes the address in the text field with scheme fallback (https first
  /// for hostnames) and persists the working base URL on success.
  ///
  /// On failure the saved server is left unchanged and the error is shown
  /// inline so a bad address never clobbers a working configuration.
  Future<void> _saveAddress() async {
    final String raw = _addressController.text.trim();
    final String? error = ServerConfig.validate(raw);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
      return;
    }
    _addressFocus.unfocus();
    setState(() => _testedUrl = raw);
    final ConnectionTestResult result =
        await ref.read(serverProbeProvider(raw).future);
    if (result.success && result.baseUrl != null) {
      await ref.read(settingsProvider.notifier).setServerUrl(result.baseUrl!);
    }
  }

  /// Probes the address currently in the text field without saving it.
  Future<void> _testConnection() async {
    final String raw = _addressController.text.trim();
    if (raw.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a server address first.')),
      );
      return;
    }
    _probe(raw);
  }

  /// Invalidates the probe for the raw [input] and shows its result inline.
  void _probe(String input) {
    setState(() => _testedUrl = input);
    ref.invalidate(serverProbeProvider(input));
  }

  /// Persists the HTTP Basic-auth credentials entered in the form. Empty
  /// fields clear the corresponding value, so saving an empty form disables
  /// auth entirely.
  Future<void> _saveAuth() async {
    final String username = _usernameController.text.trim();
    final String password = _passwordController.text;
    await ref
        .read(settingsProvider.notifier)
        .setAuth(username.isEmpty ? null : username, password.isEmpty ? null : password);
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Credentials saved.')),
    );
  }

  /// Clears both Basic-auth fields and the persisted credentials.
  Future<void> _clearAuth() async {
    _usernameController.clear();
    _passwordController.clear();
    await ref.read(settingsProvider.notifier).clearAuth();
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Credentials cleared.')),
    );
  }
}

/// Inline connection-test result for the most recently probed [url].
class _ConnectionTestResult extends ConsumerWidget {
  const _ConnectionTestResult({required this.url});

  final String url;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<ConnectionTestResult> probe =
        ref.watch(serverProbeProvider(url));
    return probe.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
          children: <Widget>[
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: AppSpacing.sm),
            Text('Testing connection…'),
          ],
        ),
      ),
      error: (Object error, StackTrace stackTrace) => Text(
        'Connection failed',
        style: TextStyle(color: AppColors.danger),
      ),
      data: (ConnectionTestResult result) => Row(
        children: <Widget>[
          Icon(
            result.success ? Icons.check_circle : Icons.error,
            size: 16,
            color: result.success ? AppColors.success : AppColors.danger,
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: SelectableText(
              result.message,
              style: TextStyle(
                color: result.success ? AppColors.success : AppColors.danger,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// mDNS discovery: a "Scan again" button, the discovered server list, and the
/// "No servers found" hint.
class _DiscoverySection extends ConsumerWidget {
  const _DiscoverySection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            _SectionHeader(title: 'Discover on network', icon: Icons.wifi),
            const Spacer(),
            TextButton.icon(
              onPressed: () => ref.invalidate(serverDiscoveryProvider),
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Scan again'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        _SectionCard(
          child: ref.watch(serverDiscoveryProvider).when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: <Widget>[
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: AppSpacing.sm),
                      Text('Scanning for Glances servers…'),
                    ],
                  ),
                ),
                error: (Object error, StackTrace stackTrace) => const Padding(
                  padding: EdgeInsets.all(AppSpacing.md),
                  child: Text('Discovery failed'),
                ),
                data: (List<DiscoveredServer> servers) {
                  if (servers.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(AppSpacing.md),
                      child: Text(
                        'No servers found. Make sure Glances is running on the '
                        'same network (ZeroConf/mDNS enabled, port 61209 '
                        'reachable) or enter the address manually above.',
                        style: TextStyle(fontSize: 13),
                      ),
                    );
                  }
                  return Column(
                    children: <Widget>[
                      for (final DiscoveredServer server in servers)
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                          ),
                          dense: true,
                          leading: const Icon(Icons.dns, size: 20),
                          title: Text(server.name),
                          subtitle: Text(
                            server.baseUrl,
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: const Icon(Icons.chevron_right, size: 18),
                          onTap: () {
                            ref
                                .read(settingsProvider.notifier)
                                .setServerUrl(server.baseUrl);
                            ref.read(selectedDiscoveredServerProvider.notifier)
                                .select(server);
                          },
                        ),
                    ],
                  );
                },
              ),
        ),
      ],
    );
  }
}

/// One refresh-interval row with an inline value picker.
class _IntervalTile extends ConsumerWidget {
  const _IntervalTile({
    required this.title,
    required this.subtitle,
    required this.seconds,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final int seconds;
  final ValueChanged<int> onChanged;

  static const List<int> _options = <int>[1, 2, 5, 10, 30, 60];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(title, style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: AppSpacing.xs),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        DropdownButtonHideUnderline(
          child: DropdownButton<int>(
            value: _options.contains(seconds) ? seconds : _options.first,
            items: <DropdownMenuItem<int>>[
              for (final int option in _options)
                DropdownMenuItem<int>(
                  value: option,
                  child: Text('$option s'),
                ),
            ],
            onChanged: (int? value) {
              if (value != null) {
                onChanged(value);
              }
            },
          ),
        ),
      ],
    );
  }
}

/// App-update section: latest GitHub release, "Update available", and the
/// GitHub update check + install action. Errors render as persistent,
/// long-press-selectable text so they can be copied for debugging.
class _UpdateSection extends ConsumerStatefulWidget {
  const _UpdateSection();

  @override
  ConsumerState<_UpdateSection> createState() => _UpdateSectionState();
}

class _UpdateSectionState extends ConsumerState<_UpdateSection> {
  /// Install error from the last [downloadAndInstall] attempt. Kept in state
  /// (not a SnackBar) so the full message stays visible and copyable.
  String? _installError;

  @override
  Widget build(BuildContext context) {
    final AsyncValue<GithubRelease?> release = ref.watch(updateCheckProvider);
    final AsyncValue<bool> updateAvailable = ref.watch(updateAvailableProvider);

    return _SectionCard(
      child: release.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: <Widget>[
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: AppSpacing.sm),
              Text('Checking for updates…'),
            ],
          ),
        ),
        error: (Object error, StackTrace stackTrace) => Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: SelectableText(
            'Update check failed: $error',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ),
        data: (GithubRelease? latest) {
          if (latest == null) {
            return const Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: Text('No updates available'),
            );
          }
          final bool available =
              updateAvailable.value ?? false;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Icon(
                    available ? Icons.system_update_alt : Icons.check_circle,
                    size: 16,
                    color:
                        available ? AppColors.warning : AppColors.success,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      available
                          ? 'Update available: ${latest.tagName}'
                          : 'You are up to date (${latest.tagName})',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
              if (available) ...[
                const SizedBox(height: AppSpacing.sm),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: () => _install(context, ref, latest),
                    icon: const Icon(Icons.download, size: 18),
                    label: const Text('Install update'),
                  ),
                ),
              ],
              if (_installError != null) ...[
                const SizedBox(height: AppSpacing.sm),
                SelectableText(
                  'Update failed: $_installError',
                  style: const TextStyle(color: AppColors.danger, fontSize: 12),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Future<void> _install(
    BuildContext context,
    WidgetRef ref,
    GithubRelease release,
  ) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    setState(() {
      _installError = null;
    });
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Downloading update…'),
        duration: Duration(seconds: 30),
      ),
    );
    try {
      await downloadAndInstall(release);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        const SnackBar(content: Text('Update downloaded. Install it now?')),
      );
    } on Object catch (error) {
      messenger.hideCurrentSnackBar();
      setState(() {
        _installError = '$error';
      });
    }
  }
}

/// Reusable section header: small icon + uppercase-ish label.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Row(
      children: <Widget>[
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: AppSpacing.xs),
        Text(
          title,
          style: textTheme.labelLarge?.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.4,
          ),
        ),
      ],
    );
  }
}

/// Reusable card body for a settings section.
class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: child,
      ),
    );
  }
}
