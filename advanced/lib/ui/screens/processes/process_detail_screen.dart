import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/process_detail_info.dart';
import '../../../data/providers.dart';
import '../../components/error_view.dart';
import '../../components/loading_view.dart';
import '../../components/responsive_card_grid.dart';
import '../../components/settings_button.dart';
import '../../theme/colors.dart';
import '../../theme/theme.dart';
import '../../utils/formatters.dart';

/// Per-process detail screen.
///
/// Pushed from the Home/Processes lists with the process id as the `:pid`
/// path segment. Watches [processDetailProvider] (`GET /api/4/processes/{pid}`,
/// refreshed every [refreshIntervalProvider]) and renders the nested detail
/// fields — CPU times, memory regions, gids, I/O counters — that the flat
/// process list does not carry. Resolves to `null` when the process exits,
/// which is shown as a "process ended" state.
class ProcessDetailScreen extends ConsumerWidget {
  /// Creates a [ProcessDetailScreen] for [pid].
  const ProcessDetailScreen({super.key, required this.pid});

  /// Process id from the Glances process list.
  final int pid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<ProcessDetailInfo?> detail =
        ref.watch(processDetailProvider(pid));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Process'),
        actions: const <Widget>[SettingsButton()],
      ),
      body: detail.when(
        skipLoadingOnReload: true,
        skipLoadingOnRefresh: true,
        loading: () => const LoadingView(),
        error: (Object error, StackTrace stackTrace) => ErrorView(
          message: '$error',
          onRetry: () => ref.invalidate(processDetailProvider(pid)),
        ),
        data: (ProcessDetailInfo? info) {
          if (info == null) {
            return const _GoneCard();
          }
          return RefreshIndicator(
            onRefresh: () =>
                ref.read(processDetailProvider(pid).notifier).refresh(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.md),
              children: <Widget>[
                ResponsiveCardGrid(
                  children: <Widget>[
                    ResponsiveCardGrid.span(_HeroCard(info: info)),
                    if (info.cmdline != null && info.cmdline!.isNotEmpty)
                      ResponsiveCardGrid.span(_CommandCard(cmdline: info.cmdline!)),
                    if (info.cpuTimes != null) _CpuCard(info: info),
                    if (info.memoryInfo != null) _MemoryCard(info: info),
                    if (info.ioCounters != null) _IoCard(info: info),
                    _MetaCard(info: info),
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

/// Shown when the process has exited and the server no longer reports it.
class _GoneCard extends StatelessWidget {
  const _GoneCard();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: Text('Process no longer reported by the server'),
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
            const SizedBox(height: AppSpacing.sm),
            child,
          ],
        ),
      ),
    );
  }
}

/// One label/value row inside a detail card.
class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontFeatures: const <FontFeature>[
                  FontFeature.tabularFigures(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Header card: name, status dot, PID/user/status and the two headline
/// percentages.
class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.info});

  final ProcessDetailInfo info;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final String pid = info.pid?.toString() ?? '—';
    final String username = info.username ?? '—';
    final String status = info.status ?? '—';
    return Card(
      clipBehavior: Clip.antiAlias,
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
                  color: _statusColor(info.status),
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
                    info.name ?? '—',
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
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  formatPercent(info.cpuPercent),
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w700,
                    fontFeatures: const <FontFeature>[
                      FontFeature.tabularFigures(),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  formatPercent(info.memPercent),
                  style: textTheme.bodyMedium?.copyWith(
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
    );
  }
}

/// Command line card: the full argv, wrapped.
class _CommandCard extends StatelessWidget {
  const _CommandCard({required this.cmdline});

  final List<String> cmdline;

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      title: 'Command',
      icon: Icons.terminal,
      child: Text(
        cmdline.join(' '),
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textPrimary,
              fontFamily: 'monospace',
            ),
      ),
    );
  }
}

/// CPU card: headline percentage plus the per-category CPU times.
class _CpuCard extends StatelessWidget {
  const _CpuCard({required this.info});

  final ProcessDetailInfo info;

  static const List<String> _order = <String>[
    'user',
    'system',
    'idle',
    'iowait',
    'nice',
    'children_user',
    'children_system',
  ];

  @override
  Widget build(BuildContext context) {
    final List<(String, String)> rows = <(String, String)>[
      ('CPU', formatPercent(info.cpuPercent)),
      for (final String key in _order)
        if (info.cpuTimes!.containsKey(key))
          (key, '${info.cpuTimes![key]!.toStringAsFixed(1)} s'),
    ];
    return _CardShell(
      title: 'CPU',
      icon: Icons.memory,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (int i = 0; i < rows.length; i++)
            _InfoRow(label: rows[i].$1, value: rows[i].$2),
        ],
      ),
    );
  }
}

/// Memory card: headline percentage plus the memory-region sizes.
class _MemoryCard extends StatelessWidget {
  const _MemoryCard({required this.info});

  final ProcessDetailInfo info;

  static const List<String> _order = <String>[
    'rss',
    'vms',
    'data',
    'shared',
    'text',
  ];

  @override
  Widget build(BuildContext context) {
    final List<(String, String)> rows = <(String, String)>[
      ('Memory', formatPercent(info.memPercent)),
      for (final String key in _order)
        if (info.memoryInfo!.containsKey(key))
          (key, formatBytes(info.memoryInfo![key])),
    ];
    return _CardShell(
      title: 'Memory',
      icon: Icons.data_usage,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (int i = 0; i < rows.length; i++)
            _InfoRow(label: rows[i].$1, value: rows[i].$2),
        ],
      ),
    );
  }
}

/// I/O card: the psutil io_counters tuple with labels.
class _IoCard extends StatelessWidget {
  const _IoCard({required this.info});

  final ProcessDetailInfo info;

  static const List<String> _labels = <String>[
    'Read count',
    'Write count',
    'Read bytes',
    'Write bytes',
    'Read chars',
    'Write chars',
  ];

  @override
  Widget build(BuildContext context) {
    final List<double> io = info.ioCounters!;
    final List<(String, String)> rows = <(String, String)>[
      for (int i = 0; i < io.length && i < _labels.length; i++)
        (i >= 2
            ? (_labels[i], formatBytes(io[i]))
            : (_labels[i], io[i].toStringAsFixed(0))),
      if (info.timeSinceUpdate != null)
        (
          'Since update',
          '${info.timeSinceUpdate!.toStringAsFixed(1)} s',
        ),
    ];
    return _CardShell(
      title: 'I/O',
      icon: Icons.swap_vert,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (int i = 0; i < rows.length; i++)
            _InfoRow(label: rows[i].$1, value: rows[i].$2),
        ],
      ),
    );
  }
}

/// Metadata card: threads, nice, gids, refresh window.
class _MetaCard extends StatelessWidget {
  const _MetaCard({required this.info});

  final ProcessDetailInfo info;

  @override
  Widget build(BuildContext context) {
    final List<(String, String)> rows = <(String, String)>[
      ('Threads', '${info.numThreads ?? '—'}'),
      ('Nice', '${info.nice ?? '—'}'),
      ('Status', info.status ?? '—'),
      if (info.gids != null)
        for (final MapEntry<String, int> entry in info.gids!.entries)
          (entry.key, '${entry.value}'),
    ];
    return _CardShell(
      title: 'Details',
      icon: Icons.info_outline,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (int i = 0; i < rows.length; i++)
            _InfoRow(label: rows[i].$1, value: rows[i].$2),
        ],
      ),
    );
  }
}

/// Maps a process status onto the status color scale (matches the process
/// list rows).
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
