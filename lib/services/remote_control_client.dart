import 'dart:async';
import 'package:flutter/foundation.dart';
import '../core/transport/websocket_transport.dart';
import '../core/transport/transport_interface.dart';
import '../core/protocol/command_protocol.dart';

/// Remote control client with multi-transport support
class RemoteControlClient {
  static final RemoteControlClient _instance = RemoteControlClient._();

  factory RemoteControlClient() {
    return _instance;
  }

  RemoteControlClient._() {
    _transport = WebSocketTransport();
    _setupTransportListeners();
  }

  // Transport layer
  late WebSocketTransport _transport;

  // Shared state notifiers for widgets
  final connected = ValueNotifier<bool>(false);
  final isConnecting = ValueNotifier<bool>(false);
  final errorMessage = ValueNotifier<String?>('');
  final activeServer = ValueNotifier<String?>('');
  final mouseX = ValueNotifier<double>(0);
  final mouseY = ValueNotifier<double>(0);

  TransportState _state = TransportState.disconnected;
  TransportState get state => _state;

  // Command history
  final commandHistory = ValueNotifier<List<String>>([]);

  void _setupTransportListeners() {
    _transport.events.listen((event) {
      if (event is TransportConnectedEvent) {
        connected.value = true;
        isConnecting.value = false;
        _state = TransportState.connected;
        errorMessage.value = '';
      } else if (event is TransportDisconnectedEvent) {
        connected.value = false;
        isConnecting.value = false;
        _state = TransportState.disconnected;
      } else if (event is TransportErrorEvent) {
        errorMessage.value = event.error;
        _state = TransportState.error;
        isConnecting.value = false;
      }
    });
  }

  /// Connect to a server via specified protocol
  Future<void> connect(String host, {int port = 8765}) async {
    try {
      isConnecting.value = true;
      errorMessage.value = '';
      _state = TransportState.connecting;

      final target = 'ws://$host:$port';
      await _transport.connect(target);

      activeServer.value = '$host:$port';
    } catch (e) {
      _state = TransportState.error;
      errorMessage.value = e.toString();
      connected.value = false;
    } finally {
      isConnecting.value = false;
    }
  }

  /// Disconnect from server
  Future<void> disconnect() async {
    try {
      isConnecting.value = true;
      await _transport.disconnect();
      connected.value = false;
      activeServer.value = '';
      _state = TransportState.disconnected;
      errorMessage.value = '';
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isConnecting.value = false;
    }
  }

  // ==================== Mouse Commands ====================

  /// Move mouse relative to current position
  Future<void> mouseMoveRelative(int deltaX, int deltaY) async {
    if (!connected.value) return;
    mouseX.value += deltaX;
    mouseY.value += deltaY;
    _recordCommand('Mouse Move: +$deltaX, +$deltaY');

    final command = RemoteCommand.mouseMoveRelative(deltaX, deltaY);
    try {
      await _transport.sendCommand(command);
    } catch (e) {
      errorMessage.value = 'Failed to send mouse move: $e';
    }
  }

  /// Click mouse button (1=left, 2=right, 3=middle)
  Future<void> mouseClick({int button = 1}) async {
    if (!connected.value) return;
    final buttonName = ['left', 'right', 'middle'][button - 1];
    _recordCommand(
      '${buttonName[0].toUpperCase()}${buttonName.substring(1)} Click',
    );

    final command = RemoteCommand.mouseClick(button: buttonName);
    try {
      await _transport.sendCommand(command);
    } catch (e) {
      errorMessage.value = 'Failed to send mouse click: $e';
    }
  }

  /// Double click
  Future<void> mouseDoubleClick({int button = 1}) async {
    if (!connected.value) return;
    _recordCommand('Double Click');

    final buttonName = ['left', 'right', 'middle'][button - 1];
    final command = RemoteCommand.mouseDoubleClick(button: buttonName);
    try {
      await _transport.sendCommand(command);
    } catch (e) {
      errorMessage.value = 'Failed to send double click: $e';
    }
  }

