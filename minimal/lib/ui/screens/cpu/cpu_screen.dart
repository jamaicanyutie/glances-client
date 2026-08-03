import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/cpu_info.dart';
import '../../../data/models/glances_all.dart';
import '../../../data/models/history_point.dart';
import '../../../data/providers.dart';
import '../../components/error_view.dart';
import '../../components/loading_view.dart';
import '../../components/server_reset_button.dart';
import '../../theme/colors.dart';
import '../../theme/theme.dart';
import '../../utils/formatters.dart';

/// Live CPU usage screen.
///
/// Watches [allStatsProvider] for the total and per-category CPU percentages
/// (refreshed every 2 seconds) and [cpuHistoryProvider] for the last 60
/// samples rendered as a sparkline (refreshed every 5 seconds). Pull-to-refresh
/// forces both providers.
class CpuScreen extends ConsumerWidget {
  const CpuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<GlancesAll> allStats = ref.watch(allStatsProvider);
    final AsyncValue<List<HistoryPoint>> history =
        ref.watch(cpuHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('CPU'),
        actions: const <Widget>[ServerResetButton()],
      ),
      body: allStats.when(
        skipLoadingOnReload: true,
        skipLoadingOnRefresh: true,
        loading: () => const LoadingView(),
        error: (Object error, StackTrace stackTrace) => ErrorView(
          message: '$error',
          onRetry: () {
            ref.invalidate(allStatsProvider);
            ref.invalidate(cpuHistoryProvider);
          },
        ),
        data: (GlancesAll data) {
          return RefreshIndicator(
            onRefresh: () async {
              await ref.read(allStatsProvider.notifier).refresh();
              await ref.read(cpuHistoryProvider.notifier).refresh();
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.md),
              children: <Widget>[
                _CpuHeroCard(cpu: data.cpu),
                const SizedBox(height: AppSpacing.md),
                _CpuBreakdownCard(cpu: data.cpu),
                const SizedBox(height: AppSpacing.md),
                _CpuHistoryCard(history: history),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Shared shell for the CPU cards: a themed [Card] with a title row.
class _CardShell extends StatelessWidget {
  const _CardShell({required this.title, required this.icon, required this.child});

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

/// Full-width hero card: total CPU percentage, core count and a progress bar.
class _CpuHeroCard extends StatelessWidget {
  const _CpuHeroCard({required this.cpu});

  final CpuInfo? cpu;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final double percent = cpu?.total ?? 0;
    final String cores = cpu?.cpucore?.toString() ?? '—';
    return _CardShell(
      title: 'Total Usage',
      icon: Icons.memory,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            formatPercent(cpu?.total),
            style: textTheme.headlineMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
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

/// Full-width card with one progress row per CPU time category.
///
/// A row is only rendered when its value is non-null.
class _CpuBreakdownCard extends StatelessWidget {
  const _CpuBreakdownCard({required this.cpu});

  final CpuInfo? cpu;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final List<(String, double?)> rows = <(String, double?)>[
      ('User', cpu?.user),
      ('System', cpu?.system),
      ('Nice', cpu?.nice),
      ('I/O wait', cpu?.iowait),
      ('Steal', cpu?.steal),
      ('IRQ', cpu?.irq),
      ('SoftIRQ', cpu?.softInterrupts),
    ];

    final List<Widget> children = <Widget>[];
    for (final (String label, double? value) in rows) {
      if (value == null) {
        continue;
      }
      if (children.isNotEmpty) {
        children.add(const SizedBox(height: AppSpacing.sm));
      }
      children.add(_BreakdownRow(label: label, value: value));
    }

    return _CardShell(
      title: 'Breakdown',
      icon: Icons.donut_small,
      child: children.isEmpty
          ? Text(
              'No breakdown data',
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: children,
            ),
    );
  }
}

/// A single breakdown row: label, percentage and a thin progress bar.
class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({required this.label, required this.value});

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                label,
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              formatPercent(value),
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
                fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        LinearProgressIndicator(
          value: _barFraction(value),
          color: _barColor(value),
          backgroundColor: AppColors.surfaceAlt,
          minHeight: 4,
          borderRadius: BorderRadius.circular(2),
        ),
      ],
    );
  }
}

/// Full-width card with the sparkline of the last 60 CPU samples.
///
/// The history provider has its own loading/error handling: it only degrades
/// this card, never the whole screen.
class _CpuHistoryCard extends StatelessWidget {
  const _CpuHistoryCard({required this.history});

  final AsyncValue<List<HistoryPoint>> history;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return _CardShell(
      title: 'History',
      icon: Icons.show_chart,
      child: history.when(
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
        error: (Object error, StackTrace stackTrace) => SizedBox(
          height: 120,
          child: Center(
            child: Text(
              'History unavailable',
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ),
        data: (List<HistoryPoint> points) {
          if (points.isEmpty) {
            return SizedBox(
              height: 120,
              child: Center(
                child: Text(
                  'No history yet',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            );
          }
          return SizedBox(
            height: 120,
            child: _CpuSparkline(points: points),
          );
        },
      ),
    );
  }
}

/// Renders the CPU history series as a bare line chart (0-100).
class _CpuSparkline extends StatelessWidget {
  const _CpuSparkline({required this.points});

  final List<HistoryPoint> points;

  @override
  Widget build(BuildContext context) {
    final List<FlSpot> spots = <FlSpot>[
      for (int i = 0; i < points.length; i++)
        FlSpot(i.toDouble(), points[i].value),
    ];
    return LineChart(
      LineChartData(
        minX: 0,
        maxX: points.length > 1 ? (points.length - 1).toDouble() : 1.0,
        minY: 0,
        maxY: 100,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: const FlTitlesData(show: false),
        lineBarsData: <LineChartBarData>[
          LineChartBarData(
            spots: spots,
            isCurved: false,
            color: AppColors.accent,
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.accent.withValues(alpha: 0.15),
            ),
          ),
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
