// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'load_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LoadInfo _$LoadInfoFromJson(Map<String, dynamic> json) => LoadInfo(
  min1: (json['min1'] as num?)?.toDouble(),
  min5: (json['min5'] as num?)?.toDouble(),
  min15: (json['min15'] as num?)?.toDouble(),
  cpucore: (json['cpucore'] as num?)?.toInt(),
);

Map<String, dynamic> _$LoadInfoToJson(LoadInfo instance) => <String, dynamic>{
  'min1': instance.min1,
  'min5': instance.min5,
  'min15': instance.min15,
  'cpucore': instance.cpucore,
};
