// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gpu_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GpuInfo _$GpuInfoFromJson(Map<String, dynamic> json) => GpuInfo(
  key: json['key'] as String?,
  name: json['name'] as String?,
  vendor: json['vendor'] as String?,
  driver: json['driver'] as String?,
  temperature: json['temperature'] as num?,
  mem: json['mem'] as num?,
  proc: json['proc'] as num?,
);

Map<String, dynamic> _$GpuInfoToJson(GpuInfo instance) => <String, dynamic>{
  'key': instance.key,
  'name': instance.name,
  'vendor': instance.vendor,
  'driver': instance.driver,
  'temperature': instance.temperature,
  'mem': instance.mem,
  'proc': instance.proc,
};
