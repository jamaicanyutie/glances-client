import 'package:json_annotation/json_annotation.dart';

part 'cpu_info.g.dart';

/// CPU usage statistics reported by the Glances `cpu` plugin.
///
/// All values are nullable because the set of fields reported by the server
/// is platform-dependent (Linux vs Windows vs macOS) and can vary between
/// Glances versions. Percentages are on a 0-100 scale.
@JsonSerializable()
class CpuInfo {
  /// Number of logical CPU cores on the host.
  final int? cpucore;

  /// Total CPU usage percentage (0-100).
  final double? total;

  /// Percentage of CPU time spent in user mode.
  final double? user;

  /// Percentage of CPU time spent in system (kernel) mode.
  final double? system;

  /// Percentage of CPU time spent idle.
  final double? idle;

  /// Percentage of CPU time spent waiting on I/O (Linux only).
  final double? iowait;

  /// Percentage of CPU time spent on low-priority (nice) processes.
  final double? nice;

  /// Percentage of CPU time stolen by the hypervisor (Linux only).
  final double? steal;

  /// Percentage of CPU time spent serving hardware interrupts (Linux only).
  final double? irq;

  /// Percentage of CPU time spent serving software interrupts (Linux only).
  @JsonKey(name: 'soft_interrupts')
  final double? softInterrupts;

  /// Number of context switches since boot (Linux only).
  @JsonKey(name: 'ctx_switches')
  final int? ctxSwitches;

  /// Number of system calls since boot (Linux only).
  final int? syscalls;

  /// Percentage of CPU time spent running guest (virtualized) processes.
  final double? guest;

  /// Percentage of CPU time spent running nice guest (virtualized) processes.
  @JsonKey(name: 'guest_nice')
  final double? guestNice;

  /// Creates a [CpuInfo] with all fields optional.
  const CpuInfo({
    this.cpucore,
    this.total,
    this.user,
    this.system,
    this.idle,
    this.iowait,
    this.nice,
    this.steal,
    this.irq,
    this.softInterrupts,
    this.ctxSwitches,
    this.syscalls,
    this.guest,
    this.guestNice,
  });

  factory CpuInfo.fromJson(Map<String, dynamic> json) =>
      _$CpuInfoFromJson(json);

  Map<String, dynamic> toJson() => _$CpuInfoToJson(this);
}
