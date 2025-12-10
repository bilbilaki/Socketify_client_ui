import 'package:client_ui/models/server_config.dart';
import 'package:json_annotation/json_annotation.dart';

part 'connected_config.g.dart';

@JsonSerializable()
class ConnectedConfig {
  final String id;
  final ServerConfig config;
  final String status;

  ConnectedConfig({
    required this.config,
    required this.id,
    required this.status,
  });
  factory ConnectedConfig.fromJson(Map<String, dynamic> json) =>
      _$ConnectedConfigFromJson(json);

  Map<String, dynamic> toJson() => _$ConnectedConfigToJson(this);

  ConnectedConfig copyWith({String? id, ServerConfig? config, String? status}) {
    return ConnectedConfig(
      config: config ?? this.config,
      id: id ?? this.id,
      status: status ?? this.status,
    );
  }
}
