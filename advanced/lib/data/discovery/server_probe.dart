/// Connection probing: test whether a Glances REST API is reachable.
library;

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';

import '../../config/server_config.dart';

/// Result of a connection test against a candidate Glances server.
class ConnectionTestResult {
  const ConnectionTestResult({
    required this.success,
    required this.message,
    this.latency,
    this.baseUrl,
  });

  /// Whether the API responded with HTTP 200.
  final bool success;

  /// Human-readable message describing the outcome.
  final String message;

  /// Round-trip latency in milliseconds, when a response was received.
  final int? latency;

  /// The base URL that answered (only set on success — the candidate that
  /// actually worked, e.g. `https://host` when https won the fallback chain).
  final String? baseUrl;

  @override
  String toString() => message;
}

/// Probes every candidate for a user-entered address in resolution order and
/// returns the first success.
///
/// Resolution order (see [ServerConfig.resolveCandidates]): explicit
/// `http(s)://` as typed; hostnames `https://` first then `http://`; `ip:port`
/// straight to `http://`. When every candidate fails, the last failure is
/// reported. Never throws.
Future<ConnectionTestResult> probeWithFallback(
  String input, {
  bool allowInsecureTls = true,
}) async {
  final List<String> candidates = ServerConfig.resolveCandidates(input);
  if (candidates.isEmpty) {
    return const ConnectionTestResult(
      success: false,
      message: 'Enter a server address',
    );
  }
  ConnectionTestResult lastFailure = const ConnectionTestResult(
    success: false,
    message: 'No candidates to probe',
  );
  for (final String baseUrl in candidates) {
    final ConnectionTestResult result =
        await testConnection(baseUrl, allowInsecureTls: allowInsecureTls);
    if (result.success) {
      return result;
    }
    lastFailure = result;
  }
  return lastFailure;
}

/// Tests a single Glances REST API at [baseUrl].
///
/// Probes `GET $baseUrl/api/4/version` first (the smallest REST endpoint;
/// the bare `/api/4` path returns 404 on Glances 4.x even when healthy), then
/// falls back to `GET $baseUrl/api/4` for servers that only answer there.
/// Never throws — network failures are captured into [ConnectionTestResult].
/// When [allowInsecureTls] is true the HTTPS check is relaxed (self-signed
/// certificates accepted).
Future<ConnectionTestResult> testConnection(
  String baseUrl, {
  bool allowInsecureTls = true,
}) async {
  final stopwatch = Stopwatch()..start();
  try {
    final dio = _buildDio(allowInsecureTls);
    final String versionUrl = '$baseUrl/api/4/version';
    final Response<dynamic> response =
        await dio.get<dynamic>(versionUrl, options: Options(
          validateStatus: (int? status) => status != null && status < 500,
        ));
    if (response.statusCode == 200) {
      stopwatch.stop();
      return ConnectionTestResult(
        success: true,
        message: 'Connected to $baseUrl in ${stopwatch.elapsedMilliseconds} ms',
        latency: stopwatch.elapsedMilliseconds,
        baseUrl: baseUrl,
      );
    }
    // /api/4/version answered with a non-200 (404 etc.) — try the bare path
    // before giving up, so servers exposing only the root REST endpoint still
    // connect.
    final Response<dynamic> fallback = await dio.get<dynamic>(
      '$baseUrl/api/4',
      options: Options(
        validateStatus: (int? status) => status != null && status < 500,
      ),
    );
    stopwatch.stop();
    if (fallback.statusCode == 200) {
      return ConnectionTestResult(
        success: true,
        message: 'Connected to $baseUrl in ${stopwatch.elapsedMilliseconds} ms',
        latency: stopwatch.elapsedMilliseconds,
        baseUrl: baseUrl,
      );
    }
    return ConnectionTestResult(
      success: false,
      message: 'No Glances REST API at $baseUrl'
          ' (server answered HTTP ${response.statusCode})',
      baseUrl: baseUrl,
    );
  } on DioException catch (e) {
    stopwatch.stop();
    final String message = switch (e.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.receiveTimeout =>
        'Connection timed out, host: $baseUrl',
      DioExceptionType.connectionError ||
      DioExceptionType.badCertificate =>
        'Connection refused, host: $baseUrl',
      DioExceptionType.badResponse =>
        'Server answered HTTP ${e.response?.statusCode} at $baseUrl'
            ' (${_statusMeaning(e.response?.statusCode)})',
      _ => 'Request failed: ${e.message}',
    };
    return ConnectionTestResult(success: false, message: message);
  } catch (_) {
    stopwatch.stop();
    return ConnectionTestResult(
      success: false,
      message: 'Request failed, host: $baseUrl',
    );
  }
}

/// Short human-readable meaning for common HTTP status codes.
String _statusMeaning(int? status) {
  return switch (status) {
    400 => 'bad request',
    401 => 'unauthorized',
    403 => 'forbidden',
    404 => 'address or API not found on this server',
    405 => 'method not allowed',
    500 => 'server error',
    502 || 503 || 504 => 'server unavailable',
    _ => 'unexpected response',
  };
}

Dio _buildDio(bool allowInsecureTls) {
  final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );
  if (allowInsecureTls) {
    dio.httpClientAdapter = IOHttpClientAdapter(
      // Accept the server certificate during the TLS handshake (dart:io
      // level), mirroring the adapter in `lib/data/api/dio_client.dart`.
      createHttpClient: () => HttpClient()
        ..badCertificateCallback = (cert, host, port) => true,
      // Accept the leaf certificate at the dio level as well.
      validateCertificate: (cert, host, port) => true,
    );
  }
  return dio;
}
