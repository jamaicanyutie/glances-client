import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/folders_info.dart';
import '../../../data/providers.dart';
import '../../components/error_view.dart';
import '../../components/loading_view.dart';
import '../../components/responsive_card_grid.dart';
import '../../components/settings_button.dart';
import '../../theme/colors.dart';
import '../../theme/theme.dart';
import '../../utils/formatters.dart';

/// Folders screen.
///
/// Watches [foldersProvider] (auto-refreshed on the refresh interval) and
/// renders one card per monitored folder with its size breakdown and a usage
/// bar. Pull-to-refresh forces a re-fetch. Servers without a configured
/// folders list report an empty array, which renders as a friendly empty
/// state.
class FoldersScreen extends ConsumerWidget {
  const FoldersScreen({super.key, this.showAppBar = true});

  /// When false the screen renders without its own AppBar, for embedding as a
  /// sub-tab inside the Disks hub (which owns the AppBar + TabBar).
  final bool showAppBar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<FolderInfo>> folders = ref.watch(foldersProvider);
    return Scaffold(
      appBar: showAppBar
          ? AppBar(
              title: const Text('Folders'),
              actions: const <Widget>[SettingsButton()],
            )
          : null,
      body: folders.when(
        skipLoadingOnReload: true,
        skipLoadingOnRefresh: true,
        loading: () => const LoadingView(),
        error: (Object error, StackTrace stackTrace) => ErrorView(
          message: '$error',
          onRetry: () => ref.invalidate(foldersProvider),
        ),
        data: (List<FolderInfo> data) {
          return RefreshIndicator(
            onRefresh: () => ref.read(foldersProvider.notifier).refresh(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.md),
              children: <Widget>[
                if (data.isEmpty)
                  SizedBox(
                    height: MediaQuery.sizeOf(context).height * 0.65,
                    child: const _EmptyView(
                      icon: Icons.folder_open,
                      title: 'No monitored folders',
                      message: 'This server does not expose any folders.',
                    ),
                  )
                else
                  ResponsiveCardGrid(
                    children: <Widget>[
                      for (final FolderInfo folder in data)
                        _FolderCard(folder: folder),
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

/// Centered empty state shown when the server reports no monitored folders.
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

/// One monitored folder: name, size breakdown and a usage bar.
class _FolderCard extends StatelessWidget {
  const _FolderCard({required this.folder});

  final FolderInfo folder;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final double percent = folder.percent?.toDouble() ?? 0;
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
                    folder.name ?? '—',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  formatPercent(folder.percent?.toDouble()),
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${formatBytes(folder.used?.toDouble())} used of '
              '${formatBytes(folder.size?.toDouble())} · '
              '${formatBytes(folder.free?.toDouble())} free',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
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