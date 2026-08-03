import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/alert_info.dart';
import '../../../data/providers.dart';
import '../../components/error_view.dart';
import '../../components/loading_view.dart';
import '../../components/metric_sheets.dart';
import '../../components/responsive_card_grid.dart';
import '../../components/settings_button.dart';
import '../../theme/colors.dart';
import '../../theme/theme.dart';

/// Warning and critical alert events from the Glances `alert` plugin.
///
/// Watches [alertsProvider] (auto-refreshed on the refresh interval) and
/// renders one card per alert with its state chip, stats and timeline.
/// Pull-to-refresh forces a re-fetch. Hosts with no recorded events show an
/// empty state instead of an empty list.
class AlertsScreen extends ConsumerWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<AlertInfo>> alerts = ref.watch(alertsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alerts'),
        actions: const <Widget>[SettingsButton()],
      ),
      body: alerts.when(
        skipLoadingOnReload: true,
        skipLoadingOnRefresh: true,
        loading: () => const LoadingView(),
        error: (Object error, StackTrace stackTrace) => ErrorView(
          message: '$error',
          onRetry: () => ref.invalidate(alertsProvider),
        ),
        data: (List<AlertInfo> data) {
          return RefreshIndicator(
            onRefresh: () => ref.read(alertsProvider.notifier).refresh(),
            child: data.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: <Widget>[
                      SizedBox(
                        height: MediaQuery.sizeOf(context).height * 0.65,
                        child: const _EmptyView(
                          icon: Icons.notifications_none,
                          title: 'No alerts',
                          message: 'No warning or critical events have been '
                              'recorded.',
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
                          for (final AlertInfo alert in data)
                            _AlertCard(
                              alert: alert,
                              onTap: () => showMetricSheet(
                                context: context,
                                title: alert.type ?? 'Alert',
                                body: _AlertSheetBody(alert: alert),
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

/// Centered empty state shown when the server has recorded no alerts.
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

/// Shared shell for the alert cards: a themed [Card] with a title row.
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

/// One alert event: state chip, live indicator, message, stats, top
/// processes and the event timeline.
class _AlertCard extends StatelessWidget {
  const _AlertCard({required this.alert, this.onTap});

  final AlertInfo alert;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final Color stateColor =
        alert.isCritical ? AppColors.danger : AppColors.warning;
    final String message = alert.globalMsg ?? alert.desc ?? '—';
    return _CardShell(
      title: alert.type ?? 'Alert',
      icon: alert.isCritical ? Icons.warning_amber : Icons.error_outline,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              _StateChip(state: alert.state, color: stateColor),
              if (alert.isOngoing) ...[
                const SizedBox(width: AppSpacing.sm),
                const _OngoingIndicator(),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            message,
            style: textTheme.bodyLarge?.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            _statsLine(alert),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
              fontFeatures: const <FontFeature>[
                FontFeature.tabularFigures(),
              ],
            ),
          ),
          if (alert.top != null && alert.top!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Top: ${alert.top!.join(' · ')}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.xs),
          Text(
            _timeline(alert),
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

/// Small pill showing the alert state, tinted by its severity.
class _StateChip extends StatelessWidget {
  const _StateChip({required this.state, required this.color});

  final String? state;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        state ?? '—',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

/// Accent dot plus a `LIVE` label for alerts that are still running.
class _OngoingIndicator extends StatelessWidget {
  const _OngoingIndicator();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.accent,
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          'LIVE',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppColors.accent,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

/// `avg 1.31 · min 0.90 · max 1.76 · 240 samples`, keeping only non-null
/// stats.
String _statsLine(AlertInfo alert) {
  final List<String> parts = <String>[];
  if (alert.avg != null) {
    parts.add('avg ${_formatNum(alert.avg)}');
  }
  if (alert.min != null) {
    parts.add('min ${_formatNum(alert.min)}');
  }
  if (alert.max != null) {
    parts.add('max ${_formatNum(alert.max)}');
  }
  if (alert.count != null) {
    parts.add('${alert.count} samples');
  }
  return parts.isEmpty ? '—' : parts.join(' · ');
}

/// Formats a numeric stat with two decimals, or `—` when null.
String _formatNum(num? value) {
  if (value == null) {
    return '—';
  }
  return value.toStringAsFixed(2);
}

/// `begin → end` for finished alerts, `begin → now` while ongoing.
String _timeline(AlertInfo alert) {
  final String begin = _formatTimestamp(alert.begin);
  if (alert.isOngoing) {
    return '$begin → now';
  }
  return '$begin → ${_formatTimestamp(alert.end)}';
}

/// Formats epoch seconds as a local `yyyy-MM-dd HH:mm` string, or `—` when
/// null.
String _formatTimestamp(int? epochSeconds) {
  if (epochSeconds == null) {
    return '—';
  }
  final DateTime dt =
      DateTime.fromMillisecondsSinceEpoch(epochSeconds * 1000);
  return '${dt.year}-${_two(dt.month)}-${_two(dt.day)} '
      '${_two(dt.hour)}:${_two(dt.minute)}';
}

/// Left-pads [value] to two digits.
String _two(int value) => value.toString().padLeft(2, '0');

/// Sheet body for an alert drill-down: the full detail behind the card —
/// state chip, timestamps, stats, the complete message and every top process.
class _AlertSheetBody extends StatelessWidget {
  const _AlertSheetBody({required this.alert});

  final AlertInfo alert;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final Color stateColor =
        alert.isCritical ? AppColors.danger : AppColors.warning;
    final List<(String, String)> rows = <(String, String)>[
      ('State', alert.state ?? '—'),
      ('Type', alert.type ?? '—'),
      if (alert.sort != null) ('Sort', alert.sort!),
      if (alert.begin != null) ('Begin', _formatTimestamp(alert.begin)),
      ('End', alert.isOngoing ? 'Ongoing' : _formatTimestamp(alert.end)),
      if (alert.min != null) ('Min', _formatNum(alert.min)),
      if (alert.max != null) ('Max', _formatNum(alert.max)),
      if (alert.avg != null) ('Average', _formatNum(alert.avg)),
      if (alert.sum != null) ('Sum', _formatNum(alert.sum)),
      if (alert.count != null) ('Count', '${alert.count}'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          children: <Widget>[
            _StateChip(state: alert.state, color: stateColor),
            if (alert.isOngoing) ...[
              const SizedBox(width: AppSpacing.sm),
              const _OngoingIndicator(),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        for (int i = 0; i < rows.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.sm),
          SheetValueRow(label: rows[i].$1, value: rows[i].$2),
        ],
        if (alert.globalMsg != null) ...[
          const SizedBox(height: AppSpacing.md),
          const Divider(color: AppColors.border),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Message',
            style: textTheme.labelLarge?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            alert.globalMsg!,
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
        ],
        if (alert.desc != null) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            'Description',
            style: textTheme.labelLarge?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            alert.desc!,
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
        ],
        if (alert.top != null && alert.top!.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          const Divider(color: AppColors.border),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Top processes',
            style: textTheme.labelLarge?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          for (final String name in alert.top!)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(
                name,
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ),
        ],
      ],
    );
  }
}
