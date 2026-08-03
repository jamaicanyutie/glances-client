// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'port_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PortInfo _$PortInfoFromJson(Map<String, dynamic> json) => PortInfo(
  host: json['host'] as String?,
  port: (json['port'] as num?)?.toInt(),
  description: json['description'] as String?,
  refresh: (json['refresh'] as num?)?.toInt(),
  timeout: (json['timeout'] as num?)?.toInt(),
  status: json['status'] as num?,
  rttWarning: json['rtt_warning'] as num?,
  indice: (json['indice'] as num?)?.toInt(),
);

Map<String, dynamic> _$PortInfoToJson(PortInfo instance) => <String, dynamic>{
  'host': instance.host,
  'port': instance.port,
  'description': instance.description,
  'refresh': instance.refresh,
  'timeout': instance.timeout,
  'status': instance.status,
  'rtt_warning': instance.rttWarning,
  'indice': instance.indice,
};
