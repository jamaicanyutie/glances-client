// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'network_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NetworkInfo _$NetworkInfoFromJson(Map<String, dynamic> json) => NetworkInfo(
  interfaceName: json['interface_name'] as String?,
  bytesSent: (json['bytes_sent'] as num?)?.toDouble(),
  bytesRecv: (json['bytes_recv'] as num?)?.toDouble(),
  packetsSent: (json['packets_sent'] as num?)?.toInt(),
  packetsRecv: (json['packets_recv'] as num?)?.toInt(),
  errin: (json['errin'] as num?)?.toInt(),
  errout: (json['errout'] as num?)?.toInt(),
  dropin: (json['dropin'] as num?)?.toInt(),
  dropout: (json['dropout'] as num?)?.toInt(),
  speed: (json['speed'] as num?)?.toDouble(),
  isUp: json['is_up'] as bool?,
);

Map<String, dynamic> _$NetworkInfoToJson(NetworkInfo instance) =>
    <String, dynamic>{
      'interface_name': instance.interfaceName,
      'bytes_sent': instance.bytesSent,
      'bytes_recv': instance.bytesRecv,
      'packets_sent': instance.packetsSent,
      'packets_recv': instance.packetsRecv,
      'errin': instance.errin,
      'errout': instance.errout,
      'dropin': instance.dropin,
      'dropout': instance.dropout,
      'speed': instance.speed,
      'is_up': instance.isUp,
    };
