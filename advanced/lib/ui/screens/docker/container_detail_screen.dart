import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/docker_container_info.dart';
import '../../../data/models/glances_all.dart';
import '../../../data/providers.dart';
import '../../components/error_view.dart';
import '../../components/loading_view.dart';
import '../../components/responsive_card_grid.dart';
import '../../components/settings_button.dart';
import '../../theme/colors.dart';
import '../../theme/theme.dart';
import '../../utils/formatters.dart';

/// Per-container detail screen.
///
/// Pushed from the Services tab with the container's full id as the `:id`
/// path segment. Watches [allStatsProvider] (refreshed every 2 seconds) and
/// re-locates the container by id on every build, so the stats stay live and
/// the screen degrades gracefully if the container disappears.
class ContainerDetailScreen extends ConsumerWidget {
  const ContainerDetailScreen({super.key, required this.containerId});

  /// Full container id from the Glances `containers` plugin.
  final String containerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<GlancesAll> allStats = ref.watch(allStatsProvider);

    return Scaffold(
        appBar: AppBar(
          title: const Text('Container'),
          actions: const <Widget>[SettingsButton()],
        ),
      body: allStats.when(
        skipLoadingOnReload: true,
        skipLoadingOnRefresh: true,
        loading: () => const LoadingView(),
        error: (Object error, StackTrace stackTrace) => ErrorView(
          message: '$error',
          onRetry: () => ref.invalidate(allStatsProvider),
        ),
        data: (GlancesAll data) {
          final DockerContainerInfo? container = data.docker
              ?.where((DockerContainerInfo c) => c.id == containerId)
              .firstOrNull;
          if (container == null) {
            return const _GoneCard();
          }
          return RefreshIndicator(
            onRefresh: () => ref.read(allStatsProvider.notifier).refresh(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.md),
              children: <Widget>[
                ResponsiveCardGrid(
                  children: <Widget>[
                    ResponsiveCardGrid.span(_HeroCard(container: container)),
                    _CpuCard(container: container),
                    _MemoryCard(container: container),
                    _NetworkCard(container: container),
                    _IoCard(container: container),
                    _MetaCard(container: container),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Shown when the container id no longer matches any running container.
class _GoneCard extends StatelessWidget {
  const _GoneCard();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: Text('Container no longer reported by the server'),
      ),
    );
  }
}

/// Shared shell for the detail cards: a themed [Card] with a title row.
class _CardShell extends StatelessWidget {
  const _CardShell({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Card(
      clipBehavior: Clip.antiAlias,
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
    );
  }
}

/// Name, status dot, image and engine.
class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.container});

  final DockerContainerInfo container;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final bool running = container.isRunning;
    final Color dotColor =
        running ? AppColors.success : AppColors.textSecondary;
    final String statusLabel = container.status ?? container.state ?? '—';
    final List<String>? images = container.image;
    final String imageLabel = (images == null || images.isEmpty)
        ? '—'
        : images.join(', ');
    return _CardShell(
      title: 'Overview',
      icon: Icons.info_outline,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  container.name ?? '—',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleLarge?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Icon(Icons.circle, size: 8, color: dotColor),
              const SizedBox(width: AppSpacing.xs),
              Text(
                statusLabel,
                style: textTheme.bodySmall?.copyWith(
                  color: dotColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            imageLabel,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          if (container.engine != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              container.engine!,
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// CPU usage: total percentage, core limit and a progress bar.
class _CpuCard extends StatelessWidget {
  const _CpuCard({required this.container});

  final DockerContainerInfo container;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final double? total = container.cpu?['total'] ?? container.cpuPercent;
    final double? limit = container.cpu?['limit'];
    final double percent = total ?? 0;
    final String limitLabel = limit == null
        ? '—'
        : '${limit.toStringAsFixed(1)} cores';
    return _CardShell(
      title: 'CPU',
      icon: Icons.memory,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(
                formatPercent(total),
                style: textTheme.headlineMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontFeatures: const <FontFeature>[
                    FontFeature.tabularFigures(),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  'limit $limitLabel',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          LinearProgressIndicator(
            value: _barFraction(percent),
            color: _barColor(percent),
            backgroundColor: AppColors.surfaceAlt,
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
          ),
        ],
      ),
    );
  }
}

/// Memory usage: used/limit bytes and a progress bar.
class _MemoryCard extends StatelessWidget {
  const _MemoryCard({required this.container});

  final DockerContainerInfo container;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final Map<String, double>? mem = container.memory ?? container.memUsage;
    final double? used = mem?['usage'];
    final double? limit = mem?['limit'];
    final double percent = (used != null && limit != null && limit > 0)
        ? (used / limit) * 100
        : 0;
    final String valueLabel = used == null
        ? '—'
        : '${formatBytes(used)} / ${formatBytes(limit)}';
    return _CardShell(
      title: 'Memory',
      icon: Icons.straighten,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            formatPercent(container.memoryPercent),
            style: textTheme.headlineMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            valueLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          LinearProgressIndicator(
            value: _barFraction(percent),
            color: _barColor(percent),
            backgroundColor: AppColors.surfaceAlt,
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
          ),
        ],
      ),
    );
  }
}

/// Network rates and cumulative byte counters.
class _NetworkCard extends StatelessWidget {
  const _NetworkCard({required this.container});

  final DockerContainerInfo container;

  @override
  Widget build(BuildContext context) {
    final Map<String, double>? net = container.network;
    return _CardShell(
      title: 'Network',
      icon: Icons.swap_vert,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _RateRow(
            label: 'Rx',
            rate: net?['rx'],
            cumulative: net?['cumulative_rx'],
          ),
          if (net != null) const SizedBox(height: AppSpacing.sm),
          _RateRow(
            label: 'Tx',
            rate: net?['tx'],
            cumulative: net?['cumulative_tx'],
          ),
        ],
      ),
    );
  }
}

/// I/O read/write rates and cumulative byte counters.
class _IoCard extends StatelessWidget {
  const _IoCard({required this.container});

  final DockerContainerInfo container;

  @override
  Widget build(BuildContext context) {
    final Map<String, double>? io = container.io;
    return _CardShell(
      title: 'I/O',
      icon: Icons.sd_storage,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _RateRow(
            label: 'Read',
            rate: io?['ior'],
            cumulative: io?['cumulative_ior'],
          ),
          if (io != null) const SizedBox(height: AppSpacing.sm),
          _RateRow(
            label: 'Write',
            rate: io?['iow'],
            cumulative: io?['cumulative_iow'],
          ),
        ],
      ),
    );
  }
}

