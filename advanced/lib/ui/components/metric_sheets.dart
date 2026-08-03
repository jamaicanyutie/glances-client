import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/connection_stats_info.dart';
import '../../data/models/cpu_info.dart';
import '../../data/models/disk_io_info.dart';
import '../../data/models/docker_container_info.dart';
import '../../data/models/fs_info.dart';
import '../../data/models/glances_all.dart';
import '../../data/models/history_point.dart';
import '../../data/models/mem_info.dart';
import '../../data/models/mem_swap_info.dart';
import '../../data/models/network_info.dart';
import '../../data/models/per_cpu_info.dart';
import '../../data/models/process_info.dart';
import '../../data/providers.dart';
import '../theme/colors.dart';
import '../theme/theme.dart';
import '../utils/formatters.dart';
import 'history_chart.dart';

/// Opens a themed bottom sheet with [title] and [body].
///
/// The sheet is capped at 85% of the screen height; [body] scrolls when it
/// overflows. Metric drill-downs use sheets (lightweight, contextual), while
/// process details push a full screen.
Future<void> showMetricSheet({
  required BuildContext context,
  required String title,
  required Widget body,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surface,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (BuildContext context) => SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: AppSpacing.md),
              Flexible(child: SingleChildScrollView(child: body)),
            ],
          ),
        ),
      ),
    ),
  );
}

