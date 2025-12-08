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
class SshKeysListNotifier extends StateNotifier<List<SshKey>> {
  SshKeysListNotifier() : super([]);

  void addKey(SshKey key) {
    state = [...state, key];
  }

  void removeKey(String keyId) {
    state = state.where((k) => k.id != keyId).toList();
  }

  void updateKey(String keyId, SshKey updatedKey) {
    state = state.map((k) => k.id == keyId ? updatedKey : k).toList();
  }

  void setKeys(List<SshKey> keys) {
    state = keys;
  }
}

final sshKeysProvider =
    StateNotifierProvider<SshKeysListNotifier, List<SshKey>>((ref) {
      return SshKeysListNotifier();
    });

// Selected SSH key for server provider
final selectedSshKeyProvider = StateProvider<String?>((ref) => null);
