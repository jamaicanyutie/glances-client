import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/models/process_detail_info.dart';
import '../../../data/providers.dart';
import '../../components/error_view.dart';
import '../../components/loading_view.dart';
import '../../components/responsive_card_grid.dart';
import '../../theme/colors.dart';
import '../../theme/theme.dart';
import '../../utils/formatters.dart';

/// Extended process list (`GET /api/4/processes/extended`), embedded as the
/// **Extended** sub-tab of the Services hub.
///
/// Shows the extra per-process fields the server reports (thread count,
/// children CPU time, I/O counters) in addition to the standard name/PID/CPU/
/// memory columns. Servers not started with `--enable-process-extended` return
/// no data, which is rendered as a "not enabled" empty state rather than an
/// error.
class ExtendedProcessesView extends ConsumerWidget {
  const ExtendedProcessesView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<ProcessDetailInfo>> processes =
        ref.watch(extendedProcessesProvider);

    return processes.when(
      skipLoadingOnReload: true,
      skipLoadingOnRefresh: true,
      loading: () => const LoadingView(),
      error: (Object error, StackTrace stackTrace) => ErrorView(
        message: '$error',
        onRetry: () => ref.invalidate(extendedProcessesProvider),
      ),
      data: (List<ProcessDetailInfo> items) {
        return RefreshIndicator(
          onRefresh: () => ref.read(extendedProcessesProvider.notifier).refresh(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.md),
            children: <Widget>[
              if (items.isEmpty)
                const _ExtendedNotEnabledCard()
              else
                ResponsiveCardGrid(
                  children: <Widget>[
                    for (final ProcessDetailInfo process in items)
                      _ExtendedProcessCard(process: process),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Shown when the server is not collecting extended process stats.
class _ExtendedNotEnabledCard extends StatelessWidget {
  const _ExtendedNotEnabledCard();

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Extended stats not enabled',
              style: textTheme.titleMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'This server is not collecting extended process information. '
              'Start Glances with the `--enable-process-extended` flag to '
              'expose per-process I/O counters, threads and children CPU '
              'times here.',
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A single extended process card: the standard name/PID/CPU/memory row plus
/// the extra fields (threads, children CPU, I/O counters) the extended
/// endpoint reports. Tapping a row with a known pid pushes the process detail
/// screen.
class _ExtendedProcessCard extends StatelessWidget {
  const _ExtendedProcessCard({required this.process});

  final ProcessDetailInfo process;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final String pid = process.pid?.toString() ?? '—';
    final String username = process.username ?? '—';
    final String status = process.status ?? '—';
    final String? commandLine = process.cmdline?.join(' ');

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: process.pid == null
            ? null
            : () => context.push('/processes/${process.pid}'),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _statusColor(status),
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
                          fontFeatures: const <FontFeature>[
                            FontFeature.tabularFigures(),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        formatPercent(process.memPercent),
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
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: <Widget>[
                  _MetaChip(
                    label: 'Threads',
                    value: process.numThreads?.toString() ?? '—',
                  ),
                  _MetaChip(
                    label: 'Children CPU',
                    value: formatPercent(_childrenCpuPercent(process)),
                  ),
                  _MetaChip(
                    label: 'I/O read',
                    value: formatBytes(_ioBytes(process, read: true)),
                  ),
                  _MetaChip(
                    label: 'I/O write',
                    value: formatBytes(_ioBytes(process, read: false)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Sum of the `children_user` and `children_system` CPU times, or null when
  /// the server reported neither.
  static double? _childrenCpuPercent(ProcessDetailInfo process) {
    final Map<String, double>? times = process.cpuTimes;
    if (times == null) {
      return null;
    }
    final double? user = times['children_user'];
    final double? system = times['children_system'];
    if (user == null && system == null) {
      return null;
    }
    return (user ?? 0) + (system ?? 0);
  }

  /// Read (`read: true`) or write byte counter from psutil's
  /// `io_counters` tuple: `[read_count, write_count, read_bytes, write_bytes,
  /// read_chars, write_chars]`.
  static double? _ioBytes(ProcessDetailInfo process, {required bool read}) {
    final List<double>? io = process.ioCounters;
    if (io == null) {
      return null;
    }
    final int index = read ? 2 : 3;
    if (index >= io.length) {
      return null;
    }
    return io[index];
  }

  /// Maps a process status onto the status color scale.
  Color _statusColor(String status) {
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

/// A small label/value pill used for the extended per-process fields.
class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(8),
      ),
      child: RichText(
        text: TextSpan(
          style: textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
          ),
          children: <TextSpan>[
            TextSpan(text: '$label '),
            TextSpan(
              text: value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}