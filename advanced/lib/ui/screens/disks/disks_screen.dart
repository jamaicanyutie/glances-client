import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/models/disk_io_info.dart';
import '../../../data/models/fs_info.dart';
import '../../../data/models/glances_all.dart';
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

/// Live Disks screen: filesystem usage plus per-device disk I/O rates.
///
/// Watches [allStatsProvider] (auto-refreshed every 2 seconds) and renders a
/// "Filesystems" section with one card per mount and a "Disk I/O" summary card
/// with per-device read/write rates. Pull-to-refresh re-fetches the snapshot.
class DisksScreen extends ConsumerWidget {
  const DisksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<GlancesAll> allStats = ref.watch(allStatsProvider);
    return Scaffold(
        appBar: AppBar(
          title: const Text('Disks'),
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
          final List<FsInfo> mounts = _sortedMounts(data.fs);
          return RefreshIndicator(
            onRefresh: () => ref.read(allStatsProvider.notifier).refresh(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.md),
              children: <Widget>[
                ResponsiveCardGrid(
                  children: <Widget>[
                    ResponsiveCardGrid.span(
                      const _SectionHeader(
                        title: 'Filesystems',
                        icon: Icons.storage,
                      ),
                    ),
                    if (mounts.isEmpty)
                      ResponsiveCardGrid.span(
                        const _MessageCard(message: 'No filesystems reported'),
                      )
                    else
                      for (final FsInfo mount in mounts)
                        _MountCard(mount: mount),
                    NavCard(
                      title: 'Virtual Machines',
                      icon: Icons.dns_outlined,
                      onTap: () => context.push('/vms'),
                      caption: 'Libvirt/KVM virtual machines →',
                    ),
                    ResponsiveCardGrid.span(
                      const _SectionHeader(title: 'Disk I/O', icon: Icons.speed),
                    ),
                    ResponsiveCardGrid.span(
                      _DiskIoCard(diskio: data.diskio),
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

  /// Filesystem mounts sorted by usage, most-used first (null usage last).
  static List<FsInfo> _sortedMounts(List<FsInfo>? fs) {
    if (fs == null) {
      return const <FsInfo>[];
    }
    final List<FsInfo> sorted = List<FsInfo>.of(fs)
      ..sort((FsInfo a, FsInfo b) {
        final double? pa = a.percent;
        final double? pb = b.percent;
        if (pa == null && pb == null) {
          return 0;
        }
        if (pa == null) {
          return 1;
        }
        if (pb == null) {
          return -1;
        }
        return pb.compareTo(pa);
      });
    return sorted;
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

/// One filesystem mount: mount point, usage percentage, device/type, the
/// size breakdown and a usage bar. Tapping opens the mount detail sheet with
/// the full field set and usage history.
class _MountCard extends StatelessWidget {
  const _MountCard({required this.mount});

  final FsInfo mount;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final double percent = mount.percent ?? 0;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => showMetricSheet(
          context: context,
          title: mount.mntPoint ?? 'Filesystem',
          body: FsMountSheetBody(mount: mount),
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
                      mount.mntPoint ?? '—',
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
                    formatPercent(mount.percent),
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                _deviceLabel(mount),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '${formatBytes(mount.used)} used of ${formatBytes(mount.size)}'
                ' · ${formatBytes(mount.avail)} free',
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
      ),
    );
  }

  /// `deviceName · fsType`, falling back to `—` when both are missing.
  static String _deviceLabel(FsInfo mount) {
    final String? device = mount.deviceName;
    final String? type = mount.fsType;
    if (device == null && type == null) {
      return '—';
    }
    return '${device ?? '—'} · ${type ?? '—'}';
  }
}

/// Summary card listing every disk device with its read and write rates.
class _DiskIoCard extends StatelessWidget {
  const _DiskIoCard({required this.diskio});

  final List<DiskIoInfo>? diskio;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final List<DiskIoInfo> devices = diskio ?? const <DiskIoInfo>[];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: devices.isEmpty
            ? Text(
                'No disk I/O data',
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  for (final DiskIoInfo device in devices) ...[
                    _IoRow(device: device),
                    if (device != devices.last)
                      const SizedBox(height: AppSpacing.sm),
                  ],
                ],
              ),
      ),
    );
  }
}

/// A single disk row: device name plus read and write rate cells. Tapping the
/// row opens the device detail sheet with counters and rate history.
class _IoRow extends StatelessWidget {
  const _IoRow({required this.device});

  final DiskIoInfo device;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return InkWell(
      onTap: () => showMetricSheet(
        context: context,
        title: device.diskName ?? 'Disk I/O',
        body: DiskIoSheetBody(device: device),
      ),
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Text(
                device.diskName ?? '—',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            _IoRateCell(
              icon: Icons.arrow_downward,
              color: AppColors.accent,
              label: _ioRate(device.readBytes, device.timeSinceUpdate),
            ),
            const SizedBox(width: AppSpacing.sm),
            _IoRateCell(
              icon: Icons.arrow_upward,
              color: AppColors.warning,
              label: _ioRate(device.writeBytes, device.timeSinceUpdate),
            ),
          ],
        ),
      ),
    );
  }
}

/// A right-aligned read/write rate cell: small arrow icon plus the value.
class _IoRateCell extends StatelessWidget {
  const _IoRateCell({
    required this.icon,
    required this.color,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return SizedBox(
      width: 96,
      child: Align(
        alignment: Alignment.centerRight,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: AppSpacing.xs),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontFeatures: const <FontFeature>[
                    FontFeature.tabularFigures(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Formats a read/write rate from the cumulative byte counter.
///
/// Glances reports cumulative bytes plus the seconds since the counters were
/// last updated; the rate is `bytes / timeSinceUpdate`. When no usable update
/// window is available, falls back to the cumulative byte count, or `—/s`
/// when the counter itself is missing.
String _ioRate(double? bytes, double? timeSinceUpdate) {
  final double? window = timeSinceUpdate;
  if (bytes != null && window != null && window > 0) {
    return '${formatBytes(bytes / window)}/s';
  }
  if (bytes != null) {
    return formatBytes(bytes);
  }
  return '—/s';
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