/// A label/value row inside a metric sheet.
class SheetValueRow extends StatelessWidget {
  /// Creates a [SheetValueRow].
  const SheetValueRow({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Row(
      children: <Widget>[
        Text(
          label,
          style: textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        // Expanded (not a bare Text): a non-flexible child is laid out at its
        // intrinsic width and would push the label to zero width and overflow
        // the row when the value is long (e.g. mount options).
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
            style: textTheme.bodyMedium?.copyWith(
              color: valueColor ?? AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    );
  }
}

/// Shared loading box used by sheet bodies while their provider resolves.
class _SheetLoading extends StatelessWidget {
  const _SheetLoading();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 120,
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}

/// Shared muted message used by sheet bodies for empty/unavailable states.
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

/// Renders a history [series] as a chart plus a latest/min/max/avg row.
///
/// Pure widget — the provider is watched by the parent sheet bodies.
class HistoryAsyncBody extends StatelessWidget {
  /// Creates a [HistoryAsyncBody].
  const HistoryAsyncBody({
    super.key,
    required this.history,
    this.color = AppColors.accent,
    this.format,
    this.minY,
    this.maxY,
    this.height = 180,
    this.showAxisTitles = true,
  });

  final AsyncValue<List<HistoryPoint>> history;
  final Color color;
  final String Function(double)? format;
  final double? minY;
  final double? maxY;
  final double height;
  final bool showAxisTitles;

  @override
  Widget build(BuildContext context) {
    return history.when(
      skipLoadingOnReload: true,
      skipLoadingOnRefresh: true,
      loading: () => const _SheetLoading(),
      error: (Object error, StackTrace stackTrace) =>
          const _SheetMessage('History unavailable for this metric'),
      data: (List<HistoryPoint> points) {
        if (points.isEmpty) {
          return const _SheetMessage('No history recorded for this metric');
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            HistoryChart(
              series: points,
              color: color,
              minY: minY,
              maxY: maxY,
              height: height,
              showAxisTitles: showAxisTitles,
            ),
            const SizedBox(height: AppSpacing.md),
            HistoryStatsRow(series: points, format: format),
          ],
        );
      },
    );
  }
}

/// Sheet body for a single plugin-field history series.
///
/// Watches [itemHistoryProvider] for the given [query].
class SingleHistorySheetBody extends ConsumerWidget {
  /// Creates a [SingleHistorySheetBody].
  const SingleHistorySheetBody({
    super.key,
    required this.query,
    this.color = AppColors.accent,
    this.format,
    this.minY,
    this.maxY,
    this.height = 180,
  });

  final ItemHistoryQuery query;
  final Color color;
  final String Function(double)? format;
  final double? minY;
  final double? maxY;
  final double height;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<HistoryPoint>> history =
        ref.watch(itemHistoryProvider(query));
    return HistoryAsyncBody(
      history: history,
      color: color,
      format: format,
      minY: minY,
      maxY: maxY,
      height: height,
    );
  }
}

/// Sheet body for the expanded CPU history (merged total usage).
///
/// Watches the auto-refreshed [cpuHistoryProvider].
class CpuHistorySheetBody extends ConsumerWidget {
  /// Creates a [CpuHistorySheetBody].
  const CpuHistorySheetBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<HistoryPoint>> history =
        ref.watch(cpuHistoryProvider);
    return HistoryAsyncBody(
      history: history,
      minY: 0,
      maxY: 100,
      format: (double value) => '${value.toStringAsFixed(1)}%',
      height: 220,
    );
  }
}

/// One progress row inside [CpuBreakdownSheetBody].
class _BreakdownSheetRow extends StatelessWidget {
  const _BreakdownSheetRow({required this.label, required this.value});

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
              _percentFormat(value),
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

/// Sheet body for the CPU breakdown drill-down: the current per-category
/// percentages plus a user/system history chart.
///
/// The REST history endpoint for the `cpu` plugin only exposes `user` and
/// `system` samples (the other categories are live-only), so the chart shows
/// those two series while the rows list every category's current value.
class CpuBreakdownSheetBody extends ConsumerWidget {
  /// Creates a [CpuBreakdownSheetBody].
  const CpuBreakdownSheetBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<GlancesAll> allStats = ref.watch(allStatsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          'Current breakdown',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
              ),
        ),
        const SizedBox(height: AppSpacing.sm),
        allStats.when(
          skipLoadingOnReload: true,
          skipLoadingOnRefresh: true,
          loading: () => const _SheetLoading(),
          error: (Object error, StackTrace stackTrace) =>
              const _SheetMessage('CPU data unavailable'),
          data: (GlancesAll data) {
            final CpuInfo? cpu = data.cpu;
            if (cpu == null) {
              return const _SheetMessage('CPU data unavailable');
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (cpu.user != null)
                  _BreakdownSheetRow(label: 'User', value: cpu.user!),
                if (cpu.system != null)
                  _BreakdownSheetRow(label: 'System', value: cpu.system!),
                if (cpu.nice != null)
                  _BreakdownSheetRow(label: 'Nice', value: cpu.nice!),
                if (cpu.iowait != null)
                  _BreakdownSheetRow(label: 'I/O wait', value: cpu.iowait!),
                if (cpu.steal != null)
                  _BreakdownSheetRow(label: 'Steal', value: cpu.steal!),
                if (cpu.irq != null)
                  _BreakdownSheetRow(label: 'IRQ', value: cpu.irq!),
                if (cpu.softInterrupts != null)
                  _BreakdownSheetRow(
                    label: 'SoftIRQ',
                    value: cpu.softInterrupts!,
                  ),
                const SizedBox(height: AppSpacing.xs),
                SheetValueRow(label: 'Idle', value: formatPercent(cpu.idle)),
                const SizedBox(height: AppSpacing.xs),
                SheetValueRow(label: 'Guest', value: formatPercent(cpu.guest)),
                const SizedBox(height: AppSpacing.xs),
                SheetValueRow(
                  label: 'Guest nice',
                  value: formatPercent(cpu.guestNice),
                ),
                const SizedBox(height: AppSpacing.xs),
                SheetValueRow(
                  label: 'Context switches',
                  value: cpu.ctxSwitches?.toString() ?? '—',
                ),
                const SizedBox(height: AppSpacing.xs),
                SheetValueRow(
                  label: 'Syscalls',
                  value: cpu.syscalls?.toString() ?? '—',
                ),
              ],
            );
          },
        ),
        const SizedBox(height: AppSpacing.md),
        const Divider(color: AppColors.border),
        const SizedBox(height: AppSpacing.md),
        Text(
          'User vs system history',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
              ),
        ),
        const SizedBox(height: AppSpacing.sm),
        MultiSeriesHistoryChart(
          series: <SeriesSpec>[
            SeriesSpec(
              label: 'User',
              query: const ItemHistoryQuery(plugin: 'cpu', item: 'user'),
              color: AppColors.accent,
              format: _percentFormat,
            ),
            SeriesSpec(
              label: 'System',
              query: const ItemHistoryQuery(plugin: 'cpu', item: 'system'),
              color: AppColors.warning,
              format: _percentFormat,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        const Divider(color: AppColors.border),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Per-container CPU',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
              ),
        ),
        const SizedBox(height: AppSpacing.sm),
        _PerContainerCpuBody(),
      ],
    );
  }
}

