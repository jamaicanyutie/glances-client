import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/server_config.dart';
import 'api/dio_client.dart';
import 'api/glances_repository.dart';
import 'models/glances_all.dart';
import 'models/history_point.dart';

/// Provides the [Dio] HTTP client used for all Glances REST API calls.
///
/// Built from the current [serverConfigProvider] value. Throws until a server
/// has been configured; the first-run gate keeps data providers unbuilt until
/// then, so this state is unreachable in practice.
final dioProvider = Provider<Dio>((ref) {
  final ServerConfig? config = ref.watch(serverConfigProvider).value;
  if (config == null) {
    throw StateError('No Glances server configured');
  }
  return buildDio(config);
});

/// Provides the [GlancesRepository] used to query the Glances server.
final glancesRepositoryProvider = Provider<GlancesRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return GlancesRepository(dio);
});

/// How often the live dashboard providers re-fetch from the server.
///
/// The Glances server refreshes its own snapshot roughly once per second, so
/// polling every 2 seconds keeps the dashboard fresh without hammering the
/// host.
const Duration dashboardRefreshInterval = Duration(seconds: 2);

/// How often the CPU history series is re-fetched.
///
/// History moves slower than the live snapshot, so a 5 s poll is plenty.
const Duration historyRefreshInterval = Duration(seconds: 5);

/// Notifier backing [allStatsProvider].
///
/// Fetches `GET /api/4/all` once on build, then re-fetches on every
/// [dashboardRefreshInterval] by invalidating itself. The periodic timer is
/// torn down with the notifier, so no work happens while the provider is
/// unused.
final class AllStatsNotifier extends AsyncNotifier<GlancesAll> {
  @override
  Future<GlancesAll> build() async {
    _startAutoRefresh();
    return ref.watch(glancesRepositoryProvider).getAll();
  }

  /// Forces an immediate re-fetch and waits for it to complete (used by
  /// pull-to-refresh).
  ///
  /// The container is used directly because the notifier's own `ref` forbids
  /// self-references in debug mode; the container layer supports them.
  Future<void> refresh() async {
    ref.invalidateSelf();
    try {
      await ref.container.read(allStatsProvider.future);
    } on Object {
      // The failure is already surfaced through the provider's AsyncValue;
      // swallow it here so pull-to-refresh does not throw.
    }
  }

  void _startAutoRefresh() {
    final Timer timer = Timer.periodic(dashboardRefreshInterval, (_) {
      ref.invalidateSelf();
    });
    ref.onDispose(timer.cancel);
  }
}

/// Aggregated live snapshot of every Glances plugin, auto-refreshed every
/// [dashboardRefreshInterval] seconds.
final allStatsProvider =
    AsyncNotifierProvider<AllStatsNotifier, GlancesAll>(AllStatsNotifier.new);

/// Notifier backing [cpuHistoryProvider].
///
/// Fetches the last 60 CPU-usage samples (`GET /api/4/cpu/history/60`) on
/// build, then re-fetches on every [historyRefreshInterval].
final class CpuHistoryNotifier extends AsyncNotifier<List<HistoryPoint>> {
  @override
  Future<List<HistoryPoint>> build() async {
    final Timer timer = Timer.periodic(historyRefreshInterval, (_) {
      ref.invalidateSelf();
    });
    ref.onDispose(timer.cancel);
    return ref.watch(glancesRepositoryProvider).getCpuHistory(nb: 60);
  }

  /// Forces an immediate re-fetch of the history series.
  Future<void> refresh() async {
    ref.invalidateSelf();
    try {
      await ref.container.read(cpuHistoryProvider.future);
    } on Object {
      // Failure is surfaced through the provider's AsyncValue.
    }
  }
}

/// Last 60 CPU-usage samples, auto-refreshed every [historyRefreshInterval].
final cpuHistoryProvider =
    AsyncNotifierProvider<CpuHistoryNotifier, List<HistoryPoint>>(
  CpuHistoryNotifier.new,
);
