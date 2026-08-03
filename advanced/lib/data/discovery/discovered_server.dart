/// Model for a Glances server discovered on the local network via mDNS.
library;

/// A Glances server discovered via the `_glances._tcp` mDNS service.
///
/// [baseUrl] is computed from [host] and [port] using the plain `http://`
/// scheme — mDNS-discovered servers are on the LAN where TLS is unnecessary.
class DiscoveredServer {
  const DiscoveredServer({
    required this.name,
    required this.host,
    required this.port,
    String? baseUrl,
  }) : baseUrl = baseUrl ?? 'http://$host:$port';

  /// Service instance name, e.g. "Glances on kitchen".
  final String name;

  /// IP address or hostname of the server.
  final String host;

  /// Port the REST API listens on (default 61209).
  final int port;

  /// Computed base URL (`http://host:port`).
  final String baseUrl;

  @override
  String toString() => '$name ($host:$port)';
}
