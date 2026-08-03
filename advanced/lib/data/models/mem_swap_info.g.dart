// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mem_swap_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MemSwapInfo _$MemSwapInfoFromJson(Map<String, dynamic> json) => MemSwapInfo(
  total: (json['total'] as num?)?.toDouble(),
  used: (json['used'] as num?)?.toDouble(),
  free: (json['free'] as num?)?.toDouble(),
  percent: (json['percent'] as num?)?.toDouble(),
  sin: (json['sin'] as num?)?.toDouble(),
  sout: (json['sout'] as num?)?.toDouble(),
);

Map<String, dynamic> _$MemSwapInfoToJson(MemSwapInfo instance) =>
    <String, dynamic>{
      'total': instance.total,
      'used': instance.used,
      'free': instance.free,
      'percent': instance.percent,
      'sin': instance.sin,
      'sout': instance.sout,
    };
