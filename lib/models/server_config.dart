import 'package:json_annotation/json_annotation.dart';

part 'server_config.g.dart';

@JsonSerializable()
class ServerConfig {
  final String id;
  final String name;
  final String address;
  final String? ipv4Address;
  final String? ipv6Address;
  final int port;
  final String osType;
  final String username;
  final String? gatewayProxy;
  final String? password;
  final String? privKey;
  final String? chainConnection;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool? isOnline;
  final String? osVersion;
  final String? connectionType;
  final ServerConfig? jumpServer;

  ServerConfig({
    required this.id,
    required this.name,
    required this.address,
    this.ipv4Address,
    this.ipv6Address,
    required this.port,
    required this.osType,
    required this.username,
    this.gatewayProxy,
    this.password,
    this.privKey,
    this.chainConnection,
    required this.createdAt,
    required this.updatedAt,
    this.isOnline,
    this.osVersion,
    required this.connectionType,
    this.jumpServer
  });

  factory ServerConfig.fromJson(Map<String, dynamic> json) =>
      _$ServerConfigFromJson(json);

  Map<String, dynamic> toJson() => _$ServerConfigToJson(this);

  ServerConfig copyWith({
    String? id,
    String? name,
    String? address,
    String? ipv4Address,
    String? ipv6Address,
    int? port,
    String? osType,
    String? username,
    String? gatewayProxy,
    String? password,
    String? privKey,
    String? chainConnection,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isOnline,
    String? osVersion,
    String? connectionType,
    ServerConfig? jumpServer
  }) {
    return ServerConfig(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      ipv4Address: ipv4Address ?? this.ipv4Address,
      ipv6Address: ipv6Address ?? this.ipv6Address,
      port: port ?? this.port,
      osType: osType ?? this.osType,
      username: username ?? this.username,
      gatewayProxy: gatewayProxy ?? this.gatewayProxy,
      password: password ?? this.password,
      privKey: privKey ?? this.privKey,
      chainConnection: chainConnection ?? this.chainConnection,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isOnline: isOnline ?? this.isOnline,
      osVersion: osVersion ?? this.osVersion,
      connectionType: connectionType ?? this.connectionType,
      jumpServer: jumpServer?? this.jumpServer
    );
  }
}

enum ConnectionType { ssh, telnet, rdp, ws, sftp, smb }
