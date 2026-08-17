import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/gpu_info.dart';
import '../../../data/providers.dart';
import '../../components/error_view.dart';
import '../../components/loading_view.dart';
import '../../components/responsive_card_grid.dart';
import '../../components/settings_button.dart';
import '../../theme/colors.dart';
import '../../theme/theme.dart';
import '../../utils/formatters.dart';

/// GPU screen.
///
/// Watches [gpuProvider] (auto-refreshed on the refresh interval) and renders
/// one card per GPU with its vendor, driver, temperature and memory/processor
/// usage. Pull-to-refresh forces a re-fetch. Only hosts with a GPU report
/// entries; hosts without one show a friendly empty state.
class GpuScreen extends ConsumerWidget {
  const GpuScreen({super.key, this.showAppBar = true});

  /// When false the screen renders without its own AppBar, for embedding as a
  /// sub-tab inside the CPU hub (which owns the AppBar + TabBar).
  final bool showAppBar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<GpuInfo>> gpus = ref.watch(gpuProvider);
    return Scaffold(
      appBar: showAppBar
          ? AppBar(
              title: const Text('GPU'),
              actions: const <Widget>[SettingsButton()],
            )
          : null,
      body: gpus.when(
        skipLoadingOnReload: true,
        skipLoadingOnRefresh: true,
        loading: () => const LoadingView(),
        error: (Object error, StackTrace stackTrace) => ErrorView(
          message: '$error',
          onRetry: () => ref.invalidate(gpuProvider),
        ),
        data: (List<GpuInfo> data) {
          return RefreshIndicator(
            onRefresh: () => ref.read(gpuProvider.notifier).refresh(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.md),
              children: <Widget>[
                if (data.isEmpty)
                  SizedBox(
                    height: MediaQuery.sizeOf(context).height * 0.65,
                    child: const _EmptyView(
                      icon: Icons.memory,
                      title: 'No GPUs detected',
                      message: 'This host does not expose any GPUs.',
                    ),
                  )
                else
                  ResponsiveCardGrid(
                    children: <Widget>[
                      for (final GpuInfo gpu in data)
                        _GpuCard(gpu: gpu),
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

/// Centered empty state shown when the server reports no GPUs.
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

/// One GPU: name, vendor/driver line, temperature and memory/processor usage.
class _GpuCard extends StatelessWidget {
  const _GpuCard({required this.gpu});

  final GpuInfo gpu;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final String? vendor = gpu.vendor;
    final String? driver = gpu.driver;
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
                Expanded(
                  child: Text(
                    gpu.name ?? '—',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (gpu.temperature != null) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    '${gpu.temperature!.toStringAsFixed(0)}°C',
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                      fontFeatures: const <FontFeature>[
                        FontFeature.tabularFigures(),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            if (vendor != null || driver != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                '${vendor ?? '—'} · ${driver ?? '—'}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            _UsageBar(label: 'Memory', percent: gpu.mem?.toDouble()),
            if (gpu.proc != null) ...[
              const SizedBox(height: AppSpacing.sm),
              _UsageBar(label: 'Processor', percent: gpu.proc?.toDouble()),
            ],
          ],
        ),
      ),
    );
  }
}

/// A labeled usage percentage with a thin progress bar.
class _UsageBar extends StatelessWidget {
  const _UsageBar({required this.label, required this.percent});

  final String label;
  final double? percent;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final double value = percent ?? 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                label,
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              formatPercent(percent),
              style: textTheme.bodySmall?.copyWith(
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
          color: _barColor(value),
          backgroundColor: AppColors.surfaceAlt,
          minHeight: 4,
          borderRadius: BorderRadius.circular(2),
        ),
      ],
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