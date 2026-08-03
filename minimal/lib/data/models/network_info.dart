import 'package:json_annotation/json_annotation.dart';

part 'network_info.g.dart';

/// Network interface statistics reported by the Glances `network` plugin.
///
/// All counters are nullable because the set of fields reported by the
/// server is platform-dependent (Linux vs Windows vs macOS) and can vary
/// between Glances versions. Byte counters are expressed in bytes.
@JsonSerializable()
class NetworkInfo {
  /// Name of the network interface (e.g. `eth0`, `wlan0`).
  @JsonKey(name: 'interface_name')
  final String? interfaceName;

  /// Cumulative bytes sent on the interface.
  @JsonKey(name: 'bytes_sent')
  final double? bytesSent;

  /// Cumulative bytes received on the interface.
  @JsonKey(name: 'bytes_recv')
  final double? bytesRecv;

  /// Cumulative packets sent on the interface.
  @JsonKey(name: 'packets_sent')
  final int? packetsSent;

  /// Cumulative packets received on the interface.
  @JsonKey(name: 'packets_recv')
  final int? packetsRecv;

  /// Cumulative receive errors on the interface.
  final int? errin;

  /// Cumulative transmit errors on the interface.
  final int? errout;

  /// Cumulative dropped received packets on the interface.
  final int? dropin;

  /// Cumulative dropped transmitted packets on the interface.
  final int? dropout;

  /// Interface speed, in bits per second.
  final double? speed;

  /// Whether the interface is currently up.
  @JsonKey(name: 'is_up')
  final bool? isUp;

  /// Creates a [NetworkInfo] with all fields optional.
  const NetworkInfo({
    this.interfaceName,
    this.bytesSent,
    this.bytesRecv,
    this.packetsSent,
    this.packetsRecv,
    this.errin,
    this.errout,
    this.dropin,
    this.dropout,
    this.speed,
    this.isUp,
  });

  factory NetworkInfo.fromJson(Map<String, dynamic> json) =>
      _$NetworkInfoFromJson(json);

  Map<String, dynamic> toJson() => _$NetworkInfoToJson(this);
}
