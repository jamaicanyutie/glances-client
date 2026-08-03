import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/models/glances_all.dart';
import '../../../data/models/network_info.dart';
import '../../../data/providers.dart';
import '../../components/error_view.dart';
import '../../components/loading_view.dart';
import '../../components/metric_sheets.dart';
import '../../components/nav_card.dart';
import '../../components/responsive_card_grid.dart';
import '../../components/settings_button.dart';
import '../../theme/colors.dart';
import '../../theme/theme.dart';
import '../../utils/formatters.dart';

/// Live Network screen: per-interface traffic counters and link speed.
///
/// Watches [allStatsProvider] (auto-refreshed every 2 seconds) and renders one
/// card per network interface showing the link state, cumulative bytes
/// received/sent and the interface speed. Pull-to-refresh re-fetches the
/// snapshot.
class NetworkScreen extends ConsumerWidget {
  const NetworkScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<GlancesAll> allStats = ref.watch(allStatsProvider);
    return Scaffold(
        appBar: AppBar(
          title: const Text('Network'),
          actions: const <Widget>[SettingsButton()],
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
          final List<NetworkInfo>? interfaces = data.network;
          return RefreshIndicator(
            onRefresh: () => ref.read(allStatsProvider.notifier).refresh(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.md),
              children: <Widget>[
                ResponsiveCardGrid(
                  children: <Widget>[
                    if (interfaces == null)
                      ResponsiveCardGrid.span(
                        const _MessageCard(message: 'No network interfaces'),
                      )
                    else if (interfaces.isEmpty)
                      ResponsiveCardGrid.span(
                        const _MessageCard(message: 'No interfaces reported'),
                      )
                    else
                      for (final NetworkInfo iface in interfaces)
                        _InterfaceCard(iface: iface),
                    ResponsiveCardGrid.span(
                      const _SectionHeader(
                        title: 'Connections',
                        icon: Icons.hub,
                      ),
                    ),
                    const _ConnectionsCard(),
                    ResponsiveCardGrid.span(
                      const _SectionHeader(
                        title: 'Addressing & ports',
                        icon: Icons.lan_outlined,
                      ),
                    ),
                    NavCard(
                      title: 'IP Address',
                      icon: Icons.lan_outlined,
                      onTap: () => context.push('/ip'),
                      caption: 'Private and public network addressing →',
                    ),
                    NavCard(
                      title: 'Wi-Fi',
                      icon: Icons.wifi,
                      onTap: () => context.push('/wifi'),
                      caption: 'Detected Wi-Fi networks →',
                    ),
                    NavCard(
                      title: 'Ports',
                      icon: Icons.hub_outlined,
                      onTap: () => context.push('/ports'),
                      caption: 'Host and port reachability checks →',
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

/// Section heading row, styled like the card titles on the Home screen.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Row(
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
    );
  }
}

/// A card that only shows a muted message (used for empty states).
class _MessageCard extends StatelessWidget {
  const _MessageCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Text(
          message,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

/// Tappable card that opens the aggregate connections sheet.
class _ConnectionsCard extends StatelessWidget {
  const _ConnectionsCard();

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => showMetricSheet(
          context: context,
          title: 'Connections',
          body: const ConnectionsSheetBody(),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: <Widget>[
              Icon(Icons.hub, size: 20, color: AppColors.textSecondary),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  'Active connections',
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: 20,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One network interface: name, link state, cumulative traffic and speed.
/// Tapping opens the interface detail sheet with counters and rate history.
class _InterfaceCard extends StatelessWidget {
  const _InterfaceCard({required this.iface});

  final NetworkInfo iface;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final bool up = iface.isUp ?? false;
    final Color statusColor = up ? AppColors.success : AppColors.danger;
    final double? speed = iface.speed;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => showMetricSheet(
          context: context,
          title: iface.interfaceName ?? 'Interface',
          body: InterfaceSheetBody(iface: iface),
        ),
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
                      iface.interfaceName ?? '—',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Icon(Icons.circle, size: 8, color: statusColor),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    up ? 'Up' : 'Down',
                    style: textTheme.bodySmall?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _TrafficRow(
                label: 'Received',
                icon: Icons.arrow_downward,
                color: AppColors.accent,
                value: formatBytes(iface.bytesRecv),
              ),
              const SizedBox(height: AppSpacing.sm),
              _TrafficRow(
                label: 'Sent',
                icon: Icons.arrow_upward,
                color: AppColors.warning,
                value: formatBytes(iface.bytesSent),
              ),
              if (speed != null) ...[
                const SizedBox(height: AppSpacing.md),
                const Divider(),
                const SizedBox(height: AppSpacing.md),
                _TrafficRow(
                  label: 'Speed',
                  icon: Icons.speed,
                  color: AppColors.textSecondary,
                  value: _formatSpeed(speed),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// A label/value row inside an interface card.
class _TrafficRow extends StatelessWidget {
  const _TrafficRow({
    required this.label,
    required this.icon,
    required this.color,
    required this.value,
  });

  final String label;
  final IconData icon;
  final Color color;
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
        Icon(icon, size: 12, color: color),
        const SizedBox(width: AppSpacing.xs),
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

/// Formats an interface speed (bits per second) in Mb/s with one decimal.
String _formatSpeed(double speedBps) {
  return '${(speedBps / 1e6).toStringAsFixed(1)} Mb/s';
}
