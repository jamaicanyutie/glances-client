import 'package:json_annotation/json_annotation.dart';

part 'vm_info.g.dart';

/// A single virtual machine from the Glances `vms` plugin
/// (`GET /api/4/vms`).
///
/// Glances discovers VMs through a virtualization engine (virsh/libvirt
/// `[engine]` or multipass); with no engine installed the endpoint returns an
/// empty list. Load averages are `None` when unsupported by the engine, so all
/// fields are nullable.
@JsonSerializable()
class VmInfo {
  /// VM name.
  final String? name;

  /// VM ID.
  final String? id;

  /// VM release/OS label.
  final String? release;

  /// VM status (engine-dependent, e.g. `running`, `paused`, `stopped`).
  final String? status;

  /// Number of virtual CPUs.
  @JsonKey(name: 'cpu_count')
  final int? cpuCount;

  /// VM CPU time as a percentage rate.
  @JsonKey(name: 'cpu_time')
  final num? cpuTime;

  /// VM memory usage, in bytes.
  @JsonKey(name: 'memory_usage')
  final num? memoryUsage;

  /// VM memory total, in bytes.
  @JsonKey(name: 'memory_total')
  final num? memoryTotal;

  /// Load average over the last 1 minute (`None` if unsupported by engine).
  @JsonKey(name: 'load_1min')
  final num? load1min;

  /// Load average over the last 5 minutes (`None` if unsupported by engine).
  @JsonKey(name: 'load_5min')
  final num? load5min;

  /// Load average over the last 15 minutes (`None` if unsupported by engine).
  @JsonKey(name: 'load_15min')
  final num? load15min;

  /// VM IPv4 address.
  final String? ipv4;

  /// Virtualization engine name (e.g. `virsh`).
  final String? engine;

  /// Virtualization engine version.
  @JsonKey(name: 'engine_version')
  final String? engineVersion;

  /// Creates a [VmInfo] with all fields optional.
  const VmInfo({
    this.name,
    this.id,
    this.release,
    this.status,
    this.cpuCount,
    this.cpuTime,
    this.memoryUsage,
    this.memoryTotal,
    this.load1min,
    this.load5min,
    this.load15min,
    this.ipv4,
    this.engine,
    this.engineVersion,
  });

  factory VmInfo.fromJson(Map<String, dynamic> json) => _$VmInfoFromJson(json);

  Map<String, dynamic> toJson() => _$VmInfoToJson(this);
}