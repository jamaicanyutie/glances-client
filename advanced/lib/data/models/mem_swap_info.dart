import 'package:json_annotation/json_annotation.dart';

part 'mem_swap_info.g.dart';

/// Memory-swap statistics reported by the Glances `memswap` plugin
/// (`GET /api/4/memswap`).
///
/// All fields are nullable because the set of fields reported by the server
/// can vary between Glances versions. Byte values are expressed in bytes.
@JsonSerializable()
class MemSwapInfo {
  /// Total swap size, in bytes.
  final double? total;

  /// Used swap, in bytes.
  final double? used;

  /// Free swap, in bytes.
  final double? free;

  /// Swap usage percentage (0-100).
  final double? percent;

  /// Cumulative bytes swapped in from disk.
  final double? sin;

  /// Cumulative bytes swapped out to disk.
  final double? sout;

  /// Creates a [MemSwapInfo] with all fields optional.
  const MemSwapInfo({
    this.total,
    this.used,
    this.free,
    this.percent,
    this.sin,
    this.sout,
  });

  factory MemSwapInfo.fromJson(Map<String, dynamic> json) =>
      _$MemSwapInfoFromJson(json);

  Map<String, dynamic> toJson() => _$MemSwapInfoToJson(this);
}
