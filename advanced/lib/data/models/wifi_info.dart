import 'package:json_annotation/json_annotation.dart';

part 'wifi_info.g.dart';

/// Wi-Fi network signal statistics from the Glances `wifi` plugin
/// (`GET /api/4/wifi`). Values are read from `/proc/net/wireless` (Linux only),
/// so on servers without Wi-Fi the endpoint returns an empty list.
@JsonSerializable()
class WifiInfo {
  /// Wi-Fi network name (SSID).
  final String? ssid;

  /// Signal quality level, in dBm.
  @JsonKey(name: 'quality_link')
  final int? qualityLink;

  /// Signal strength level, in dBm. Negative values; closer to 0 is stronger.
  @JsonKey(name: 'quality_level')
  final int? qualityLevel;

  /// Creates a [WifiInfo] with all fields optional.
  const WifiInfo({
    this.ssid,
    this.qualityLink,
    this.qualityLevel,
  });

  factory WifiInfo.fromJson(Map<String, dynamic> json) => _$WifiInfoFromJson(json);

  Map<String, dynamic> toJson() => _$WifiInfoToJson(this);
}