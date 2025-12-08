import 'dart:async';
import 'dart:convert';
import 'package:dartssh2/dartssh2.dart';
import 'package:xterm/xterm.dart';

class TerminalSession {
  final String id;
  final String host;
  final int port;
  final String username;
  final String password;
  final String privKey;

  // The UI Engine for this specific tab
  late final Terminal terminal;

  // The actual SSH connection
  SSHClient? _client;

  // The active SSH session
  SSHSession? _session;

  // KeepAlive timer
  Timer? _keepAliveTimer;

  // Connection Status
  bool isConnected = false;

  // Reconnection flag
  bool _isReconnecting = false;
  bool authenticated = false;
  TerminalSession(this.id, this.host, this.port, this.username, this.password, this.privKey) {
    terminal = Terminal(maxLines: 10000);
  }

  Future<void> connect() async {
    terminal.write('Connecting to $host...\r\n');

    try {
      final socket = await SSHSocket.connect(
        host,
        port,
        timeout: Duration(seconds: 20),
      );

      _client = SSHClient(
        socket,
        username: username,
        onChangePasswordRequest: (prompt) {
          // TODO showing dialog to getting new value from user
        },
        onUserauthBanner: (banner) {
          ///TODO  showing it in dialg to user
        },
        onAuthenticated: () => authenticated = true,

        ///TODO leter should I add selection of this value in settings like page =>
        keepAliveInterval: const Duration(seconds: 35),
        identities: [...SSHKeyPair.fromPem(privKey)],

        onPasswordRequest: () {
          ///TODO if user not added a password showing a dialog for getting passwrd

          return password;
        },
      );

      terminal.write('Connected.\r\n');
      isConnected = true;
      _isReconnecting = false;

      // Start the shell with specific dimensions
      _session = await _client!.shell(
        pty: SSHPtyConfig(
          width: terminal.viewWidth,
          height: terminal.viewHeight,
        ),
      );

      // 1. Pipe SSH Output -> Terminal
      _session!.stdout.listen(
        (data) {
          terminal.write(utf8.decode(data));
        },
        onDone: _onDisconnected,
        onError: (e) => _onDisconnected(),
      );

      _session!.stderr.listen((data) {
        terminal.write(utf8.decode(data));
      });

      // 2. Pipe Terminal Input -> SSH
      terminal.onOutput = (input) {
        if (_client != null && !_client!.isClosed && _session != null) {
          // Check if user pressed Enter while disconnected
          if (!isConnected && input.trim().isEmpty) {
            _attemptReconnect();
            return;
          }

          _session!.write(utf8.encode(input));
        }
      };

      // 3. Start KeepAlive (Crucial for mobile)
      _startKeepAlive();
    } catch (e) {
      terminal.write('Error: $e\r\n');
      _onDisconnected();
    }
  }

  void _startKeepAlive() {
    _keepAliveTimer = Timer.periodic(Duration(seconds: 15), (timer) async {
      if (_client == null || _client!.isClosed) {
        timer.cancel();
        _keepAliveTimer = null;
        return;
      }
      // Send a ping to keep the NAT traversal open
      try {
        await _client!.ping();
      } catch (_) {
        _onDisconnected();
      }
    });
  }

  void _onDisconnected() {
    if (!isConnected) return; // Already disconnected
    isConnected = false;
    terminal.write(
      '\r\n\x1b[31m⚠️ Connection Lost. Press Enter to reconnect...\x1b[0m\r\n',
    );
  }

  Future<void> _attemptReconnect() async {
    if (_isReconnecting) {
      terminal.write('Reconnection in progress...\r\n');
      return;
    }

    _isReconnecting = true;
    terminal.write('\r\nAttempting to reconnect...\r\n');

    try {
      // Clean up old connection
      await dispose();

      // Attempt new connection
      await connect();
      terminal.write('✓ Reconnected successfully!\r\n');
    } catch (e) {
      _isReconnecting = false;
      terminal.write(
        '\r\n\x1b[31m✗ Reconnection failed: $e\r\nPress Enter to try again...\x1b[0m\r\n',
      );
      isConnected = false;
    }
  }

  Future<void> dispose() async {
    _keepAliveTimer?.cancel();
    _keepAliveTimer = null;
    try {
      _session?.close();
      _session = null;
    } catch (_) {}
    try {
      _client?.close();
      _client = null;
    } catch (_) {}
  }
}
