// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mem_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MemInfo _$MemInfoFromJson(Map<String, dynamic> json) => MemInfo(
  total: (json['total'] as num?)?.toDouble(),
  available: (json['available'] as num?)?.toDouble(),
  percent: (json['percent'] as num?)?.toDouble(),
  used: (json['used'] as num?)?.toDouble(),
  free: (json['free'] as num?)?.toDouble(),
  active: (json['active'] as num?)?.toDouble(),
  inactive: (json['inactive'] as num?)?.toDouble(),
  buffers: (json['buffers'] as num?)?.toDouble(),
  cached: (json['cached'] as num?)?.toDouble(),
  shared: (json['shared'] as num?)?.toDouble(),
  slab: (json['slab'] as num?)?.toDouble(),
);

Map<String, dynamic> _$MemInfoToJson(MemInfo instance) => <String, dynamic>{
  'total': instance.total,
  'available': instance.available,
  'percent': instance.percent,
  'used': instance.used,
  'free': instance.free,
  'active': instance.active,
  'inactive': instance.inactive,
  'buffers': instance.buffers,
  'cached': instance.cached,
  'shared': instance.shared,
  'slab': instance.slab,
};
