import 'package:json_annotation/json_annotation.dart';

part 'mem_info.g.dart';

/// Memory usage statistics reported by the Glances `mem` plugin.
///
/// All byte values are nullable because the set of fields reported by the
/// server is platform-dependent (Linux vs Windows vs macOS) and can vary
/// between Glances versions. Byte values are expressed in bytes.
@JsonSerializable()
class MemInfo {
  /// Total physical memory, in bytes.
  final double? total;

  /// Memory currently available for new processes, in bytes.
  final double? available;

  /// Memory usage percentage (0-100).
  final double? percent;

  /// Memory currently in use, in bytes.
  final double? used;

  /// Memory currently free, in bytes.
  final double? free;

  /// Memory currently active (Linux only), in bytes.
  final double? active;

  /// Memory currently inactive (Linux only), in bytes.
  final double? inactive;

  /// Memory used for file buffers (Linux only), in bytes.
  final double? buffers;

  /// Memory used for page cache (Linux only), in bytes.
  final double? cached;

  /// Memory used by tmpfs/shared mappings (Linux only), in bytes.
  final double? shared;

  /// Memory used by the kernel slab allocator (Linux only), in bytes.
  final double? slab;

  /// Creates a [MemInfo] with all fields optional.
  const MemInfo({
    this.total,
    this.available,
    this.percent,
    this.used,
    this.free,
    this.active,
    this.inactive,
    this.buffers,
    this.cached,
    this.shared,
    this.slab,
  });

  factory MemInfo.fromJson(Map<String, dynamic> json) =>
      _$MemInfoFromJson(json);

  Map<String, dynamic> toJson() => _$MemInfoToJson(this);
}
