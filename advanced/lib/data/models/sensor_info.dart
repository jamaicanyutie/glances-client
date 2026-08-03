import 'package:json_annotation/json_annotation.dart';

part 'sensor_info.g.dart';

/// Hardware sensor reading from the Glances `sensors` plugin
/// (`GET /api/4/sensors`). Values come from psutil temps/fans, the hddtemp
/// daemon, or the battery, so the set of keys varies by [type].
@JsonSerializable()
class SensorInfo {
  /// Sensor kind: `temperature_core`, `fan_speed`, `temperature_hdd`, `battery`.
  final String? type;

  /// Display label (contains spaces, e.g. `Core 0`, `BAT BAT0`).
  final String? label;

  /// API item-lookup key (always `label`).
  final String? key;

  /// Reading. Normally a number, but HDD error states arrive as strings
  /// (`ERR`, `SLP`, `UNK`, `NOS`), so the field is intentionally loose.
  final Object? value;

  /// Unit: `C`, `R` (fan rotations), `%`, or a hddtemp-daemon unit.
  final String? unit;

  /// Warning threshold. Absent on battery/HDD items.
  final num? warning;

  /// Critical threshold. Absent on battery/HDD items.
  final num? critical;

  /// Battery-only status (`Charging`/`Discharging`).
  final String? status;

  /// Creates a [SensorInfo] with all fields optional.
  const SensorInfo({
    this.type,
    this.label,
    this.key,
    this.value,
    this.unit,
    this.warning,
    this.critical,
    this.status,
  });

  /// Numeric form of [value], or null when the reading is a string.
  double? get valueAsDouble => value is num ? (value as num).toDouble() : null;

  /// Status color level: 0 = ok, 1 = warning, 2 = critical (battery not
  /// colored here — it lacks thresholds).
  int get level {
    final double? v = valueAsDouble;
    if (v == null) return 0;
    if (critical != null && v >= critical!.toDouble()) return 2;
    if (warning != null && v >= warning!.toDouble()) return 1;
    return 0;
  }

  factory SensorInfo.fromJson(Map<String, dynamic> json) =>
      _$SensorInfoFromJson(json);

  Map<String, dynamic> toJson() => _$SensorInfoToJson(this);
}
