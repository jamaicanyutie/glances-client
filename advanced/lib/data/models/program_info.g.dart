// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'program_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProgramInfo _$ProgramInfoFromJson(Map<String, dynamic> json) => ProgramInfo(
  name: json['name'] as String?,
  cmdline: (json['cmdline'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  pid: json['pid'] as String?,
  cpuPercent: (json['cpu_percent'] as num?)?.toDouble(),
  memoryPercent: (json['memory_percent'] as num?)?.toDouble(),
  numThreads: (json['num_threads'] as num?)?.toInt(),
  nprocs: (json['nprocs'] as num?)?.toInt(),
  username: json['username'] as String?,
  status: json['status'] as String?,
);

Map<String, dynamic> _$ProgramInfoToJson(ProgramInfo instance) =>
    <String, dynamic>{
      'name': instance.name,
      'cmdline': instance.cmdline,
      'pid': instance.pid,
      'cpu_percent': instance.cpuPercent,
      'memory_percent': instance.memoryPercent,
      'num_threads': instance.numThreads,
      'nprocs': instance.nprocs,
      'username': instance.username,
      'status': instance.status,
    };
