/// Per-item alert limits and server-computed decoration.
///
/// Mirrors the shape returned by `GET /api/4/all/limits` and
/// `GET /api/4/all/views`: a plugin map whose values are item maps, each
/// carrying optional `warning` / `critical` thresholds and an optional
/// `decoration` label (e.g. `OK`, `WARNING`, `CRITICAL`) computed by the
/// server.
///
/// Keys are dynamic (they depend on the plugins enabled on the host and the
/// Glances version), so parsing is manual rather than code-generated.
class MetricLimits {
  /// Creates a [MetricLimits].
  const MetricLimits({this.warning, this.critical, this.decoration});

  /// Server-configured warning threshold for the item, or null when unset.
  final double? warning;

  /// Server-configured critical threshold for the item, or null when unset.
  final double? critical;

  /// Server-computed decoration label (`OK`, `WARNING`, `CRITICAL`, ...), or
  /// null when the item has no alert configured.
  final String? decoration;

  /// Parses a single item entry from `/all/limits` or `/all/views`.
  ///
  /// Accepts any map; unknown keys are ignored. Returns a [MetricLimits]
  /// with only the fields that were present.
  factory MetricLimits.fromJson(Map<String, dynamic> json) {
    return MetricLimits(
      warning: _toDouble(json['warning']),
      critical: _toDouble(json['critical']),
      decoration: json['decoration'] is String
          ? json['decoration'] as String
          : null,
    );
  }

  /// The critical threshold, or a sane default when unset.
  ///
  /// Defaults match the client's historical hardcoded scale so callers get
  /// deterministic behavior even when the server omits the value.
  double get criticalOrFallback => critical ?? 85;

  /// The warning threshold, or a sane default when unset.
  double get warningOrFallback => warning ?? 60;

  static double? _toDouble(Object? value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }
}

/// Aggregated alert thresholds for every plugin, as reported by the server.
///
/// `plugins[pluginName][itemName]` resolves to the [MetricLimits] for that
/// metric. An empty map means the server reported no limits (or the fetch
/// failed); callers fall back to their built-in scale in that case.
class AlertThresholds {
  /// Creates an [AlertThresholds] from a raw `plugins -> items -> limits`
  /// map.
  const AlertThresholds(this.plugins);

  /// The raw per-plugin, per-item limits.
  final Map<String, Map<String, MetricLimits>> plugins;

  /// An empty [AlertThresholds] with no server-reported limits.
  static const AlertThresholds empty =
      AlertThresholds(<String, Map<String, MetricLimits>>{});

  /// Resolves the [MetricLimits] for `plugin`/`item`, or null when unset.
  MetricLimits? limitsFor(String plugin, String item) {
    return plugins[plugin]?[item];
  }

  /// Parses the `GET /api/4/all/limits` response body.
  ///
  /// The server returns `{ "cpu": { "total": { "warning": 70.0,
  /// "critical": 90.0 } }, "mem": {...} }`. Items that are not objects are
  /// skipped defensively.
  factory AlertThresholds.fromLimitsJson(Map<String, dynamic> json) {
    final Map<String, Map<String, MetricLimits>> out =
        <String, Map<String, MetricLimits>>{};
    json.forEach((String plugin, Object? items) {
      if (items is! Map<String, dynamic>) {
        return;
      }
      final Map<String, MetricLimits> itemMap = <String, MetricLimits>{};
      items.forEach((String item, Object? entry) {
        if (entry is Map<String, dynamic>) {
          itemMap[item] = MetricLimits.fromJson(entry);
        }
      });
      if (itemMap.isNotEmpty) {
        out[plugin] = itemMap;
      }
    });
    return AlertThresholds(out);
  }

  /// Parses the `GET /api/4/all/views` response body.
  ///
  /// Same shape as limits but each entry carries the server-computed
  /// `decoration` label. Entries are merged into the plugin/item maps so a
  /// caller can read either the thresholds or the decoration from one place.
  factory AlertThresholds.fromViewsJson(Map<String, dynamic> json) {
    final Map<String, Map<String, MetricLimits>> out =
        <String, Map<String, MetricLimits>>{};
    json.forEach((String plugin, Object? items) {
      if (items is! Map<String, dynamic>) {
        return;
      }
      final Map<String, MetricLimits> itemMap = <String, MetricLimits>{};
      items.forEach((String item, Object? entry) {
        if (entry is Map<String, dynamic>) {
          itemMap[item] = MetricLimits.fromJson(entry);
        }
      });
      if (itemMap.isNotEmpty) {
        out[plugin] = itemMap;
      }
    });
    return AlertThresholds(out);
  }
}
