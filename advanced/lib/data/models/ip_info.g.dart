// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ip_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

IpInfo _$IpInfoFromJson(Map<String, dynamic> json) => IpInfo(
  address: json['address'] as String?,
  mask: json['mask'] as String?,
  maskCidr: (json['mask_cidr'] as num?)?.toInt(),
  gateway: json['gateway'] as String?,
  publicAddress: json['public_address'] as String?,
  publicInfoHuman: json['public_info_human'] as String?,
);

Map<String, dynamic> _$IpInfoToJson(IpInfo instance) => <String, dynamic>{
  'address': instance.address,
  'mask': instance.mask,
  'mask_cidr': instance.maskCidr,
  'gateway': instance.gateway,
  'public_address': instance.publicAddress,
  'public_info_human': instance.publicInfoHuman,
};
