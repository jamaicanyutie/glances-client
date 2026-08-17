import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:glances_client/data/api/glances_repository.dart';
import 'package:glances_client/data/exceptions.dart';
import 'package:glances_client/data/providers.dart';

/// [HttpClientAdapter] that serves canned JSON for every request.
class _FakeDioAdapter implements HttpClientAdapter {
  _FakeDioAdapter(this._respondWith);

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

Future<ResponseBody> _jsonBody(String json, {int status = 200}) async {
  return ResponseBody.fromString(
    json,
    status,
    headers: <String, List<String>>{
      Headers.contentTypeHeader: <String>[Headers.jsonContentType],
    },
  );
}

void main() {
  group('hasPluginCapability', () {
    test('treats an unresolved capability set as present', () {
      expect(
        hasPluginCapability(
          const AsyncLoading<Set<String>>(),
          'containers',
        ),
        isTrue,
      );
    });

    test('treats an empty capability set as present (failed lookup)', () {
      expect(
        hasPluginCapability(
          const AsyncValue<Set<String>>.data(<String>{}),
          'containers',
        ),
        isTrue,
      );
    });

    test('returns true when the plugin is reported', () {
      expect(
        hasPluginCapability(
          const AsyncValue<Set<String>>.data(<String>{'cpu', 'mem'}),
          'mem',
        ),
        isTrue,
      );
    });

    test('returns false when the plugin is not reported', () {
      expect(
        hasPluginCapability(
          const AsyncValue<Set<String>>.data(<String>{'cpu', 'mem'}),
          'containers',
        ),
        isFalse,
      );
    });
  });

  group('getPluginsList', () {
    test('returns the enabled plugin names', () async {
      final Dio dio = Dio(
        BaseOptions(
          baseUrl: 'http://glances.example.com',
          responseType: ResponseType.plain,
        ),
      )..httpClientAdapter = _FakeDioAdapter(
          (_) => _jsonBody('["cpu", "mem", "fs", "diskio", "network"]'),
        );
      final GlancesRepository repo = GlancesRepository(dio);

      final List<String> plugins = await repo.getPluginsList();

      expect(plugins, <String>['cpu', 'mem', 'fs', 'diskio', 'network']);
    });

    test('filters out non-string entries', () async {
      final Dio dio = Dio(
        BaseOptions(
          baseUrl: 'http://glances.example.com',
          responseType: ResponseType.plain,
        ),
      )..httpClientAdapter = _FakeDioAdapter(
          (_) => _jsonBody('[1, "cpu", null, "mem", {"name": "fs"}]'),
        );
      final GlancesRepository repo = GlancesRepository(dio);

      final List<String> plugins = await repo.getPluginsList();

      expect(plugins, <String>['cpu', 'mem']);
    });

    test('throws an ApiException on a non-2xx response', () async {
      final Dio dio = Dio(
        BaseOptions(
          baseUrl: 'http://glances.example.com',
          responseType: ResponseType.plain,
        ),
      )..httpClientAdapter = _FakeDioAdapter(
          (_) => _jsonBody('not found', status: 404),
        );
      final GlancesRepository repo = GlancesRepository(dio);

      expect(repo.getPluginsList(), throwsA(isA<ApiException>()));
    });
  });

  group('capabilitiesProvider', () {
    test('resolves to the set of reported plugins', () async {
      final Dio dio = Dio(
        BaseOptions(
          baseUrl: 'http://glances.example.com',
          responseType: ResponseType.plain,
        ),
      )..httpClientAdapter = _FakeDioAdapter(
          (_) => _jsonBody('["cpu", "mem", "containers"]'),
        );
      final ProviderContainer container = ProviderContainer(
        overrides: [
          glancesRepositoryProvider.overrideWithValue(GlancesRepository(dio)),
        ],
      );
      addTearDown(container.dispose);

      final Set<String>? capabilities =
          await container.read(capabilitiesProvider.future);

      expect(capabilities, <String>{'cpu', 'mem', 'containers'});
    });

    test('resolves to an empty set when the lookup fails', () async {
      final Dio dio = Dio(
        BaseOptions(
          baseUrl: 'http://glances.example.com',
          responseType: ResponseType.plain,
        ),
      )..httpClientAdapter = _FakeDioAdapter(
          (_) => _jsonBody('not found', status: 500),
        );
      final ProviderContainer container = ProviderContainer(
        overrides: [
          glancesRepositoryProvider.overrideWithValue(GlancesRepository(dio)),
        ],
      );
      addTearDown(container.dispose);

      final Set<String>? capabilities =
          await container.read(capabilitiesProvider.future);

      expect(capabilities, isEmpty);
    });
  });
}
