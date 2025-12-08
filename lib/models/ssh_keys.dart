import 'package:uuid/uuid.dart';

class SshKey {
  final String id;  // Unique ID, generated with uuid.v4()
  final String? name;  // Optional human-readable name
  final List<String?> usedbyServers;  // List of server IPs/hosts where key is used
  final String type;  // e.g., "RSA", "Ed25519", "DSA"
  final String? publicKey;  // PEM-formatted public key string
  final String? privateKey;  // PEM-formatted private key string (encrypted if passphrase provided)
  final String? passphrase;  // Optional passphrase for encryption/decryption
  final bool isEncrypted;  // True if privateKey is encrypted

  SshKey({
    required this.id,
    this.name,
    required this.usedbyServers,
    required this.type,
    this.publicKey,
    this.privateKey,
    this.passphrase,
    this.isEncrypted = false,
  });

  // Generate a new ID if not provided
  factory SshKey.generateId() {
    return SshKey(
      id: Uuid().v4(),
      usedbyServers: [],
      type: '',  // Set during creation
    );
  }

  // CopyWith method
  SshKey copyWith({
    String? id,
    String? name,
    List<String?>? usedbyServers,
    String? type,
    String? publicKey,
    String? privateKey,
    String? passphrase,
    bool? isEncrypted,
  }) {
    return SshKey(
      id: id ?? this.id,
      name: name ?? this.name,
      usedbyServers: usedbyServers ?? this.usedbyServers,
      type: type ?? this.type,
      publicKey: publicKey ?? this.publicKey,
      privateKey: privateKey ?? this.privateKey,
      passphrase: passphrase ?? this.passphrase,
      isEncrypted: isEncrypted ?? this.isEncrypted,
    );
  }

  // To JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'usedbyServers': usedbyServers,
      'type': type,
      'publicKey': publicKey,
      'privateKey': privateKey,
      'passphrase': passphrase,
      'isEncrypted': isEncrypted,
    };
  }

  // From JSON
  factory SshKey.fromJson(Map<String, dynamic> json) {
    return SshKey(
      id: json['id'] as String,
      name: json['name'] as String?,
      usedbyServers: List<String?>.from(json['usedbyServers'] ?? []),
      type: json['type'] as String,
      publicKey: json['publicKey'] as String?,
      privateKey: json['privateKey'] as String?,
      passphrase: json['passphrase'] as String?,
      isEncrypted: json['isEncrypted'] as bool? ?? false,
    );
  }
}