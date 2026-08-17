import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/server_config.dart';
import '../../../data/models/cpu_info.dart';
import '../../../data/models/docker_container_info.dart';
import '../../../data/models/fs_info.dart';
import '../../../data/models/glances_all.dart';
import '../../../data/models/load_info.dart';
import '../../../data/models/mem_info.dart';
import '../../../data/models/process_info.dart';
import '../../../data/providers.dart';
import '../../components/error_view.dart';
import '../../components/loading_view.dart';
import '../../components/responsive_card_grid.dart';
import '../../components/settings_button.dart';
import '../../theme/colors.dart';
import '../../theme/theme.dart';
import '../../utils/alert_color_resolver.dart';
import '../../utils/formatters.dart';

/// Landing screen: live overview of the host.
///
/// Before a Glances server has been configured it shows a first-run hint with
/// a button that opens Settings. Once configured it watches [allStatsProvider]
/// and [topProcessesProvider] (both auto-refreshed on the settings-derived
/// refresh interval) and renders a dashboard of metric cards. Each card pushes
/// the matching drill-down route on tap, and the list supports pull-to-refresh.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ServerConfig? serverConfig = ref.watch(serverConfigProvider);
    final AsyncValue<GlancesAll> allStats = ref.watch(allStatsProvider);
    final AsyncValue<List<ProcessInfo>> topProcesses =
        ref.watch(topProcessesProvider);
    final AsyncValue<Set<String>> capabilities =
        ref.watch(capabilitiesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: const <Widget>[SettingsButton()],
      ),
      body: serverConfig == null
          ? const _NoServerView()
          : allStats.when(
              loading: () => const LoadingView(),
              error: (Object error, StackTrace stackTrace) => ErrorView(
                message: '$error',
                onRetry: () {
                  ref.invalidate(allStatsProvider);
                  ref.invalidate(topProcessesProvider);
                  ref.invalidate(processListProvider);
                },
              ),
              data: (GlancesAll data) {
                return RefreshIndicator(
                  onRefresh: () async {
                    await ref.read(allStatsProvider.notifier).refresh();
                    await ref.read(topProcessesProvider.notifier).refresh();
                    await ref.read(processListProvider.notifier).refresh();
                  },
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(AppSpacing.md),
                    children: <Widget>[
                      const _ServerVersionBadge(),
                      const SizedBox(height: AppSpacing.sm),
                      LayoutBuilder(
                        builder:
                            (BuildContext context, BoxConstraints constraints) {
                          // Portrait: keep the original two-up CPU/Memory row
                          // and full-width cards below.
                          if (constraints.maxWidth < 600) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Expanded(child: _CpuCard(cpu: data.cpu)),
                                    const SizedBox(width: AppSpacing.sm),
                                    Expanded(child: _MemoryCard(mem: data.mem)),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.md),
                                _LoadCard(load: data.load),
                                const SizedBox(height: AppSpacing.md),
                                _QuicklookCard(),
                                const SizedBox(height: AppSpacing.md),
                                if (hasPluginCapability(capabilities, 'sensors'))
                                  _SensorsCard(),
                                if (hasPluginCapability(capabilities, 'sensors'))
                                  const SizedBox(height: AppSpacing.md),
                                _SystemCard(),
                                const SizedBox(height: AppSpacing.md),
                                _AlertsCard(),
                                const SizedBox(height: AppSpacing.md),
                                _FilesystemCard(fs: data.fs),
                                const SizedBox(height: AppSpacing.md),
                                if (hasPluginCapability(capabilities, 'containers'))
                                  _DockerCard(docker: data.docker),
                                if (hasPluginCapability(capabilities, 'containers'))
                                  const SizedBox(height: AppSpacing.md),
                                _ProcessCountCard(),
                                const SizedBox(height: AppSpacing.md),
                                _TopProcessesCard(topProcesses: topProcesses),
                              ],
                            );
                          }
                          // Landscape / wide: reflow every card into a
                          // multi-column grid so cards resize with the width.
                          return ResponsiveCardGrid(
                            children: <Widget>[
                              _CpuCard(cpu: data.cpu),
                              _MemoryCard(mem: data.mem),
                              _LoadCard(load: data.load),
                              _QuicklookCard(),
                              if (hasPluginCapability(capabilities, 'sensors'))
                                _SensorsCard(),
                              _SystemCard(),
                              _AlertsCard(),
                              _FilesystemCard(fs: data.fs),
                              if (hasPluginCapability(capabilities, 'containers'))
                                _DockerCard(docker: data.docker),
                              _ProcessCountCard(),
                              _TopProcessesCard(topProcesses: topProcesses),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

/// First-run placeholder shown before a Glances server is configured — same
/// wording as the phone app.
class _NoServerView extends StatelessWidget {
  const _NoServerView();

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.wifi_tethering,
              size: 56,
              color: AppColors.textSecondary.withValues(alpha: 0.6),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Glances shows you nothing until it reaches a Glances server. '
              'Scan your network, or enter an address in Settings.',
              textAlign: TextAlign.center,
              style: textTheme.bodyLarge?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: () => context.push('/settings'),
              icon: const Icon(Icons.settings),
              label: const Text('Open settings'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small header chip showing the connected Glances server version
/// (`GET /api/4/version`). Hidden entirely when the server does not expose a
/// version — a failed lookup is non-fatal.
class _ServerVersionBadge extends ConsumerWidget {
  const _ServerVersionBadge();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String? version = ref.watch(serverVersionProvider).value;
    if (version == null || version.isEmpty) {
      return const SizedBox.shrink();
    }
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 4,
        ),
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.dns, size: 14, color: AppColors.textSecondary),
            const SizedBox(width: 4),
            Text(
              'Glances $version',
              style: textTheme.labelMedium?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shared shell for the dashboard cards: a themed [Card] with a title row,
/// the card content, and optional tap navigation.
class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.icon,
    required this.child,
    this.onTap,
  });

  final String title;
  final IconData icon;
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Icon(icon, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    title,
                    style: textTheme.labelLarge?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

/// Half-width card showing total CPU usage.
class _CpuCard extends ConsumerWidget {
  const _CpuCard({required this.cpu});

  final CpuInfo? cpu;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final double percent = cpu?.total ?? 0;
    final String cores = cpu?.cpucore?.toString() ?? '—';
    final AlertColorResolver colors = ref.watch(alertColorResolverProvider);
    return _StatCard(
      title: 'CPU',
      icon: Icons.memory,
      onTap: () => context.push('/cpu'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            formatPercent(cpu?.total),
            style: textTheme.headlineMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '$cores cores',
            style: textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          LinearProgressIndicator(
            value: _barFraction(percent),
            color: colors.colorFor('cpu', percent, item: 'total'),
            backgroundColor: AppColors.surfaceAlt,
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
          ),
        ],
      ),
    );
  }
}

/// Half-width card showing memory usage.
class _MemoryCard extends ConsumerWidget {
  const _MemoryCard({required this.mem});

  final MemInfo? mem;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final double percent = mem?.percent ?? 0;
    final AlertColorResolver colors = ref.watch(alertColorResolverProvider);
    return _StatCard(
      title: 'Memory',
      icon: Icons.speed,
      onTap: () => context.push('/memory'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            formatPercent(mem?.percent),
            style: textTheme.headlineMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${formatBytes(mem?.used)} / ${formatBytes(mem?.total)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          LinearProgressIndicator(
            value: _barFraction(percent),
            color: colors.colorFor('mem', percent, item: 'percent'),
            backgroundColor: AppColors.surfaceAlt,
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
          ),
        ],
      ),
    );
  }
}

/// Full-width card showing the 1/5/15-minute load averages, normalized by the
/// number of CPU cores.
class _LoadCard extends ConsumerWidget {
  const _LoadCard({required this.load});

  final LoadInfo? load;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AlertColorResolver colors = ref.watch(alertColorResolverProvider);
    return _StatCard(
      title: 'Load Average',
      icon: Icons.av_timer,
      onTap: () => context.push('/cpu'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: _LoadColumn(
                  label: '1m',
                  value: load?.min1,
                  cores: load?.cpucore,
                  colors: colors,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _LoadColumn(
                  label: '5m',
                  value: load?.min5,
                  cores: load?.cpucore,
                  colors: colors,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _LoadColumn(
                  label: '15m',
                  value: load?.min15,
                  cores: load?.cpucore,
                  colors: colors,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// One load-average column inside [_LoadCard].
class _LoadColumn extends StatelessWidget {
  const _LoadColumn({
    required this.label,
    required this.value,
    required this.cores,
    required this.colors,
  });

  final String label;
  final double? value;
  final int? cores;
  final AlertColorResolver colors;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final double fraction = _loadBarFraction(value, cores);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          label,
          style: textTheme.labelMedium?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          _formatLoad(value),
          style: textTheme.titleMedium?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        LinearProgressIndicator(
          value: fraction,
          color: colors.colorFor('load', fraction * 100),
          backgroundColor: AppColors.surfaceAlt,
          minHeight: 4,
          borderRadius: BorderRadius.circular(2),
        ),
      ],
    );
  }
}

/// At-a-glance CPU / memory / load percentages from the `quicklook` plugin
/// (`GET /api/4/quicklook`), rendered as a compact three-cell strip.
///
/// Falls back to the live [allStatsProvider] values when the quicklook
/// endpoint is unavailable, and hides itself entirely when neither source has
/// data — so the strip degrades gracefully on older Glances versions.
class _QuicklookCard extends ConsumerWidget {
  const _QuicklookCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AlertColorResolver colors = ref.watch(alertColorResolverProvider);
    final AsyncValue<Map<String, dynamic>> quicklook =
        ref.watch(quicklookProvider);

    final double? cpuPercent;
    final double? memPercent;
    final double? loadPercent;
    if (quicklook.hasValue && quicklook.value!.isNotEmpty) {
      cpuPercent = (quicklook.value!['cpu'] as num?)?.toDouble();
      memPercent = (quicklook.value!['mem'] as num?)?.toDouble();
      loadPercent = (quicklook.value!['load'] as num?)?.toDouble();
    } else {
      final GlancesAll? live = ref.watch(allStatsProvider).value;
      final LoadInfo? load = live?.load;
      cpuPercent = live?.cpu?.total;
      memPercent = live?.mem?.percent;
      loadPercent = load == null || load.cpucore == null
          ? null
          : _loadBarFraction(load.min1, load.cpucore) * 100;
    }

    final List<_QuicklookCell> cells = <_QuicklookCell>[
      _QuicklookCell(
        label: 'CPU',
        percent: cpuPercent,
        color: colors.colorFor('cpu', cpuPercent ?? 0, item: 'total'),
      ),
      _QuicklookCell(
        label: 'MEM',
        percent: memPercent,
        color: colors.colorFor('mem', memPercent ?? 0, item: 'percent'),
      ),
      _QuicklookCell(
        label: 'LOAD',
        percent: loadPercent,
        color: colors.colorFor('load', loadPercent ?? 0),
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: <Widget>[
          for (int i = 0; i < cells.length; i++) ...[
            if (i > 0) const SizedBox(width: AppSpacing.lg),
            Expanded(child: cells[i]),
          ],
        ],
      ),
    );
  }
}

/// One labeled cell inside [_QuicklookCard].
class _QuicklookCell extends StatelessWidget {
  const _QuicklookCell({
    required this.label,
    required this.percent,
    required this.color,
  });

  final String label;
  final double? percent;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          label,
          style: textTheme.labelMedium?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          formatPercent(percent),
          style: textTheme.titleMedium?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        LinearProgressIndicator(
          value: _barFraction(percent),
          color: color,
          backgroundColor: AppColors.surfaceAlt,
          minHeight: 4,
          borderRadius: BorderRadius.circular(2),
        ),
      ],
    );
  }
}

/// Full-width card listing the three most-used filesystems.
class _FilesystemCard extends ConsumerWidget {  const _FilesystemCard({required this.fs});

  final List<FsInfo>? fs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final List<FsInfo> mounts = _topMounts(fs);
    final AlertColorResolver colors = ref.watch(alertColorResolverProvider);
    return _StatCard(
      title: 'Filesystems',
      icon: Icons.storage,
      onTap: () => context.push('/disks'),
      child: mounts.isEmpty
          ? Text(
              'No filesystem data',
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                for (final FsInfo mount in mounts) ...[
                  _MountRow(mount: mount, colors: colors),
                  if (mount != mounts.last) const SizedBox(height: AppSpacing.md),
                ],
              ],
            ),
    );
  }

  /// Returns up to three mounts sorted by usage, most-used first.
  static List<FsInfo> _topMounts(List<FsInfo>? fs) {
    if (fs == null) {
      return const <FsInfo>[];
    }
    final List<FsInfo> sorted = List<FsInfo>.of(fs)
      ..sort((FsInfo a, FsInfo b) {
        final double? pa = a.percent;
        final double? pb = b.percent;
        if (pa == null && pb == null) {
          return 0;
        }
        if (pa == null) {
          return 1;
        }
        if (pb == null) {
          return -1;
        }
        return pb.compareTo(pa);
      });
    return sorted.take(3).toList();
  }
}

