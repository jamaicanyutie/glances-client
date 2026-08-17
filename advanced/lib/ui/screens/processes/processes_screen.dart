import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/models/process_info.dart';
import '../../../data/providers.dart';
import '../../components/error_view.dart';
import '../../components/loading_view.dart';
import '../../components/responsive_card_grid.dart';
import '../../components/settings_button.dart';
import '../../theme/colors.dart';
import '../../theme/theme.dart';
import '../../utils/formatters.dart';

/// Live process list drill-down screen (pushed from CPU/Memory).
///
/// Watches [topProcessesProvider] (top 30 processes by CPU usage, refreshed
/// every 2 seconds) and renders one card per process with a status-colored
/// dot, name, PID/user/status and CPU/memory percentages. Pull-to-refresh
/// forces a re-fetch.
class ProcessesScreen extends ConsumerWidget {
  const ProcessesScreen({super.key, this.showAppBar = true});

  /// When false the screen renders without its own AppBar, for embedding as a
  /// sub-tab inside the Services hub (which owns the AppBar + TabBar).
  final bool showAppBar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<ProcessInfo>> processes =
        ref.watch(topProcessesProvider);

    return Scaffold(
        appBar: showAppBar
            ? AppBar(
                title: const Text('Processes'),
                actions: const <Widget>[SettingsButton()],
              )
            : null,
      body: processes.when(
        skipLoadingOnReload: true,
        skipLoadingOnRefresh: true,
        loading: () => const LoadingView(),
        error: (Object error, StackTrace stackTrace) => ErrorView(
          message: '$error',
          onRetry: () => ref.invalidate(topProcessesProvider),
        ),
        data: (List<ProcessInfo> items) {
          return RefreshIndicator(
            onRefresh: () => ref.read(topProcessesProvider.notifier).refresh(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.md),
              children: <Widget>[
                if (items.isEmpty)
                  const _EmptyProcessesCard()
                else
                  ResponsiveCardGrid(
                    children: <Widget>[
                      for (final ProcessInfo process in items)
                        _ProcessCard(process: process),
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

/// Shown when the server reports no processes at all.
class _EmptyProcessesCard extends StatelessWidget {
  const _EmptyProcessesCard();

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Center(
          child: Text(
            'No process data',
            style: textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

/// A single process row: status dot, name + metadata, CPU and memory
/// percentages. Tapping a row with a known pid pushes the process detail
/// screen.
class _ProcessCard extends StatelessWidget {
  const _ProcessCard({required this.process});

  final ProcessInfo process;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final String pid = process.pid?.toString() ?? '—';
    final String username = process.username ?? '—';
    final String status = process.status ?? '—';
    final String? commandLine = process.command?.join(' ');
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: process.pid == null
            ? null
            : () => context.push('/processes/${process.pid}'),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _statusColor(process.status),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      process.name ?? '—',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodyLarge?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'PID $pid · $username · $status',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (commandLine != null && commandLine.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        commandLine,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    formatPercent(process.cpuPercent),
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w700,
                      fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    formatPercent(process.memPercent),
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
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

  /// Maps a process status onto the status color scale.
  Color _statusColor(String? status) {
    if (status == null) {
      return AppColors.textSecondary;
    }
    switch (status.toUpperCase()) {
      case 'R':
      case 'RUNNING':
        return AppColors.success;
      case 'S':
      case 'SLEEPING':
        return AppColors.warning;
      case 'Z':
      case 'ZOMBIE':
        return AppColors.danger;
      default:
        return AppColors.textSecondary;
    }
  }
}
