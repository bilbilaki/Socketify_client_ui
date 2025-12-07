import 'dart:async';
import '../core/protocol/command_protocol.dart';
import '../core/transport/transport_interface.dart';
import '../core/transport/websocket_transport.dart';
import '../core/transport/bluetooth_transport.dart';

/// Unified remote control client for mobile
class RemoteClient {
  TransportInterface?  _activeTransport;
  final Map<String, TransportInterface> _transports = {};
  
  final _stateController = StreamController<TransportState>.broadcast();
  Stream<TransportState> get stateStream => _stateController. stream;
  
  TransportState get state => _activeTransport?.state ?? TransportState.disconnected;
  String?  get activeTransportName => _activeTransport?.name;
  
  RemoteClient() {
    // Initialize available transports
    _transports['websocket'] = WebSocketTransport();
    _transports['bluetooth'] = BluetoothTransport();
  }
  
  Future<void> initialize() async {
    for (final transport in _transports.values) {
      if (transport.isAvailable) {
        await transport.initialize();
      }
    }
  }
  
  /// Connect via WebSocket
  Future<void> connectWebSocket(String host, {int port = 8765}) async {
    final transport = _transports['websocket']!;
    await transport.connect('$host:$port');
    _activeTransport = transport;
    _stateController.add(transport.state);
  }
  
  /// Connect via Bluetooth
  Future<void> connectBluetooth(dynamic device) async {
    final transport = _transports['bluetooth']!;
    await transport.connect('', config: {'device': device});
    _activeTransport = transport;
    _stateController.add(transport.state);
  }
  
  /// Disconnect current connection
  Future<void> disconnect() async {
    await _activeTransport?. disconnect();
    _activeTransport = null;
    _stateController.add(TransportState.disconnected);
  }
  
  /// Send command and wait for response
  Future<CommandResponse> send(RemoteCommand command) async {
    if (_activeTransport == null) {
      throw StateError('Not connected');
    }
    return _activeTransport!. sendCommand(command);
  }
  
  // ==================== Convenience Methods ====================
  
  /// Move mouse to absolute position
  Future<Map<String, int>> mouseMove(int x, int y) async {
    final response = await send(RemoteCommand. mouseMove(x, y));
    return Map<String, int>.from(response.data);
  }
  
  /// Move mouse relative to current position
  Future<Map<String, int>> mouseMoveRelative(int dx, int dy) async {
    final response = await send(RemoteCommand.mouseMoveRelative(dx, dy));
    return Map<String, int>.from(response.data);
  }
  
  /// Click mouse button
  Future<void> mouseClick({String button = 'left'}) async {
    await send(RemoteCommand.mouseClick(button: button));
  }
  
  /// Double click
  Future<void> mouseDoubleClick({String button = 'left'}) async {
    await send(RemoteCommand.mouseDoubleClick(button: button));
  }
  
  /// Scroll mouse
  Future<void> mouseScroll(int x, int y) async {
    await send(RemoteCommand.mouseScroll(x, y));
  }
  
  /// Get mouse location
  Future<Map<String, int>> getMouseLocation() async {
    final response = await send(RemoteCommand.getMouseLocation());
    return Map<String, int>.from(response.data);
  }
  
  /// Type a string
  Future<void> typeString(String text) async {
    await send(RemoteCommand.typeString(text));
  }
  
  /// Press a key with optional modifiers
  Future<void> keyTap(String key, {List<String>? modifiers}) async {
    await send(RemoteCommand.keyTap(key, modifiers: modifiers));
  }
  
  /// Execute hotkey combination
  Future<void> hotkey(List<String> keys) async {
    await send(RemoteCommand.hotkey(keys));
  }
  
  /// Get screen size
  Future<Map<String, int>> getScreenSize() async {
    final response = await send(RemoteCommand.getScreenSize());
    return Map<String, int>.from(response. data);
  }
  
  /// Capture screen region as base64
  Future<String> captureScreen(int x, int y, int w, int h) async {
    final response = await send(RemoteCommand.captureScreen(x, y, w, h));
    return response.data as String;
  }
  
  /// Read clipboard
  Future<String> readClipboard() async {
    final response = await send(RemoteCommand.readClipboard());
    return response.data as String;
  }
  
  /// Write to clipboard
  Future<void> writeClipboard(String text) async {
    await send(RemoteCommand.writeClipboard(text));
  }
  
  void dispose() {
    for (final transport in _transports.values) {
      transport. dispose();
    }
    _stateController.close();
  }
}