class _PerContainerCpuBody extends ConsumerWidget {
  const _PerContainerCpuBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<GlancesAll> allStats = ref.watch(allStatsProvider);
    return allStats.when(
      skipLoadingOnReload: true,
      skipLoadingOnRefresh: true,
      loading: () => const _SheetLoading(),
      error: (Object error, StackTrace stackTrace) =>
          const _SheetMessage('Container data unavailable'),
      data: (GlancesAll data) {
        final List<DockerContainerInfo>? containers = data.docker;
        if (containers == null || containers.isEmpty) {
          return const _SheetMessage('No container data');
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            for (int i = 0; i < containers.length; i++) ...[
              _ContainerCpuRow(container: containers[i]),
              if (i != containers.length - 1)
                const SizedBox(height: AppSpacing.sm),
            ],
          ],
        );
      },
    );
  }
}

/// Per-container CPU row inside [CpuBreakdownSheetBody].
class _ContainerCpuRow extends StatelessWidget {
  const _ContainerCpuRow({required this.container});

  final DockerContainerInfo container;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final String? id = container.id;
    final double percent = container.cpu?.containsKey('total') == true
        ? (container.cpu!['total'] ?? 0)
        : (container.cpuPercent ?? 0);
    return InkWell(
      onTap: id == null ? null : () => context.push('/containers/$id'),
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
                    container.name ?? id?.substring(0, 12) ?? '—',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  formatPercent(percent),
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            LinearProgressIndicator(
              value: _barFraction(percent),
              color: _barColor(percent),
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
class _PerCoreRow extends StatelessWidget {
  const _PerCoreRow({required this.core, required this.isLast});

  final PerCpuInfo core;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final double percent = core.total ?? 0;
    final Color barColor = _barColor(percent);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                'Core ${core.cpuNumber ?? '—'}',
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              formatPercent(core.total),
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
          value: _barFraction(percent),
          color: barColor,
          backgroundColor: AppColors.surfaceAlt,
          minHeight: 4,
          borderRadius: BorderRadius.circular(2),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.xs,
          children: <Widget>[
            _PerCoreDetail(label: 'User', value: formatPercent(core.user)),
            _PerCoreDetail(label: 'System', value: formatPercent(core.system)),
            _PerCoreDetail(label: 'Idle', value: formatPercent(core.idle)),
            _PerCoreDetail(label: 'I/O wait', value: formatPercent(core.iowait)),
            _PerCoreDetail(label: 'Nice', value: formatPercent(core.nice)),
            _PerCoreDetail(label: 'Steal', value: formatPercent(core.steal)),
            _PerCoreDetail(label: 'IRQ', value: formatPercent(core.irq)),
            _PerCoreDetail(label: 'SoftIRQ', value: formatPercent(core.softirq)),
            _PerCoreDetail(label: 'Guest', value: formatPercent(core.guest)),
            _PerCoreDetail(
              label: 'Guest nice',
              value: formatPercent(core.guestNice),
            ),
          ],
        ),
        if (!isLast) const SizedBox(height: AppSpacing.sm),
      ],
    );
  }
}

/// One compact label/value pair inside [_PerCoreRow]'s per-core detail wrap.
class _PerCoreDetail extends StatelessWidget {
  const _PerCoreDetail({required this.label, required this.value});

