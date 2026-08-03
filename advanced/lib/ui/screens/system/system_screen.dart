import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/system_info.dart';
import '../../../data/providers.dart';
import '../../components/error_view.dart';
import '../../components/loading_view.dart';
import '../../components/metric_sheets.dart';
import '../../components/responsive_card_grid.dart';
import '../../components/settings_button.dart';
import '../../theme/colors.dart';
import '../../theme/theme.dart';

/// Host, operating-system and uptime overview.
///
/// Watches [systemProvider] for the host metadata and [uptimeProvider] for the
/// uptime string (both auto-refreshed on the refresh interval). An uptime
/// error only degrades its own card — it never takes down the screen.
/// Pull-to-refresh forces both providers.
class SystemScreen extends ConsumerWidget {
  const SystemScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<SystemInfo> system = ref.watch(systemProvider);
    final AsyncValue<String> uptime = ref.watch(uptimeProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('System'),
        actions: const <Widget>[SettingsButton()],
      ),
      body: system.when(
        skipLoadingOnReload: true,
        skipLoadingOnRefresh: true,
        loading: () => const LoadingView(),
        error: (Object error, StackTrace stackTrace) => ErrorView(
          message: '$error',
          onRetry: () {
            ref.invalidate(systemProvider);
            ref.invalidate(uptimeProvider);
          },
        ),
        data: (SystemInfo info) {
          // Wait for the uptime's initial load before painting so the first
          // frame is never half-empty.
          if (uptime.isLoading) {
            return const LoadingView();
          }
          return RefreshIndicator(
            onRefresh: () async {
              await ref.read(systemProvider.notifier).refresh();
              await ref.read(uptimeProvider.notifier).refresh();
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.md),
              children: <Widget>[
                ResponsiveCardGrid(
                  children: <Widget>[
                    ResponsiveCardGrid.span(
                      _HostCard(
                        system: info,
                        onTap: () => showMetricSheet(
                          context: context,
                          title: 'Host Details',
                          body: _HostSheetBody(system: info),
                        ),
                      ),
                    ),
                    ResponsiveCardGrid.span(
                      _OsCard(
                        system: info,
                        onTap: () => showMetricSheet(
                          context: context,
                          title: 'OS Details',
                          body: _OsSheetBody(system: info),
                        ),
                      ),
                    ),
                    ResponsiveCardGrid.span(
                      _UptimeCard(
                        uptime: uptime,
                        onTap: () => showMetricSheet(
                          context: context,
                          title: 'Uptime',
                          body: _UptimeSheetBody(uptime: uptime),
                        ),
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

/// Shared shell for the system cards: a themed [Card] with a title row.
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

/// Full-width hero card: hostname as the headline with the human-readable
/// OS string below.
class _HostCard extends StatelessWidget {
  const _HostCard({required this.system, this.onTap});

  final SystemInfo system;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return _CardShell(
      title: 'Host',
      icon: Icons.dns,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            system.hostname ?? '—',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.headlineMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            system.hrName ?? '—',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Full-width card with one labeled row per operating-system field.
class _OsCard extends StatelessWidget {
  const _OsCard({required this.system, this.onTap});

  final SystemInfo system;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final List<(String, String?)> rows = <(String, String?)>[
      ('Name', system.osName),
      ('Version', system.osVersion),
      ('Distribution', system.linuxDistro),
      ('Platform', system.platform),
    ];

    final List<Widget> children = <Widget>[];
    for (final (String label, String? value) in rows) {
      if (children.isNotEmpty) {
        children.add(const SizedBox(height: AppSpacing.sm));
      }
      children.add(_InfoRow(label: label, value: value));
    }

    return _CardShell(
      title: 'Operating System',
      icon: Icons.computer,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }
}

/// A single labeled row: muted label on the left, value on the right.
class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            value ?? '—',
            textAlign: TextAlign.right,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

/// Full-width card showing the uptime string. Its own loading/error handling
/// keeps an uptime failure from affecting the rest of the screen.
class _UptimeCard extends StatelessWidget {
  const _UptimeCard({required this.uptime, this.onTap});

  final AsyncValue<String> uptime;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return _CardShell(
      title: 'Uptime',
      icon: Icons.timer,
      onTap: onTap,
      child: uptime.when(
        skipLoadingOnReload: true,
        skipLoadingOnRefresh: true,
        loading: () => const SizedBox(
          height: 32,
          child: Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
        error: (Object error, StackTrace stackTrace) => Text(
          'Uptime unavailable',
          style: textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        data: (String value) => Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: textTheme.headlineSmall?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontFeatures: const <FontFeature>[
              FontFeature.tabularFigures(),
            ],
          ),
        ),
      ),
    );
  }
}

/// Sheet body for the host drill-down: every [SystemInfo] field as a value row.
class _HostSheetBody extends StatelessWidget {
  const _HostSheetBody({required this.system});

  final SystemInfo system;

  @override
  Widget build(BuildContext context) {
    final List<(String, String)> rows = <(String, String)>[
      ('Hostname', system.hostname ?? '—'),
      ('HR Name', system.hrName ?? '—'),
      ('OS Name', system.osName ?? '—'),
      ('OS Version', system.osVersion ?? '—'),
      ('Distribution', system.linuxDistro ?? '—'),
      ('Platform', system.platform ?? '—'),
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

/// Sheet body for the operating-system drill-down: the full field set as value
/// rows.
class _OsSheetBody extends StatelessWidget {
  const _OsSheetBody({required this.system});

  final SystemInfo system;

  @override
  Widget build(BuildContext context) {
    final List<(String, String)> rows = <(String, String)>[
      ('Name', system.osName ?? '—'),
      ('Version', system.osVersion ?? '—'),
      ('Distribution', system.linuxDistro ?? '—'),
      ('Platform', system.platform ?? '—'),
      ('HR Name', system.hrName ?? '—'),
      ('Hostname', system.hostname ?? '—'),
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

/// Sheet body for the uptime drill-down: the value shown prominently plus a
/// note that the API returns the uptime as a pre-formatted string.
class _UptimeSheetBody extends StatelessWidget {
  const _UptimeSheetBody({required this.uptime});

  final AsyncValue<String> uptime;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        uptime.when(
          skipLoadingOnReload: true,
          skipLoadingOnRefresh: true,
          loading: () => const SizedBox(
            height: 32,
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
          error: (Object error, StackTrace stackTrace) => Text(
            'Uptime unavailable',
            style: textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          data: (String value) => Text(
            value,
            style: textTheme.headlineSmall?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              fontFeatures: const <FontFeature>[
                FontFeature.tabularFigures(),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'The API returns the uptime as a pre-formatted string.',
          style: textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
