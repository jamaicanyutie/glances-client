import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_settings.dart';
import '../config/server_config.dart';
import 'api/dio_client.dart';
import 'api/glances_repository.dart';
import 'exceptions.dart';
import 'models/alert_info.dart';
import 'models/alert_thresholds.dart';
import 'models/connection_stats_info.dart';
import 'models/folders_info.dart';
import 'models/glances_all.dart';
import 'models/gpu_info.dart';
import 'models/history_point.dart';
import 'models/ip_info.dart';
import 'models/mem_swap_info.dart';
import 'models/per_cpu_info.dart';
import 'models/port_info.dart';
import 'models/process_detail_info.dart';
import 'models/process_info.dart';
import 'models/program_info.dart';
import 'models/sensor_info.dart';
import 'models/system_info.dart';
import 'models/vm_info.dart';
import 'models/wifi_info.dart';

/// Provides the [Dio] HTTP client used for all Glances REST API calls.
///
/// Built from the current [serverConfigProvider] value. Throws until a server
/// has been configured; the first-run gate keeps data providers unbuilt until
/// then, so this state is unreachable in practice.
final dioProvider = Provider<Dio>((ref) {
  final ServerConfig? config = ref.watch(serverConfigProvider);
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

/// Notifier backing [allStatsProvider].
///
/// Fetches `GET /api/4/all` once on build, then re-fetches on every
/// [refreshIntervalProvider] by invalidating itself. The periodic timer is
/// torn down with the notifier, so no work happens while the provider is
/// unused.
final class AllStatsNotifier extends AsyncNotifier<GlancesAll> {
  @override
  Future<GlancesAll> build() async {
    final Duration interval = ref.watch(refreshIntervalProvider);
    _startAutoRefresh(interval);
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

  void _startAutoRefresh(Duration interval) {
    final Timer timer = Timer.periodic(interval, (_) {
      ref.invalidateSelf();
    });
    ref.onDispose(timer.cancel);
  }
}

/// Aggregated live snapshot of every Glances plugin, auto-refreshed every
/// [dashboardRefreshInterval] seconds.
final allStatsProvider =
    AsyncNotifierProvider<AllStatsNotifier, GlancesAll>(AllStatsNotifier.new);

/// Notifier backing [topProcessesProvider].
///
/// Fetches the top 15 processes by CPU usage on build, then re-fetches on
/// every [refreshIntervalProvider].
final class TopProcessesNotifier extends AsyncNotifier<List<ProcessInfo>> {
  @override
  Future<List<ProcessInfo>> build() async {
    final Duration interval = ref.watch(refreshIntervalProvider);
    _startAutoRefresh(interval);
    return ref.watch(glancesRepositoryProvider).getTopProcesses(n: 30);
  }

  /// Forces an immediate re-fetch and waits for it to complete (used by
  /// pull-to-refresh).
  ///
  /// The container is used directly because the notifier's own `ref` forbids
  /// self-references in debug mode; the container layer supports them.
  Future<void> refresh() async {
    ref.invalidateSelf();
    try {
      await ref.container.read(topProcessesProvider.future);
    } on Object {
      // The failure is already surfaced through the provider's AsyncValue;
      // swallow it here so pull-to-refresh does not throw.
    }
  }

  void _startAutoRefresh(Duration interval) {
    final Timer timer = Timer.periodic(interval, (_) {
      ref.invalidateSelf();
    });
    ref.onDispose(timer.cancel);
  }
}

/// Top 30 processes by CPU usage, auto-refreshed every
/// [refreshIntervalProvider].
final topProcessesProvider =
    AsyncNotifierProvider<TopProcessesNotifier, List<ProcessInfo>>(
  TopProcessesNotifier.new,
);

/// Top processes sorted by memory usage (client-side sort of [topProcessesProvider]).
final topProcessesByMemoryProvider = Provider<List<ProcessInfo>>((ref) {
  final AsyncValue<List<ProcessInfo>> processes = ref.watch(topProcessesProvider);
  return processes.whenData(
    (List<ProcessInfo> list) {
      final List<ProcessInfo> sorted = List<ProcessInfo>.from(list);
      sorted.sort((ProcessInfo a, ProcessInfo b) {
        final double ma = a.memPercent ?? 0;
        final double mb = b.memPercent ?? 0;
        return mb.compareTo(ma);
      });
      return sorted;
    },
  ).value ?? const <ProcessInfo>[];
});

/// Notifier backing [processListProvider].
///
/// Fetches the full process list (`GET /api/4/processlist`) on build, then
/// re-fetches on every [refreshIntervalProvider].
final class ProcessListNotifier extends AsyncNotifier<List<ProcessInfo>> {
  @override
  Future<List<ProcessInfo>> build() async {
    final Duration interval = ref.watch(refreshIntervalProvider);
    _startAutoRefresh(interval);
    return ref.watch(glancesRepositoryProvider).getProcesses();
  }

  /// Forces an immediate re-fetch and waits for it to complete (used by
  /// pull-to-refresh).
  Future<void> refresh() async {
    ref.invalidateSelf();
    try {
      await ref.container.read(processListProvider.future);
    } on Object {
      // The failure is already surfaced through the provider's AsyncValue;
      // swallow it here so pull-to-refresh does not throw.
    }
  }

  void _startAutoRefresh(Duration interval) {
    final Timer timer = Timer.periodic(interval, (_) {
      ref.invalidateSelf();
    });
    ref.onDispose(timer.cancel);
  }
}

/// Full process list, auto-refreshed every [refreshIntervalProvider].
///
/// Used to compute status-based aggregates (e.g. active = total minus
/// zombie/dead/stopped) that the `processcount` plugin does not expose.
final processListProvider =
    AsyncNotifierProvider<ProcessListNotifier, List<ProcessInfo>>(
  ProcessListNotifier.new,
);

/// Notifier backing [cpuHistoryProvider].
///
/// Fetches the last 60 CPU-usage samples (`GET /api/4/cpu/history/60`) on
/// build, then re-fetches on every [historyRefreshIntervalProvider].
final class CpuHistoryNotifier extends AsyncNotifier<List<HistoryPoint>> {
  @override
  Future<List<HistoryPoint>> build() async {
    final Duration interval = ref.watch(historyRefreshIntervalProvider);
    final Timer timer = Timer.periodic(interval, (_) {
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

/// Last 60 CPU-usage samples, auto-refreshed every [historyRefreshIntervalProvider].
final cpuHistoryProvider =
    AsyncNotifierProvider<CpuHistoryNotifier, List<HistoryPoint>>(
  CpuHistoryNotifier.new,
);

/// Identifies a single plugin-field history series to fetch.
///
/// Used as the family argument of [itemHistoryProvider]. Immutable so the
/// provider's equality check (and therefore caching) works correctly.
class ItemHistoryQuery {
  /// Creates an [ItemHistoryQuery].
  const ItemHistoryQuery({
    required this.plugin,
    required this.item,
    this.nb = 60,
  });

  /// Plugin name (`cpu`, `mem`, `fs`, `diskio`, `network`, ...).
  final String plugin;

  /// Field whose samples should be returned.
  final String item;

  /// Number of samples to request.
  final int nb;

  @override
  bool operator ==(Object other) =>
      other is ItemHistoryQuery &&
      other.plugin == plugin &&
      other.item == item &&
      other.nb == nb;

  @override
  int get hashCode => Object.hash(plugin, item, nb);
}

/// Notifier backing [processDetailProvider].
///
/// Fetches the full detail of one process (`GET /api/4/processes/{pid}`) on
/// build, then re-fetches on every [refreshIntervalProvider]. Resolves to
/// `null` when the process has disappeared from the server.
///
/// In Riverpod 3 the family argument is passed to the provider's create
/// function rather than to `build`, so the pid is captured by the constructor.
final class ProcessDetailNotifier extends AsyncNotifier<ProcessDetailInfo?> {
  /// Creates a notifier for [pid].
  ProcessDetailNotifier(this.pid);

  /// Process whose detail this notifier fetches.
  final int pid;

  @override
  Future<ProcessDetailInfo?> build() async {
    final Duration interval = ref.watch(refreshIntervalProvider);
    final Timer timer = Timer.periodic(interval, (_) {
      ref.invalidateSelf();
    });
    ref.onDispose(timer.cancel);
    return ref.watch(glancesRepositoryProvider).getProcessDetail(pid);
  }

  /// Forces an immediate re-fetch of the process detail.
  Future<void> refresh() async {
    ref.invalidateSelf();
    try {
      await ref.container.read(processDetailProvider(pid).future);
    } on Object {
      // Failure is surfaced through the provider's AsyncValue.
    }
  }
}

/// Full detail of a single process, auto-refreshed every
/// [refreshIntervalProvider]. Resolves to `null` when the process is gone.
final processDetailProvider =
    AsyncNotifierProvider.family<ProcessDetailNotifier, ProcessDetailInfo?, int>(
  ProcessDetailNotifier.new,
);

/// Notifier backing [extendedProcessesProvider].
///
/// Fetches the extended process list (`GET /api/4/processes/extended`) on
/// build, then re-fetches on every [refreshIntervalProvider]. Servers not
/// started with `--enable-process-extended` report an empty list, which the
/// UI renders as a "not enabled" empty state.
final class ExtendedProcessesNotifier extends AsyncNotifier<List<ProcessDetailInfo>> {
  @override
  Future<List<ProcessDetailInfo>> build() async {
    final Duration interval = ref.watch(refreshIntervalProvider);
    _startAutoRefresh(interval);
    return ref.watch(glancesRepositoryProvider).getExtendedProcesses();
  }

  /// Forces an immediate re-fetch of the extended process list.
  Future<void> refresh() async {
    ref.invalidateSelf();
    try {
      await ref.container.read(extendedProcessesProvider.future);
    } on Object {
      // Failure is surfaced through the provider's AsyncValue.
    }
  }

  void _startAutoRefresh(Duration interval) {
    final Timer timer = Timer.periodic(interval, (_) {
      ref.invalidateSelf();
    });
    ref.onDispose(timer.cancel);
  }
}

/// Extended process list, auto-refreshed every [refreshIntervalProvider].
/// Empty when the server does not collect extended stats.
final extendedProcessesProvider =
    AsyncNotifierProvider<ExtendedProcessesNotifier, List<ProcessDetailInfo>>(
  ExtendedProcessesNotifier.new,
);

/// Notifier backing [connectionsProvider].
///
/// Fetches the aggregate TCP connection counts (`GET /api/4/connections`) on
/// build, then re-fetches on every [refreshIntervalProvider].
final class ConnectionsNotifier extends AsyncNotifier<ConnectionStatsInfo> {
  @override
  Future<ConnectionStatsInfo> build() async {
    final Duration interval = ref.watch(refreshIntervalProvider);
    _startAutoRefresh(interval);
    return ref.watch(glancesRepositoryProvider).getConnections();
  }

  /// Forces an immediate re-fetch and waits for it to complete (used by
  /// pull-to-refresh).
  Future<void> refresh() async {
    ref.invalidateSelf();
    try {
      await ref.container.read(connectionsProvider.future);
    } on Object {
      // Failure is surfaced through the provider's AsyncValue.
    }
  }

  void _startAutoRefresh(Duration interval) {
    final Timer timer = Timer.periodic(interval, (_) {
      ref.invalidateSelf();
    });
    ref.onDispose(timer.cancel);
  }
}

/// Aggregate TCP connection counts, auto-refreshed every
/// [refreshIntervalProvider].
final connectionsProvider =
    AsyncNotifierProvider<ConnectionsNotifier, ConnectionStatsInfo>(
  ConnectionsNotifier.new,
);

/// Notifier backing [sensorsProvider].
///
/// Fetches the hardware sensors (`GET /api/4/sensors`) on build, then
/// re-fetches on every [refreshIntervalProvider].
final class SensorsNotifier extends AsyncNotifier<List<SensorInfo>> {
  @override
  Future<List<SensorInfo>> build() async {
    final Duration interval = ref.watch(refreshIntervalProvider);
    _startAutoRefresh(interval);
    return ref.watch(glancesRepositoryProvider).getSensors();
  }

  /// Forces an immediate re-fetch and waits for it to complete (used by
  /// pull-to-refresh).
  Future<void> refresh() async {
    ref.invalidateSelf();
    try {
      await ref.container.read(sensorsProvider.future);
    } on Object {
      // Failure is surfaced through the provider's AsyncValue.
    }
  }

  void _startAutoRefresh(Duration interval) {
    final Timer timer = Timer.periodic(interval, (_) {
      ref.invalidateSelf();
    });
    ref.onDispose(timer.cancel);
  }
}

/// Hardware sensor readings, auto-refreshed every [refreshIntervalProvider].
final sensorsProvider =
    AsyncNotifierProvider<SensorsNotifier, List<SensorInfo>>(
  SensorsNotifier.new,
);

/// Notifier backing [systemProvider].
///
/// Fetches the host system metadata (`GET /api/4/system`) on build, then
/// re-fetches on every [refreshIntervalProvider].
final class SystemNotifier extends AsyncNotifier<SystemInfo> {
  @override
  Future<SystemInfo> build() async {
    final Duration interval = ref.watch(refreshIntervalProvider);
    _startAutoRefresh(interval);
    return ref.watch(glancesRepositoryProvider).getSystem();
  }

  /// Forces an immediate re-fetch and waits for it to complete (used by
  /// pull-to-refresh).
  Future<void> refresh() async {
    ref.invalidateSelf();
    try {
      await ref.container.read(systemProvider.future);
    } on Object {
      // Failure is surfaced through the provider's AsyncValue.
    }
  }

  void _startAutoRefresh(Duration interval) {
    final Timer timer = Timer.periodic(interval, (_) {
      ref.invalidateSelf();
    });
    ref.onDispose(timer.cancel);
  }
}

/// Host system metadata, auto-refreshed every [refreshIntervalProvider].
final systemProvider = AsyncNotifierProvider<SystemNotifier, SystemInfo>(
  SystemNotifier.new,
);

/// Notifier backing [uptimeProvider].
///
/// Fetches the system uptime (`GET /api/4/uptime`) on build, then re-fetches
/// on every [refreshIntervalProvider].
final class UptimeNotifier extends AsyncNotifier<String> {
  @override
  Future<String> build() async {
    final Duration interval = ref.watch(refreshIntervalProvider);
    _startAutoRefresh(interval);
    return ref.watch(glancesRepositoryProvider).getUptime();
  }

  /// Forces an immediate re-fetch and waits for it to complete (used by
  /// pull-to-refresh).
  Future<void> refresh() async {
    ref.invalidateSelf();
    try {
      await ref.container.read(uptimeProvider.future);
    } on Object {
      // Failure is surfaced through the provider's AsyncValue.
    }
  }

  void _startAutoRefresh(Duration interval) {
    final Timer timer = Timer.periodic(interval, (_) {
      ref.invalidateSelf();
    });
    ref.onDispose(timer.cancel);
  }
}

/// System uptime string, auto-refreshed every [refreshIntervalProvider].
final uptimeProvider = AsyncNotifierProvider<UptimeNotifier, String>(
  UptimeNotifier.new,
);

/// Notifier backing [alertsProvider].
///
/// Fetches the alert history (`GET /api/4/alert`) on build, then re-fetches
/// on every [refreshIntervalProvider].
final class AlertsNotifier extends AsyncNotifier<List<AlertInfo>> {
  @override
  Future<List<AlertInfo>> build() async {
    final Duration interval = ref.watch(refreshIntervalProvider);
    _startAutoRefresh(interval);
    return ref.watch(glancesRepositoryProvider).getAlerts();
  }

  /// Forces an immediate re-fetch and waits for it to complete (used by
  /// pull-to-refresh).
  Future<void> refresh() async {
    ref.invalidateSelf();
    try {
      await ref.container.read(alertsProvider.future);
    } on Object {
      // Failure is surfaced through the provider's AsyncValue.
    }
  }

  void _startAutoRefresh(Duration interval) {
    final Timer timer = Timer.periodic(interval, (_) {
      ref.invalidateSelf();
    });
    ref.onDispose(timer.cancel);
  }
}

/// Alert history, auto-refreshed every [refreshIntervalProvider].
final alertsProvider = AsyncNotifierProvider<AlertsNotifier, List<AlertInfo>>(
  AlertsNotifier.new,
);

/// Notifier backing [ipProvider].
///
/// Fetches the host network-address information (`GET /api/4/ip`) on build,
/// then re-fetches on every [refreshIntervalProvider].
final class IpNotifier extends AsyncNotifier<IpInfo> {
  @override
  Future<IpInfo> build() async {
    final Duration interval = ref.watch(refreshIntervalProvider);
    _startAutoRefresh(interval);
    return ref.watch(glancesRepositoryProvider).getIp();
  }

  /// Forces an immediate re-fetch and waits for it to complete (used by
  /// pull-to-refresh).
  Future<void> refresh() async {
    ref.invalidateSelf();
    try {
      await ref.container.read(ipProvider.future);
    } on Object {
      // Failure is surfaced through the provider's AsyncValue.
    }
  }

  void _startAutoRefresh(Duration interval) {
    final Timer timer = Timer.periodic(interval, (_) {
      ref.invalidateSelf();
    });
    ref.onDispose(timer.cancel);
  }
}

/// Host network-address information, auto-refreshed every
/// [refreshIntervalProvider].
final ipProvider = AsyncNotifierProvider<IpNotifier, IpInfo>(IpNotifier.new);

/// Notifier backing [wifiProvider].
///
/// Fetches the visible Wi-Fi networks (`GET /api/4/wifi`) on build, then
/// re-fetches on every [refreshIntervalProvider].
final class WifiNotifier extends AsyncNotifier<List<WifiInfo>> {
  @override
  Future<List<WifiInfo>> build() async {
    final Duration interval = ref.watch(refreshIntervalProvider);
    _startAutoRefresh(interval);
    return ref.watch(glancesRepositoryProvider).getWifi();
  }

  /// Forces an immediate re-fetch and waits for it to complete (used by
  /// pull-to-refresh).
  Future<void> refresh() async {
    ref.invalidateSelf();
    try {
      await ref.container.read(wifiProvider.future);
    } on Object {
      // Failure is surfaced through the provider's AsyncValue.
    }
  }

  void _startAutoRefresh(Duration interval) {
    final Timer timer = Timer.periodic(interval, (_) {
      ref.invalidateSelf();
    });
    ref.onDispose(timer.cancel);
  }
}

/// Visible Wi-Fi networks, auto-refreshed every [refreshIntervalProvider].
final wifiProvider = AsyncNotifierProvider<WifiNotifier, List<WifiInfo>>(
  WifiNotifier.new,
);

/// Notifier backing [portsProvider].
///
/// Fetches the host/port reachability measurements (`GET /api/4/ports`) on
/// build, then re-fetches on every [refreshIntervalProvider].
final class PortsNotifier extends AsyncNotifier<List<PortInfo>> {
  @override
  Future<List<PortInfo>> build() async {
    final Duration interval = ref.watch(refreshIntervalProvider);
    _startAutoRefresh(interval);
    return ref.watch(glancesRepositoryProvider).getPorts();
  }

  /// Forces an immediate re-fetch and waits for it to complete (used by
  /// pull-to-refresh).
  Future<void> refresh() async {
    ref.invalidateSelf();
    try {
      await ref.container.read(portsProvider.future);
    } on Object {
      // Failure is surfaced through the provider's AsyncValue.
    }
  }

  void _startAutoRefresh(Duration interval) {
    final Timer timer = Timer.periodic(interval, (_) {
      ref.invalidateSelf();
    });
    ref.onDispose(timer.cancel);
  }
}

/// Host/port reachability measurements, auto-refreshed every
/// [refreshIntervalProvider].
final portsProvider = AsyncNotifierProvider<PortsNotifier, List<PortInfo>>(
  PortsNotifier.new,
);

/// Notifier backing [vmsProvider].
///
/// Fetches the virtual machines (`GET /api/4/vms`) on build, then re-fetches
/// on every [refreshIntervalProvider]. When the server does not report the
/// `vms` plugin (e.g. no libvirt, which surfaces as HTTP 400 "Unknown plugin"),
/// resolves to an empty list so the screen shows the empty state instead of an
/// error.
final class VmsNotifier extends AsyncNotifier<List<VmInfo>> {
  @override
  Future<List<VmInfo>> build() async {
    final Duration interval = ref.watch(refreshIntervalProvider);
    _startAutoRefresh(interval);
    final GlancesRepository repo = ref.watch(glancesRepositoryProvider);
    try {
      return await repo.getVms();
    } on ApiException catch (e) {
      if (e.statusCode == 400) {
        return const <VmInfo>[];
      }
      rethrow;
    }
  }

  /// Forces an immediate re-fetch and waits for it to complete (used by
  /// pull-to-refresh).
  Future<void> refresh() async {
    ref.invalidateSelf();
    try {
      await ref.container.read(vmsProvider.future);
    } on Object {
      // Failure is surfaced through the provider's AsyncValue.
    }
  }

  void _startAutoRefresh(Duration interval) {
    final Timer timer = Timer.periodic(interval, (_) {
      ref.invalidateSelf();
    });
    ref.onDispose(timer.cancel);
  }
}

/// Virtual machines, auto-refreshed every [refreshIntervalProvider].
final vmsProvider = AsyncNotifierProvider<VmsNotifier, List<VmInfo>>(
  VmsNotifier.new,
);

/// Notifier backing [foldersProvider].
///
/// Fetches the monitored folders (`GET /api/4/folders`) on build, then
/// re-fetches on every [refreshIntervalProvider]. When the server does not
/// report the `folders` plugin (surfaced as HTTP 400 "Unknown plugin"),
/// resolves to an empty list so the screen shows the empty state instead of an
/// error.
final class FoldersNotifier extends AsyncNotifier<List<FolderInfo>> {
  @override
  Future<List<FolderInfo>> build() async {
    final Duration interval = ref.watch(refreshIntervalProvider);
    _startAutoRefresh(interval);
    final GlancesRepository repo = ref.watch(glancesRepositoryProvider);
    try {
      return await repo.getFolders();
    } on ApiException catch (e) {
      if (e.statusCode == 400) {
        return const <FolderInfo>[];
      }
      rethrow;
    }
  }

  /// Forces an immediate re-fetch and waits for it to complete (used by
  /// pull-to-refresh).
  Future<void> refresh() async {
    ref.invalidateSelf();
    try {
      await ref.container.read(foldersProvider.future);
    } on Object {
      // Failure is surfaced through the provider's AsyncValue.
    }
  }

  void _startAutoRefresh(Duration interval) {
    final Timer timer = Timer.periodic(interval, (_) {
      ref.invalidateSelf();
    });
    ref.onDispose(timer.cancel);
  }
}

/// Monitored folders, auto-refreshed every [refreshIntervalProvider].
final foldersProvider = AsyncNotifierProvider<FoldersNotifier, List<FolderInfo>>(
  FoldersNotifier.new,
);

/// Notifier backing [gpuProvider].
///
/// Fetches the GPUs (`GET /api/4/gpu`) on build, then re-fetches on every
/// [refreshIntervalProvider]. When the server does not report the `gpu`
/// plugin (surfaced as HTTP 400 "Unknown plugin"), resolves to an empty list
/// so the screen shows the empty state instead of an error.
final class GpuNotifier extends AsyncNotifier<List<GpuInfo>> {
  @override
  Future<List<GpuInfo>> build() async {
    final Duration interval = ref.watch(refreshIntervalProvider);
    _startAutoRefresh(interval);
    final GlancesRepository repo = ref.watch(glancesRepositoryProvider);
    try {
      return await repo.getGpu();
    } on ApiException catch (e) {
      if (e.statusCode == 400) {
        return const <GpuInfo>[];
      }
      rethrow;
    }
  }

  /// Forces an immediate re-fetch and waits for it to complete (used by
  /// pull-to-refresh).
  Future<void> refresh() async {
    ref.invalidateSelf();
    try {
      await ref.container.read(gpuProvider.future);
    } on Object {
      // Failure is surfaced through the provider's AsyncValue.
    }
  }

  void _startAutoRefresh(Duration interval) {
    final Timer timer = Timer.periodic(interval, (_) {
      ref.invalidateSelf();
    });
    ref.onDispose(timer.cancel);
  }
}

/// GPUs, auto-refreshed every [refreshIntervalProvider].
final gpuProvider = AsyncNotifierProvider<GpuNotifier, List<GpuInfo>>(
  GpuNotifier.new,
);

/// Notifier backing [programsProvider].
///
/// Fetches the aggregated program list (`GET /api/4/programlist`) on build,
/// then re-fetches on every [refreshIntervalProvider]. When the server does
/// not report the `programlist` plugin (surfaced as HTTP 400 "Unknown
/// plugin"), resolves to an empty list so the screen shows the empty state
/// instead of an error.
final class ProgramsNotifier extends AsyncNotifier<List<ProgramInfo>> {
  @override
  Future<List<ProgramInfo>> build() async {
    final Duration interval = ref.watch(refreshIntervalProvider);
    _startAutoRefresh(interval);
    final GlancesRepository repo = ref.watch(glancesRepositoryProvider);
    try {
      return await repo.getPrograms();
    } on ApiException catch (e) {
      if (e.statusCode == 400) {
        return const <ProgramInfo>[];
      }
      rethrow;
    }
  }

  /// Forces an immediate re-fetch and waits for it to complete (used by
  /// pull-to-refresh).
  Future<void> refresh() async {
    ref.invalidateSelf();
    try {
      await ref.container.read(programsProvider.future);
    } on Object {
      // Failure is surfaced through the provider's AsyncValue.
    }
  }

  void _startAutoRefresh(Duration interval) {
    final Timer timer = Timer.periodic(interval, (_) {
      ref.invalidateSelf();
    });
    ref.onDispose(timer.cancel);
  }
}

/// Aggregated program list, auto-refreshed every [refreshIntervalProvider].
final programsProvider = AsyncNotifierProvider<ProgramsNotifier, List<ProgramInfo>>(
  ProgramsNotifier.new,
);

/// Memory-swap statistics (`GET /api/4/memswap`).
///
/// Fetched on demand when the Memory & Swap sheet is opened; the sheet does
/// not need live auto-refresh.
final memSwapProvider = FutureProvider<MemSwapInfo>((ref) {
  return ref.watch(glancesRepositoryProvider).getMemSwap();
});

/// Per-core CPU usage (`GET /api/4/percpu`).
///
/// Fetched on demand when the per-core sheet is opened.
final perCpuProvider = FutureProvider<List<PerCpuInfo>>((ref) {
  return ref.watch(glancesRepositoryProvider).getPerCpu();
});

/// History of a single plugin field (`GET /api/4/{plugin}/{item}/history/{nb}`).
///
/// Fetched on demand when a history sheet is opened. Auto-disposed so stale
/// series do not linger after their sheet closes.
final itemHistoryProvider =
    FutureProvider.autoDispose.family<List<HistoryPoint>, ItemHistoryQuery>(
  (ref, query) => ref.watch(glancesRepositoryProvider).getItemHistory(
        plugin: query.plugin,
        item: query.item,
        nb: query.nb,
      ),
);

/// Identifies a single plugin-field metadata lookup (unit / description).
///
/// Used as the family argument of [itemUnitProvider] and
/// [itemDescriptionProvider]. Immutable so the provider's equality check (and
/// therefore caching) works correctly.
class ItemMetadataQuery {
  /// Creates an [ItemMetadataQuery].
  const ItemMetadataQuery({
    required this.plugin,
    required this.item,
  });

  /// Plugin name (`cpu`, `mem`, `fs`, `diskio`, `network`, ...).
  final String plugin;

  /// Field whose metadata should be returned.
  final String item;

  @override
  bool operator ==(Object other) =>
      other is ItemMetadataQuery &&
      other.plugin == plugin &&
      other.item == item;

  @override
  int get hashCode => Object.hash(plugin, item);
}

/// Server-provided unit for a plugin item (`GET /api/4/{plugin}/{item}/unit`).
///
/// Fetched lazily per (plugin, item) and auto-disposed when unused. Resolves
/// to null when the server exposes no unit for the item; callers are expected
/// to fall back to their hardcoded unit in that case.
final itemUnitProvider =
    FutureProvider.autoDispose.family<String?, ItemMetadataQuery>(
  (ref, query) => ref
      .watch(glancesRepositoryProvider)
      .getItemUnit(query.plugin, query.item),
);

/// Server-provided description for a plugin item
/// (`GET /api/4/{plugin}/{item}/description`).
///
/// Fetched lazily per (plugin, item) and auto-disposed when unused. Resolves
/// to null when the server exposes no description for the item.
final itemDescriptionProvider =
    FutureProvider.autoDispose.family<String?, ItemMetadataQuery>(
  (ref, query) => ref
      .watch(glancesRepositoryProvider)
      .getItemDescription(query.plugin, query.item),
);

/// Server-configured alert thresholds (`GET /api/4/all/limits` + `/all/views`).
///
/// Drives the [AlertColorResolver] so alert colors follow server truth instead
/// of the client's hardcoded 60/85 scale. Fetched once per server config; a
/// failed fetch (older Glances versions, empty limits) resolves to an empty
/// [AlertThresholds] so callers transparently fall back to their built-in
/// scale rather than surfacing an error.
final alertThresholdsProvider = Provider<AsyncValue<AlertThresholds>>((ref) {
  final FutureProvider<AlertThresholds> p = FutureProvider<AlertThresholds>((
    ref,
  ) async {
    final GlancesRepository repo = ref.watch(glancesRepositoryProvider);
    try {
      return await repo.getLimits();
    } on Object {
      return const AlertThresholds(<String, Map<String, MetricLimits>>{});
    }
  });
  return ref.watch(p);
});

/// Server-computed decoration labels (`GET /api/4/all/views`).
///
/// Merged into the [alertThresholdsProvider] data in screens that want the
/// server's own OK/WARNING/CRITICAL verdict (status chips, card accents).
final alertViewsProvider = FutureProvider<AlertThresholds>((ref) async {
  final GlancesRepository repo = ref.watch(glancesRepositoryProvider);
  try {
    return await repo.getViews();
  } on Object {
    return const AlertThresholds(<String, Map<String, MetricLimits>>{});
  }
});

/// Server status payload (`GET /api/4/status`).
///
/// One of the two endpoints always served without authentication. Used for
/// the version badge and connectivity checks on the home screen.
final serverStatusProvider = FutureProvider<Map<String, dynamic>>((ref) {
  return ref.watch(glancesRepositoryProvider).getStatus();
});

/// Enabled plugin names (`GET /api/4/pluginslist`), as a sorted set.
///
/// Used for capability detection: cards and sub-tabs for plugins the server
/// does not report are hidden. Resolves to an empty set when the endpoint is
/// unavailable so the UI never blocks on it.
final capabilitiesProvider = FutureProvider<Set<String>>((ref) async {
  final GlancesRepository repo = ref.watch(glancesRepositoryProvider);
  try {
    final List<String> plugins = await repo.getPluginsList();
    return plugins.toSet();
  } on Object {
    return const <String>{};
  }
});

/// True when the server reports [plugin] as an enabled plugin.
///
/// When the capabilities have not resolved yet, or the `pluginslist` endpoint
/// is unavailable (empty set), returns true so the UI degrades to showing all
/// cards/sections rather than hiding them.
bool hasPluginCapability(AsyncValue<Set<String>> capabilities, String plugin) {
  final Set<String>? caps = capabilities.value;
  return caps == null || caps.isEmpty || caps.contains(plugin);
}

/// Glances server version string (`GET /api/4/version`), or null when the
/// server does not expose it.
final serverVersionProvider = FutureProvider<String?>((ref) async {
  final GlancesRepository repo = ref.watch(glancesRepositoryProvider);
  try {
    return await repo.getVersion();
  } on Object {
    return null;
  }
});

/// Quick-look CPU / memory / load percentages (`GET /api/4/quicklook`).
///
/// Powers the at-a-glance strip on the home screen. Non-fatal: a failed fetch
/// resolves to an empty map so the strip simply does not render.
final quicklookProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final GlancesRepository repo = ref.watch(glancesRepositoryProvider);
  try {
    return await repo.getQuicklook();
  } on Object {
    return const <String, dynamic>{};
  }
});
