import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/glances_all.dart';
import '../../../data/models/mem_info.dart';
import '../../../data/providers.dart';
import '../../components/error_view.dart';
import '../../components/loading_view.dart';
import '../../components/server_reset_button.dart';
import '../../theme/colors.dart';
import '../../theme/theme.dart';
import '../../utils/formatters.dart';

/// Live memory usage screen.
///
/// Watches [allStatsProvider] (refreshed every 2 seconds) and renders the
/// memory plugin summary: a hero card with the usage percentage plus a details
/// card with the byte-level breakdown. Pull-to-refresh forces a re-fetch.
class MemoryScreen extends ConsumerWidget {
  const MemoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<GlancesAll> allStats = ref.watch(allStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Memory'),
        actions: const <Widget>[ServerResetButton()],
      ),
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
                else ...[
                  _MemoryHeroCard(mem: mem),
                  const SizedBox(height: AppSpacing.md),
                  _MemoryDetailsCard(mem: mem),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Shared shell for the memory cards: a themed [Card] with a title row.
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

/// Full-width hero card: memory usage percentage, used/total and a progress bar.
class _MemoryHeroCard extends StatelessWidget {
  const _MemoryHeroCard({required this.mem});

  final MemInfo mem;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final double percent = mem.percent ?? 0;
    return _CardShell(
      title: 'Usage',
      icon: Icons.speed,
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

/// Full-width card with one row per memory category (formatted bytes).
///
/// A row is only rendered when its value is non-null.
class _MemoryDetailsCard extends StatelessWidget {
  const _MemoryDetailsCard({required this.mem});

  final MemInfo mem;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final List<(String, double?)> rows = <(String, double?)>[
      ('Used', mem.used),
      ('Total', mem.total),
      ('Available', mem.available),
      ('Free', mem.free),
      ('Cached', mem.cached),
      ('Buffers', mem.buffers),
      ('Shared', mem.shared),
      ('Slab', mem.slab),
    ];

    final List<Widget> children = <Widget>[];
    for (final (String label, double? value) in rows) {
      if (value == null) {
        continue;
      }
      if (children.isNotEmpty) {
        children.add(const SizedBox(height: AppSpacing.sm));
      }
      children.add(_DetailRow(label: label, value: formatBytes(value)));
    }

    return _CardShell(
      title: 'Details',
      icon: Icons.straighten,
      child: children.isEmpty
          ? Text(
              'No memory details',
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

/// A single details row: label on the left, formatted value on the right.
class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            label,
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          value,
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