  final String label;
  final String value;

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
            style: textTheme.labelSmall?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

/// Sheet body for the per-core CPU breakdown (`GET /api/4/percpu`).
class PerCoreSheetBody extends ConsumerWidget {
  /// Creates a [PerCoreSheetBody].
  const PerCoreSheetBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<PerCpuInfo>> cores = ref.watch(perCpuProvider);
    return cores.when(
      skipLoadingOnReload: true,
      skipLoadingOnRefresh: true,
      loading: () => const _SheetLoading(),
      error: (Object error, StackTrace stackTrace) =>
          const _SheetMessage('Per-core data unavailable'),
      data: (List<PerCpuInfo> items) {
        if (items.isEmpty) {
          return const _SheetMessage('No per-core data');
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            for (int i = 0; i < items.length; i++)
              _PerCoreRow(core: items[i], isLast: i == items.length - 1),
          ],
        );
      },
    );
  }
}

class _AppMemRow extends StatelessWidget {
  const _AppMemRow({required this.process});

  final ProcessInfo process;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final int? pid = process.pid;
    final double percent = process.memPercent ?? 0;
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
                  formatPercent(percent),
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            LinearProgressIndicator(
              value: _barFraction(percent),
              color: _barColor(percent),
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

/// Sheet body for the per-app memory breakdown: the raw memory counters plus
/// the top processes by memory usage.
class MemBreakdownSheetBody extends ConsumerWidget {
  const MemBreakdownSheetBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<ProcessInfo>> processes =
        ref.watch(topProcessesProvider);
    final AsyncValue<GlancesAll> allStats = ref.watch(allStatsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        allStats.when(
          skipLoadingOnReload: true,
          skipLoadingOnRefresh: true,
          loading: () => const SizedBox.shrink(),
          error: (Object error, StackTrace stackTrace) =>
              const SizedBox.shrink(),
          data: (GlancesAll data) {
            final MemInfo? mem = data.mem;
            if (mem == null) {
              return const SizedBox.shrink();
            }
            final List<(String, String)> rows = <(String, String)>[
              ('Used', formatBytes(mem.used)),
              ('Free', formatBytes(mem.free)),
              ('Available', formatBytes(mem.available)),
              ('Usage', formatPercent(mem.percent)),
              ('Active', formatBytes(mem.active)),
              ('Inactive', formatBytes(mem.inactive)),
              ('Buffers', formatBytes(mem.buffers)),
              ('Cached', formatBytes(mem.cached)),
              ('Shared', formatBytes(mem.shared)),
              ('Slab', formatBytes(mem.slab)),
              ('Total', formatBytes(mem.total)),
            ];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  'Memory',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.4,
                      ),
                ),
                const SizedBox(height: AppSpacing.sm),
                for (int i = 0; i < rows.length; i++) ...[
                  if (i > 0) const SizedBox(height: AppSpacing.sm),
                  SheetValueRow(label: rows[i].$1, value: rows[i].$2),
                ],
              ],
            );
          },
        ),
        const SizedBox(height: AppSpacing.md),
        const Divider(color: AppColors.border),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Top processes by memory',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
              ),
        ),
        const SizedBox(height: AppSpacing.sm),
        processes.when(
          skipLoadingOnReload: true,
          skipLoadingOnRefresh: true,
          loading: () => const _SheetLoading(),
          error: (Object error, StackTrace stackTrace) =>
              const _SheetMessage('Process list unavailable'),
          data: (List<ProcessInfo> list) {
            final List<ProcessInfo> sorted = List<ProcessInfo>.from(list);
            sorted.sort((ProcessInfo a, ProcessInfo b) {
              final double ma = a.memPercent ?? 0;
              final double mb = b.memPercent ?? 0;
              return mb.compareTo(ma);
            });
            final List<ProcessInfo> visible = sorted.take(10).toList();
            if (visible.isEmpty) {
              return const _SheetMessage('No process data');
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                for (int i = 0; i < visible.length; i++) ...[
                  _AppMemRow(process: visible[i]),
                  if (i != visible.length - 1) const SizedBox(height: AppSpacing.sm),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

/// Sheet body for the Memory & Swap drill-down: the current memory summary,
/// the swap plugin fields and the mem-percent history.
class SwapSheetBody extends ConsumerWidget {
  /// Creates a [SwapSheetBody].
  const SwapSheetBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<MemSwapInfo> swap = ref.watch(memSwapProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        swap.when(
          skipLoadingOnReload: true,
          skipLoadingOnRefresh: true,
          loading: () => const _SheetLoading(),
          error: (Object error, StackTrace stackTrace) =>
              const _SheetMessage('Swap data unavailable'),
          data: (MemSwapInfo info) {
            final List<(String, String)> rows = <(String, String)>[
              ('Total', formatBytes(info.total)),
              ('Used', formatBytes(info.used)),
              ('Free', formatBytes(info.free)),
              ('Usage', formatPercent(info.percent)),
              ('Swapped in', formatBytes(info.sin)),
              ('Swapped out', formatBytes(info.sout)),
            ];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                for (int i = 0; i < rows.length; i++) ...[
                  if (i > 0) const SizedBox(height: AppSpacing.sm),
                  SheetValueRow(label: rows[i].$1, value: rows[i].$2),
                ],
              ],
            );
          },
        ),
        const SizedBox(height: AppSpacing.md),
        const Divider(color: AppColors.border),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Memory usage history',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
              ),
        ),
        const SizedBox(height: AppSpacing.sm),
        const SingleHistorySheetBody(
          query: ItemHistoryQuery(plugin: 'mem', item: 'percent'),
          minY: 0,
          maxY: 100,
          format: _percentFormat,
        ),
      ],
    );
  }
}

