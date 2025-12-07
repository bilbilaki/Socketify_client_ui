import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/scene/data_model.dart';
import '../dartblock/dart_block_types.dart';

/// Metadata for a saved scene
class SceneMeta {
  final String id;
  final String name;
  final DateTime savedAt;
  final String? description;

  SceneMeta({
    required this.id,
    required this.name,
    required this.savedAt,
    this.description,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'savedAt': savedAt.toIso8601String(),
    'description': description,
  };

  factory SceneMeta.fromJson(Map<String, dynamic> json) {
    return SceneMeta(
      id: json['id'] as String,
      name: json['name'] as String,
      savedAt: DateTime.parse(json['savedAt'] as String),
      description: json['description'] as String?,
    );
  }
}

/// Complete scene data for saving/loading
class SceneData {
  final SceneMeta meta;
  final Map<String, dynamic> sceneJson;
  final Map<String, dynamic> framesJson;
  final double sceneScale;
  final Offset sceneOffset;

  SceneData({
    required this.meta,
    required this.sceneJson,
    required this.framesJson,
    required this.sceneScale,
    required this.sceneOffset,
  });

  Map<String, dynamic> toJson() => {
    'meta': meta.toJson(),
    'scene': sceneJson,
    'frames': framesJson,
    'sceneScale': sceneScale,
    'sceneOffsetX': sceneOffset.dx,
    'sceneOffsetY': sceneOffset.dy,
  };

  factory SceneData.fromJson(Map<String, dynamic> json) {
    return SceneData(
      meta: SceneMeta.fromJson(json['meta'] as Map<String, dynamic>),
      sceneJson: json['scene'] as Map<String, dynamic>,
      framesJson: json['frames'] as Map<String, dynamic>,
      sceneScale: (json['sceneScale'] as num?)?.toDouble() ?? 1.0,
      sceneOffset: Offset(
        (json['sceneOffsetX'] as num?)?.toDouble() ?? 0.0,
        (json['sceneOffsetY'] as num?)?.toDouble() ?? 0.0,
      ),
    );
  }
}

/// Service for saving and loading scenes
class SceneStorageService {
  static const String _scenesListKey = 'scene_list';
  static const String _sceneDataPrefix = 'scene_data_';
  static const String _lastOpenedKey = 'last_opened_scene';
  static const String _autoSaveKey = 'auto_save_scene';

  SharedPreferences? _prefs;

  Future<SharedPreferences> get prefs async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  /// Get list of all saved scenes (metadata only)
  Future<List<SceneMeta>> getSavedScenes() async {
    final p = await prefs;
    final listJson = p.getString(_scenesListKey);
    if (listJson == null) return [];

    final list = jsonDecode(listJson) as List<dynamic>;
    return list
        .map((e) => SceneMeta.fromJson(e as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.savedAt.compareTo(a.savedAt)); // newest first
  }

  /// Save a scene
  Future<void> saveScene(SceneData data) async {
    final p = await prefs;

    // Save scene data
    final dataJson = jsonEncode(data.toJson());
    await p.setString('$_sceneDataPrefix${data.meta.id}', dataJson);

    // Update scenes list
    final scenes = await getSavedScenes();
    final existingIndex = scenes.indexWhere((s) => s.id == data.meta.id);
    if (existingIndex >= 0) {
      scenes[existingIndex] = data.meta;
    } else {
      scenes.insert(0, data.meta);
    }

    final listJson = jsonEncode(scenes.map((s) => s.toJson()).toList());
    await p.setString(_scenesListKey, listJson);

    // Update last opened
    await p.setString(_lastOpenedKey, data.meta.id);
  }

  /// Load a scene by id
  Future<SceneData?> loadScene(String id) async {
    final p = await prefs;
    final dataJson = p.getString('$_sceneDataPrefix$id');
    if (dataJson == null) return null;

    final data = SceneData.fromJson(
      jsonDecode(dataJson) as Map<String, dynamic>,
    );

    // Update last opened
    await p.setString(_lastOpenedKey, id);

    return data;
  }

  /// Delete a scene
  Future<void> deleteScene(String id) async {
    final p = await prefs;

    // Remove scene data
    await p.remove('$_sceneDataPrefix$id');

    // Update scenes list
    final scenes = await getSavedScenes();
    scenes.removeWhere((s) => s.id == id);

    final listJson = jsonEncode(scenes.map((s) => s.toJson()).toList());
    await p.setString(_scenesListKey, listJson);
  }

  /// Get last opened scene id
  Future<String?> getLastOpenedSceneId() async {
    final p = await prefs;
    return p.getString(_lastOpenedKey);
  }

  /// Save auto-save data (temporary)
  Future<void> saveAutoSave(SceneData data) async {
    final p = await prefs;
    final dataJson = jsonEncode(data.toJson());
    await p.setString(_autoSaveKey, dataJson);
  }

  /// Load auto-save data
  Future<SceneData?> loadAutoSave() async {
    final p = await prefs;
    final dataJson = p.getString(_autoSaveKey);
    if (dataJson == null) return null;

    return SceneData.fromJson(jsonDecode(dataJson) as Map<String, dynamic>);
  }

  /// Clear auto-save
  Future<void> clearAutoSave() async {
    final p = await prefs;
    await p.remove(_autoSaveKey);
  }

  /// Rename a scene
  Future<void> renameScene(String id, String newName) async {
    final data = await loadScene(id);
    if (data == null) return;

    final updatedMeta = SceneMeta(
      id: data.meta.id,
      name: newName,
      savedAt: data.meta.savedAt,
      description: data.meta.description,
    );

    final updatedData = SceneData(
      meta: updatedMeta,
      sceneJson: data.sceneJson,
      framesJson: data.framesJson,
      sceneScale: data.sceneScale,
      sceneOffset: data.sceneOffset,
    );

    await saveScene(updatedData);
  }
}

/// Extension to serialize SceneNode tree
extension SceneNodeSerialization on SceneNode {
  Map<String, dynamic> toJson() {
    final base = {
      'id': id,
      'name': name,
      'locked': locked,
      'selected': selected,
      'localRect': localRect != null
          ? {
              'left': localRect!.left,
              'top': localRect!.top,
              'width': localRect!.width,
              'height': localRect!.height,
            }
          : null,
    };

    if (this is SceneLeafNode) {
      final leaf = this as SceneLeafNode;
      return {
        ...base,
        'type': 'leaf',
        'widgetType': leaf.id.split('_').first, // e.g., 'widget', 'form1', etc.
        'onInteractionScript': leaf.onInteractionScript?.toJson(),
      };
    } else if (this is SceneContainerNode) {
      final container = this as SceneContainerNode;
      return {
        ...base,
        'type': 'container',
        'containerType': container.type.name,
        'config': container.config,
        'children': container.children.map((c) => c.toJson()).toList(),
      };
    }

    return base;
  }
}

/// Extension to serialize SceneElementFrame
extension SceneElementFrameSerialization on SceneElementFrame {
  Map<String, dynamic> toJson() => {
    'nodeId': nodeId,
    'positionX': position.dx,
    'positionY': position.dy,
    'width': size.width,
    'height': size.height,
  };

