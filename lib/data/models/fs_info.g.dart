// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fs_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FsInfo _$FsInfoFromJson(Map<String, dynamic> json) => FsInfo(
  deviceName: json['device_name'] as String?,
  fsType: json['fs_type'] as String?,
  mntPoint: json['mnt_point'] as String?,
  size: (json['size'] as num?)?.toDouble(),
  used: (json['used'] as num?)?.toDouble(),
  avail: (json['avail'] as num?)?.toDouble(),
  percent: (json['percent'] as num?)?.toDouble(),
);

Map<String, dynamic> _$FsInfoToJson(FsInfo instance) => <String, dynamic>{
  'device_name': instance.deviceName,
  'fs_type': instance.fsType,
  'mnt_point': instance.mntPoint,
  'size': instance.size,
  'used': instance.used,
  'avail': instance.avail,
  'percent': instance.percent,
};
