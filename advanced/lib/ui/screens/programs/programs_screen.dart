import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/models/process_info.dart';
import '../../../data/models/program_info.dart';
import '../../../data/providers.dart';
import '../../components/error_view.dart';
import '../../components/loading_view.dart';
import '../../components/metric_sheets.dart';
import '../../components/responsive_card_grid.dart';
import '../../components/settings_button.dart';
import '../../theme/colors.dart';
import '../../theme/theme.dart';
import '../../utils/formatters.dart';

/// Programs screen.
///
/// Watches [programsProvider] (auto-refreshed on the refresh interval) and
/// renders one card per aggregated program with its process count, threads,
/// user/status and CPU/memory percentages. Pull-to-refresh forces a re-fetch.
/// Servers without the programlist plugin report an empty list, which renders
/// as a friendly empty state.
class ProgramsScreen extends ConsumerWidget {
  const ProgramsScreen({super.key, this.showAppBar = true});

  /// When false the screen renders without its own AppBar, for embedding as a
  /// sub-tab inside the Services hub (which owns the AppBar + TabBar).
  final bool showAppBar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<ProgramInfo>> programs = ref.watch(programsProvider);
    return Scaffold(
      appBar: showAppBar
          ? AppBar(
              title: const Text('Programs'),
              actions: const <Widget>[SettingsButton()],
            )
          : null,
      body: programs.when(
        skipLoadingOnReload: true,
        skipLoadingOnRefresh: true,
        loading: () => const LoadingView(),
        error: (Object error, StackTrace stackTrace) => ErrorView(
          message: '$error',
          onRetry: () => ref.invalidate(programsProvider),
        ),
        data: (List<ProgramInfo> data) {
          return RefreshIndicator(
            onRefresh: () => ref.read(programsProvider.notifier).refresh(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.md),
              children: <Widget>[
                if (data.isEmpty)
                  SizedBox(
                    height: MediaQuery.sizeOf(context).height * 0.65,
                    child: const _EmptyView(
                      icon: Icons.apps,
                      title: 'No programs reported',
                      message: 'This server does not expose an aggregated '
                          'program list.',
                    ),
                  )
                else
                  ResponsiveCardGrid(
                    children: <Widget>[
                      for (final ProgramInfo program in data)
                        _ProgramCard(program: program),
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

/// Centered empty state shown when the server reports no programs.
class _EmptyView extends StatelessWidget {
  const _EmptyView({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 56, color: AppColors.textSecondary.withValues(alpha: 0.6)),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              style: textTheme.titleLarge?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

/// One aggregated program: name, process/thread count, user/status line,
/// command line and CPU/memory percentages. Tapping opens a sheet listing the
/// program's constituent processes, each of which pushes the process-detail
/// screen.
class _ProgramCard extends StatelessWidget {
  const _ProgramCard({required this.program});

  final ProgramInfo program;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final String username = program.username ?? '—';
    final String status = program.status ?? '—';
    final String? commandLine = program.cmdline?.join(' ');
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => showMetricSheet(
          context: context,
          title: program.name ?? 'Program',
          body: _ProgramProcessesSheetBody(programName: program.name),
        ),
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
                    Text(
                      program.name ?? '—',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodyLarge?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '${_plural(program.nprocs, 'process')} · '
                      '${_plural(program.numThreads, 'thread')} · '
                      '$username · $status',
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
                    formatPercent(program.cpuPercent),
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
                    formatPercent(program.memoryPercent),
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      fontFeatures: const <FontFeature>[
                        FontFeature.tabularFigures(),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(width: AppSpacing.xs),
              const Icon(
                Icons.chevron_right,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Sheet body listing the processes aggregated under a program name.
///
/// Watches [processListProvider] (auto-refreshed) and filters by [programName].
/// Each row pushes the full process-detail screen, mirroring the per-app
/// memory rows in the metric sheets.
class _ProgramProcessesSheetBody extends ConsumerWidget {
  const _ProgramProcessesSheetBody({required this.programName});

  final String? programName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String name = programName ?? '';
    if (name.isEmpty) {
      return const _SheetMessage('No process details available');
    }
    final AsyncValue<List<ProcessInfo>> processes =
        ref.watch(processListProvider);
    return processes.when(
      skipLoadingOnReload: true,
      skipLoadingOnRefresh: true,
      loading: () => const SizedBox(
        height: 120,
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      error: (Object error, StackTrace stackTrace) =>
          const _SheetMessage('Process list unavailable'),
      data: (List<ProcessInfo> list) {
        final List<ProcessInfo> matches =
            list.where((ProcessInfo p) => p.name == name).toList()
              ..sort((ProcessInfo a, ProcessInfo b) {
                final double ca = a.cpuPercent ?? 0;
                final double cb = b.cpuPercent ?? 0;
                return cb.compareTo(ca);
              });
        if (matches.isEmpty) {
          return const _SheetMessage('No individual processes reported');
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            for (int i = 0; i < matches.length; i++) ...[
              _ProgramProcessRow(process: matches[i]),
              if (i != matches.length - 1) const SizedBox(height: AppSpacing.sm),
            ],
          ],
        );
      },
    );
  }
}

/// One process row inside [_ProgramProcessesSheetBody]. Tapping pushes the
/// process-detail screen for that pid.
class _ProgramProcessRow extends StatelessWidget {
  const _ProgramProcessRow({required this.process});

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    pid == null ? '—' : 'PID $pid',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                _PercentLabel(
                  label: 'CPU',
                  value: formatPercent(process.cpuPercent),
                  color: AppColors.accent,
                ),
                const SizedBox(width: AppSpacing.sm),
                _PercentLabel(
                  label: 'MEM',
                  value: formatPercent(process.memPercent),
                  color: AppColors.textSecondary,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            LinearProgressIndicator(
              value: _barFraction(process.cpuPercent),
              color: AppColors.accent,
              backgroundColor: AppColors.surfaceAlt,
              minHeight: 4,
              borderRadius: BorderRadius.circular(2),
            ),
          ],
        ),
      ),
    );
  }
}

/// A tiny labeled percentage (e.g. `CPU 12.8%`) used inside process rows so
/// the two numbers are distinguishable.
class _PercentLabel extends StatelessWidget {
  const _PercentLabel({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Text.rich(
      TextSpan(
        children: <InlineSpan>[
          TextSpan(
            text: '$label ',
            style: textTheme.labelSmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          TextSpan(
            text: value,
            style: textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

/// The shared muted message widget for sheet bodies.
class _SheetMessage extends StatelessWidget {
  const _SheetMessage(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Text(
      message,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
          ),
    );
  }
}

/// Clamps a percentage to the 0-1 bar range.
double _barFraction(double? percent) {
  if (percent == null) {
    return 0;
  }
  return (percent / 100).clamp(0.0, 1.0);
}

/// Formats a count with its noun, handling null (rendered as `—`).
String _plural(int? count, String noun) {
  if (count == null) {
    return '— $noun';
  }
  return '$count $noun${count == 1 ? '' : 's'}';
}