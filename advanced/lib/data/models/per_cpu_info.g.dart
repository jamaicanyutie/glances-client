// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'per_cpu_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PerCpuInfo _$PerCpuInfoFromJson(Map<String, dynamic> json) => PerCpuInfo(
  cpuNumber: (json['cpu_number'] as num?)?.toInt(),
  total: (json['total'] as num?)?.toDouble(),
  user: (json['user'] as num?)?.toDouble(),
  system: (json['system'] as num?)?.toDouble(),
  idle: (json['idle'] as num?)?.toDouble(),
  iowait: (json['iowait'] as num?)?.toDouble(),
  nice: (json['nice'] as num?)?.toDouble(),
  steal: (json['steal'] as num?)?.toDouble(),
  irq: (json['irq'] as num?)?.toDouble(),
  softirq: (json['softirq'] as num?)?.toDouble(),
  guest: (json['guest'] as num?)?.toDouble(),
  guestNice: (json['guest_nice'] as num?)?.toDouble(),
);

Map<String, dynamic> _$PerCpuInfoToJson(PerCpuInfo instance) =>
    <String, dynamic>{
      'cpu_number': instance.cpuNumber,
      'total': instance.total,
      'user': instance.user,
      'system': instance.system,
      'idle': instance.idle,
      'iowait': instance.iowait,
      'nice': instance.nice,
      'steal': instance.steal,
      'irq': instance.irq,
      'softirq': instance.softirq,
      'guest': instance.guest,
      'guest_nice': instance.guestNice,
    };
