// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'system_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SystemInfo _$SystemInfoFromJson(Map<String, dynamic> json) => SystemInfo(
  osName: json['os_name'] as String?,
  hostname: json['hostname'] as String?,
  platform: json['platform'] as String?,
  osVersion: json['os_version'] as String?,
  linuxDistro: json['linux_distro'] as String?,
  hrName: json['hr_name'] as String?,
);

Map<String, dynamic> _$SystemInfoToJson(SystemInfo instance) =>
    <String, dynamic>{
      'os_name': instance.osName,
      'hostname': instance.hostname,
      'platform': instance.platform,
      'os_version': instance.osVersion,
      'linux_distro': instance.linuxDistro,
      'hr_name': instance.hrName,
    };
