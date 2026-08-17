import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/port_info.dart';
import '../../../data/providers.dart';
import '../../components/error_view.dart';
import '../../components/loading_view.dart';
import '../../components/metric_sheets.dart';
import '../../components/responsive_card_grid.dart';
import '../../components/settings_button.dart';
import '../../theme/colors.dart';
import '../../theme/theme.dart';

/// Live host/port reachability screen.
///
/// Watches [portsProvider] (auto-refreshed on the refresh interval) and
/// renders one card per monitored port, with its reachability status and
/// round-trip time. Pull-to-refresh forces a re-fetch.
class PortsScreen extends ConsumerWidget {
  const PortsScreen({super.key, this.showAppBar = true});

  /// When false the screen renders without its own AppBar, for embedding as a
  /// sub-tab inside the Network hub (which owns the AppBar + TabBar).
  final bool showAppBar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<PortInfo>> ports = ref.watch(portsProvider);
    return Scaffold(
      appBar: showAppBar
          ? AppBar(
              title: const Text('Ports'),
              actions: const <Widget>[SettingsButton()],
            )
          : null,
      body: ports.when(
        skipLoadingOnReload: true,
        skipLoadingOnRefresh: true,
        loading: () => const LoadingView(),
        error: (Object error, StackTrace stackTrace) => ErrorView(
          message: '$error',
          onRetry: () => ref.invalidate(portsProvider),
        ),
        data: (List<PortInfo> data) {
          return RefreshIndicator(
            onRefresh: () => ref.read(portsProvider.notifier).refresh(),
            child: data.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: <Widget>[
                      SizedBox(
                        height: MediaQuery.sizeOf(context).height * 0.65,
                        child: const _EmptyView(
                          icon: Icons.hub_outlined,
                          title: 'No ports configured',
                          message: 'This host does not expose any '
                              'host/port reachability checks.',
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
                          for (final PortInfo port in data)
                            _PortCard(
                              port: port,
                              onTap: port.isReachable
                                  ? () => showMetricSheet(
                                        context: context,
                                        title: '${port.host}:${port.port}',
                                        body: _PortSheetBody(port: port),
                                      )
                                  : null,
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

/// Centered empty state shown when the server reports no port checks.
class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.icon, required this.title, required this.message});

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

/// Shared shell for the port cards.
class _CardShell extends StatelessWidget {
  const _CardShell({required this.title, required this.icon, required this.child, this.onTap});

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

/// One port-check card: host:port, reachability dot and round-trip time.
class _PortCard extends StatelessWidget {
  const _PortCard({required this.port, this.onTap});

  final PortInfo port;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final bool reachable = port.isReachable;
    final Color statusColor = reachable ? AppColors.success : AppColors.danger;
    return _CardShell(
      title: '${port.host ?? '—'}:${port.port ?? '—'}',
      icon: Icons.lan_outlined,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.circle, size: 8, color: statusColor),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  reachable ? 'Reachable' : 'Not reachable',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodyMedium?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (port.rttMs != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              'RTT ${port.rttMs!.toStringAsFixed(0)} ms',
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Sheet body for a port drill-down: every field the API exposes.
class _PortSheetBody extends StatelessWidget {
  const _PortSheetBody({required this.port});

  final PortInfo port;

  @override
  Widget build(BuildContext context) {
    final List<(String, String)> rows = <(String, String)>[
      if (port.host != null) ('Host', port.host!),
      if (port.port != null) ('Port', '${port.port}'),
      if (port.description != null) ('Description', port.description!),
      if (port.status != null) ('Status', '${port.status}'),
      if (port.rttMs != null) ('RTT', '${port.rttMs!.toStringAsFixed(1)} ms'),
      if (port.rttWarning != null) ('RTT warning', '${port.rttWarning}'),
      if (port.indice != null) ('Indice', '${port.indice}'),
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