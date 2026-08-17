import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/alert_thresholds.dart';
import '../../data/providers.dart';
import '../theme/colors.dart';

/// Ready-to-use [AlertColorResolver] backed by [alertThresholdsProvider].
///
/// Falls back to the client's built-in scale whenever the server limits are
/// still loading or absent, so consumers never block on the fetch.
final alertColorResolverProvider = Provider<AlertColorResolver>((ref) {
  final AsyncValue<AlertThresholds> thresholds =
      ref.watch(alertThresholdsProvider);
  return AlertColorResolver(
    thresholds.value ?? AlertThresholds.empty,
  );
});

/// Maps a usage percentage onto a status color using server-provided limits.
///
/// The resolver reads the per-plugin/per-item thresholds fetched from
/// `GET /api/4/all/limits` (via [AlertThresholds]) and returns:
///   - [AppColors.danger] when the value is at or above the critical limit,
///   - [AppColors.warning] when it is at or above the warning limit,
///   - [AppColors.accent] otherwise.
///
/// When the server provides no limits for a metric, [colorFor] falls back to
/// the client's historical scale (critical at 85, warning at 60) so existing
/// behavior is preserved on servers that do not expose limits.
class AlertColorResolver {
  /// Creates a resolver from server-reported [thresholds].
  ///
  /// Pass [AlertThresholds.empty] when the server reported none.
  const AlertColorResolver(this.thresholds);

  /// Server-reported per-plugin/per-item limits.
  final AlertThresholds thresholds;

  /// A resolver with no server limits, using the built-in fallback scale.
  static const AlertColorResolver fallback =
      AlertColorResolver(AlertThresholds.empty);

  /// Resolves the status color for `percent` of `plugin`/`item`.
  ///
  /// [item] may be omitted for metrics where the server keys limits under the
  /// plugin name itself (rare); the resolver then falls back to the whole
  /// plugin's first entry if exactly one exists.
  Color colorFor(String plugin, double percent, {String? item}) {
    final MetricLimits? limits = item != null
        ? thresholds.limitsFor(plugin, item)
        : _singleItemLimits(plugin);
    if (limits != null) {
      final double? critical = limits.critical;
      final double? warning = limits.warning;
      if (critical != null && percent >= critical) {
        return AppColors.danger;
      }
      if (warning != null && percent >= warning) {
        return AppColors.warning;
      }
      // A server limit exists but the value is below it — still healthy.
      if (critical != null || warning != null) {
        return AppColors.accent;
      }
    }
    return _fallbackColor(percent);
  }

  /// The built-in scale used when the server reports no limits for a metric.
  Color _fallbackColor(double percent) {
    if (percent >= 85) {
      return AppColors.danger;
    }
    if (percent >= 60) {
      return AppColors.warning;
    }
    return AppColors.accent;
  }

  /// Returns the sole item limits for [plugin] when the plugin maps to exactly
  /// one item, or null otherwise.
  MetricLimits? _singleItemLimits(String plugin) {
    final Map<String, MetricLimits>? items = thresholds.plugins[plugin];
    if (items == null || items.length != 1) {
      return null;
    }
    return items.values.first;
  }
}