/// Sheet body for the aggregate connections drill-down: per-state counts plus
/// the netfilter conntrack statistics.
///
/// The REST API only exposes aggregate counts; the individual connection
/// tuples shown by the Glances web UI are not available over HTTP, which the
/// sheet notes.
class ConnectionsSheetBody extends ConsumerWidget {
  /// Creates a [ConnectionsSheetBody].
  const ConnectionsSheetBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<ConnectionStatsInfo> connections =
        ref.watch(connectionsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        connections.when(
          skipLoadingOnReload: true,
          skipLoadingOnRefresh: true,
          loading: () => const _SheetLoading(),
          error: (Object error, StackTrace stackTrace) =>
              const _SheetMessage('Connections data unavailable'),
          data: (ConnectionStatsInfo info) {
            final List<(String, String)> rows = <(String, String)>[
              if (info.statusCounts.isNotEmpty) ...[
                ('Total', '${info.totalConnections}'),
                for (final MapEntry<String, int> entry
                    in info.statusCounts.entries)
                  (entry.key, '${entry.value}'),
              ],
              if (info.initiated != null) ('Initiated', '${info.initiated}'),
              if (info.terminated != null) ('Terminated', '${info.terminated}'),
              if (info.nfConntrackCount != null)
                (
                  'Conntrack count',
                  info.nfConntrackCount!.toStringAsFixed(0),
                ),
              if (info.nfConntrackMax != null)
                ('Conntrack max', info.nfConntrackMax!.toStringAsFixed(0)),
              if (info.nfConntrackPercent != null)
                ('Conntrack usage', formatPercent(info.nfConntrackPercent)),
            ];
            if (rows.isEmpty) {
              return const _SheetMessage('No connection data');
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                for (int i = 0; i < rows.length; i++) ...[
                  if (i > 0) const SizedBox(height: AppSpacing.sm),
                  SheetValueRow(label: rows[i].$1, value: rows[i].$2),
                ],
              ],
            );
          },
        ),
        const SizedBox(height: AppSpacing.md),
        const Divider(color: AppColors.border),
        const SizedBox(height: AppSpacing.md),
        Text(
          'The REST API exposes aggregate counts only — individual '
          'connections are not available.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
      ],
    );
  }
}

/// Sheet body for a filesystem mount: full mount fields plus the fs-percent
/// history.
class FsMountSheetBody extends ConsumerWidget {
  /// Creates a [FsMountSheetBody].
  const FsMountSheetBody({super.key, required this.mount});

