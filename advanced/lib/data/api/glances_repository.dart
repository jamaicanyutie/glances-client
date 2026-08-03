import 'dart:convert';

import 'package:dio/dio.dart';

import '../exceptions.dart';
import '../models/alert_info.dart';
import '../models/cpu_info.dart';
import '../models/disk_io_info.dart';
import '../models/docker_container_info.dart';
import '../models/fs_info.dart';
import '../models/glances_all.dart';
import '../models/history_point.dart';
import '../models/connection_stats_info.dart';
import '../models/ip_info.dart';
import '../models/load_info.dart';
import '../models/mem_info.dart';
import '../models/mem_swap_info.dart';
import '../models/network_info.dart';
import '../models/per_cpu_info.dart';
import '../models/port_info.dart';
import '../models/process_detail_info.dart';
import '../models/process_info.dart';
import '../models/sensor_info.dart';
import '../models/system_info.dart';
import '../models/vm_info.dart';
import '../models/wifi_info.dart';

/// Read-only client for the Glances REST API (v4).
///
/// Every method performs a GET request against the configured server and
/// returns a typed model. Methods throw an [ApiException] when the server
/// responds with a non-2xx status, when the response body cannot be decoded
/// as JSON, or when the body does not match the expected shape.
class GlancesRepository {
  final Dio _dio;

  /// Creates a [GlancesRepository] backed by [dio].
  GlancesRepository(this._dio);

  static const String _apiPrefix = '/api/4';

  /// Fetches the aggregated stats of every plugin (`GET /api/4/all`).
  Future<GlancesAll> getAll() async {
    final path = '$_apiPrefix/all';
    return GlancesAll.fromJson(_requireMap(await _getJson(path), path));
  }

  /// Fetches CPU usage statistics (`GET /api/4/cpu`).
  Future<CpuInfo> getCpu() async {
    final path = '$_apiPrefix/cpu';
    return CpuInfo.fromJson(_requireMap(await _getJson(path), path));
  }

  /// Fetches the CPU usage history (`GET /api/4/cpu/history/$nb`).
  ///
  /// [nb] is the number of samples to request. The server returns either a
  /// per-category object (`{"user": [[ts, val], ...], "system": [...]}`) or,
  /// on older Glances versions, a flat array of `[ts, val]` pairs. The
  /// category series are summed into a single total-usage series so the
  /// result is one [HistoryPoint] per timestamp, comparable to the live
  /// `cpu.total` figure.
  Future<List<HistoryPoint>> getCpuHistory({int nb = 60}) async {
    final path = '$_apiPrefix/cpu/history/$nb';
    final data = await _getJson(path);
    if (data is Map<String, dynamic>) {
      return _mergeCategoryHistory(data, path);
    }
    final list = _requireList(data, path);
    try {
      return list.map(HistoryPoint.fromJson).toList();
    } on FormatException catch (e) {
      throw ApiException('Malformed history entry in $path: ${e.message}');
    }
  }

  /// Merges the per-category history object from [data] into a single
  /// total-usage series keyed by timestamp.
  ///
  /// Categories that represent idle/unallocated time (`idle`, `guest`,
  /// `guest_nice`) are excluded so the summed value matches the live
  /// `cpu.total` percentage. Timestamps are truncated to the millisecond
  /// before bucketing: the server stamps each category a few microseconds
  /// apart within the same refresh tick, so exact-string keys would split
  /// one sample into multiple points.
  List<HistoryPoint> _mergeCategoryHistory(
    Map<String, dynamic> data,
    String path,
  ) {
    const Set<String> excluded = <String>{'idle', 'guest', 'guest_nice'};
    final Map<String, double> totals = <String, double>{};
    for (final MapEntry<String, dynamic> entry in data.entries) {
      if (excluded.contains(entry.key) || entry.value is! List) {
        continue;
      }
      for (final dynamic item in entry.value as List) {
        if (item is! List || item.length < 2) {
          continue;
        }
        final Object? timeRaw = item[0];
        final Object? valueRaw = item[1];
        if (timeRaw is! String || valueRaw is! num) {
          continue;
        }
        final DateTime? parsed = DateTime.tryParse(timeRaw);
        if (parsed == null) {
          continue;
        }
        final String key = DateTime.utc(
          parsed.year,
          parsed.month,
          parsed.day,
          parsed.hour,
          parsed.minute,
          parsed.second,
          parsed.millisecond,
        ).toIso8601String();
        totals.update(
          key,
          (double v) => v + valueRaw.toDouble(),
          ifAbsent: () => valueRaw.toDouble(),
        );
      }
    }
    if (totals.isEmpty) {
      throw ApiException('Empty history response from $path');
    }
    final List<String> sortedKeys = totals.keys.toList()..sort();
    try {
      return sortedKeys
          .map(
            (String ts) => HistoryPoint(
              time: DateTime.parse(ts),
              value: totals[ts]!,
            ),
          )
          .toList();
    } on FormatException catch (e) {
      throw ApiException('Malformed history entry in $path: ${e.message}');
    }
  }

