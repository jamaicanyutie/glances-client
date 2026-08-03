import 'package:json_annotation/json_annotation.dart';

part 'docker_container_info.g.dart';

/// Container statistics reported by the Glances `containers` plugin.
///
/// All fields are nullable because the set of fields reported by the server
/// can vary between container engines and Glances versions, and the
/// `containers` plugin is only present when a container engine (e.g. Docker)
/// is available on the host.
@JsonSerializable()
class DockerContainerInfo {
  /// Container name.
  final String? name;

  /// Container ID (short form).
  final String? id;

  /// Container status. In recent Glances versions this is the container
  /// health state (e.g. `healthy`, `unhealthy`, `running`) rather than the
  /// legacy Docker state (`running`, `exited`).
  final String? status;

  /// Container image (e.g. `nginx:latest`). Reported as a list in recent
  /// Glances versions, but can be a bare string on some setups (Unraid); both
  /// forms are normalized to a list.
  @JsonKey(fromJson: _imageFromJson)
  final List<String>? image;

  /// Normalizes the `image` field, which Glances reports as a list of tags
  /// normally, but as a single string on some engines/setups.
  static List<String>? _imageFromJson(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is List) {
      return value.map((Object? e) => e.toString()).toList();
    }
    return <String>[value.toString()];
  }

  /// CPU usage percentage (0-100+ when accounting for multiple cores).
  @JsonKey(name: 'cpu_percent')
  final double? cpuPercent;

  /// Memory usage percentage (0-100).
  ///
  /// The containers endpoint reports this as `memory_percent` in Glances
  /// 4.5.x (where it is always null) and as `mem_percent` in older versions;
  /// both keys are accepted, with `memory_percent` taking precedence (see
  /// [fromJson]). Prefer the computed [memoryPercent] getter, which falls
  /// back to deriving the value from the byte counters when the server
  /// reports neither key.
  @JsonKey(name: 'mem_percent')
  final double? memPercent;

  /// Memory usage breakdown, keyed by metric name (e.g. `usage`, `limit`),
  /// with values in bytes.
  @JsonKey(name: 'mem_usage')
  final Map<String, double>? memUsage;

  /// Container state (e.g. `running`, `paused`).
  final String? state;

  /// Container engine (e.g. `docker`).
  final String? engine;

  /// Command the container was started with (e.g. `/entrypoint.sh`).
  ///
  /// Glances reports this as a space-joined string for active containers but
  /// as the raw argv list (or null) for inactive/unhealthy ones — the
  /// Docker engine only joins the list on the active-code path. Both forms
  /// are normalized to a single string.
  @JsonKey(fromJson: _commandFromJson)
  final String? command;

  /// Normalizes the `command` field, which Glances reports either as a single
  /// string (running/healthy containers) or as a list of arguments
  /// (unhealthy/stopped containers), or null.
  static String? _commandFromJson(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is String) {
      return value;
    }
    if (value is List) {
      return value.join(' ');
    }
    return value.toString();
  }

  /// Container creation timestamp (ISO-8601).
  final String? created;

  /// Human-readable uptime (e.g. `2 hours`).
  final String? uptime;

  /// Exposed ports (raw string, may be empty).
  final String? ports;

  /// I/O counters: cumulative read/write bytes and per-refresh rates
  /// (`cumulative_ior`, `cumulative_iow`, `ior`, `iow`).
  @JsonKey(name: 'io')
  final Map<String, double>? io;

  /// CPU counters: `total` usage percent and `limit` (cores).
  final Map<String, double>? cpu;

  /// Memory counters in bytes: `usage`, `limit`, `inactive_file`.
  final Map<String, double>? memory;

  /// Network counters: cumulative rx/tx bytes and per-refresh rates
  /// (`cumulative_rx`, `cumulative_tx`, `rx`, `tx`).
  final Map<String, double>? network;

  /// Creates a [DockerContainerInfo] with all fields optional.
  const DockerContainerInfo({
    this.name,
    this.id,
    this.status,
    this.image,
    this.cpuPercent,
    this.memPercent,
    this.memUsage,
    this.state,
    this.engine,
    this.command,
    this.created,
    this.uptime,
    this.ports,
    this.io,
    this.cpu,
    this.memory,
    this.network,
  });

  /// Whether the container is effectively up.
  ///
  /// Matches both the legacy Docker states (`running`) and the health-state
  /// values reported by recent Glances versions (`healthy`, `unhealthy`,
  /// `restarting`). Exited, paused, dead and created containers count as
  /// down.
  bool get isRunning {
    final String? s = status ?? state;
    switch (s) {
      case 'running':
      case 'healthy':
      case 'unhealthy':
      case 'restarting':
        return true;
      default:
        return false;
    }
  }

  /// Memory usage percentage, preferring the server-provided value and
  /// falling back to computing it from `memory.usage / memory.limit`
  /// (Glances 4.5.x never populates container `memory_percent`).
  double? get memoryPercent {
    final double? direct = memPercent;
    if (direct != null) return direct;
    final Map<String, double>? mem = memory ?? memUsage;
    final double? used = mem?['usage'];
    final double? limit = mem?['limit'];
    if (used != null && limit != null && limit > 0) return (used / limit) * 100;
    return null;
  }

  /// Parses a container entry tolerantly, accepting both the
  /// `memory_percent` key used by Glances 4.5.x and the legacy `mem_percent`
  /// key, preferring the former.
  factory DockerContainerInfo.fromJson(Map<String, dynamic> json) {
    final DockerContainerInfo parsed = _$DockerContainerInfoFromJson(json);
    return DockerContainerInfo(
      name: parsed.name,
      id: parsed.id,
      status: parsed.status,
      image: parsed.image,
      cpuPercent: parsed.cpuPercent,
      memPercent:
          _asDouble(json['memory_percent']) ?? _asDouble(json['mem_percent']),
      memUsage: parsed.memUsage,
      state: parsed.state,
      engine: parsed.engine,
      command: parsed.command,
      created: parsed.created,
      uptime: parsed.uptime,
      ports: parsed.ports,
      io: parsed.io,
      cpu: parsed.cpu,
      memory: parsed.memory,
      network: parsed.network,
    );
  }

  static double? _asDouble(Object? value) =>
      value is num ? value.toDouble() : null;

  Map<String, dynamic> toJson() => _$DockerContainerInfoToJson(this);
}
