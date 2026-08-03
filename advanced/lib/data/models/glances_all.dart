import 'package:json_annotation/json_annotation.dart';

import 'cpu_info.dart';
import 'disk_io_info.dart';
import 'docker_container_info.dart';
import 'fs_info.dart';
import 'load_info.dart';
import 'mem_info.dart';
import 'network_info.dart';
import 'process_count_info.dart';

part 'glances_all.g.dart';

/// Aggregated snapshot of every plugin, as returned by `GET /api/4/all`.
///
/// Every field is nullable so that a single call can power the whole
/// dashboard even when the server does not report every plugin (for example
/// `docker` is absent when Docker is not installed on the host).
@JsonSerializable()
class GlancesAll {
  /// CPU usage statistics.
  final CpuInfo? cpu;

  /// Memory usage statistics.
  final MemInfo? mem;

  /// System load averages.
  final LoadInfo? load;

  /// Filesystem usage statistics.
  final List<FsInfo>? fs;

  /// Disk I/O counters.
  final List<DiskIoInfo>? diskio;

  /// Network interface statistics.
  final List<NetworkInfo>? network;

  /// Process counters.
  final ProcessCountInfo? processcount;

  /// Container statistics. Recent Glances versions report this under the
  /// `containers` plugin (the legacy `docker` plugin name was renamed).
  @JsonKey(name: 'containers')
  final List<DockerContainerInfo>? docker;

  /// Creates a [GlancesAll] with all fields optional.
  const GlancesAll({
    this.cpu,
    this.mem,
    this.load,
    this.fs,
    this.diskio,
    this.network,
    this.processcount,
    this.docker,
  });

  factory GlancesAll.fromJson(Map<String, dynamic> json) =>
      _$GlancesAllFromJson(json);

  Map<String, dynamic> toJson() => _$GlancesAllToJson(this);
}
