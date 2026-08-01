import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';

import '../../config/server_config.dart';

/// Builds the [Dio] HTTP client used to talk to the Glances REST API.
///
/// The client accepts any TLS certificate, because the Tailscale-hosted
/// Glances server presents a certificate that is not signed by a public
/// certificate authority. Timeouts are generous to tolerate slow remote
/// hosts. Requests are logged in debug builds only.
Dio buildDio(ServerConfig config) {
  final dio = Dio(
    BaseOptions(
      baseUrl: config.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );

  dio.httpClientAdapter = IOHttpClientAdapter(
    // Accept the server certificate during the TLS handshake (dart:io
    // level). Required for the self-signed Tailscale certificate.
    createHttpClient: () => HttpClient()
      ..badCertificateCallback = (cert, host, port) => true,
    // Accept the leaf certificate at the dio level as well. This is the
    // successor of the `badCertificateCallback` option that dio 5.10
    // removed from [IOHttpClientAdapter].
    validateCertificate: (cert, host, port) => true,
  );

  if (kDebugMode) {
    dio.interceptors.add(
      LogInterceptor(requestBody: false, responseBody: false),
    );
  }

  return dio;
}
