import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:client_ui/models/server_config.dart';
import 'package:dartssh2/dartssh2.dart';
import 'package:xterm/xterm.dart';

class TerminalSession {
  final String id;
  final String host;
  final int port;
  final String username;
  final String password;
  final String privKey;
  final ServerConfig? jumpServer;

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
  bool jumpAuthenticated = false;
  List<StreamSubscription> _forwardSubscriptions = [];
  List<ServerSocket> _serverSockets = [];

  TerminalSession(
    this.id,
    this.host,
    this.port,
    this.username,
    this.password,
    this.privKey,
    this.jumpServer,
  ) {
    terminal = Terminal(maxLines: 10000);
  }
  Future<SSHClient?> jumpserv() async {
    SSHClient? jServer;
    terminal.write('Connecting to ${jumpServer!.address}...\r\n');
    if (jumpServer != null) {
      try {
        final socket = await SSHSocket.connect(
          jumpServer!.address,
          jumpServer!.port,
          timeout: Duration(seconds: 20),
        );

        _client = SSHClient(
          socket,
          username: jumpServer!.username,
          onChangePasswordRequest: (prompt) {
            // TODO showing dialog to getting new value from user
            return null;
          },
          onUserauthBanner: (banner) {
            ///TODO  showing it in dialg to user
          },
          onAuthenticated: () => jumpAuthenticated = true,

          ///TODO leter should I add selection of this value in settings like page =>
          keepAliveInterval: const Duration(seconds: 25),
          identities: jumpServer!.privKey != ""
              ? [...SSHKeyPair.fromPem(jumpServer!.privKey ?? "")]
              : [],

          onPasswordRequest: () {
            ///TODO if user not added a password showing a dialog for getting passwrd

            return jumpServer!.password;
          },
        );
        jServer = _client;
        return jServer;
      } catch (e) {
        print(e);
      }
      return jServer;
    }
    return jServer;
  }

  Future<void> connect() async {
    terminal.write('Connecting to $host...\r\n');
    try {
      if (jumpServer != null) {
        final jump = await jumpserv();
        if (jump != null) {
          _client = SSHClient(
            await jump.forwardLocal(host, port),
            username: username,
            onChangePasswordRequest: (prompt) {
              // TODO showing dialog to getting new value from user
              return null;
            },
            onUserauthBanner: (banner) {
              ///TODO  showing it in dialg to user
            },
            onAuthenticated: () => authenticated = true,

            ///TODO leter should I add selection of this value in settings like page =>
            keepAliveInterval: const Duration(seconds: 35),
            identities: privKey != "" ? [...SSHKeyPair.fromPem(privKey)] : [],

            onPasswordRequest: () {
              ///TODO if user not added a password showing a dialog for getting passwrd

              return password;
            },
          );
        }

        ///TODO showing user connecting to jumpserver is faild and you can retry or cancell or if you want forgot jump instead walk haha
      } else {
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
            return null;
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
      }
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

  Future<void> setupConnection() async {
    if (_client != null && !_client!.isClosed) {
      return; // Already connected
    }
    terminal.write('Setting up connection to $host...\r\n');
    try {
      if (jumpServer != null) {
        final jump = await jumpserv();
        if (jump != null) {
          _client = SSHClient(
            await jump.forwardLocal(host, port),
            username: username,
            onChangePasswordRequest: (prompt) {
              // TODO showing dialog to getting new value from user
              return null;
            },
            onUserauthBanner: (banner) {
              ///TODO  showing it in dialg to user
            },
            onAuthenticated: () => authenticated = true,

            ///TODO leter should I add selection of this value in settings like page =>
            keepAliveInterval: const Duration(seconds: 35),
            identities: privKey != "" ? [...SSHKeyPair.fromPem(privKey)] : [],

            onPasswordRequest: () {
              ///TODO if user not added a password showing a dialog for getting passwrd

              return password;
            },
          );
        } else {
          throw Exception('Failed to connect to jumpserver');
        }
      } else {
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
            return null;
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
      }
      terminal.write('Connection established for port forwarding.\r\n');
      isConnected = true;
      _startKeepAlive(); // Keep alive for forwardings
    } catch (e) {
      terminal.write('Error: $e\r\n');
    }
  }

  Future<void> forwardLocalToRemote(
    int localPort,
    String remoteHost,
    int remotePort,
  ) async {
    await setupConnection();
    if (_client == null) return;

    try {
      final serverSocket = await ServerSocket.bind('localhost', localPort);
      _serverSockets.add(serverSocket);
      terminal.write(
        'Forwarding local port $localPort to $remoteHost:$remotePort...\r\n',
      );

      final subscription = serverSocket.listen((socket) async {
        final forward = await _client!.forwardLocal(remoteHost, remotePort);
        forward.stream.cast<List<int>>().listen(
          (data) => socket.add(data),
          onDone: () => socket.close(),
          onError: (e) => socket.close(),
        );
        socket.listen(
          (data) => forward.sink.add(data),
          onDone: () => forward.sink.close(),
          onError: (e) => forward.sink.close(),
        );
      });

      _forwardSubscriptions.add(subscription);
    } catch (e) {
      terminal.write('Error in local to remote forward: $e\r\n');
    }
  }

  Future<void> forwardRemoteToLocal(int remotePort, int localPort) async {
    await setupConnection();
    if (_client == null) return;

    try {
      final forward = await _client!.forwardRemote(port: remotePort);
      if (forward == null) {
        terminal.write('Failed to forward remote port $remotePort\r\n');
        return;
      }

      terminal.write(
        'Forwarding remote port $remotePort to local port $localPort...\r\n',
      );

      final subscription = forward.connections.listen((connection) async {
        final socket = await Socket.connect('localhost', localPort);
        connection.stream.cast<List<int>>().listen(
          (data) => socket.add(data),
          onDone: () => socket.close(),
          onError: (e) => socket.close(),
        );
        socket.listen(
          (data) => connection.sink.add(data),
          onDone: () => connection.sink.close(),
          onError: (e) => connection.sink.close(),
        );
      });

      _forwardSubscriptions.add(subscription);
    } catch (e) {
      terminal.write('Error in remote to local forward: $e\r\n');
    }
  }

  // Method to stop all port forwardings
  void stopAllForwardings() {
    for (var sub in _forwardSubscriptions) {
      sub.cancel();
    }
    _forwardSubscriptions.clear();
    for (var socket in _serverSockets) {
      socket.close();
    }
    _serverSockets.clear();
    terminal.write('All port forwardings stopped.\r\n');
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
    stopAllForwardings();
  }
}
