import 'dart:convert';

import 'package:dio/dio.dart';

import '../exceptions.dart';
import '../models/cpu_info.dart';
import '../models/disk_io_info.dart';
import '../models/docker_container_info.dart';
import '../models/fs_info.dart';
import '../models/glances_all.dart';
import '../models/history_point.dart';
import '../models/load_info.dart';
import '../models/mem_info.dart';
import '../models/network_info.dart';

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

  /// Fetches system load averages (`GET /api/4/load`).
  Future<LoadInfo> getLoad() async {
    final path = '$_apiPrefix/load';
    return LoadInfo.fromJson(_requireMap(await _getJson(path), path));
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
