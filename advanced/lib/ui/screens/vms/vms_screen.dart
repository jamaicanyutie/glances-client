import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/vm_info.dart';
import '../../../data/providers.dart';
import '../../components/error_view.dart';
import '../../components/loading_view.dart';
import '../../components/metric_sheets.dart';
import '../../components/responsive_card_grid.dart';
import '../../components/settings_button.dart';
import '../../theme/colors.dart';
import '../../theme/theme.dart';
import '../../utils/formatters.dart';

/// Virtual machines screen.
///
/// Watches [vmsProvider] (auto-refreshed on the refresh interval) and renders
/// one card per VM, with its status, CPU time and memory usage. Pull-to-refresh
/// forces a re-fetch. Glances discovers VMs through a virtualization engine;
/// hosts without one report an empty list, which renders as a friendly empty
/// state.
class VmsScreen extends ConsumerWidget {
  const VmsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<VmInfo>> vms = ref.watch(vmsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Virtual Machines'),
        actions: const <Widget>[SettingsButton()],
      ),
      body: vms.when(
        skipLoadingOnReload: true,
        skipLoadingOnRefresh: true,
        loading: () => const LoadingView(),
        error: (Object error, StackTrace stackTrace) => ErrorView(
          message: '$error',
          onRetry: () => ref.invalidate(vmsProvider),
        ),
        data: (List<VmInfo> data) {
          return RefreshIndicator(
            onRefresh: () => ref.read(vmsProvider.notifier).refresh(),
            child: data.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: <Widget>[
                      SizedBox(
                        height: MediaQuery.sizeOf(context).height * 0.65,
                        child: const _EmptyView(
                          icon: Icons.dns_outlined,
                          title: 'No virtual machines',
                          message: 'This host does not expose any '
                              'virtual machines.',
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
                          for (final VmInfo vm in data)
                            _VmCard(
                              vm: vm,
                              onTap: () => showMetricSheet(
                                context: context,
                                title: vm.name ?? 'VM',
                                body: _VmSheetBody(vm: vm),
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

/// Centered empty state shown when the server reports no virtual machines.
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

/// Shared shell for the VM cards.
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

/// Maps a VM status string onto a color: running = success, paused = warning,
/// anything else (stopped, error…) = danger. Unknown status falls back to the
/// primary text color.
Color _statusColor(String? status) {
  final String s = status?.toLowerCase() ?? '';
  if (s.contains('running')) {
    return AppColors.success;
  }
  if (s.contains('paused') || s.contains('suspended')) {
    return AppColors.warning;
  }
  return AppColors.danger;
}

/// One VM card: name, status, CPU time, and memory usage.
class _VmCard extends StatelessWidget {
  const _VmCard({required this.vm, this.onTap});

  final VmInfo vm;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final Color statusColor = _statusColor(vm.status);
    final double? memoryPercent = _memoryPercent(vm);
    return _CardShell(
      title: vm.name ?? '—',
      icon: Icons.dns_outlined,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (vm.status != null) ...[
            Row(
              children: <Widget>[
                Icon(Icons.circle, size: 8, color: statusColor),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    vm.status!,
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
            const SizedBox(height: AppSpacing.sm),
          ],
          if (vm.cpuTime != null) ...[
            _CaptionRow(label: 'CPU', value: formatPercent(vm.cpuTime?.toDouble())),
            const SizedBox(height: AppSpacing.xs),
          ],
          if (vm.cpuCount != null) ...[
            _CaptionRow(label: 'vCPUs', value: '${vm.cpuCount}'),
            const SizedBox(height: AppSpacing.xs),
          ],
          if (vm.memoryUsage != null || vm.memoryTotal != null) ...[
            _CaptionRow(
              label: 'Memory',
              value:
                  '${formatBytes(vm.memoryUsage?.toDouble())} / '
                  '${formatBytes(vm.memoryTotal?.toDouble())}',
            ),
            if (memoryPercent != null) ...[
              const SizedBox(height: AppSpacing.xs),
              LinearProgressIndicator(
                value: (memoryPercent / 100).clamp(0.0, 1.0),
                color: AppColors.accent,
                backgroundColor: AppColors.surfaceAlt,
                minHeight: 4,
                borderRadius: BorderRadius.circular(2),
              ),
            ],
          ],
          if (vm.ipv4 != null && vm.ipv4!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            _CaptionRow(label: 'IPv4', value: vm.ipv4!),
          ],
        ],
      ),
    );
  }

  double? _memoryPercent(VmInfo vm) {
    final num? used = vm.memoryUsage;
    final num? total = vm.memoryTotal;
    if (used == null || total == null || total <= 0) {
      return null;
    }
    return (used / total) * 100;
  }
}

/// Small label/value caption row used inside a card.
class _CaptionRow extends StatelessWidget {
  const _CaptionRow({required this.label, required this.value});

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
            style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Flexible(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: textTheme.bodySmall?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    );
  }
}

/// Sheet body for a VM drill-down: every field the API exposes.
class _VmSheetBody extends StatelessWidget {
  const _VmSheetBody({required this.vm});

  final VmInfo vm;

  @override
  Widget build(BuildContext context) {
    final List<(String, String)> rows = <(String, String)>[
      if (vm.name != null) ('Name', vm.name!),
      if (vm.id != null) ('ID', vm.id!),
      if (vm.release != null) ('Release', vm.release!),
      if (vm.status != null) ('Status', vm.status!),
      if (vm.cpuCount != null) ('vCPUs', '${vm.cpuCount}'),
      if (vm.cpuTime != null) ('CPU time', formatPercent(vm.cpuTime?.toDouble())),
      if (vm.memoryUsage != null) ('Memory used', formatBytes(vm.memoryUsage?.toDouble())),
      if (vm.memoryTotal != null) ('Memory total', formatBytes(vm.memoryTotal?.toDouble())),
      if (vm.load1min != null) ('Load 1m', '${vm.load1min}'),
      if (vm.load5min != null) ('Load 5m', '${vm.load5min}'),
      if (vm.load15min != null) ('Load 15m', '${vm.load15min}'),
      if (vm.ipv4 != null && vm.ipv4!.isNotEmpty) ('IPv4', vm.ipv4!),
      if (vm.engine != null) ('Engine', vm.engine!),
      if (vm.engineVersion != null) ('Engine version', vm.engineVersion!),
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