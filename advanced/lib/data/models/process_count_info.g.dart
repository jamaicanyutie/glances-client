// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'process_count_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProcessCountInfo _$ProcessCountInfoFromJson(Map<String, dynamic> json) =>
    ProcessCountInfo(
      total: (json['total'] as num?)?.toInt(),
      running: (json['running'] as num?)?.toInt(),
      sleeping: (json['sleeping'] as num?)?.toInt(),
      threads: (json['thread'] as num?)?.toInt(),
      pidMax: (json['pid_max'] as num?)?.toInt(),
    );

Map<String, dynamic> _$ProcessCountInfoToJson(ProcessCountInfo instance) =>
    <String, dynamic>{
      'total': instance.total,
      'running': instance.running,
      'sleeping': instance.sleeping,
      'thread': instance.threads,
      'pid_max': instance.pidMax,
    };
