// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'process_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProcessInfo _$ProcessInfoFromJson(Map<String, dynamic> json) => ProcessInfo(
  pid: (json['pid'] as num?)?.toInt(),
  name: json['name'] as String?,
  cpuPercent: (json['cpu_percent'] as num?)?.toDouble(),
  memPercent: (json['mem_percent'] as num?)?.toDouble(),
  status: json['status'] as String?,
  username: json['username'] as String?,
  command: (json['command'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
);

Map<String, dynamic> _$ProcessInfoToJson(ProcessInfo instance) =>
    <String, dynamic>{
      'pid': instance.pid,
      'name': instance.name,
      'cpu_percent': instance.cpuPercent,
      'mem_percent': instance.memPercent,
      'status': instance.status,
      'username': instance.username,
      'command': instance.command,
    };
