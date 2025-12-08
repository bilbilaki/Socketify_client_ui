import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:client_ui/models/ssh_keys.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pointycastle/export.dart' hide Mac;
import 'package:cryptography/cryptography.dart';
import 'package:uuid/uuid.dart';

class SshKeyService {
  static final AesCbc aesCbc = AesCbc.with256bits(macAlgorithm: MacAlgorithm.empty);  // Simple AES for encryption
  static final pbkdf2 = Pbkdf2(macAlgorithm: Hmac.sha256(), iterations: 10000, bits: 256);  // For key derivation

  // Directory for storing keys
  static Future<String> _getKeysDirectory() async {
    final dir = await getApplicationDocumentsDirectory();
    final keysDir = Directory('${dir.path}/ssh_keys');
    if (!await keysDir.exists()) await keysDir.create();
    return keysDir.path;
  }

  // Generate an RSA key pair (supports with/without passphrase)
  static Future<SshKey> createRSAKey({
    String? name,
    String? passphrase,
    List<String?> usedbyServers = const [],
  }) async {
    final rsaParameters = RSAKeyGeneratorParameters(BigInt.from(2048),2048,2048);
    final keyGenerator = RSAKeyGenerator();
    final secureRandom = FortunaRandom();
    final keyParams = ParametersWithRandom(rsaParameters, secureRandom);
    keyGenerator.init(keyParams);

    final keyPair = keyGenerator.generateKeyPair();
    final privateKey = keyPair.privateKey as RSAPrivateKey;
    final publicKey = keyPair.publicKey as RSAPublicKey;

    final privatePem = (privateKey);
    final publicPem = (publicKey);

    String? finalPrivatePem = privatePem.toString();
    bool isEncrypted = false;
    if (passphrase != null && passphrase.isNotEmpty) {
      finalPrivatePem = await _encryptPem(privatePem.toString(), passphrase);
      isEncrypted = true;
    }

    return SshKey(
      id: Uuid().v4(),
      name: name,
      usedbyServers: usedbyServers,
      type: 'RSA',
      publicKey: publicPem.toString(),
      privateKey: finalPrivatePem,
      passphrase: passphrase,
      isEncrypted: isEncrypted,
    );
  }

  // Generate an Ed25519 key pair (supports with/without passphrase)
  static Future<SshKey> createEd25519Key({
    String? name,
    String? passphrase,
    List<String?> usedbyServers = const [],
  }) async {
    final algorithm = Ed25519();
    final keyPair = await algorithm.newKeyPair();

    final privateBytes = await keyPair.extractPrivateKeyBytes();
    final publicBytes = await keyPair.extractPublicKey();

    final privatePem = _encodeEd25519PrivateToPEM(privateBytes);
    final publicPem = _encodeEd25519PublicToPEM(publicBytes.bytes);

    String? finalPrivatePem = privatePem;
    bool isEncrypted = false;
    if (passphrase != null && passphrase.isNotEmpty) {
      finalPrivatePem = await _encryptPem(privatePem, passphrase);
      isEncrypted = true;
    }

    return SshKey(
      id: Uuid().v4(),
      name: name,
      usedbyServers: usedbyServers,
      type: 'Ed25519',
      publicKey: publicPem,
      privateKey: finalPrivatePem,
      passphrase: passphrase,
      isEncrypted: isEncrypted,
    );
  }

  // Decrypt private key if encrypted
  static Future<String?> decryptPrivateKey(SshKey key) async {
    if (!key.isEncrypted || key.privateKey == null || key.passphrase == null) {
      return key.privateKey;  // Not encrypted or no passphrase
    }
    return await _decryptPem(key.privateKey!, key.passphrase!);
  }

  // Encrypt a PEM string with AES-256 using passphrase
  static Future<String> _encryptPem(String pem, String passphrase) async {
    final salt = Uint8List(16)..setRange(0, 16, [Random.secure().nextInt(16)]);
    final derivedKey = await pbkdf2.deriveKeyFromPassword(
      password: passphrase,
      nonce: salt,
    );
    final secretKey = await derivedKey.extract();

    final plaintext = Uint8List.fromList(utf8.encode(pem));
    final secretBox = await aesCbc.encrypt(plaintext, secretKey: secretKey);

    final encrypted = salt + secretBox.nonce + secretBox.cipherText + secretBox.mac!.bytes;
    return base64.encode(encrypted);
  }

  // Decrypt an encrypted PEM string
  static Future<String> _decryptPem(String encryptedPem, String passphrase) async {
    final encrypted = base64.decode(encryptedPem);
    final salt = encrypted.sublist(0, 16);
    final nonce = encrypted.sublist(16, 16 + aesCbc.nonceLength);
    final ciphertext = encrypted.sublist(16 + aesCbc.nonceLength, encrypted.length - aesCbc.macAlgorithm.macLength);

    final derivedKey = await pbkdf2.deriveKeyFromPassword(
      password: passphrase,
      nonce: salt,
    );
    final secretKey = await derivedKey.extract();

    final secretBox = SecretBox(ciphertext, nonce: nonce, mac: Mac(encrypted.sublist(encrypted.length - aesCbc.macAlgorithm.macLength)));
    final decrypted = await aesCbc.decrypt(secretBox, secretKey: secretKey);
    return utf8.decode(decrypted);
  }

  // Export key to JSON and PEM files
  static Future<void> exportKey(SshKey key, {String? customPath}) async {
    final dir = customPath ?? await _getKeysDirectory();
    final basePath = '$dir/${key.id}';

    final jsonFile = File('$basePath.json');
    await jsonFile.writeAsString(jsonEncode(key.toJson()));

    if (key.publicKey != null) await File('$basePath.pub').writeAsString(key.publicKey!);
    if (key.privateKey != null) await File('$basePath').writeAsString(key.privateKey!);  // Encrypted or plain
  }

  // Import key from JSON file
  static Future<SshKey> importKey(String keyId, {String? customPath}) async {
    final dir = customPath ?? await _getKeysDirectory();
    final jsonFile = File('$dir/$keyId.json');

    if (!await jsonFile.exists()) throw Exception('Key not found');

    final jsonString = await jsonFile.readAsString();
    return SshKey.fromJson(jsonDecode(jsonString));
  }

  // // Helper: Encode RSA private key to PEM
  // static String _encodePrivateKeyToPEM(RSAPrivateKey key) {
  //   final asn1 = key.encodeToASN1();
  //   return '-----BEGIN RSA PRIVATE KEY-----\n' +
  //       base64.encode(asn1.encode()!) +
  //       '\n-----END RSA PRIVATE KEY-----\n';
  // }

  // // Helper: Encode public key to PEM
  // static String _encodePublicKeyToPEM(RSAPublicKey key) {
  //   final asn1 = key.exponent();
  //   return '-----BEGIN PUBLIC KEY-----\n' +
  //       base64.encode(asn1.encode()!) +
  //       '\n-----END PUBLIC KEY-----\n';
  // }

  // Helper: Encode Ed25519 private to PEM
  static String _encodeEd25519PrivateToPEM(List<int> bytes) {
    return '-----BEGIN OPENSSH PRIVATE KEY-----\n' +
        base64.encode(bytes) +
        '\n-----END OPENSSH PRIVATE KEY-----\n';
  }

  // Helper: Encode Ed25519 public to PEM
  static String _encodeEd25519PublicToPEM(List<int> bytes) {
    return '-----BEGIN PUBLIC KEY-----\n' +
        base64.encode(bytes) +
        '\n-----END PUBLIC KEY-----\n';
  }
}