/// A single filesystem row: mount point, usage percentage and a thin bar.
class _MountRow extends StatelessWidget {
  const _MountRow({required this.mount, required this.colors});

  final FsInfo mount;
  final AlertColorResolver colors;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final double percent = mount.percent ?? 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                mount.mntPoint ?? '—',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              formatPercent(mount.percent),
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        LinearProgressIndicator(
          value: _barFraction(percent),
          color: colors.colorFor('fs', percent, item: 'percent'),
          backgroundColor: AppColors.surfaceAlt,
          minHeight: 4,
          borderRadius: BorderRadius.circular(2),
        ),
      ],
    );
  }
}

/// Full-width card summarizing Docker container status.
class _DockerCard extends StatelessWidget {
  const _DockerCard({required this.docker});

  final List<DockerContainerInfo>? docker;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final List<DockerContainerInfo>? containers = docker;
    final int running;
    final String subtitle;
    if (containers == null) {
      running = 0;
      subtitle = 'Docker not available';
    } else {
      running =
          containers.where((DockerContainerInfo c) => c.isRunning).length;
      subtitle = '$running running / ${containers.length} total';
    }

    final Color statusColor =
        running > 0 ? AppColors.success : AppColors.textSecondary;
    return _StatCard(
      title: 'Docker',
      icon: Icons.inventory_2,
      onTap: () => context.push('/docker'),
      child: Row(
        children: <Widget>[
          Icon(Icons.circle, size: 8, color: statusColor),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodyMedium?.copyWith(
                color: statusColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Full-width card summarizing the host's process counts, with a link to the
/// full process list.
///
/// The `processcount` plugin's `running` field is not shown: it reports 0
/// whenever no process happens to be on-CPU at the sample instant, which is
/// the normal state of an idle host. Instead the card shows "active", computed
/// client-side from the full process list as total minus processes whose state
/// is zombie, dead, or stopped.
class _ProcessCountCard extends ConsumerWidget {
  const _ProcessCountCard();

  /// Linux `ps` state letters that are not actively doing work.
  static const Set<String> _inactiveStates = <String>{'Z', 'X', 'T', 't'};

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final AsyncValue<List<ProcessInfo>> processes =
        ref.watch(processListProvider);
    final String subtitle = processes.when(
      data: (List<ProcessInfo> list) {
        final int inactive = list
            .where((ProcessInfo p) => _inactiveStates.contains(p.status))
            .length;
        final int active = list.length - inactive;
        return '$active active · ${list.length} total';
      },
      loading: () => 'Counting processes…',
      error: (Object e, StackTrace s) => 'Process data unavailable',
    );
    final Color statusColor = processes.hasValue &&
            (processes.value?.isNotEmpty ?? false)
        ? AppColors.success
        : AppColors.textSecondary;
    return _StatCard(
      title: 'Processes',
      icon: Icons.developer_board,
      onTap: () => context.push('/processes'),
      child: Row(
        children: <Widget>[
          Icon(Icons.circle, size: 8, color: statusColor),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodyMedium?.copyWith(
                color: statusColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Navigation card for the Sensors screen.
class _SensorsCard extends StatelessWidget {
  const _SensorsCard();

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return _StatCard(
      title: 'Sensors',
      icon: Icons.thermostat,
      onTap: () => context.push('/sensors'),
      child: Text(
        'View temperature, fan, and battery sensors →',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: textTheme.bodyMedium?.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

/// Navigation card for the System screen.
class _SystemCard extends StatelessWidget {
  const _SystemCard();

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return _StatCard(
      title: 'System',
      icon: Icons.info_outline,
      onTap: () => context.push('/system'),
      child: Text(
        'Host, operating system, and uptime →',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: textTheme.bodyMedium?.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

/// Navigation card for the Alerts screen.
class _AlertsCard extends StatelessWidget {
  const _AlertsCard();

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return _StatCard(
      title: 'Alerts',
      icon: Icons.notifications_outlined,
      onTap: () => context.push('/alerts'),
      child: Text(
        'Warning and critical events →',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: textTheme.bodyMedium?.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

/// Card listing the top processes by CPU, with a link to the full process
/// list.
class _TopProcessesCard extends StatelessWidget {
  const _TopProcessesCard({required this.topProcesses});

  final AsyncValue<List<ProcessInfo>> topProcesses;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return _StatCard(
      title: 'Top Processes',
      icon: Icons.list_alt,
      onTap: () => context.push('/processes'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ...topProcesses.when(
            loading: () => const <Widget>[
              Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
            ],
            error: (Object error, StackTrace stackTrace) => <Widget>[
              Text(
                'Process list unavailable',
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
            data: (List<ProcessInfo> processes) {
              final List<ProcessInfo> visible = processes.take(8).toList();
              return <Widget>[
                for (final ProcessInfo process in visible) ...[
                  _ProcessRow(process: process),
                  if (process != visible.last)
                    const SizedBox(height: AppSpacing.sm),
                ],
                if (visible.isEmpty)
                  Text(
                    'No process data',
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
              ];
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => context.push('/processes'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.accent,
                minimumSize: const Size(0, 32),
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('View all →'),
            ),
          ),
        ],
      ),
    );
  }
}

/// A single process row: name plus CPU and memory percentages. Tapping a row
/// with a known pid pushes the process detail screen.
class _ProcessRow extends StatelessWidget {
  const _ProcessRow({required this.process});

  final ProcessInfo process;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final int? pid = process.pid;
    return InkWell(
      onTap: pid == null ? null : () => context.push('/processes/$pid'),
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Text(
                process.name ?? '—',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              formatPercent(process.cpuPercent),
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            SizedBox(
              width: 56,
              child: Text(
                formatPercent(process.memPercent),
                textAlign: TextAlign.right,
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Clamps [value] into the 0-100 range and returns the 0-1 fraction used by
/// progress bars. Returns 0 when [value] is null.
double _barFraction(double? value) {
  if (value == null) {
    return 0;
  }
  return (value.clamp(0, 100) / 100).toDouble();
}

/// Normalized load fraction (load average per core), clamped to 0-1 for the
/// progress bar. Returns 0 when the load or core count is unavailable.
double _loadBarFraction(double? load, int? cores) {
  if (load == null || cores == null || cores <= 0) {
    return 0;
  }
  return (load / cores).clamp(0.0, 1.0);
}

/// Formats a load average with two decimals, or `—` when null.
String _formatLoad(double? load) {
  if (load == null) {
    return '—';
  }
  return load.toStringAsFixed(2);
}
