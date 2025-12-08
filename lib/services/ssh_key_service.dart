import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../models/ssh_key_model.dart';

class SshKeyService {
  static const String _sshKeysKey = 'ssh_keys';

  /// Generate SSH key fingerprint from public key
  static String generateFingerprint(String publicKey) {
    final bytes = utf8.encode(publicKey);
    final digest = md5.convert(bytes);
    return digest.toString();
  }

  /// Parse OpenSSH public key to extract key type and fingerprint
  static Map<String, String> parsePublicKey(String publicKey) {
    try {
      final lines = publicKey.trim().split('\n');
      final keyLine = lines.firstWhere(
        (line) => line.startsWith('ssh-'),
        orElse: () => publicKey,
      );

      final parts = keyLine.split(' ');
      final keyType = parts.isNotEmpty
          ? parts[0].replaceFirst('ssh-', '')
          : 'unknown';
      final fingerprint = generateFingerprint(publicKey);

      return {'keyType': keyType, 'fingerprint': fingerprint};
    } catch (e) {
      print('Error parsing public key: $e');
      return {
        'keyType': 'unknown',
        'fingerprint': generateFingerprint(publicKey),
      };
    }
  }

  /// Validate private key format
  static bool validatePrivateKey(String privateKey) {
    try {
      final normalized = privateKey.trim();
      return normalized.contains('BEGIN OPENSSH PRIVATE KEY') ||
          normalized.contains('BEGIN RSA PRIVATE KEY') ||
          normalized.contains('BEGIN EC PRIVATE KEY') ||
          normalized.contains('BEGIN PRIVATE KEY');
    } catch (e) {
      return false;
    }
  }

  /// Validate public key format
  static bool validatePublicKey(String publicKey) {
    try {
      final normalized = publicKey.trim();
      return normalized.startsWith('ssh-rsa') ||
          normalized.startsWith('ssh-ed25519') ||
          normalized.startsWith('ecdsa-sha2-') ||
          normalized.startsWith('ssh-dss') ||
          normalized.contains('BEGIN PUBLIC KEY') ||
          normalized.contains('BEGIN RSA PUBLIC KEY');
    } catch (e) {
      return false;
    }
  }

  /// Format private key for storage (ensure proper line breaks)
  static String formatPrivateKey(String key) {
    final lines = key.split('\n');
    final formattedLines = lines
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
    return formattedLines.join('\n');
  }

  /// Format public key for storage
  static String formatPublicKey(String key) {
    return key.trim();
  }

  /// Extract comment from public key if present
  static String? extractComment(String publicKey) {
    try {
      final parts = publicKey.trim().split(' ');
      if (parts.length >= 3) {
        return parts.sublist(2).join(' ');
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Create SSH key from imported keys
  static SshKey createKeyFromImport({
    required String name,
    required String publicKey,
    required String privateKey,
    String? keyType,
    int? keySize,
    String? id,
  }) {
    final pubKeyInfo = parsePublicKey(publicKey);
    final detectedKeyType = keyType ?? pubKeyInfo['keyType'] ?? 'unknown';
    final fingerprint = pubKeyInfo['fingerprint'];

    return SshKey(
      id: id ?? _generateKeyId(),
      name: name.isNotEmpty
          ? name
          : 'SSH Key ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
      publicKey: formatPublicKey(publicKey),
      privateKey: formatPrivateKey(privateKey),
      keyType: detectedKeyType,
      keySize: keySize,
      createdAt: DateTime.now(),
      fingerprint: fingerprint,
    );
  }

  /// Generate unique key ID
  static String _generateKeyId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }
}
