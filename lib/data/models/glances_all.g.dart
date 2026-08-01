// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'glances_all.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GlancesAll _$GlancesAllFromJson(Map<String, dynamic> json) => GlancesAll(
  cpu: json['cpu'] == null
      ? null
      : CpuInfo.fromJson(json['cpu'] as Map<String, dynamic>),
  mem: json['mem'] == null
      ? null
      : MemInfo.fromJson(json['mem'] as Map<String, dynamic>),
  load: json['load'] == null
      ? null
      : LoadInfo.fromJson(json['load'] as Map<String, dynamic>),
  fs: (json['fs'] as List<dynamic>?)
      ?.map((e) => FsInfo.fromJson(e as Map<String, dynamic>))
      .toList(),
  diskio: (json['diskio'] as List<dynamic>?)
      ?.map((e) => DiskIoInfo.fromJson(e as Map<String, dynamic>))
      .toList(),
  network: (json['network'] as List<dynamic>?)
      ?.map((e) => NetworkInfo.fromJson(e as Map<String, dynamic>))
      .toList(),
  processcount: json['processcount'] == null
      ? null
      : ProcessCountInfo.fromJson(json['processcount'] as Map<String, dynamic>),
  docker: (json['containers'] as List<dynamic>?)
      ?.map((e) => DockerContainerInfo.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$GlancesAllToJson(GlancesAll instance) =>
    <String, dynamic>{
      'cpu': instance.cpu,
      'mem': instance.mem,
      'load': instance.load,
      'fs': instance.fs,
      'diskio': instance.diskio,
      'network': instance.network,
      'processcount': instance.processcount,
      'containers': instance.docker,
    };
