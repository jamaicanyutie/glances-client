import 'package:json_annotation/json_annotation.dart';

part 'disk_io_info.g.dart';

/// Disk I/O counters reported by the Glances `diskio` plugin.
///
/// All counters are nullable because the set of fields reported by the
/// server is platform-dependent (Linux vs Windows vs macOS) and can vary
/// between Glances versions. Byte counters are expressed in bytes, time
/// counters in milliseconds.
@JsonSerializable()
class DiskIoInfo {
  /// Name of the disk device (e.g. `sda`).
  @JsonKey(name: 'disk_name')
  final String? diskName;

  /// Cumulative bytes read from the device.
  @JsonKey(name: 'read_bytes')
  final double? readBytes;

  /// Cumulative bytes written to the device.
  @JsonKey(name: 'write_bytes')
  final double? writeBytes;

  /// Cumulative time spent reading, in milliseconds.
  @JsonKey(name: 'read_time')
  final double? readTime;

  /// Cumulative time spent writing, in milliseconds.
  @JsonKey(name: 'write_time')
  final double? writeTime;

  /// Seconds elapsed since the counters were last updated.
  @JsonKey(name: 'time_since_update')
  final double? timeSinceUpdate;

  /// Creates a [DiskIoInfo] with all fields optional.
  const DiskIoInfo({
    this.diskName,
    this.readBytes,
    this.writeBytes,
    this.readTime,
    this.writeTime,
    this.timeSinceUpdate,
  });

  factory DiskIoInfo.fromJson(Map<String, dynamic> json) =>
      _$DiskIoInfoFromJson(json);

  Map<String, dynamic> toJson() => _$DiskIoInfoToJson(this);
}
