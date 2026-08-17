import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:glances_client/config/server_config.dart';
import 'package:glances_client/data/api/dio_client.dart';

/// [HttpClientAdapter] that records the request headers and serves canned
/// JSON.
class _CaptureAdapter implements HttpClientAdapter {
  _CaptureAdapter(this._respondWith);

  final Future<ResponseBody> Function(RequestOptions options) _respondWith;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    return _respondWith(options);
  }

  @override
  void close({bool force = false}) {}
}

Future<ResponseBody> _jsonBody(String json) async {
  return ResponseBody.fromString(
    json,
    200,
    headers: <String, List<String>>{
      Headers.contentTypeHeader: <String>[Headers.jsonContentType],
    },
  );
}

void main() {
  group('buildDio', () {
    test('adds a Basic Authorization header when credentials are set',
        () async {
      final Dio dio = buildDio(
        const ServerConfig(
          baseUrl: 'http://glances.example.com',
          authUsername: 'admin',
          authPassword: 'secret',
        ),
      );
      final List<Map<String, dynamic>> seen = <Map<String, dynamic>>[];
      dio.httpClientAdapter = _CaptureAdapter((RequestOptions options) {
        seen.add(options.headers);
        return _jsonBody('[]');
      });

      await dio.get('/api/4/pluginslist');

      final String expected = base64Encode(utf8.encode('admin:secret'));
      expect(seen, hasLength(1));
      expect(seen.single['Authorization'], 'Basic $expected');
    });

    test('sends no Authorization header without credentials', () async {
      final Dio dio = buildDio(
        const ServerConfig(baseUrl: 'http://glances.example.com'),
      );
      final List<Map<String, dynamic>> seen = <Map<String, dynamic>>[];
      dio.httpClientAdapter = _CaptureAdapter((RequestOptions options) {
        seen.add(options.headers);
        return _jsonBody('[]');
      });

      await dio.get('/api/4/pluginslist');

      expect(seen, hasLength(1));
      expect(seen.single.containsKey('Authorization'), isFalse);
    });
  });
}
