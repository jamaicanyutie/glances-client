import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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

/// Live Services screen: container health summary plus per-container stats.
///
/// Watches [allStatsProvider] (auto-refreshed every 2 seconds) and renders a
/// summary card ("X running / Y total") followed by one card per container
/// with its image, status dot and CPU/memory usage. The plugin is only
/// present when a container engine is available on the host. Pull-to-refresh
/// re-fetches the snapshot.
class DockerScreen extends ConsumerWidget {
  const DockerScreen({super.key, this.showAppBar = true});

  /// When false the screen renders without its own AppBar, for embedding as a
  /// sub-tab inside the Services hub (which owns the AppBar + TabBar).
  final bool showAppBar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<GlancesAll> allStats = ref.watch(allStatsProvider);
    return Scaffold(
        appBar: showAppBar
            ? AppBar(
                title: const Text('Services'),
                actions: const <Widget>[SettingsButton()],
              )
            : null,
      body: allStats.when(
        skipLoadingOnReload: true,
        skipLoadingOnRefresh: true,
        loading: () => const LoadingView(),
        error: (Object error, StackTrace stackTrace) => ErrorView(
          message: '$error',
          onRetry: () => ref.invalidate(allStatsProvider),
        ),
        data: (GlancesAll data) {
          final List<DockerContainerInfo>? containers = data.docker;
          return RefreshIndicator(
            onRefresh: () => ref.read(allStatsProvider.notifier).refresh(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.md),
              children: <Widget>[
                ResponsiveCardGrid(
                  children: <Widget>[
                    ResponsiveCardGrid.span(
                      _SummaryCard(docker: containers),
                    ),
                    if (containers != null && containers.isNotEmpty)
                      for (final DockerContainerInfo container in containers)
                        _ContainerCard(container: container)
                    else if (containers != null)
                      ResponsiveCardGrid.span(
                        const _MessageCard(message: 'No containers reported'),
                      ),
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

/// A card that only shows a muted message (used for empty states).
class _MessageCard extends StatelessWidget {
  const _MessageCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Text(
          message,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

/// Summary card showing "X running / Y total" with a status-colored dot.
///
/// Shows `Not available` when the containers plugin is missing (no container
/// engine on the host).
class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.docker});

  final List<DockerContainerInfo>? docker;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final List<DockerContainerInfo>? containers = docker;
    final Widget content;
    if (containers == null) {
      content = Text(
        'Not available',
        style: textTheme.bodySmall?.copyWith(
          color: AppColors.textSecondary,
        ),
      );
    } else {
      final int running =
          containers.where((DockerContainerInfo c) => c.isRunning).length;
      final Color statusColor =
          running > 0 ? AppColors.success : AppColors.textSecondary;
      content = Row(
        children: <Widget>[
          Icon(Icons.circle, size: 8, color: statusColor),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              '$running running / ${containers.length} total',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodyMedium?.copyWith(
                color: statusColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      );
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              children: <Widget>[
                const Icon(
                  Icons.inventory_2,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'Services',
                  style: textTheme.labelLarge?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            content,
          ],
        ),
      ),
    );
  }
}

/// One container: name, status dot, image and CPU/memory usage.
///
/// Tapping the card pushes the per-container detail screen
/// ([ContainerDetailScreen] via the `/containers/:id` route).
class _ContainerCard extends StatelessWidget {
  const _ContainerCard({required this.container});

  final DockerContainerInfo container;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final bool running = container.isRunning;
    final Color dotColor =
        running ? AppColors.success : AppColors.textSecondary;
    final String statusLabel = container.status ?? container.state ?? '—';
    final List<String>? images = container.image;
    final String imageLabel;
    if (images == null || images.isEmpty) {
      imageLabel = container.id ?? '—';
    } else {
      imageLabel = images.join(', ');
    }
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/containers/${container.id}'),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
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
                            style: textTheme.bodyMedium?.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Icon(Icons.circle, size: 8, color: dotColor),
                        const SizedBox(width: AppSpacing.xs),
                        Flexible(
                          child: Text(
                            statusLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.bodySmall?.copyWith(
                              color: dotColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      imageLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    formatPercent(container.cpuPercent),
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w600,
                      fontFeatures: const <FontFeature>[
                        FontFeature.tabularFigures(),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    formatPercent(container.memoryPercent),
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontFeatures: const <FontFeature>[
                        FontFeature.tabularFigures(),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