  static SceneElementFrame fromJson(Map<String, dynamic> json) {
    return SceneElementFrame(
      nodeId: json['nodeId'] as String,
      position: Offset(
        (json['positionX'] as num).toDouble(),
        (json['positionY'] as num).toDouble(),
      ),
      size: Size(
        (json['width'] as num).toDouble(),
        (json['height'] as num).toDouble(),
      ),
    );
  }
}

/// Extension to deserialize SceneNode tree
class SceneNodeDeserializer {
  /// Callback to build a widget for a leaf node based on its saved data
  final Widget Function(BuildContext, Map<String, dynamic>) leafWidgetBuilder;

  SceneNodeDeserializer({required this.leafWidgetBuilder});

  SceneNode fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;
    final id = json['id'] as String;
    final name = json['name'] as String?;
    final locked = json['locked'] as bool? ?? false;
    // ignore: unused_local_variable
    final selected = json['selected'] as bool? ?? false;

    Rect? localRect;
    if (json['localRect'] != null) {
      final r = json['localRect'] as Map<String, dynamic>;
      localRect = Rect.fromLTWH(
        (r['left'] as num).toDouble(),
        (r['top'] as num).toDouble(),
        (r['width'] as num).toDouble(),
        (r['height'] as num).toDouble(),
      );
    }

    if (type == 'leaf') {
      // Deserialize onInteractionScript if present
      DartBlockProgram? onInteractionScript;
      if (json['onInteractionScript'] != null) {
        onInteractionScript = DartBlockProgram.fromJson(
          json['onInteractionScript'] as Map<String, dynamic>,
        );
      }

      return SceneLeafNode(
        id: id,
        name: name,
        locked: locked,
        selected: false, // Don't restore selection
        localRect: localRect,
        builder: (ctx) => leafWidgetBuilder(ctx, json),
        onInteractionScript: onInteractionScript,
      );
    } else if (type == 'container') {
      final containerType = SceneContainerType.values.firstWhere(
        (t) => t.name == json['containerType'],
        orElse: () => SceneContainerType.column,
      );
      final config = (json['config'] as Map<String, dynamic>?) ?? {};
      final childrenJson = json['children'] as List<dynamic>? ?? [];

      return SceneContainerNode(
        id: id,
        name: name,
        type: containerType,
        locked: locked,
        selected: false, // Don't restore selection
        localRect: localRect,
        config: Map<String, dynamic>.from(config),
        children: childrenJson
            .map((c) => fromJson(c as Map<String, dynamic>))
            .toList(),
      );
    }

    // Fallback
    return SceneLeafNode(
      id: id,
      name: name,
      builder: (_) => const Text('Unknown'),
    );
  }
}