  final FsInfo mount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<(String, String)> rows = <(String, String)>[
      ('Mount point', mount.mntPoint ?? '—'),
      ('Device', mount.deviceName ?? '—'),
      ('Type', mount.fsType ?? '—'),
      ('Options', mount.options ?? '—'),
      ('Size', formatBytes(mount.size)),
      ('Used', formatBytes(mount.used)),
      ('Free', formatBytes(mount.free)),
      ('Available', formatBytes(mount.avail)),
      ('Usage', formatPercent(mount.percent)),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (int i = 0; i < rows.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.sm),
          SheetValueRow(label: rows[i].$1, value: rows[i].$2),
        ],
        const SizedBox(height: AppSpacing.md),
        const Divider(color: AppColors.border),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Usage history',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
              ),
        ),
        const SizedBox(height: AppSpacing.sm),
        const SingleHistorySheetBody(
          query: ItemHistoryQuery(plugin: 'fs', item: 'percent'),
          minY: 0,
          maxY: 100,
          format: _percentFormat,
        ),
        const SizedBox(height: AppSpacing.md),
        const Divider(color: AppColors.border),
        const SizedBox(height: AppSpacing.md),
        const _PerContainerRateSection(
          title: 'Per-container disk I/O',
          readLabel: 'Read',
          writeLabel: 'Write',
          pickRates: _containerDiskIoRates,
        ),
      ],
    );
  }
}

/// Sheet body for a disk device: counters plus a two-series read/write rate
/// history.
class DiskIoSheetBody extends ConsumerWidget {
  /// Creates a [DiskIoSheetBody].
  const DiskIoSheetBody({super.key, required this.device});

  final DiskIoInfo device;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<(String, String)> rows = <(String, String)>[
      ('Device', device.diskName ?? '—'),
      ('Read rate', formatRate(device.readBytes, device.timeSinceUpdate)),
      ('Write rate', formatRate(device.writeBytes, device.timeSinceUpdate)),
      if (device.readTime != null)
        ('Read time', '${device.readTime!.toStringAsFixed(0)} ms'),
      if (device.writeTime != null)
        ('Write time', '${device.writeTime!.toStringAsFixed(0)} ms'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (int i = 0; i < rows.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.sm),
          SheetValueRow(label: rows[i].$1, value: rows[i].$2),
        ],
        const SizedBox(height: AppSpacing.md),
        const Divider(color: AppColors.border),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Read/write rate history',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
              ),
        ),
        const SizedBox(height: AppSpacing.sm),
        MultiSeriesHistoryChart(
          series: <SeriesSpec>[
            SeriesSpec(
              label: 'Read',
              query: const ItemHistoryQuery(
                plugin: 'diskio',
                item: 'read_bytes_rate_per_sec',
              ),
              color: AppColors.accent,
              format: formatBytes,
            ),
            SeriesSpec(
              label: 'Write',
              query: const ItemHistoryQuery(
                plugin: 'diskio',
                item: 'write_bytes_rate_per_sec',
              ),
              color: AppColors.warning,
              format: formatBytes,
            ),
          ],
        ),
      ],
    );
  }
}

/// Sheet body for a network interface: counters plus a two-series rx/tx rate
/// history.
class InterfaceSheetBody extends ConsumerWidget {
  /// Creates an [InterfaceSheetBody].
  const InterfaceSheetBody({super.key, required this.iface});

  final NetworkInfo iface;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool up = iface.isUp ?? false;
    final List<(String, String)> rows = <(String, String)>[
      ('Interface', iface.interfaceName ?? '—'),
      ('State', up ? 'Up' : 'Down'),
      ('Received', formatBytes(iface.bytesRecv)),
      ('Sent', formatBytes(iface.bytesSent)),
      if (iface.packetsRecv != null) ('Packets received', '${iface.packetsRecv}'),
      if (iface.packetsSent != null) ('Packets sent', '${iface.packetsSent}'),
      if (iface.errin != null) ('Errors in', '${iface.errin}'),
      if (iface.errout != null) ('Errors out', '${iface.errout}'),
      if (iface.dropin != null) ('Drops in', '${iface.dropin}'),
      if (iface.dropout != null) ('Drops out', '${iface.dropout}'),
      if (iface.speed != null)
        ('Speed', '${(iface.speed! / 1e6).toStringAsFixed(1)} Mb/s'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (int i = 0; i < rows.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.sm),
          SheetValueRow(label: rows[i].$1, value: rows[i].$2),
        ],
        const SizedBox(height: AppSpacing.md),
        const Divider(color: AppColors.border),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Traffic rate history',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
              ),
        ),
        const SizedBox(height: AppSpacing.sm),
        MultiSeriesHistoryChart(
          series: <SeriesSpec>[
            SeriesSpec(
              label: 'Rx',
              query: const ItemHistoryQuery(
                plugin: 'network',
                item: 'bytes_recv_rate_per_sec',
              ),
              color: AppColors.accent,
              format: formatBytes,
            ),
            SeriesSpec(
              label: 'Tx',
              query: const ItemHistoryQuery(
                plugin: 'network',
                item: 'bytes_sent_rate_per_sec',
              ),
              color: AppColors.warning,
              format: formatBytes,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        const Divider(color: AppColors.border),
        const SizedBox(height: AppSpacing.md),
        const _PerContainerRateSection(
          title: 'Per-container traffic',
          readLabel: 'Rx',
          writeLabel: 'Tx',
          pickRates: _containerNetworkRates,
        ),
      ],
    );
  }
}

