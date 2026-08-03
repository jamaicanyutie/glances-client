// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wifi_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WifiInfo _$WifiInfoFromJson(Map<String, dynamic> json) => WifiInfo(
  ssid: json['ssid'] as String?,
  qualityLink: (json['quality_link'] as num?)?.toInt(),
  qualityLevel: (json['quality_level'] as num?)?.toInt(),
);

Map<String, dynamic> _$WifiInfoToJson(WifiInfo instance) => <String, dynamic>{
  'ssid': instance.ssid,
  'quality_link': instance.qualityLink,
  'quality_level': instance.qualityLevel,
};
