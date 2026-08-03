/// Detail of a single process reported by the Glances `processlist` plugin
/// (`GET /api/4/processes/{pid}`).
///
/// Unlike the flat [ProcessInfo] list entries, the detail response nests CPU
/// times, memory regions, GIDs and I/O counters. The class is parsed manually
/// (rather than via json_serializable) so every field is tolerated: the
/// server can omit fields, rename them across versions, or return `int`s
/// where `double`s are expected, and a process may vanish mid-request.
class ProcessDetailInfo {
  /// Process ID.
  final int? pid;

  /// Process name.
  final String? name;

  /// CPU usage percentage (0-100+ when accounting for multiple cores).
  final double? cpuPercent;

  /// Memory usage percentage (0-100).
  ///
  /// The detail endpoint reports this as `memory_percent`; older versions use
  /// `mem_percent`. Both keys are accepted.
  final double? memPercent;

  /// Process state (e.g. `R` for running, `S` for sleeping on Linux).
  final String? status;

  /// User the process runs as.
  final String? username;

  /// Nice priority of the process.
  final int? nice;

  /// Number of threads of the process.
  final int? numThreads;

  /// Command line of the process, split into arguments.
  final List<String>? cmdline;

  /// Per-category CPU times, in seconds (keys such as `user`, `system`,
  /// `iowait`, `children_user`, `children_system`).
  final Map<String, double>? cpuTimes;

  /// Memory region sizes, in bytes (keys such as `rss`, `vms`, `data`,
  /// `shared`, `text`).
  final Map<String, double>? memoryInfo;

  /// Effective/real/saved group ids of the process.
  final Map<String, int>? gids;

  /// I/O counters as reported by psutil, typically
  /// `[read_count, write_count, read_bytes, write_bytes, ...]`.
  final List<double>? ioCounters;

  /// Seconds elapsed since the last process refresh.
  final double? timeSinceUpdate;

  /// Creates a [ProcessDetailInfo] with all fields optional.
  const ProcessDetailInfo({
    this.pid,
    this.name,
    this.cpuPercent,
    this.memPercent,
    this.status,
    this.username,
    this.nice,
    this.numThreads,
    this.cmdline,
    this.cpuTimes,
    this.memoryInfo,
    this.gids,
    this.ioCounters,
    this.timeSinceUpdate,
  });

  /// Parses the process-detail response tolerantly, dropping any field whose
  /// value does not match the expected shape instead of throwing.
  factory ProcessDetailInfo.fromJson(Map<String, dynamic> json) {
    return ProcessDetailInfo(
      pid: _asInt(json['pid']),
      name: json['name'] as String?,
      cpuPercent: _asDouble(json['cpu_percent']),
      memPercent: _asDouble(json['memory_percent']) ??
          _asDouble(json['mem_percent']),
      status: json['status'] as String?,
      username: json['username'] as String?,
      nice: _asInt(json['nice']),
      numThreads: _asInt(json['num_threads']),
      cmdline: _asStringList(json['cmdline']),
      cpuTimes: _asDoubleMap(json['cpu_times']),
      memoryInfo: _asDoubleMap(json['memory_info']),
      gids: _asIntMap(json['gids']),
      ioCounters: _asDoubleList(json['io_counters']),
      timeSinceUpdate: _asDouble(json['time_since_update']),
    );
  }

  static int? _asInt(Object? value) => value is num ? value.toInt() : null;

  static double? _asDouble(Object? value) => value is num ? value.toDouble() : null;

  static List<String>? _asStringList(Object? value) {
    if (value is List) {
      return value.whereType<String>().toList();
    }
    if (value is String) {
      return <String>[value];
    }
    return null;
  }

  static Map<String, double>? _asDoubleMap(Object? value) {
    if (value is! Map) {
      return null;
    }
    final Map<String, double> result = <String, double>{};
    for (final MapEntry<dynamic, dynamic> entry in value.entries) {
      if (entry.key is String && entry.value is num) {
        result[entry.key as String] = (entry.value as num).toDouble();
      }
    }
    return result.isEmpty ? null : result;
  }

  static Map<String, int>? _asIntMap(Object? value) {
    if (value is! Map) {
      return null;
    }
    final Map<String, int> result = <String, int>{};
    for (final MapEntry<dynamic, dynamic> entry in value.entries) {
      if (entry.key is String && entry.value is num) {
        result[entry.key as String] = (entry.value as num).toInt();
      }
    }
    return result.isEmpty ? null : result;
  }

  static List<double>? _asDoubleList(Object? value) {
    if (value is! List) {
      return null;
    }
    final List<double> result = <double>[];
    for (final dynamic item in value) {
      if (item is num) {
        result.add(item.toDouble());
      }
    }
    return result.isEmpty ? null : result;
  }
}
