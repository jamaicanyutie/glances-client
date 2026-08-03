import 'package:json_annotation/json_annotation.dart';

part 'fs_info.g.dart';

/// Filesystem usage statistics reported by the Glances `fs` plugin.
///
/// All byte values are nullable because the set of fields reported by the
/// server is platform-dependent (Linux vs Windows vs macOS) and can vary
/// between Glances versions. Byte values are expressed in bytes.
@JsonSerializable()
class FsInfo {
  /// Device backing the filesystem (e.g. `/dev/sda1`).
  @JsonKey(name: 'device_name')
  final String? deviceName;

  /// Filesystem type (e.g. `ext4`, `ntfs`, `apfs`).
  @JsonKey(name: 'fs_type')
  final String? fsType;

  /// Mount point of the filesystem (e.g. `/`).
  @JsonKey(name: 'mnt_point')
  final String? mntPoint;

  /// Mount options reported by the kernel (e.g. `rw,relatime`).
  @JsonKey(name: 'options')
  final String? options;

  /// Total size of the filesystem, in bytes.
  final double? size;

  /// Used space on the filesystem, in bytes.
  final double? used;

  /// Free space on the filesystem, in bytes.
  @JsonKey(name: 'free')
  final double? free;

  /// Available space on the filesystem, in bytes.
  final double? avail;

  /// Used space as a percentage (0-100).
  final double? percent;

  /// Creates a [FsInfo] with all fields optional.
  const FsInfo({
    this.deviceName,
    this.fsType,
    this.mntPoint,
    this.options,
    this.size,
    this.used,
    this.free,
    this.avail,
    this.percent,
  });

  factory FsInfo.fromJson(Map<String, dynamic> json) => _$FsInfoFromJson(json);

  Map<String, dynamic> toJson() => _$FsInfoToJson(this);
}
