import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/glances_all.dart';
import '../../../data/models/network_info.dart';
import '../../../data/providers.dart';
import '../../components/error_view.dart';
import '../../components/loading_view.dart';
import '../../components/server_reset_button.dart';
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
          final List<NetworkInfo>? interfaces = data.network;
          return RefreshIndicator(
            onRefresh: () => ref.read(allStatsProvider.notifier).refresh(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.md),
              children: <Widget>[
                if (interfaces == null)
                  const _MessageCard(message: 'No network interfaces')
                else if (interfaces.isEmpty)
                  const _MessageCard(message: 'No interfaces reported')
                else
                  for (final NetworkInfo iface in interfaces) ...[
                    _InterfaceCard(iface: iface),
                    if (iface != interfaces.last)
                      const SizedBox(height: AppSpacing.md),
                  ],
              ],
            ),
          );
        },
      ),
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

/// One network interface: name, link state, cumulative traffic and speed.
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
