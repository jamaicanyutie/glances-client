import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_settings.dart';

/// Immutable configuration describing how to reach the Glances server.
///
/// The data layer consumes a [ServerConfig] to build the [Dio] HTTP client
/// used by the repository.
class ServerConfig {
  /// Base URL of the Glances REST API server (scheme + host, no trailing
  /// slash, e.g. `https://glances.example.com` or `http://192.168.1.10:61208`).
  final String baseUrl;

  /// Whether the HTTP client accepts self-signed / untrusted TLS
  /// certificates (Tailscale, LAN-only servers).
  final bool allowInsecureTls;

  /// Creates a [ServerConfig] with an explicit base URL.
  const ServerConfig({
    required this.baseUrl,
    this.allowInsecureTls = true,
  });

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

  /// Resolves a user-entered address into the ordered list of base URLs to
  /// probe.
  ///
  /// Resolution order:
  ///   1. `ip:port` / bare IP → `http://` directly (IPs are tried last; they
  ///      resolve straight to http, no https attempt).
  ///   2. hostname with no scheme → `https://` first, then `http://` as
  ///      fallback.
  ///   3. Explicit `http(s)://` scheme → used as typed.
  static List<String> resolveCandidates(String input) {
    String value = input.trim();
    if (value.isEmpty) {
      return const <String>[];
    }
    // Explicit scheme: single candidate, exactly as typed.
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return <String>[normalize(value)];
    }
    // Strip a trailing scheme-less path before splitting host:port.
    while (value.endsWith('/')) {
      value = value.substring(0, value.length - 1);
    }
    final String host = _hostOf(value);
    final bool isIp = InternetAddress.tryParse(host) != null;
    if (isIp) {
      // Raw IP addresses resolve directly over http — no https attempt.
      return <String>['http://$value'];
    }
    // Hostnames: https first, http as fallback.
    return <String>['https://$value', 'http://$value'];
  }

  /// Returns the host portion of `host[:port]` or `ip:port`.
  static String _hostOf(String value) {
    // IPv6 literals are bracketed ([::1]:61208) — no port to strip.
    if (value.startsWith('[')) {
      final int close = value.indexOf(']');
      if (close != -1) {
        return value.substring(1, close);
      }
    }
    final int colon = value.lastIndexOf(':');
    if (colon == -1) {
      return value;
    }
    final String after = value.substring(colon + 1);
    // Only treat the suffix as a port when it is numeric; otherwise the
    // colon belongs to the host (unbracketed IPv6, rare).
    if (after.isNotEmpty && int.tryParse(after) != null) {
      return value.substring(0, colon);
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

/// Provides the current [ServerConfig], or null before first configuration.
///
/// Derived from [settingsProvider]: the configured server URL lives in the
/// app settings (so the Settings screen is the single place that edits it),
/// and the TLS trust setting flows through to the HTTP client.
///
/// Override this provider in tests or when connecting to a different Glances
/// instance.
final serverConfigProvider = Provider<ServerConfig?>((ref) {
  final AppSettings settings =
      ref.watch(settingsProvider).value ?? AppSettings.defaults();
  final String? serverUrl = settings.serverUrl;
  if (serverUrl == null || serverUrl.isEmpty) {
    return null;
  }
  return ServerConfig(
    baseUrl: serverUrl,
    allowInsecureTls: settings.allowInsecureTls,
  );
});
