// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'disk_io_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DiskIoInfo _$DiskIoInfoFromJson(Map<String, dynamic> json) => DiskIoInfo(
  diskName: json['disk_name'] as String?,
  readBytes: (json['read_bytes'] as num?)?.toDouble(),
  writeBytes: (json['write_bytes'] as num?)?.toDouble(),
  readTime: (json['read_time'] as num?)?.toDouble(),
  writeTime: (json['write_time'] as num?)?.toDouble(),
  timeSinceUpdate: (json['time_since_update'] as num?)?.toDouble(),
);

Map<String, dynamic> _$DiskIoInfoToJson(DiskIoInfo instance) =>
    <String, dynamic>{
      'disk_name': instance.diskName,
      'read_bytes': instance.readBytes,
      'write_bytes': instance.writeBytes,
      'read_time': instance.readTime,
      'write_time': instance.writeTime,
      'time_since_update': instance.timeSinceUpdate,
    };
