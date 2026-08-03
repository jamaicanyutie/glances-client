import 'package:json_annotation/json_annotation.dart';

part 'ip_info.g.dart';

/// Private/public network addressing from the Glances `ip` plugin
/// (`GET /api/4/ip`).
///
/// The plugin reports one object, not a list. The public fields
/// (`public_address`, `public_info_human`) are only populated when the server
/// is configured with an external public-IP API; otherwise they arrive as
/// empty strings. All fields are nullable because the set reported by the
/// server varies by version and configuration.
@JsonSerializable()
class IpInfo {
  /// Private IP address.
  final String? address;

  /// Private IP subnet mask.
  final String? mask;

  /// Private IP mask in CIDR format (e.g. `24`).
  @JsonKey(name: 'mask_cidr')
  final int? maskCidr;

  /// Default gateway for the private network.
  final String? gateway;

  /// Public IP address (may be empty when no public API is configured).
  @JsonKey(name: 'public_address')
  final String? publicAddress;

  /// Human-readable public IP location/information.
  @JsonKey(name: 'public_info_human')
  final String? publicInfoHuman;

  /// Creates an [IpInfo] with all fields optional.
  const IpInfo({
    this.address,
    this.mask,
    this.maskCidr,
    this.gateway,
    this.publicAddress,
    this.publicInfoHuman,
  });

  factory IpInfo.fromJson(Map<String, dynamic> json) => _$IpInfoFromJson(json);

  Map<String, dynamic> toJson() => _$IpInfoToJson(this);
}