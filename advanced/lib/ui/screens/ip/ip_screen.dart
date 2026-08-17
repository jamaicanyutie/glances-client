import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/ip_info.dart';
import '../../../data/providers.dart';
import '../../components/error_view.dart';
import '../../components/loading_view.dart';
import '../../components/metric_sheets.dart';
import '../../components/responsive_card_grid.dart';
import '../../components/settings_button.dart';
import '../../theme/colors.dart';
import '../../theme/theme.dart';

/// Live network-addressing screen.
///
/// Watches [ipProvider] (auto-refreshed on the refresh interval) and renders
/// one card per network address family. Pull-to-refresh forces a re-fetch.
/// On hosts behind NAT without a public-IP API configured, the public fields
/// arrive as empty strings and render as `—`.
class IpScreen extends ConsumerWidget {
  const IpScreen({super.key, this.showAppBar = true});

  /// When false the screen renders without its own AppBar, for embedding as a
  /// sub-tab inside the Network hub (which owns the AppBar + TabBar).
  final bool showAppBar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<IpInfo> ip = ref.watch(ipProvider);
    return Scaffold(
      appBar: showAppBar
          ? AppBar(
              title: const Text('IP Address'),
              actions: const <Widget>[SettingsButton()],
            )
          : null,
      body: ip.when(
        skipLoadingOnReload: true,
        skipLoadingOnRefresh: true,
        loading: () => const LoadingView(),
        error: (Object error, StackTrace stackTrace) => ErrorView(
          message: '$error',
          onRetry: () => ref.invalidate(ipProvider),
        ),
        data: (IpInfo data) {
          return RefreshIndicator(
            onRefresh: () => ref.read(ipProvider.notifier).refresh(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.md),
              children: <Widget>[
                ResponsiveCardGrid(
                  children: <Widget>[
                    _IpCard(
                      title: 'Private',
                      icon: Icons.home_outlined,
                      info: data,
                      onTap: () => showMetricSheet(
                        context: context,
                        title: 'Private Network',
                        body: _IpSheetBody(info: data),
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

/// Shared shell for the IP cards: a themed [Card] with a title row.
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

/// One network-address card: private address, mask and gateway.
class _IpCard extends StatelessWidget {
  const _IpCard({
    required this.title,
    required this.icon,
    required this.info,
    this.onTap,
  });

  final String title;
  final IconData icon;
  final IpInfo info;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return _CardShell(
      title: title,
      icon: icon,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            _privateLabel(info),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.headlineSmall?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
            ),
          ),
          if (_maskLabel(info) != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              _maskLabel(info)!,
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
          if (info.gateway != null && info.gateway!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            _CaptionRow(label: 'Gateway', value: info.gateway!),
          ],
          const SizedBox(height: AppSpacing.md),
          const Divider(color: AppColors.border),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Public',
            style: textTheme.labelLarge?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            _publicLabel(info),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.titleMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
            ),
          ),
          if (_publicInfoLabel(info) != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              _publicInfoLabel(info)!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _privateLabel(IpInfo info) {
    final String? address = info.address;
    if (address != null && address.isNotEmpty) {
      return address;
    }
    return '—';
  }

  String? _maskLabel(IpInfo info) {
    final String? mask = info.mask;
    final int? cidr = info.maskCidr;
    if (mask != null && cidr != null) {
      return 'Mask $mask (/$cidr)';
    }
    if (mask != null) {
      return 'Mask $mask';
    }
    return null;
  }

  String _publicLabel(IpInfo info) {
    final String? address = info.publicAddress;
    if (address != null && address.isNotEmpty) {
      return address;
    }
    return 'Not available';
  }

  String? _publicInfoLabel(IpInfo info) {
    final String? infoH = info.publicInfoHuman;
    if (infoH == null || infoH.isEmpty) {
      return null;
    }
    return infoH;
  }
}

/// Small label/value caption row used inside the card.
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
            style: textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
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

/// Sheet body for the IP drill-down: every field the API exposes, shown as
/// value rows. Rows appear only when the corresponding field is non-null.
class _IpSheetBody extends StatelessWidget {
  const _IpSheetBody({required this.info});

  final IpInfo info;

  @override
  Widget build(BuildContext context) {
    final List<(String, String)> rows = <(String, String)>[
      if (info.address != null && info.address!.isNotEmpty)
        ('Address', info.address!),
      if (info.mask != null && info.mask!.isNotEmpty) ('Mask', info.mask!),
      if (info.maskCidr != null) ('Mask CIDR', '${info.maskCidr}'),
      if (info.gateway != null && info.gateway!.isNotEmpty)
        ('Gateway', info.gateway!),
      if (info.publicAddress != null && info.publicAddress!.isNotEmpty)
        ('Public address', info.publicAddress!),
      if (info.publicInfoHuman != null && info.publicInfoHuman!.isNotEmpty)
        ('Public info', info.publicInfoHuman!),
    ];
    if (rows.isEmpty) {
      return const _Empty('No address information available.');
    }
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

/// Centered empty/message state for a sheet body with nothing to show.
class _Empty extends StatelessWidget {
  const _Empty(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
      ),
    );
  }
}