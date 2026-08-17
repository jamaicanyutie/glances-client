import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/glances_all.dart';
import '../../../data/models/mem_info.dart';
import '../../../data/models/mem_swap_info.dart';
import '../../../data/providers.dart';
import '../../components/error_view.dart';
import '../../components/loading_view.dart';
import '../../components/metric_sheets.dart';
import '../../components/responsive_card_grid.dart';
import '../../components/settings_button.dart';
import '../../theme/colors.dart';
import '../../theme/theme.dart';
import '../../utils/formatters.dart';

/// Live memory usage screen.
///
/// Watches [allStatsProvider] (refreshed every 2 seconds) and [memSwapProvider]
/// for swap details. Renders three cards: Usage (per-app breakdown on tap),
/// Swap (details on tap), and Memory History.
class MemoryScreen extends ConsumerWidget {
  const MemoryScreen({super.key, this.showAppBar = true});

  /// When false the screen renders without its own AppBar, for embedding as a
  /// sub-tab inside the Memory hub (which owns the AppBar + TabBar).
  final bool showAppBar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<GlancesAll> allStats = ref.watch(allStatsProvider);
    final AsyncValue<MemSwapInfo> swap = ref.watch(memSwapProvider);

    return Scaffold(
        appBar: showAppBar
            ? AppBar(
                title: const Text('Memory'),
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
          final MemInfo? mem = data.mem;
          return RefreshIndicator(
            onRefresh: () => ref.read(allStatsProvider.notifier).refresh(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.md),
              children: <Widget>[
                if (mem == null)
                  const _MemoryUnavailableCard()
                else
                  ResponsiveCardGrid(
                    children: <Widget>[
                      _MemoryHeroCard(
                        mem: mem,
                        onTap: () => showMetricSheet(
                          context: context,
                          title: 'Memory breakdown',
                          body: const MemBreakdownSheetBody(),
                        ),
                      ),
                      _SwapCard(
                        swap: swap,
                        onTap: () => showMetricSheet(
                          context: context,
                          title: 'Swap',
                          body: const SwapSheetBody(),
                        ),
                      ),
                      _MemoryHistoryCard(
                        onTap: () => showMetricSheet(
                          context: context,
                          title: 'Memory History',
                          body: const SingleHistorySheetBody(
                            query: ItemHistoryQuery(plugin: 'mem', item: 'percent'),
                            minY: 0,
                            maxY: 100,
                            format: _percentFormat,
                          ),
                        ),
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

/// Shown when the Glances server reports no memory plugin at all.
class _MemoryUnavailableCard extends StatelessWidget {
  const _MemoryUnavailableCard();

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return _CardShell(
      title: 'Memory',
      icon: Icons.speed,
      child: Text(
        'Not available',
        style: textTheme.bodyMedium?.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

/// Shared shell for the memory cards: a themed [Card] with a title row and
/// optional tap navigation.
class _CardShell extends StatelessWidget {
  const _CardShell({
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

/// Full-width card showing swap summary.
class _SwapCard extends StatelessWidget {
  const _SwapCard({required this.swap, this.onTap});

  final AsyncValue<MemSwapInfo> swap;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      title: 'Swap',
      icon: Icons.swap_horiz,
      onTap: onTap,
      child: swap.when(
        skipLoadingOnReload: true,
        skipLoadingOnRefresh: true,
        loading: () => const SizedBox(
          height: 48,
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
        error: (Object error, StackTrace stackTrace) => Text(
          'Swap unavailable',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        data: (MemSwapInfo info) {
          final double percent = info.percent ?? 0;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                formatPercent(percent),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
                    ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '${formatBytes(info.used)} / ${formatBytes(info.total)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
              if (info.sin != null || info.sout != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Swapped in: ${formatBytes(info.sin)}  |  Swapped out: ${formatBytes(info.sout)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

/// Full-width card showing memory history sparkline.
class _MemoryHistoryCard extends StatelessWidget {
  const _MemoryHistoryCard({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      title: 'Memory History',
      icon: Icons.show_chart,
      onTap: onTap,
      child: const SingleHistorySheetBody(
        query: ItemHistoryQuery(plugin: 'mem', item: 'percent'),
        minY: 0,
        maxY: 100,
        format: _percentFormat,
        height: 120,
      ),
    );
  }
}

/// Full-width hero card: memory usage percentage, used/total and a progress bar.
class _MemoryHeroCard extends StatelessWidget {
  const _MemoryHeroCard({required this.mem, this.onTap});

  final MemInfo mem;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final double percent = mem.percent ?? 0;
    return _CardShell(
      title: 'Usage',
      icon: Icons.speed,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            formatPercent(mem.percent),
            style: textTheme.headlineMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${formatBytes(mem.used)} / ${formatBytes(mem.total)}',
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

/// Formats a history value as a one-decimal percentage.
String _percentFormat(double value) => '${value.toStringAsFixed(1)}%';
