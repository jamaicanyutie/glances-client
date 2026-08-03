import 'package:json_annotation/json_annotation.dart';

part 'process_count_info.g.dart';

/// Process counters reported by the Glances `processcount` plugin.
///
/// All fields are nullable because the set of fields reported by the server
/// is platform-dependent (Linux vs Windows vs macOS) and can vary between
/// Glances versions.
@JsonSerializable()
class ProcessCountInfo {
  /// Total number of processes on the host.
  final int? total;

  /// Number of processes currently running.
  final int? running;

  /// Number of processes currently sleeping.
  final int? sleeping;

  /// Number of threads across all processes.
  ///
  /// The server serializes this field as `thread` (the plugin's internal
  /// name), so it is mapped explicitly.
  @JsonKey(name: 'thread')
  final int? threads;

  /// Highest PID the server has observed (`pid_max`), often 0 on Linux.
  @JsonKey(name: 'pid_max')
  final int? pidMax;

  /// Creates a [ProcessCountInfo] with all fields optional.
  const ProcessCountInfo({
    this.total,
    this.running,
    this.sleeping,
    this.threads,
    this.pidMax,
  });

  factory ProcessCountInfo.fromJson(Map<String, dynamic> json) =>
      _$ProcessCountInfoFromJson(json);

  Map<String, dynamic> toJson() => _$ProcessCountInfoToJson(this);
}
