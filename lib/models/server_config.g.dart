// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'server_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ServerConfig _$ServerConfigFromJson(Map<String, dynamic> json) => ServerConfig(
  id: json['id'] as String,
  name: json['name'] as String,
  address: json['address'] as String,
  ipv4Address: json['ipv4Address'] as String?,
  ipv6Address: json['ipv6Address'] as String?,
  port: (json['port'] as num).toInt(),
  osType: json['osType'] as String,
  username: json['username'] as String,
  gatewayProxy: json['gatewayProxy'] as String?,
  password: json['password'] as String?,
  privKey: json['privKey'] as String?,
  chainConnection: json['chainConnection'] as String?,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
  isOnline: json['isOnline'] as bool?,
  osVersion: json['osVersion'] as String?,
  connectionType: json['connectionType'] as String?,
);

Map<String, dynamic> _$ServerConfigToJson(ServerConfig instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'address': instance.address,
      'ipv4Address': instance.ipv4Address,
      'ipv6Address': instance.ipv6Address,
      'port': instance.port,
      'osType': instance.osType,
      'username': instance.username,
      'gatewayProxy': instance.gatewayProxy,
      'password': instance.password,
      'privKey': instance.privKey,
      'chainConnection': instance.chainConnection,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'isOnline': instance.isOnline,
      'osVersion': instance.osVersion,
      'connectionType': instance.connectionType,
    };