/// Extracts per-second disk read/write rates from a container's `io` counters
/// (`ior`/`iow` deltas over `time_since_update` seconds). Returns null when the
/// container reports no I/O data.
(String, String)? _containerDiskIoRates(DockerContainerInfo container) {
  final Map<String, double>? io = container.io;
  if (io == null) {
    return null;
  }
  final double? ior = io['ior'];
  final double? iow = io['iow'];
  if (ior == null && iow == null) {
    return null;
  }
  return (
    formatRate(ior, io['time_since_update']),
    formatRate(iow, io['time_since_update']),
  );
}

/// Extracts per-second network rx/tx rates from a container's `network`
/// counters (`rx`/`tx` deltas over `time_since_update` seconds). Returns null
/// when the container reports no network data.
(String, String)? _containerNetworkRates(DockerContainerInfo container) {
  final Map<String, double>? network = container.network;
  if (network == null) {
    return null;
  }
  final double? rx = network['rx'];
  final double? tx = network['tx'];
  if (rx == null && tx == null) {
    return null;
  }
  return (
    formatRate(rx, network['time_since_update']),
    formatRate(tx, network['time_since_update']),
  );
}

/// Section listing per-container rates (disk I/O or network traffic) inside
/// metric sheets. Hidden entirely when the host reports no Docker containers
/// or no container has usable counters for the metric.
class _PerContainerRateSection extends ConsumerWidget {
  const _PerContainerRateSection({
    required this.title,
    required this.readLabel,
    required this.writeLabel,
    required this.pickRates,
  });

  final String title;
  final String readLabel;
  final String writeLabel;
  final (String, String)? Function(DockerContainerInfo container) pickRates;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<GlancesAll> all = ref.watch(allStatsProvider);
    return all.when(
      skipLoadingOnReload: true,
      skipLoadingOnRefresh: true,
      loading: () => const SizedBox.shrink(),
      error: (Object error, StackTrace stackTrace) => const SizedBox.shrink(),
      data: (GlancesAll data) {
        final List<DockerContainerInfo>? containers = data.docker;
        if (containers == null || containers.isEmpty) {
          return const SizedBox.shrink();
        }
        final List<(DockerContainerInfo, String, String)> rows =
            <(DockerContainerInfo, String, String)>[];
        for (final DockerContainerInfo c in containers) {
          final (String, String)? rates = pickRates(c);
          if (rates != null) {
            rows.add((c, rates.$1, rates.$2));
          }
        }
        if (rows.isEmpty) {
          return const SizedBox.shrink();
        }
        final TextTheme textTheme = Theme.of(context).textTheme;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              title,
              style: textTheme.labelLarge?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    'Container',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.labelSmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Flexible(
                  child: Text(
                    readLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.labelSmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Flexible(
                  child: Text(
                    writeLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.labelSmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            for (int i = 0; i < rows.length; i++) ...[
              _ContainerRateRow(
                container: rows[i].$1,
                read: rows[i].$2,
                write: rows[i].$3,
              ),
              if (i != rows.length - 1) const SizedBox(height: AppSpacing.xs),
            ],
          ],
        );
      },
    );
  }
}

/// One per-container rate row inside [_PerContainerRateSection].
class _ContainerRateRow extends StatelessWidget {
  const _ContainerRateRow({
    required this.container,
    required this.read,
    required this.write,
  });

