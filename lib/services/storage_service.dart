import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/server_config.dart';
import '../models/ssh_key_model.dart'; // Assuming this is the SSH key model from your previous code

class StorageService {
  static const String _serversKey = 'servers';
  static const String _keysKey = 'ssh_keys'; // Added for SSH keys

  // ==================== SERVER METHODS ====================

  Future<List<ServerConfig>> loadServers() async {
    final prefs = await SharedPreferences.getInstance();
    final String? serversJson = prefs.getString(_serversKey);

    if (serversJson == null) {
      return [];
    }

    final List<dynamic> decoded = json.decode(serversJson);
    return decoded.map((json) => ServerConfig.fromJson(json)).toList();
  }

  Future<void> saveServers(List<ServerConfig> servers) async {
    final prefs = await SharedPreferences.getInstance();
    final List<Map<String, dynamic>> jsonList = servers
        .map((server) => server.toJson())
        .toList();
    final String encoded = json.encode(jsonList);
    await prefs.setString(_serversKey, encoded);
  }

  Future<void> addServer(ServerConfig server) async {
    final servers = await loadServers();
    servers.add(server);
    await saveServers(servers);
  }

  Future<void> updateServer(ServerConfig server) async {
    final servers = await loadServers();
    final index = servers.indexWhere((s) => s.id == server.id);
    if (index != -1) {
      servers[index] = server;
      await saveServers(servers);
    }
  }

  Future<void> deleteServer(String id) async {
    final servers = await loadServers();
    servers.removeWhere((s) => s.id == id);
    await saveServers(servers);
  }

  Future<void> clearAllServers() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_serversKey);
  }

  // Added: Get server by ID
  Future<ServerConfig?> getServerById(String id) async {
    final servers = await loadServers();
    return servers.where((server) => server.id == id).cast<ServerConfig?>().firstWhere(
      (element) => true,
      orElse: () => null,
    );
  }

  // ==================== SSH KEY METHODS ====================

  Future<List<SshKey>> loadKeys() async {
    final prefs = await SharedPreferences.getInstance();
    final String? keysJson = prefs.getString(_keysKey);

    if (keysJson == null) {
      return [];
    }

    final List<dynamic> decoded = json.decode(keysJson);
    return decoded.map((json) => SshKey.fromJson(json)).toList();
  }

  Future<void> saveKeys(List<SshKey> keys) async {
    final prefs = await SharedPreferences.getInstance();
    final List<Map<String, dynamic>> jsonList = keys
        .map((key) => key.toJson())
        .toList();
    final String encoded = json.encode(jsonList);
    await prefs.setString(_keysKey, encoded);
  }

  Future<void> addKey(SshKey key) async {
    final keys = await loadKeys();
    keys.add(key);
    await saveKeys(keys);
  }

  Future<void> updateKey(SshKey key) async {
    final keys = await loadKeys();
    final index = keys.indexWhere((k) => k.id == key.id);
    if (index != -1) {
      keys[index] = key;
      await saveKeys(keys);
    }
  }

  Future<void> removeKey(String id) async {
    final keys = await loadKeys();
    keys.removeWhere((k) => k.id == id);
    await saveKeys(keys);
  }

  Future<void> clearAllKeys() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keysKey);
  }

  // Get key by ID
  Future<SshKey?> getKeyById(String id) async {
    final keys = await loadKeys();
    return keys.where((key) => key.id == id).cast<SshKey?>().firstWhere(
      (element) => true,
      orElse: () => null,
    );
  }

  // Get key by name
  Future<SshKey?> getKeyByName(String name) async {
    final keys = await loadKeys();
    return keys.where((key) => key.name == name).cast<SshKey?>().firstWhere(
      (element) => true,
      orElse: () => null,
    );
  }
}