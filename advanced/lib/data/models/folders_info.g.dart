// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'folders_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FolderInfo _$FolderInfoFromJson(Map<String, dynamic> json) => FolderInfo(
  name: json['name'] as String?,
  used: json['used'] as num?,
  free: json['free'] as num?,
  size: json['size'] as num?,
  percent: json['percent'] as num?,
);

Map<String, dynamic> _$FolderInfoToJson(FolderInfo instance) =>
    <String, dynamic>{
      'name': instance.name,
      'used': instance.used,
      'free': instance.free,
      'size': instance.size,
      'percent': instance.percent,
    };
