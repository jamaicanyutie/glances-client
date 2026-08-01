import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Immutable configuration describing how to reach the Glances server.
///
/// The data layer consumes a [ServerConfig] to build the [Dio] HTTP client
/// used by the repository.
class ServerConfig {
  /// Base URL of the Glances REST API server (scheme + host, no trailing
  /// slash, e.g. `https://glances.example.com` or `http://192.168.1.10:61208`).
  final String baseUrl;

  /// Creates a [ServerConfig] with an explicit base URL.
  const ServerConfig({required this.baseUrl});

  /// Normalizes a user-entered address into a base URL.
  ///
  /// Accepts `https://host`, `http://host`, `host:port` and bare `ip:port`
  /// (which defaults to the `http://` scheme). Trailing slashes are stripped.
  static String normalize(String input) {
    String value = input.trim();
    if (value.isEmpty) {
      return value;
    }
    if (!value.startsWith('http://') && !value.startsWith('https://')) {
      value = 'http://$value';
    }
    while (value.endsWith('/')) {
      value = value.substring(0, value.length - 1);
    }
    return value;
  }

  /// Returns an error message when [input] is not a usable server address,
  /// or null when it is valid.
  static String? validate(String input) {
    final String value = input.trim();
    if (value.isEmpty) {
      return 'Enter a server address';
    }
    // If the user typed an explicit scheme it must be http or https. Checked
    // before normalize() because e.g. `ftp://host` would otherwise be mangled
    // into `http://ftp://host` and wrongly accepted.
    if (value.contains('://') &&
        !value.startsWith('http://') &&
        !value.startsWith('https://')) {
      return 'Scheme must be http or https';
    }
    final Uri? uri = Uri.tryParse(normalize(value));
    if (uri == null || uri.host.isEmpty) {
      return 'Enter a valid address, e.g. https://host or 192.168.1.10:61208';
    }
    if (uri.scheme != 'http' && uri.scheme != 'https') {
      return 'Scheme must be http or https';
    }
    return null;
  }
}

/// Loads and persists the [ServerConfig] in [SharedPreferences].
///
/// `state == null` means the user has not configured a server yet — the app
/// shows the first-run connect flow until a server is saved.
final class ServerConfigController extends AsyncNotifier<ServerConfig?> {
  static const String _storageKey = 'glances_server_base_url';

  @override
  Future<ServerConfig?> build() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? baseUrl = prefs.getString(_storageKey);
    if (baseUrl == null || baseUrl.isEmpty) {
      return null;
    }
    return ServerConfig(baseUrl: baseUrl);
  }

  /// Persists [baseUrl] and publishes it as the current configuration.
  Future<void> setBaseUrl(String baseUrl) async {
    final String normalized = ServerConfig.normalize(baseUrl);
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, normalized);
    state = AsyncData<ServerConfig?>(ServerConfig(baseUrl: normalized));
  }
}

/// Provides the current [ServerConfig], or null before first configuration.
///
/// Override this provider in tests or when connecting to a different Glances
/// instance.
final serverConfigProvider =
    AsyncNotifierProvider<ServerConfigController, ServerConfig?>(
  ServerConfigController.new,
);
