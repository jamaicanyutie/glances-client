// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'docker_container_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DockerContainerInfo _$DockerContainerInfoFromJson(Map<String, dynamic> json) =>
    DockerContainerInfo(
      name: json['name'] as String?,
      id: json['id'] as String?,
      status: json['status'] as String?,
      image: (json['image'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      cpuPercent: (json['cpu_percent'] as num?)?.toDouble(),
      memPercent: (json['mem_percent'] as num?)?.toDouble(),
      memUsage: (json['mem_usage'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, (e as num).toDouble()),
      ),
      state: json['state'] as String?,
      engine: json['engine'] as String?,
      command: json['command'] as String?,
      created: json['created'] as String?,
      uptime: json['uptime'] as String?,
      ports: json['ports'] as String?,
      io: (json['io'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, (e as num).toDouble()),
      ),
      cpu: (json['cpu'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, (e as num).toDouble()),
      ),
      memory: (json['memory'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, (e as num).toDouble()),
      ),
      network: (json['network'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, (e as num).toDouble()),
      ),
    );

Map<String, dynamic> _$DockerContainerInfoToJson(
  DockerContainerInfo instance,
) => <String, dynamic>{
  'name': instance.name,
  'id': instance.id,
  'status': instance.status,
  'image': instance.image,
  'cpu_percent': instance.cpuPercent,
  'mem_percent': instance.memPercent,
  'mem_usage': instance.memUsage,
  'state': instance.state,
  'engine': instance.engine,
  'command': instance.command,
  'created': instance.created,
  'uptime': instance.uptime,
  'ports': instance.ports,
  'io': instance.io,
  'cpu': instance.cpu,
  'memory': instance.memory,
  'network': instance.network,
};
