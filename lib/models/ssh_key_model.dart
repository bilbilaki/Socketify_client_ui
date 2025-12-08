class SshKey {
  final String id;
  final String name;
  final String publicKey;
  final String privateKey;
  final String keyType; // 'rsa', 'ed25519', etc.
  final int? keySize; // for RSA: 2048, 4096, etc.
  final DateTime createdAt;
  final DateTime? lastUsedAt;
  final String? fingerprint;

  SshKey({
    required this.id,
    required this.name,
    required this.publicKey,
    required this.privateKey,
    required this.keyType,
    this.keySize,
    required this.createdAt,
    this.lastUsedAt,
    this.fingerprint,
  });

  SshKey copyWith({
    String? id,
    String? name,
    String? publicKey,
    String? privateKey,
    String? keyType,
    int? keySize,
    DateTime? createdAt,
    DateTime? lastUsedAt,
    String? fingerprint,
  }) {
    return SshKey(
      id: id ?? this.id,
      name: name ?? this.name,
      publicKey: publicKey ?? this.publicKey,
      privateKey: privateKey ?? this.privateKey,
      keyType: keyType ?? this.keyType,
      keySize: keySize ?? this.keySize,
      createdAt: createdAt ?? this.createdAt,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      fingerprint: fingerprint ?? this.fingerprint,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'publicKey': publicKey,
      'privateKey': privateKey,
      'keyType': keyType,
      'keySize': keySize,
      'createdAt': createdAt.toIso8601String(),
      'lastUsedAt': lastUsedAt?.toIso8601String(),
      'fingerprint': fingerprint,
    };
  }

  factory SshKey.fromJson(Map<String, dynamic> json) {
    return SshKey(
      id: json['id'] as String,
      name: json['name'] as String,
      publicKey: json['publicKey'] as String,
      privateKey: json['privateKey'] as String,
      keyType: json['keyType'] as String,
      keySize: json['keySize'] as int?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastUsedAt: json['lastUsedAt'] != null
          ? DateTime.parse(json['lastUsedAt'] as String)
          : null,
      fingerprint: json['fingerprint'] as String?,
    );
  }
}
