import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../data/models/history_point.dart';
import '../theme/colors.dart';
import '../theme/theme.dart';

/// A line chart of a single [HistoryPoint] series, styled for the AMOLED
/// theme.
///
/// When [minY]/[maxY] are null the scale is derived from the series values
/// (with padding) so byte-rate series auto-range; pass explicit bounds for
/// percentage series (e.g. 0-100). Set [showAxisTitles] to true for the
/// expanded, readable variant used inside detail sheets.
class HistoryChart extends StatelessWidget {
  /// Creates a [HistoryChart].
  const HistoryChart({
    super.key,
    required this.series,
    this.color = AppColors.accent,
    this.minY,
    this.maxY,
    this.height = 160,
    this.showAxisTitles = false,
  });

  /// The series to render.
  final List<HistoryPoint> series;

  /// Line color.
  final Color color;

  /// Lower bound of the y axis; auto-derived from [series] when null.
  final double? minY;

  /// Upper bound of the y axis; auto-derived from [series] when null.
  final double? maxY;

  /// Chart height in logical pixels.
  final double height;

  /// Whether to draw axis titles and grid lines.
  final bool showAxisTitles;

  @override
  Widget build(BuildContext context) {
    final List<FlSpot> spots = <FlSpot>[
      for (int i = 0; i < series.length; i++)
        FlSpot(i.toDouble(), series[i].value),
    ];
    final (double lo, double hi) = _yRange(series);
    final double effectiveMin = minY ?? lo;
    final double effectiveMax = maxY ?? hi;
    final double span = effectiveMax - effectiveMin;
    final double interval = span > 0 ? span / 4 : 1;
    return SizedBox(
      height: height,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: spots.length > 1 ? (spots.length - 1).toDouble() : 1.0,
          minY: effectiveMin,
          maxY: effectiveMax,
          gridData: showAxisTitles
              ? FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: interval,
                  getDrawingHorizontalLine: (double value) => FlLine(
                    color: AppColors.border.withValues(alpha: 0.6),
                    strokeWidth: 1,
                  ),
                )
              : const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: showAxisTitles
              ? FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 48,
                      interval: interval,
                      getTitlesWidget:
                          (double value, TitleMeta meta) => Text(
                        _formatAxisValue(value),
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      interval: spots.length > 1
                          ? (spots.length - 1) / 4
                          : 1,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        final int index = value.round();
                        if (index < 0 || index >= series.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            _formatTime(series[index].time),
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                )
              : const FlTitlesData(show: false),
          lineBarsData: <LineChartBarData>[
            LineChartBarData(
              spots: spots,
              isCurved: false,
              color: color,
              barWidth: 2,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: color.withValues(alpha: 0.15),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Returns a (min, max) range for [series] with padding; equal values get a
  /// ±1 band so the line stays visible.
  (double, double) _yRange(List<HistoryPoint> series) {
    double lo = double.infinity;
    double hi = double.negativeInfinity;
    for (final HistoryPoint point in series) {
      if (point.value < lo) {
        lo = point.value;
      }
      if (point.value > hi) {
        hi = point.value;
      }
    }
    if (lo == double.infinity) {
      return (0, 1);
    }
    if (lo == hi) {
      return (lo - 1, hi + 1);
    }
    final double pad = (hi - lo) * 0.1;
    return (lo - pad, hi + pad);
  }

  static String _formatAxisValue(double value) {
    if (value >= 100) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(1);
  }

  static String _formatTime(DateTime time) {
    final DateTime local = time.toLocal();
    final String hh = local.hour.toString().padLeft(2, '0');
    final String mm = local.minute.toString().padLeft(2, '0');
    final String ss = local.second.toString().padLeft(2, '0');
    return '$hh:$mm:$ss';
  }
}

/// A latest/min/max/avg summary row for a history series.
class HistoryStatsRow extends StatelessWidget {
  /// Creates a [HistoryStatsRow].
  const HistoryStatsRow({
    super.key,
    required this.series,
    this.format,
  });

  /// The series to summarize. Ignored when empty.
  final List<HistoryPoint> series;

  /// Formats each statistic; defaults to one-decimal plain numbers.
  final String Function(double)? format;

  @override
  Widget build(BuildContext context) {
    if (series.isEmpty) {
      return const SizedBox.shrink();
    }
    final String Function(double) fmt =
        format ?? (double value) => value.toStringAsFixed(1);
    double min = double.infinity;
    double max = double.negativeInfinity;
    double sum = 0;
    for (final HistoryPoint point in series) {
      if (point.value < min) {
        min = point.value;
      }
      if (point.value > max) {
        max = point.value;
      }
      sum += point.value;
    }
    final List<(String, String)> stats = <(String, String)>[
      ('Latest', fmt(series.last.value)),
      ('Max', fmt(max)),
      ('Min', fmt(min)),
      ('Avg', fmt(sum / series.length)),
    ];
    return Row(
      children: <Widget>[
        for (int i = 0; i < stats.length; i++) ...[
          if (i > 0) const SizedBox(width: AppSpacing.sm),
          Expanded(child: _StatCell(label: stats[i].$1, value: stats[i].$2)),
        ],
      ],
    );
  }
}

/// One statistic cell inside [HistoryStatsRow].
class _StatCell extends StatelessWidget {
  const _StatCell({required this.label, required this.value});

  final String label;
  final String value;

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
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: textTheme.bodyMedium?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
