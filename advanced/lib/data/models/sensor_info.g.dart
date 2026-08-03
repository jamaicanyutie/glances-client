// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sensor_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SensorInfo _$SensorInfoFromJson(Map<String, dynamic> json) => SensorInfo(
  type: json['type'] as String?,
  label: json['label'] as String?,
  key: json['key'] as String?,
  value: json['value'],
  unit: json['unit'] as String?,
  warning: json['warning'] as num?,
  critical: json['critical'] as num?,
  status: json['status'] as String?,
);

Map<String, dynamic> _$SensorInfoToJson(SensorInfo instance) =>
    <String, dynamic>{
      'type': instance.type,
      'label': instance.label,
      'key': instance.key,
      'value': instance.value,
      'unit': instance.unit,
      'warning': instance.warning,
      'critical': instance.critical,
      'status': instance.status,
    };
