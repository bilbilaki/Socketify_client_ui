import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/server_config.dart';

class StorageService {
  static const String _serversKey = 'servers';

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

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_serversKey);
  }
}
