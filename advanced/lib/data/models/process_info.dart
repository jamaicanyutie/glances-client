import 'package:json_annotation/json_annotation.dart';

part 'process_info.g.dart';

/// A single process entry from the Glances `processlist` plugin.
///
/// Only a subset of the fields reported by the server is modeled here.
/// All fields are nullable because the set of fields reported by the server
/// is platform-dependent (Linux vs Windows vs macOS) and can vary between
/// Glances versions.
@JsonSerializable()
class ProcessInfo {
  /// Process ID.
  final int? pid;

  /// Process name.
  final String? name;

  /// CPU usage percentage (0-100+ when accounting for multiple cores).
  @JsonKey(name: 'cpu_percent')
  final double? cpuPercent;

  /// Memory usage percentage (0-100).
  ///
  /// The processlist endpoint reports this as `memory_percent` in Glances
  /// 4.5.x; older versions use `mem_percent`. Both keys are accepted, with
  /// `memory_percent` taking precedence (see [fromJson]).
  @JsonKey(name: 'mem_percent')
  final double? memPercent;

  /// Process state (e.g. `R` for running, `S` for sleeping on Linux).
  final String? status;

  /// User the process runs as.
  final String? username;

  /// Command line of the process, split into arguments.
  final List<String>? command;

  /// Creates a [ProcessInfo] with all fields optional.
  const ProcessInfo({
    this.pid,
    this.name,
    this.cpuPercent,
    this.memPercent,
    this.status,
    this.username,
    this.command,
  });

  /// Parses a processlist entry tolerantly, accepting both the
  /// `memory_percent` key used by Glances 4.5.x and the legacy `mem_percent`
  /// key, preferring the former.
  factory ProcessInfo.fromJson(Map<String, dynamic> json) {
    final ProcessInfo parsed = _$ProcessInfoFromJson(json);
    return ProcessInfo(
      pid: parsed.pid,
      name: parsed.name,
      cpuPercent: parsed.cpuPercent,
      memPercent:
          _asDouble(json['memory_percent']) ?? _asDouble(json['mem_percent']),
      status: parsed.status,
      username: parsed.username,
      command: parsed.command,
    );
  }

  static double? _asDouble(Object? value) =>
      value is num ? value.toDouble() : null;

  Map<String, dynamic> toJson() => _$ProcessInfoToJson(this);
}
