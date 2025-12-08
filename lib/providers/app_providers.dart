import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:uuid/uuid.dart';
import '../models/server_config.dart';
import '../models/ssh_key_model.dart';
import '../services/storage_service.dart';
import '../services/terminal_session.dart';

// Storage service provider
final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

// Server list state notifier
class ServerListNotifier extends StateNotifier<AsyncValue<List<ServerConfig>>> {
  final StorageService _storageService;

  ServerListNotifier(this._storageService) : super(const AsyncValue.loading()) {
    loadServers();
  }

  Future<void> loadServers() async {
    state = const AsyncValue.loading();
    try {
      final servers = await _storageService.loadServers();
      state = AsyncValue.data(servers);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addServer(ServerConfig server) async {
    await _storageService.addServer(server);
    await loadServers();
  }

  Future<void> updateServer(ServerConfig server) async {
    await _storageService.updateServer(server);
    await loadServers();
  }

  Future<void> deleteServer(String id) async {
    await _storageService.deleteServer(id);
    await loadServers();
  }

  Future<void> duplicateServer(String id) async {
    final servers = state.value ?? [];
    final original = servers.firstWhere((s) => s.id == id);
    final duplicate = original.copyWith(
      id: const Uuid().v4(),
      name: '${original.name} (Copy)',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await addServer(duplicate);
  }
}

// Server list provider
final serverListProvider =
    StateNotifierProvider<ServerListNotifier, AsyncValue<List<ServerConfig>>>((
      ref,
    ) {
      final storageService = ref.watch(storageServiceProvider);
      return ServerListNotifier(storageService);
    });

// Current navigation index provider
final navigationIndexProvider = StateProvider<int>((ref) => 0);

// Terminal sessions list provider
class SessionsListNotifier extends StateNotifier<List<TerminalSession>> {
  SessionsListNotifier() : super([]);

  void addSession(TerminalSession session) {
    state = [...state, session];
  }

  Future<void> removeSession(String sessionId) async {
    final sessions = state.where((s) => s.id == sessionId).toList();
    if (sessions.isNotEmpty) {
      print('Disposing session: $sessionId');
      await sessions.first.dispose();
    }
    state = state.where((s) => s.id != sessionId).toList();
    print('Sessions remaining: ${state.length}');
  }

  void updateSession(String sessionId, TerminalSession updatedSession) {
    state = state.map((s) => s.id == sessionId ? updatedSession : s).toList();
  }
}

// Terminal sessions provider
final sessionsProvider =
    StateNotifierProvider<SessionsListNotifier, List<TerminalSession>>((ref) {
      return SessionsListNotifier();
    });

// Active session index provider
final activeSessionIndexProvider = StateProvider<int>((ref) => 0);

// SSH Keys list provider
// SSH Keys list state notifier (updated to be persistent and async like ServerListNotifier)
class SshKeysListNotifier extends StateNotifier<AsyncValue<List<SshKey>>> {
  final StorageService _storageService;

  SshKeysListNotifier(this._storageService) : super(const AsyncValue.loading()) {
    loadKeys();
  }

  Future<void> loadKeys() async {
    state = const AsyncValue.loading();
    try {
      final keys = await _storageService.loadKeys();
      state = AsyncValue.data(keys);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addKey(SshKey key) async {
    await _storageService.addKey(key);
    await loadKeys(); // Reload to ensure state is updated
  }

  Future<void> updateKey(SshKey key) async {
    await _storageService.updateKey(key);
    await loadKeys();
  }

  Future<void> removeKey(String id) async {
    await _storageService.removeKey(id);
    await loadKeys();
  }

  Future<void> duplicateKey(String id) async {
    final keys = state.value ?? [];
    final original = keys.firstWhere((k) => k.id == id);
    final duplicate = original.copyWith(
      id: const Uuid().v4(),
      name: '${original.name} (Copy)',
      createdAt: DateTime.now(),
    );
    await addKey(duplicate);
  }

  Future<void> clearAllKeys() async {
    await _storageService.clearAllKeys();
    state = AsyncValue.data([]); // Clear in-memory state immediately
  }

  Future<SshKey?> getKeyById(String id) async {
    final keys = state.value ?? [];
    return keys.where((key) => key.id == id).cast<SshKey?>().firstWhere(
      (element) => true,
      orElse: () => null,
    );
  }

  Future<SshKey?> getKeyByName(String name) async {
    final keys = state.value ?? [];
    return keys.where((key) => key.name == name).cast<SshKey?>().firstWhere(
      (element) => true,
      orElse: () => null,
    );
  }
}

// SSH Keys provider (updated to use StateNotifierProvider with AsyncValue)
final sshKeysProvider =
    StateNotifierProvider<SshKeysListNotifier, AsyncValue<List<SshKey>>>((ref) {
      final storageService = ref.watch(storageServiceProvider);
      return SshKeysListNotifier(storageService);
    });

// ... (Keep selectedSshKeyProvider unchanged)