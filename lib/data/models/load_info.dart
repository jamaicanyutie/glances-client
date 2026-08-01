import 'package:json_annotation/json_annotation.dart';

part 'load_info.g.dart';

/// System load averages reported by the Glances `load` plugin.
///
/// The load average represents the average number of runnable processes
/// over the given interval. All fields are nullable because the plugin is
/// not available on every platform (notably Windows).
@JsonSerializable()
class LoadInfo {
  /// Load average over the last 1 minute.
  final double? min1;

  /// Load average over the last 5 minutes.
  final double? min5;

  /// Load average over the last 15 minutes.
  final double? min15;

  /// Number of logical CPU cores, used to normalize the load averages.
  final int? cpucore;

  /// Creates a [LoadInfo] with all fields optional.
  const LoadInfo({this.min1, this.min5, this.min15, this.cpucore});

  factory LoadInfo.fromJson(Map<String, dynamic> json) =>
      _$LoadInfoFromJson(json);

  Map<String, dynamic> toJson() => _$LoadInfoToJson(this);
}
