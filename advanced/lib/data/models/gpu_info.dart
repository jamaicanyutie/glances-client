import 'package:json_annotation/json_annotation.dart';

part 'gpu_info.g.dart';

/// A single GPU from the Glances `gpu` plugin.
///
/// Only present on hosts with a GPU (ARM boards, Jetson, Apple Silicon, ...);
/// servers without one report an empty list. All values are nullable because
/// the field set varies by vendor and Glances version. [mem] and [proc] are
/// usage percentages on a 0-100 scale; [temperature] is in degrees Celsius.
@JsonSerializable()
class GpuInfo {
  /// Unique key identifying this GPU on the host.
  final String? key;

  /// Human-readable name, e.g. `NVIDIA GeForce RTX 3080`.
  final String? name;

  /// GPU vendor, e.g. `nvidia`, `intel`, `arm` (or empty when unknown).
  final String? vendor;

  /// Driver name, e.g. `nvidia` (or empty when unknown).
  final String? driver;

  /// GPU temperature in degrees Celsius.
  final num? temperature;

  /// Memory usage percentage (0-100).
  final num? mem;

  /// Processor usage percentage (0-100).
  final num? proc;

  /// Creates a [GpuInfo] with all fields optional.
  const GpuInfo({
    this.key,
    this.name,
    this.vendor,
    this.driver,
    this.temperature,
    this.mem,
    this.proc,
  });

  factory GpuInfo.fromJson(Map<String, dynamic> json) =>
      _$GpuInfoFromJson(json);

  Map<String, dynamic> toJson() => _$GpuInfoToJson(this);
}