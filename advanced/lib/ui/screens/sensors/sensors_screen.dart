import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/sensor_info.dart';
import '../../../data/providers.dart';
import '../../components/error_view.dart';
import '../../components/loading_view.dart';
import '../../components/metric_sheets.dart';
import '../../components/responsive_card_grid.dart';
import '../../components/settings_button.dart';
import '../../theme/colors.dart';
import '../../theme/theme.dart';

/// Live hardware sensor screen: temperatures, fan speeds and the battery.
///
/// Watches [sensorsProvider] (auto-refreshed on the refresh interval) and
/// renders one card per sensor, with values colored by their warning/critical
/// thresholds. Pull-to-refresh forces a re-fetch. Servers without hardware
/// sensors report an empty list, which renders as a friendly empty state.
class SensorsScreen extends ConsumerWidget {
  const SensorsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<SensorInfo>> sensors = ref.watch(sensorsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sensors'),
        actions: const <Widget>[SettingsButton()],
      ),
      body: sensors.when(
        skipLoadingOnReload: true,
        skipLoadingOnRefresh: true,
        loading: () => const LoadingView(),
        error: (Object error, StackTrace stackTrace) => ErrorView(
          message: '$error',
          onRetry: () => ref.invalidate(sensorsProvider),
        ),
        data: (List<SensorInfo> data) {
          return RefreshIndicator(
            onRefresh: () => ref.read(sensorsProvider.notifier).refresh(),
            child: data.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: <Widget>[
                      SizedBox(
                        height: MediaQuery.sizeOf(context).height * 0.65,
                        child: const _EmptyView(
                          icon: Icons.thermostat,
                          title: 'No sensors available',
                          message: 'This host does not expose temperature, '
                              'fan, or battery sensors.',
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
                          for (final SensorInfo sensor in data)
                            _SensorCard(
                              sensor: sensor,
                              onTap: () => showMetricSheet(
                                context: context,
                                title: sensor.label ?? _typeLabel(sensor.type),
                                body: _SensorSheetBody(sensor: sensor),
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

/// Centered empty state shown when the server reports no sensors at all.
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

/// Shared shell for the sensor cards: a themed [Card] with a title row.
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

/// One sensor reading: label and (for batteries) status on the left, value on
/// the right, colored by the warning/critical level.
class _SensorCard extends StatelessWidget {
  const _SensorCard({required this.sensor, this.onTap});

  final SensorInfo sensor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final Color valueColor = _statusColor(sensor.level);
    final String? batteryStatus = sensor.status;
    return _CardShell(
      title: _typeLabel(sensor.type),
      icon: _typeIcon(sensor.type),
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  sensor.label ?? '—',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (batteryStatus != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    batteryStatus,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            _formatValue(sensor),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.titleMedium?.copyWith(
              color: valueColor,
              fontWeight: FontWeight.w600,
              fontFeatures: const <FontFeature>[
                FontFeature.tabularFigures(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Icon for a sensor type.
IconData _typeIcon(String? type) {
  if (type == null) {
    return Icons.devices_other;
  }
  if (type.startsWith('battery')) {
    return Icons.battery_std;
  }
  if (type.startsWith('fan')) {
    return Icons.toys;
  }
  if (type.startsWith('temperature')) {
    return Icons.thermostat;
  }
  return Icons.devices_other;
}

/// Humanized sensor type, used as the card title.
String _typeLabel(String? type) {
  if (type == null) {
    return 'Sensor';
  }
  if (type.startsWith('battery')) {
    return 'Battery';
  }
  if (type.startsWith('fan')) {
    return 'Fan Speed';
  }
  if (type.startsWith('temperature')) {
    return 'Temperature';
  }
  return type;
}

/// Formats the reading: numeric values keep one decimal and the unit is
/// appended; string readings (ERR/SLP/UNK/NOS) are shown raw.
String _formatValue(SensorInfo sensor) {
  final double? value = sensor.valueAsDouble;
  final String? unit = sensor.unit;
  if (value != null) {
    final String number = value.toStringAsFixed(1);
    return unit == null ? number : '$number $unit';
  }
  final Object? raw = sensor.value;
  if (raw != null) {
    return unit == null ? '$raw' : '$raw $unit';
  }
  return '—';
}

/// Maps a sensor level (0 = ok, 1 = warning, 2 = critical) onto a color.
Color _statusColor(int level) {
  switch (level) {
    case 2:
      return AppColors.danger;
    case 1:
      return AppColors.warning;
    default:
      return AppColors.textPrimary;
  }
}

/// Sheet body for a sensor drill-down: every field the API exposes, shown as
/// value rows. Rows appear only when the corresponding field is non-null.
class _SensorSheetBody extends StatelessWidget {
  const _SensorSheetBody({required this.sensor});

  final SensorInfo sensor;

  @override
  Widget build(BuildContext context) {
    final String levelLabel = switch (sensor.level) {
      2 => 'Critical',
      1 => 'Warning',
      _ => 'OK',
    };
    final List<(String, String)> rows = <(String, String)>[
      if (sensor.type != null) ('Type', sensor.type!),
      if (sensor.label != null) ('Label', sensor.label!),
      if (sensor.key != null) ('Key', sensor.key!),
      if (sensor.unit != null) ('Unit', sensor.unit!),
      if (sensor.value != null) ('Value', _formatValue(sensor)),
      if (sensor.warning != null) ('Warning threshold', '${sensor.warning}'),
      if (sensor.critical != null)
        ('Critical threshold', '${sensor.critical}'),
      if (sensor.status != null) ('Status', sensor.status!),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (int i = 0; i < rows.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.sm),
          SheetValueRow(label: rows[i].$1, value: rows[i].$2),
        ],
        const SizedBox(height: AppSpacing.sm),
        SheetValueRow(
          label: 'Level',
          value: levelLabel,
          valueColor: _statusColor(sensor.level),
        ),
      ],
    );
  }
}
