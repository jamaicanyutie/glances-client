import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/wifi_info.dart';
import '../../../data/providers.dart';
import '../../components/error_view.dart';
import '../../components/loading_view.dart';
import '../../components/metric_sheets.dart';
import '../../components/responsive_card_grid.dart';
import '../../components/settings_button.dart';
import '../../theme/colors.dart';
import '../../theme/theme.dart';

/// Live Wi-Fi networks screen.
///
/// Watches [wifiProvider] (auto-refreshed on the refresh interval) and renders
/// one card per visible network, with a quality bar and signal percentage.
/// Pull-to-refresh forces a re-fetch. This is a Linux-only plugin; hosts
/// without a Wi-Fi interface report an empty list, which renders as a
/// friendly empty state.
class WifiScreen extends ConsumerWidget {
  const WifiScreen({super.key, this.showAppBar = true});

  /// When false the screen renders without its own AppBar, for embedding as a
  /// sub-tab inside the Network hub (which owns the AppBar + TabBar).
  final bool showAppBar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<WifiInfo>> networks = ref.watch(wifiProvider);
    return Scaffold(
      appBar: showAppBar
          ? AppBar(
              title: const Text('Wi-Fi'),
              actions: const <Widget>[SettingsButton()],
            )
          : null,
      body: networks.when(
        skipLoadingOnReload: true,
        skipLoadingOnRefresh: true,
        loading: () => const LoadingView(),
        error: (Object error, StackTrace stackTrace) => ErrorView(
          message: '$error',
          onRetry: () => ref.invalidate(wifiProvider),
        ),
        data: (List<WifiInfo> data) {
          return RefreshIndicator(
            onRefresh: () => ref.read(wifiProvider.notifier).refresh(),
            child: data.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: <Widget>[
                      SizedBox(
                        height: MediaQuery.sizeOf(context).height * 0.65,
                        child: const _EmptyView(
                          icon: Icons.wifi_off,
                          title: 'No Wi-Fi networks',
                          message: 'This host does not expose a Wi-Fi '
                              'interface, or no networks were detected.',
                        ),
                      ),
                    ],
                  )
                : ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(AppSpacing.md),
                    children: <Widget>[
                      ResponsiveCardGrid(
                        children: <Widget>[
                          for (final WifiInfo network in data)
                            _WifiCard(
                              network: network,
                              onTap: () => showMetricSheet(
                                context: context,
                                title: network.ssid ?? 'Network',
                                body: _WifiSheetBody(network: network),
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

/// Centered empty state shown when the server reports no Wi-Fi networks.
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
            Icon(
              icon,
              size: 56,
              color: AppColors.textSecondary.withValues(alpha: 0.6),
            ),
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

/// Shared shell for the Wi-Fi cards: a themed [Card] with a title row.
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
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.labelLarge?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.4,
                      ),
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

/// One Wi-Fi network card: SSID and signal quality.
class _WifiCard extends StatelessWidget {
  const _WifiCard({required this.network, this.onTap});

  final WifiInfo network;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final double quality = (network.qualityLink ?? 0).toDouble();
    return _CardShell(
      title: 'Network',
      icon: Icons.wifi,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            network.ssid ?? '—',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.titleMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          LinearProgressIndicator(
            value: (quality / 100).clamp(0.0, 1.0),
            color: _qualityColor(quality),
            backgroundColor: AppColors.surfaceAlt,
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
          ),
const SizedBox(height: AppSpacing.xs),
          Text(
            '${network.qualityLevel?.toString() ?? '—'}'
            ' · ${network.qualityLink?.toString() ?? '—'}%',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Maps a Wi-Fi quality percentage (0-100) onto a status color.
Color _qualityColor(double quality) {
  if (quality >= 70) {
    return AppColors.success;
  }
  if (quality >= 40) {
    return AppColors.warning;
  }
  return AppColors.danger;
}

/// Sheet body for a Wi-Fi drill-down: every field the API exposes.
class _WifiSheetBody extends StatelessWidget {
  const _WifiSheetBody({required this.network});

  final WifiInfo network;

  @override
  Widget build(BuildContext context) {
    final List<(String, String)> rows = <(String, String)>[
      if (network.ssid != null) ('SSID', network.ssid!),
      if (network.qualityLink != null)
        ('Link quality', '${network.qualityLink}/100'),
      if (network.qualityLevel != null)
        ('Level', '${network.qualityLevel}'),
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
  }
}