/// One rate row: label, current rate (bytes/s) and cumulative bytes.
class _RateRow extends StatelessWidget {
  const _RateRow({
    required this.label,
    required this.rate,
    required this.cumulative,
  });

  final String label;
  final double? rate;
  final double? cumulative;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final String rateLabel = rate == null
        ? '—'
        : '${formatBytes(rate)}/s';
    final String cumLabel = cumulative == null
        ? '—'
        : 'total ${formatBytes(cumulative)}';
    return Row(
      children: <Widget>[
        SizedBox(
          width: 64,
          child: Text(
            label,
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: Text(
            rateLabel,
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
            ),
          ),
        ),
        Text(
          cumLabel,
          style: textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
            fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

/// Static metadata: uptime, created, command, ports.
class _MetaCard extends StatelessWidget {
  const _MetaCard({required this.container});

  final DockerContainerInfo container;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final List<(String, String)> rows = <(String, String)>[
      ('Uptime', container.uptime ?? '—'),
      ('Created', container.created ?? '—'),
      ('Command', container.command ?? '—'),
      ('Ports', (container.ports ?? '').isEmpty ? '—' : container.ports!),
    ];
    return _CardShell(
      title: 'Details',
      icon: Icons.description_outlined,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (int i = 0; i < rows.length; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.sm),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SizedBox(
                  width: 80,
                  child: Text(
                    rows[i].$1,
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    rows[i].$2,
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
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

/// Maps a usage percentage (0-100) onto the status color scale.
Color _barColor(double percent) {
  if (percent >= 85) {
    return AppColors.danger;
  }
  if (percent >= 60) {
    return AppColors.warning;
  }
  return AppColors.accent;
}
