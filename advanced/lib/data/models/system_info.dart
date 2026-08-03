import 'package:json_annotation/json_annotation.dart';

part 'system_info.g.dart';

/// Host metadata from the Glances `system` plugin (`GET /api/4/system`).
@JsonSerializable()
class SystemInfo {
  /// Operating system name, e.g. `Linux`.
  @JsonKey(name: 'os_name')
  final String? osName;

  /// Hostname of the machine running Glances.
  final String? hostname;

  /// Architecture string, e.g. `64bit`.
  final String? platform;

  /// OS release, e.g. `6.18.33.2-microsoft-standard-WSL2`.
  @JsonKey(name: 'os_version')
  final String? osVersion;

  /// Distribution string on Linux, e.g. `Ubuntu 26.04`.
  @JsonKey(name: 'linux_distro')
  final String? linuxDistro;

  /// Human-readable combined name, e.g. `Ubuntu 26.04 64bit / Linux ...`.
  @JsonKey(name: 'hr_name')
  final String? hrName;

  /// Creates a [SystemInfo] with all fields optional.
  const SystemInfo({
    this.osName,
    this.hostname,
    this.platform,
    this.osVersion,
    this.linuxDistro,
    this.hrName,
  });

  factory SystemInfo.fromJson(Map<String, dynamic> json) =>
      _$SystemInfoFromJson(json);

  Map<String, dynamic> toJson() => _$SystemInfoToJson(this);
}
