import 'dart:async';
import 'dart:io';
import 'dart:ffi' as ffi;
import 'dart:isolate';
import 'dart:convert';
import 'package:ffi/ffi.dart';
import '../bindings/generated_bindings_for_sshkeygen.dart';

/// Service for loading and interacting with the SSHKeygen native library
class SSHKeygenService {
  late final SSHKeygenLibrary _bindings;
  late final ffi.DynamicLibrary _dylib;
  ReceivePort? _receivePort;
  int _nativePort = 0;
  final Map<String, Function(Map<String, dynamic>)> _responseHandlers = {};

  /// Singleton instance
  static SSHKeygenService? _instance;

  factory SSHKeygenService() {
    _instance ??= SSHKeygenService._internal();
    return _instance!;
  }

  SSHKeygenService._internal();

  /// Initialize the library and setup communication bridge
  Future<void> initialize() async {
    _dylib = _loadLibrary();
    _bindings = SSHKeygenLibrary(_dylib);

    // Setup receive port for callbacks from Go
    _receivePort = ReceivePort();
    _nativePort = _receivePort!.sendPort.nativePort;

    // Initialize the Dart API in Go
    final dartApiDL = ffi.NativeApi.initializeApiDLData;
    _bindings.BridgeInit(dartApiDL);

    // Register the port
    _bindings.RegisterPort(_nativePort);

    // Listen for messages from Go
    _receivePort!.listen(_handleNativeMessage);

    print('SSHKeygenService initialized successfully');
  }

  /// Load the appropriate dynamic library based on platform
  ffi.DynamicLibrary _loadLibrary() {
    if (Platform.isAndroid){
          try {
        return ffi.DynamicLibrary.open("libssl.so");
 } catch (e) {
        return ffi.DynamicLibrary.open("libssl.so");
      }
    }
   else if (Platform.isWindows) {
      // Try multiple paths for Windows
      try {
        return ffi.DynamicLibrary.open('native/windows/sshKeyGen.dll');
      } catch (e) {
        return ffi.DynamicLibrary.open('sshkeygen.dll');
      }
    } else if (Platform.isLinux) {
      try {
        return ffi.DynamicLibrary.open('native/linux/sshkeygen.so');
      } catch (e) {
        return ffi.DynamicLibrary.open('./sshkeygen.so');
      }
    } else if (Platform.isMacOS) {
      try {
        return ffi.DynamicLibrary.open('native/macos/sshkeygen.dylib');
      } catch (e) {
        return ffi.DynamicLibrary.open('./sshkeygen.dylib');
      }
    }
    throw UnsupportedError('Unsupported platform: ${Platform.operatingSystem}');
  }

 /// Handle messages from native library
  void _handleNativeMessage(dynamic message) {
    if (message is String) {
      try {
        final data = jsonDecode(message);
        final op = data['op'] as String?;

        if (op != null && _responseHandlers.containsKey(op)) {
          _responseHandlers[op]!(data);
          _responseHandlers.remove(op);
        } else {
          print('Received: $message');
        }
      } catch (e) {
        // Not JSON, just a simple message
        print('SSHKeygen Native: $message');
      }
    }
  }

  /// Dispose resources
  void dispose() {
    _bindings.UnregisterPort();
    _receivePort?.close();
    _receivePort = null;
  }

  // ==================== SSH KEYGEN OPERATIONS ====================

  /// Generate an SSH key
  ///
  /// [keytype] - Type of key (e.g., "rsa", "ed25519")
  /// [keyfile] - Path to save the key file
  /// [comment] - Comment for the key
  /// [size] - Key size (applicable for RSA)
  /// [password] - Password for encrypting the key (optional, can be empty)
  ///
  /// Returns a map containing the generated key information (private_key_file, public_key_file, key_type, comment)
  Future<Map<String, dynamic>> generateKey({
    required String keytype,
    required String keyfile,
    required String comment,
    required int size,
    String password = '',
  }) {
    final completer = Completer<Map<String, dynamic>>();
    _responseHandlers['generate_key'] = (data) {
      if (data['success'] == true) {
        completer.complete(Map<String, dynamic>.from(data['data']));
      } else {
        completer.completeError(data['error'] ?? 'Unknown error');
      }
    };

    final keytypePtr = keytype.toNativeUtf8().cast<ffi.Char>();
    final keyfilePtr = keyfile.toNativeUtf8().cast<ffi.Char>();
    final commentPtr = comment.toNativeUtf8().cast<ffi.Char>();
    final passwordPtr = password.toNativeUtf8().cast<ffi.Char>();

    _bindings.GenerateKey(
      keytypePtr,
      keyfilePtr,
      commentPtr,
      size,
      passwordPtr,
      _nativePort,
    );

    malloc.free(keytypePtr);
    malloc.free(keyfilePtr);
    malloc.free(commentPtr);
    malloc.free(passwordPtr);

    return completer.future;
  }

  /// Get the fingerprint of an SSH key
  ///
  /// [keyfile] - Path to the key file
  /// [keytype] - Type of key (e.g., "rsa", "ed25519")
  ///
  /// Returns a map containing fingerprint information (size, fingerprint, comment, key_type)
  Future<Map<String, dynamic>> getFingerprint({
    required String keyfile,
    required String keytype,
  }) {
    final completer = Completer<Map<String, dynamic>>();
    _responseHandlers['get_fingerprint'] = (data) {
      if (data['success'] == true) {
        completer.complete(Map<String, dynamic>.from(data['data']));
      } else {
        completer.completeError(data['error'] ?? 'Unknown error');
      }
    };

    final keyfilePtr = keyfile.toNativeUtf8().cast<ffi.Char>();
    final keytypePtr = keytype.toNativeUtf8().cast<ffi.Char>();

    _bindings.GetFingerprint(keyfilePtr, keytypePtr, _nativePort);

    malloc.free(keyfilePtr);
    malloc.free(keytypePtr);

    return completer.future;
  }

  /// Stop a running task by its task ID
  ///
  /// [taskID] - Task ID
  void stopTask(int taskID) {
    _bindings.StopTask(taskID, _nativePort);
  }
}