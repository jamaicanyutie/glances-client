// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vm_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VmInfo _$VmInfoFromJson(Map<String, dynamic> json) => VmInfo(
  name: json['name'] as String?,
  id: json['id'] as String?,
  release: json['release'] as String?,
  status: json['status'] as String?,
  cpuCount: (json['cpu_count'] as num?)?.toInt(),
  cpuTime: json['cpu_time'] as num?,
  memoryUsage: json['memory_usage'] as num?,
  memoryTotal: json['memory_total'] as num?,
  load1min: json['load_1min'] as num?,
  load5min: json['load_5min'] as num?,
  load15min: json['load_15min'] as num?,
  ipv4: json['ipv4'] as String?,
  engine: json['engine'] as String?,
  engineVersion: json['engine_version'] as String?,
);

Map<String, dynamic> _$VmInfoToJson(VmInfo instance) => <String, dynamic>{
  'name': instance.name,
  'id': instance.id,
  'release': instance.release,
  'status': instance.status,
  'cpu_count': instance.cpuCount,
  'cpu_time': instance.cpuTime,
  'memory_usage': instance.memoryUsage,
  'memory_total': instance.memoryTotal,
  'load_1min': instance.load1min,
  'load_5min': instance.load5min,
  'load_15min': instance.load15min,
  'ipv4': instance.ipv4,
  'engine': instance.engine,
  'engine_version': instance.engineVersion,
};