  /// Fetches memory usage statistics (`GET /api/4/mem`).
  Future<MemInfo> getMem() async {
    final path = '$_apiPrefix/mem';
    return MemInfo.fromJson(_requireMap(await _getJson(path), path));
  }

  /// Fetches filesystem usage statistics (`GET /api/4/fs`).
  Future<List<FsInfo>> getFs() async {
    final path = '$_apiPrefix/fs';
    return _requireList(await _getJson(path), path)
        .map((e) => FsInfo.fromJson(_requireMap(e, path)))
        .toList();
  }

  /// Fetches disk I/O counters (`GET /api/4/diskio`).
  Future<List<DiskIoInfo>> getDiskIo() async {
    final path = '$_apiPrefix/diskio';
    return _requireList(await _getJson(path), path)
        .map((e) => DiskIoInfo.fromJson(_requireMap(e, path)))
        .toList();
  }

  /// Fetches network interface statistics (`GET /api/4/network`).
  Future<List<NetworkInfo>> getNetwork() async {
    final path = '$_apiPrefix/network';
    return _requireList(await _getJson(path), path)
        .map((e) => NetworkInfo.fromJson(_requireMap(e, path)))
        .toList();
  }

  /// Fetches container statistics (`GET /api/4/containers`).
  ///
  /// Recent Glances versions renamed the `docker` plugin to `containers`;
  /// the legacy `/api/4/docker` endpoint no longer exists on those servers.
  Future<List<DockerContainerInfo>> getDocker() async {
    final path = '$_apiPrefix/containers';
    return _requireList(await _getJson(path), path)
        .map((e) => DockerContainerInfo.fromJson(_requireMap(e, path)))
        .toList();
  }

  /// Fetches the top [n] processes by CPU usage (`GET /api/4/processlist/top/$n`).
  Future<List<ProcessInfo>> getTopProcesses({int n = 30}) async {
    final path = '$_apiPrefix/processlist/top/$n';
    return _requireList(await _getJson(path), path)
        .map((e) => ProcessInfo.fromJson(_requireMap(e, path)))
        .toList();
  }

  /// Fetches the full process list (`GET /api/4/processlist`).
  ///
  /// Unlike [getTopProcesses] this returns every process the server reports,
  /// which is needed to compute status-based aggregates such as the number of
  /// zombie/dead/stopped processes.
  Future<List<ProcessInfo>> getProcesses() async {
    final path = '$_apiPrefix/processlist';
    return _requireList(await _getJson(path), path)
        .map((e) => ProcessInfo.fromJson(_requireMap(e, path)))
        .toList();
  }

