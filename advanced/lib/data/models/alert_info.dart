import 'package:json_annotation/json_annotation.dart';

part 'alert_info.g.dart';

/// One alert/event from the Glances `alert` plugin (`GET /api/4/alert`).
/// An alert aggregates a metric (type LOAD/CPU_IOWAIT/...) over a time
/// window and reports the min/max/avg plus the offending processes.
@JsonSerializable()
class AlertInfo {
  /// Start of the window (epoch seconds).
  final int? begin;

  /// End of the window (epoch seconds), or -1 while the alert is ongoing.
  final int? end;

  /// `WARNING` or `CRITICAL`.
  final String? state;

  /// Metric type, e.g. `LOAD`, `CPU_IOWAIT`, `CPU`.
  final String? type;

  /// Minimum value observed in the window.
  final num? min;

  /// Maximum value observed in the window.
  final num? max;

  /// Sum of the samples in the window.
  final num? sum;

  /// Average of the samples in the window.
  final num? avg;

  /// Number of samples in the window.
  final int? count;

  /// Top 3 offending process names.
  final List<String>? top;

  final String? desc;
  final String? sort;

  /// Human-readable message. NOTE: the JSON key is `global_msg` (the source
  /// comments say `global` but the dataclass serializes `global_msg`).
  @JsonKey(name: 'global_msg')
  final String? globalMsg;

  /// Creates an [AlertInfo] with all fields optional.
  const AlertInfo({
    this.begin,
    this.end,
    this.state,
    this.type,
    this.min,
    this.max,
    this.sum,
    this.avg,
    this.count,
    this.top,
    this.desc,
    this.sort,
    this.globalMsg,
  });

  /// Whether the alert is in the `CRITICAL` state.
  bool get isCritical => state == 'CRITICAL';

  /// Whether the alert is still ongoing (no end or an end of -1).
  bool get isOngoing => end == null || end == -1;

  factory AlertInfo.fromJson(Map<String, dynamic> json) =>
      _$AlertInfoFromJson(json);

  Map<String, dynamic> toJson() => _$AlertInfoToJson(this);
}
