// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'connected_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ConnectedConfig _$ConnectedConfigFromJson(Map<String, dynamic> json) =>
    ConnectedConfig(
      config: ServerConfig.fromJson(json['config'] as Map<String, dynamic>),
      id: json['id'] as String,
      status: json['status'] as String,
    );

Map<String, dynamic> _$ConnectedConfigToJson(ConnectedConfig instance) =>
    <String, dynamic>{
      'id': instance.id,
      'config': instance.config,
      'status': instance.status,
    };
