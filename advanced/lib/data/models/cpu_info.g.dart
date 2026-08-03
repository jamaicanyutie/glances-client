// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cpu_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CpuInfo _$CpuInfoFromJson(Map<String, dynamic> json) => CpuInfo(
  cpucore: (json['cpucore'] as num?)?.toInt(),
  total: (json['total'] as num?)?.toDouble(),
  user: (json['user'] as num?)?.toDouble(),
  system: (json['system'] as num?)?.toDouble(),
  idle: (json['idle'] as num?)?.toDouble(),
  iowait: (json['iowait'] as num?)?.toDouble(),
  nice: (json['nice'] as num?)?.toDouble(),
  steal: (json['steal'] as num?)?.toDouble(),
  irq: (json['irq'] as num?)?.toDouble(),
  softInterrupts: (json['soft_interrupts'] as num?)?.toDouble(),
  ctxSwitches: (json['ctx_switches'] as num?)?.toInt(),
  syscalls: (json['syscalls'] as num?)?.toInt(),
  guest: (json['guest'] as num?)?.toDouble(),
  guestNice: (json['guest_nice'] as num?)?.toDouble(),
);

Map<String, dynamic> _$CpuInfoToJson(CpuInfo instance) => <String, dynamic>{
  'cpucore': instance.cpucore,
  'total': instance.total,
  'user': instance.user,
  'system': instance.system,
  'idle': instance.idle,
  'iowait': instance.iowait,
  'nice': instance.nice,
  'steal': instance.steal,
  'irq': instance.irq,
  'soft_interrupts': instance.softInterrupts,
  'ctx_switches': instance.ctxSwitches,
  'syscalls': instance.syscalls,
  'guest': instance.guest,
  'guest_nice': instance.guestNice,
};
