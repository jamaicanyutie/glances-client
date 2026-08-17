import 'package:json_annotation/json_annotation.dart';

part 'program_info.g.dart';

/// A single aggregated program entry from the Glances `programlist` plugin.
///
/// Unlike `processlist` (one entry per process), `programlist` aggregates the
/// processes of the same program — each entry groups many processes, hence the
/// `nprocs` count and a placeholder `"_"` pid. Only a subset of the fields
/// reported by the server is modeled here, matching the [ProcessInfo] pattern;
/// all fields are nullable because the set reported varies between platforms
/// and Glances versions. Percentages are on a 0-100 scale.
@JsonSerializable()
class ProgramInfo {
  /// Program name.
  final String? name;

  /// Command line of the program, split into arguments.
  final List<String>? cmdline;

  /// Aggregated pid. Always `"_"` for a programlist entry (no single pid).
  final String? pid;

  /// Aggregate CPU usage percentage (0-100+ across the program's processes).
  @JsonKey(name: 'cpu_percent')
  final double? cpuPercent;

  /// Aggregate memory usage percentage (0-100).
  @JsonKey(name: 'memory_percent')
  final double? memoryPercent;

  /// Total number of threads across all the program's processes.
  @JsonKey(name: 'num_threads')
  final int? numThreads;

  /// Number of processes aggregated into this entry.
  final int? nprocs;

  /// User the program's processes run as.
  final String? username;

  /// Aggregate process state (e.g. `S`, `R`, `Z` on Linux).
  final String? status;

  /// Creates a [ProgramInfo] with all fields optional.
  const ProgramInfo({
    this.name,
    this.cmdline,
    this.pid,
    this.cpuPercent,
    this.memoryPercent,
    this.numThreads,
    this.nprocs,
    this.username,
    this.status,
  });

  factory ProgramInfo.fromJson(Map<String, dynamic> json) =>
      _$ProgramInfoFromJson(json);

  Map<String, dynamic> toJson() => _$ProgramInfoToJson(this);
}