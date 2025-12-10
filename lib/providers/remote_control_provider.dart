import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/remote_control_client.dart';

// Singleton instance provider
final remoteControlClientProvider = Provider<RemoteControlClient>((ref) {
  return RemoteControlClient();
});

// Connected state - uses ValueNotifier from client directly
final remoteConnectedProvider = FutureProvider<bool>((ref) async {
  final client = ref.watch(remoteControlClientProvider);
  return client.connected.value;
});

// Active server provider
final activeServerProvider = FutureProvider<String?>((ref) async {
  final client = ref.watch(remoteControlClientProvider);
  return client.activeServer.value;
});

// Connecting state provider
final connectingStateProvider = FutureProvider<bool>((ref) async {
  final client = ref.watch(remoteControlClientProvider);
  return client.isConnecting.value;
});

// Error message provider
final errorMessageProvider = FutureProvider<String?>((ref) async {
  final client = ref.watch(remoteControlClientProvider);
  return client.errorMessage.value;
});

// Command history provider
final commandHistoryProvider = FutureProvider<List<String>>((ref) async {
  final client = ref.watch(remoteControlClientProvider);
  return client.commandHistory.value;
});

// Mouse position provider
final mousePositionProvider = FutureProvider<(double, double)>((ref) async {
  final client = ref.watch(remoteControlClientProvider);
  return (client.mouseX.value, client.mouseY.value);
});
