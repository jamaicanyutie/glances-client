// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'alert_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AlertInfo _$AlertInfoFromJson(Map<String, dynamic> json) => AlertInfo(
  begin: (json['begin'] as num?)?.toInt(),
  end: (json['end'] as num?)?.toInt(),
  state: json['state'] as String?,
  type: json['type'] as String?,
  min: json['min'] as num?,
  max: json['max'] as num?,
  sum: json['sum'] as num?,
  avg: json['avg'] as num?,
  count: (json['count'] as num?)?.toInt(),
  top: (json['top'] as List<dynamic>?)?.map((e) => e as String).toList(),
  desc: json['desc'] as String?,
  sort: json['sort'] as String?,
  globalMsg: json['global_msg'] as String?,
);

Map<String, dynamic> _$AlertInfoToJson(AlertInfo instance) => <String, dynamic>{
  'begin': instance.begin,
  'end': instance.end,
  'state': instance.state,
  'type': instance.type,
  'min': instance.min,
  'max': instance.max,
  'sum': instance.sum,
  'avg': instance.avg,
  'count': instance.count,
  'top': instance.top,
  'desc': instance.desc,
  'sort': instance.sort,
  'global_msg': instance.globalMsg,
};