  /// Fetches the detail of a single process (`GET /api/4/processes/$pid`).
  ///
  /// Returns `null` when the server no longer reports the process (HTTP 404),
  /// so detail screens can degrade gracefully when a process exits.
  Future<ProcessDetailInfo?> getProcessDetail(int pid) async {
    final path = '$_apiPrefix/processes/$pid';
    try {
      return ProcessDetailInfo.fromJson(_requireMap(await _getJson(path), path));
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        return null;
      }
      rethrow;
    }
  }

  /// Fetches the aggregate TCP connection counts (`GET /api/4/connections`).
  ///
  /// The REST API only exposes aggregate counts per connection state plus the
  /// netfilter conntrack stats; the individual connection tuples shown by the
  /// Glances web UI are not available over the HTTP API.
  Future<ConnectionStatsInfo> getConnections() async {
    final path = '$_apiPrefix/connections';
    return ConnectionStatsInfo.fromJson(
      _requireMap(await _getJson(path), path),
    );
  }

  /// Fetches the private/public network addressing (`GET /api/4/ip`).
  ///
  /// The server returns a single object, not a list. Public fields may be
  /// empty strings when no public-IP API is configured.
  Future<IpInfo> getIp() async {
    final path = '$_apiPrefix/ip';
    return IpInfo.fromJson(_requireMap(await _getJson(path), path));
  }

  /// Fetches the Wi-Fi network signals (`GET /api/4/wifi`).
  ///
  /// Linux only; servers without Wi-Fi report an empty list.
  Future<List<WifiInfo>> getWifi() async {
    final path = '$_apiPrefix/wifi';
    return _requireList(await _getJson(path), path)
        .map((e) => WifiInfo.fromJson(_requireMap(e, path)))
        .toList();
  }

  /// Fetches the host/port measurements (`GET /api/4/ports`).
  Future<List<PortInfo>> getPorts() async {
    final path = '$_apiPrefix/ports';
    return _requireList(await _getJson(path), path)
        .map((e) => PortInfo.fromJson(_requireMap(e, path)))
        .toList();
  }

  /// Fetches the virtual machines (`GET /api/4/vms`).
  ///
  /// Empty when no virtualization engine is available on the server.
  Future<List<VmInfo>> getVms() async {
    final path = '$_apiPrefix/vms';
    return _requireList(await _getJson(path), path)
        .map((e) => VmInfo.fromJson(_requireMap(e, path)))
        .toList();
  }

  /// Fetches the memory-swap statistics (`GET /api/4/memswap`).
  Future<MemSwapInfo> getMemSwap() async {
    final path = '$_apiPrefix/memswap';
    return MemSwapInfo.fromJson(_requireMap(await _getJson(path), path));
  }

  /// Fetches the per-core CPU usage (`GET /api/4/percpu`).
  Future<List<PerCpuInfo>> getPerCpu() async {
    final path = '$_apiPrefix/percpu';
    return _requireList(await _getJson(path), path)
        .map((e) => PerCpuInfo.fromJson(_requireMap(e, path)))
        .toList();
  }

  /// Fetches the history of a single plugin field
  /// (`GET /api/4/{plugin}/{item}/history/{nb}`).
  ///
  /// [plugin] is the plugin name (`cpu`, `mem`, `fs`, `diskio`, `network`,
  /// ...) and [item] is the field whose samples should be returned. The
  /// server returns either a flat array of `[ts, val]` pairs or — on newer
  /// versions — an object wrapping the series in a key named after the item;
  /// both shapes are accepted. An empty series is returned when the server
  /// does not track history for the field.
  Future<List<HistoryPoint>> getItemHistory({
    required String plugin,
    required String item,
    int nb = 60,
  }) async {
    final path = '$_apiPrefix/$plugin/$item/history/$nb';
    final Object? data = await _getJson(path);
    List<dynamic>? raw;
    if (data is List) {
      raw = data;
    } else if (data is Map<String, dynamic>) {
      final Object? wrapped = data[item];
      if (wrapped is List) {
        raw = wrapped;
      } else {
        for (final Object? value in data.values) {
          if (value is List) {
            raw = value;
            break;
          }
        }
      }
    }
    if (raw == null) {
      return const <HistoryPoint>[];
    }
    try {
      return raw.map(HistoryPoint.fromJson).toList();
    } on FormatException catch (e) {
      throw ApiException('Malformed history entry in $path: ${e.message}');
    }
  }

  /// Fetches system load averages (`GET /api/4/load`).
  Future<LoadInfo> getLoad() async {
    final path = '$_apiPrefix/load';
    return LoadInfo.fromJson(_requireMap(await _getJson(path), path));
  }

  /// Fetches hardware sensors (`GET /api/4/sensors`).
  Future<List<SensorInfo>> getSensors() async {
    final path = '$_apiPrefix/sensors';
    return _requireList(await _getJson(path), path)
        .map((e) => SensorInfo.fromJson(_requireMap(e, path)))
        .toList();
  }

  /// Fetches host system metadata (`GET /api/4/system`).
  Future<SystemInfo> getSystem() async {
    final path = '$_apiPrefix/system';
    return SystemInfo.fromJson(_requireMap(await _getJson(path), path));
  }

  /// Fetches the system uptime (`GET /api/4/uptime`).
  ///
  /// Glances returns the uptime as a plain JSON string (e.g. `"2 days,
  /// 4:50:39"`), not an object, so this method returns the raw string.
  Future<String> getUptime() async {
    final path = '$_apiPrefix/uptime';
    final Object? data = await _getJson(path);
    if (data is String) {
      return data;
    }
    throw ApiException(
      'Unexpected response from $path: expected a JSON string, '
      'got ${data == null ? 'null' : data.runtimeType}',
    );
  }

  /// Fetches the alert history (`GET /api/4/alert`).
  Future<List<AlertInfo>> getAlerts() async {
    final path = '$_apiPrefix/alert';
    return _requireList(await _getJson(path), path)
        .map((e) => AlertInfo.fromJson(_requireMap(e, path)))
        .toList();
  }

  /// Performs a GET and returns the decoded JSON body.
  ///
  /// Throws an [ApiException] on non-2xx responses and when the response
  /// body is not valid JSON.
  Future<dynamic> _getJson(String path) async {
    String body;
    try {
      final response = await _dio.get<String>(
        path,
        options: Options(
          responseType: ResponseType.plain,
          validateStatus: (status) => status != null && status >= 200 && status < 300,
        ),
      );
      final data = response.data;
      if (data is! String) {
        throw ApiException(
          'Unexpected response from $path: expected a text body, '
          'got ${data.runtimeType}',
        );
      }
      body = data;
    } on DioException catch (e) {
      throw ApiException(
        'Request to $path failed: ${e.message ?? e.type}',
        statusCode: e.response?.statusCode,
      );
    }
    try {
      return jsonDecode(body);
    } on FormatException catch (e) {
      throw ApiException('Malformed JSON response from $path: ${e.message}');
    }
  }

  /// Checks that [data] is a JSON object, throwing an [ApiException] otherwise.
  Map<String, dynamic> _requireMap(dynamic data, String path) {
    if (data is Map<String, dynamic>) {
      return data;
    }
    throw ApiException(
      'Unexpected response from $path: expected a JSON object, '
      'got ${data == null ? 'null' : data.runtimeType}',
    );
  }

  /// Checks that [data] is a JSON array, throwing an [ApiException] otherwise.
  List<dynamic> _requireList(dynamic data, String path) {
    if (data is List<dynamic>) {
      return data;
    }
    throw ApiException(
      'Unexpected response from $path: expected a JSON array, '
      'got ${data == null ? 'null' : data.runtimeType}',
    );
  }
}
