/// Aggregate TCP connection counts reported by the Glances `connections`
/// plugin (`GET /api/4/connections`).
///
/// The REST API exposes only aggregate counters per connection state plus the
/// netfilter conntrack statistics — the individual connection tuples shown by
/// the Glances web UI are **not** available over the HTTP API. The class is
/// parsed manually so any connection state the server reports is captured in
/// [statusCounts] regardless of the Glances version.
class ConnectionStatsInfo {
  /// The connection states Glances aggregates on the server. Unknown states
  /// reported by newer versions are still captured via [statusCounts] because
  /// the parser classifies any integer-valued key that is not a documented
  /// scalar field as a state count.
  static const Set<String> _knownStates = <String>{
    'LISTEN',
    'ESTABLISHED',
    'SYN_SENT',
    'SYN_RECV',
    'FIN_WAIT1',
    'FIN_WAIT2',
    'TIME_WAIT',
    'CLOSE',
    'CLOSE_WAIT',
    'LAST_ACK',
    'CLOSING',
    'NONE',
  };

  /// Whether the server exposes per-state connection counts.
  final bool? netConnectionsEnabled;

  /// Whether the server exposes netfilter conntrack statistics.
  final bool? nfConntrackEnabled;

  /// Connections initiated since the last refresh tick.
  final int? initiated;

  /// Connections terminated since the last refresh tick.
  final int? terminated;

  /// Current netfilter conntrack entry count.
  final double? nfConntrackCount;

  /// Maximum netfilter conntrack entry count.
  final double? nfConntrackMax;

  /// Netfilter conntrack usage as a percentage of the maximum (0-100).
  final double? nfConntrackPercent;

  /// Connection count per TCP state, e.g. `{'LISTEN': 12, 'ESTABLISHED': 203}`.
  final Map<String, int> statusCounts;

  /// Creates a [ConnectionStatsInfo].
  const ConnectionStatsInfo({
    this.netConnectionsEnabled,
    this.nfConntrackEnabled,
    this.initiated,
    this.terminated,
    this.nfConntrackCount,
    this.nfConntrackMax,
    this.nfConntrackPercent,
    this.statusCounts = const <String, int>{},
  });

  /// Total number of connections across every reported state.
  int get totalConnections =>
      statusCounts.values.fold<int>(0, (int sum, int count) => sum + count);

  /// Parses the connections response, classifying every integer-valued key
  /// that is not a documented scalar field as a per-state connection count.
  factory ConnectionStatsInfo.fromJson(Map<String, dynamic> json) {
    final Map<String, int> statusCounts = <String, int>{};
    for (final String state in _knownStates) {
      final Object? value = json[state];
      if (value is num) {
        statusCounts[state] = value.toInt();
      }
    }
    // Capture any state keys this client version does not know about.
    for (final MapEntry<String, dynamic> entry in json.entries) {
      if (entry.key == entry.key.toUpperCase() && entry.value is num) {
        statusCounts[entry.key] = (entry.value as num).toInt();
      }
    }
    return ConnectionStatsInfo(
      netConnectionsEnabled: json['net_connections_enabled'] as bool?,
      nfConntrackEnabled: json['nf_conntrack_enabled'] as bool?,
      initiated: _asInt(json['initiated']),
      terminated: _asInt(json['terminated']),
      nfConntrackCount: _asDouble(json['nf_conntrack_count']),
      nfConntrackMax: _asDouble(json['nf_conntrack_max']),
      nfConntrackPercent: _asDouble(json['nf_conntrack_percent']),
      statusCounts: statusCounts,
    );
  }

  static int? _asInt(Object? value) => value is num ? value.toInt() : null;

  static double? _asDouble(Object? value) => value is num ? value.toDouble() : null;
}
