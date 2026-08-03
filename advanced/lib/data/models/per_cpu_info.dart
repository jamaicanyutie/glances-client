import 'package:json_annotation/json_annotation.dart';

part 'per_cpu_info.g.dart';

/// Per-core CPU usage reported by the Glances `percpu` plugin
/// (`GET /api/4/percpu`).
///
/// All fields are nullable because the set of fields reported by the server
/// is platform-dependent and can vary between Glances versions.
@JsonSerializable()
class PerCpuInfo {
  /// Zero-based index of the CPU core.
  @JsonKey(name: 'cpu_number')
  final int? cpuNumber;

  /// Total usage percentage of the core (0-100).
  final double? total;

  /// User-space time percentage.
  final double? user;

  /// System/kernel time percentage.
  final double? system;

  /// Idle time percentage.
  final double? idle;

  /// I/O wait time percentage.
  final double? iowait;

  /// Nice-priority user-space time percentage.
  final double? nice;

  /// Time stolen by the hypervisor, as a percentage.
  final double? steal;

  /// Hardware-interrupt time percentage.
  final double? irq;

  /// Software-interrupt time percentage.
  final double? softirq;

  /// Guest time percentage.
  final double? guest;

  /// Guest nice time percentage.
  @JsonKey(name: 'guest_nice')
  final double? guestNice;

  /// Creates a [PerCpuInfo] with all fields optional.
  const PerCpuInfo({
    this.cpuNumber,
    this.total,
    this.user,
    this.system,
    this.idle,
    this.iowait,
    this.nice,
    this.steal,
    this.irq,
    this.softirq,
    this.guest,
    this.guestNice,
  });

  factory PerCpuInfo.fromJson(Map<String, dynamic> json) =>
      _$PerCpuInfoFromJson(json);

  Map<String, dynamic> toJson() => _$PerCpuInfoToJson(this);
}
