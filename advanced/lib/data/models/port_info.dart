import 'package:json_annotation/json_annotation.dart';

part 'port_info.g.dart';

/// A single host/port measurement from the Glances `ports` plugin
/// (`GET /api/4/ports`). Glances scans configured TCP ports (or ICMP, via
/// `port == 0`) and reports the round-trip latency in seconds.
@JsonSerializable()
class PortInfo {
  /// Host or IP address being measured.
  final String? host;

  /// Port being measured (`0` means ICMP ping).
  final int? port;

  /// Human-readable description for this host/port.
  final String? description;

  /// Refresh interval for this measurement, in seconds.
  final int? refresh;

  /// Timeout for the measurement, in seconds.
  final int? timeout;

  /// Latest round-trip measurement result, in seconds.
  final num? status;

  /// Warning threshold for the measurement, in seconds.
  @JsonKey(name: 'rtt_warning')
  final num? rttWarning;

  /// Unique compact key for this host/port pair.
  final int? indice;

  /// Creates a [PortInfo] with all fields optional.
  const PortInfo({
    this.host,
    this.port,
    this.description,
    this.refresh,
    this.timeout,
    this.status,
    this.rttWarning,
    this.indice,
  });

  factory PortInfo.fromJson(Map<String, dynamic> json) =>
      _$PortInfoFromJson(json);

  Map<String, dynamic> toJson() => _$PortInfoToJson(this);

  /// Whether the host/port is currently reachable.
  ///
  /// Glances reports a non-negative `status` when the measurement succeeded;
  /// a `null` or out-of-range value means the probe did not complete.
  bool get isReachable {
    final num? s = status;
    return s != null && s >= 0;
  }

  /// Latest round-trip time in milliseconds, when available.
  double? get rttMs {
    final num? s = status;
    if (s == null || s < 0) {
      return null;
    }
    return s * 1000;
  }
}