  final DockerContainerInfo container;
  final String read;
  final String write;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final String name = container.name ?? container.id ?? '—';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Text(
              read,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Text(
              write,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One series of a [MultiSeriesHistoryChart].
class SeriesSpec {
  /// Creates a [SeriesSpec].
  const SeriesSpec({
    required this.label,
    required this.query,
    required this.color,
    this.format,
  });

  final String label;
  final ItemHistoryQuery query;
  final Color color;
  final String Function(double)? format;
}

/// Sheet body rendering several history series on one chart, with a legend.
class MultiSeriesHistoryChart extends ConsumerWidget {
  /// Creates a [MultiSeriesHistoryChart].
  const MultiSeriesHistoryChart({
    super.key,
    required this.series,
    this.height = 180,
  });

  final List<SeriesSpec> series;
  final double height;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<AsyncValue<List<HistoryPoint>>> histories =
        <AsyncValue<List<HistoryPoint>>>[
      for (final SeriesSpec spec in series)
        ref.watch(itemHistoryProvider(spec.query)),
    ];
    final bool anyLoading = histories.any(
      (AsyncValue<List<HistoryPoint>> h) => h.isLoading && !h.hasValue,
    );
    final bool anyError = histories.any(
      (AsyncValue<List<HistoryPoint>> h) => h.hasError,
    );
    if (anyLoading) {
      return const _SheetLoading();
    }
    if (anyError) {
      return const _SheetMessage('History unavailable for this metric');
    }
    final List<List<HistoryPoint>> datas = <List<HistoryPoint>>[
      for (final AsyncValue<List<HistoryPoint>> h in histories)
        h.value ?? const <HistoryPoint>[],
    ];
    if (datas.every((List<HistoryPoint> d) => d.isEmpty)) {
      return const _SheetMessage('No history recorded for this metric');
    }
    final int maxLength = datas
        .map((List<HistoryPoint> d) => d.length)
        .fold<int>(0, (int a, int b) => a > b ? a : b);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          children: <Widget>[
            for (int i = 0; i < series.length; i++) ...[
              if (i > 0) const SizedBox(width: AppSpacing.md),
              _LegendItem(color: series[i].color, label: series[i].label),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: height,
          child: LineChart(
            LineChartData(
              minX: 0,
              maxX: maxLength > 1 ? (maxLength - 1).toDouble() : 1.0,
              minY: 0,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: _autoInterval(datas),
                getDrawingHorizontalLine: (double value) => FlLine(
                  color: AppColors.border.withValues(alpha: 0.6),
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(show: false),
              titlesData: const FlTitlesData(show: false),
              lineBarsData: <LineChartBarData>[
                for (int i = 0; i < series.length; i++)
                  LineChartBarData(
                    spots: <FlSpot>[
                      for (int j = 0; j < datas[i].length; j++)
                        FlSpot(j.toDouble(), datas[i][j].value),
                    ],
                    isCurved: false,
                    color: series[i].color,
                    barWidth: 2,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: i == 0,
                      color: series[i].color.withValues(alpha: 0.1),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: <Widget>[
            for (int i = 0; i < series.length; i++) ...[
              if (i > 0) const SizedBox(width: AppSpacing.md),
              Expanded(
                child: HistoryStatsRow(
                  series: datas[i],
                  format: series[i].format,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  /// Picks a sensible horizontal grid interval for the combined y range.
  double _autoInterval(List<List<HistoryPoint>> datas) {
    double lo = double.infinity;
    double hi = double.negativeInfinity;
    for (final List<HistoryPoint> data in datas) {
      for (final HistoryPoint point in data) {
        if (point.value < lo) {
          lo = point.value;
        }
        if (point.value > hi) {
          hi = point.value;
        }
      }
    }
    if (lo == double.infinity || lo == hi) {
      return 1;
    }
    return (hi - lo) / 4;
  }
}

/// One legend item (colored dot plus label) inside [MultiSeriesHistoryChart].
class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
      ],
    );
  }
}

String _percentFormat(double value) => '${value.toStringAsFixed(1)}%';

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