  /// Scroll wheel
  Future<void> mouseScroll(int delta) async {
    if (!connected.value) return;
    _recordCommand('Scroll: ${delta > 0 ? 'Up' : 'Down'}');

    final command = RemoteCommand.mouseScroll(0, delta);
    try {
      await _transport.sendCommand(command);
    } catch (e) {
      errorMessage.value = 'Failed to send scroll: $e';
    }
  }

  // ==================== Keyboard Commands ====================

  /// Type text string
  Future<void> typeString(String text) async {
    if (!connected.value) return;
    _recordCommand('Type: "$text"');

    final command = RemoteCommand.typeString(text);
    try {
      await _transport.sendCommand(command);
    } catch (e) {
      errorMessage.value = 'Failed to send text: $e';
    }
  }

  /// Press single key
  Future<void> keyPress(String key) async {
    if (!connected.value) return;
    _recordCommand('Key Press: $key');

    final command = RemoteCommand.keyTap(key);
    try {
      await _transport.sendCommand(command);
    } catch (e) {
      errorMessage.value = 'Failed to send key press: $e';
    }
  }

  /// Hotkey combination (e.g., Ctrl+C)
  Future<void> hotkey(List<String> keys) async {
    if (!connected.value) return;
    _recordCommand('Hotkey: ${keys.join("+")}');

    final command = RemoteCommand.hotkey(keys);
    try {
      await _transport.sendCommand(command);
    } catch (e) {
      errorMessage.value = 'Failed to send hotkey: $e';
    }
  }

  // ==================== Special Keys ====================

  Future<void> pressEscape() => keyPress('escape');
  Future<void> pressEnter() => keyPress('return');
  Future<void> pressTab() => keyPress('tab');
  Future<void> pressBackspace() => keyPress('backspace');
  Future<void> pressDelete() => keyPress('delete');
  Future<void> pressSpace() => keyPress('space');

  Future<void> pressArrowUp() => keyPress('up');
  Future<void> pressArrowDown() => keyPress('down');
  Future<void> pressArrowLeft() => keyPress('left');
  Future<void> pressArrowRight() => keyPress('right');

  Future<void> pressCopy() => hotkey(['cmd', 'c']);
  Future<void> pressPaste() => hotkey(['cmd', 'v']);
  Future<void> pressCut() => hotkey(['cmd', 'x']);
  Future<void> pressUndo() => hotkey(['cmd', 'z']);
  Future<void> pressSelectAll() => hotkey(['cmd', 'a']);
  Future<void> pressSave() => hotkey(['cmd', 's']);

  // ==================== Screen Capture ====================

  /// Capture full screen and get base64 encoded image
  Future<CommandResponse> captureFullScreen() async {
    if (!connected.value) {
      throw StateError('Not connected');
    }

    final command = RemoteCommand(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      category: CommandCategory.screen,
      operation: ScreenOp.captureBase64.code,
      params: {
        'x': 0,
        'y': 0,
        'w': 1980, // 0 means full width
        'h': 1280, // 0 means full height
      },
    );

    _recordCommand('Capture Screen');
    return await _transport.sendCommand(command);
  }

  /// Capture specific screen region and get base64 encoded image
  Future<CommandResponse> captureRegion(
    int x,
    int y,
    int width,
    int height,
  ) async {
    if (!connected.value) {
      throw StateError('Not connected');
    }

    final command = RemoteCommand(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      category: CommandCategory.screen,
      operation: ScreenOp.captureRegion.code,
      params: {'x': x, 'y': y, 'w': width, 'h': height, 'path': './img.png'},
    );

    _recordCommand('Capture Region: x=$x, y=$y, w=$width, h=$height');
    return await _transport.sendCommand(command);
  }

  /// Clear command history
  void clearHistory() {
    commandHistory.value = [];
  }

  void _recordCommand(String command) {
    final history = [...commandHistory.value, command];
    if (history.length > 50) {
      history.removeAt(0);
    }
    commandHistory.value = history;
  }

  void dispose() {
    _transport.dispose();
    connected.dispose();
    isConnecting.dispose();
    errorMessage.dispose();
    activeServer.dispose();
    mouseX.dispose();
    mouseY.dispose();
    commandHistory.dispose();
  }
}
