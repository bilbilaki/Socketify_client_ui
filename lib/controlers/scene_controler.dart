import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../models/scene/data_model.dart';
import '../services/scene_storage.dart';

enum ResizeHandle { topLeft, topRight, bottomLeft, bottomRight }

/// Controller manages the scene tree and canvas‑space frames.
class SceneController extends StateNotifier<SceneControllerState> {
  // Auto-save
  Timer? _autoSaveTimer;
  final SceneStorageService _storage = SceneStorageService();

  SceneElementFrame? _draggingFrame;
  Offset _dragStartScenePos = Offset.zero;
  Offset _dragStartPointerScenePos = Offset.zero;

  SceneController(super.initialState);

  // Convenience getters from state
  SceneRoot get scene => state.scene;
  Map<String, SceneElementFrame> get framesByNodeId => state.framesByNodeId;
  Offset get sceneOffset => state.sceneOffset;
  double get sceneScale => state.sceneScale;
  String? get currentSceneId => state.currentSceneId;
  String get currentSceneName => state.currentSceneName;
  bool get isDirty => state.isDirty;
  SceneStorageService get storage => _storage;

  /// Convenience: top‑level nodes to show on the canvas.
  List<SceneNode> get topLevelNodes {
    return state.scene.root.children;
  }

  /// Find parent container and index for a node id.
  (SceneContainerNode?, int) findParentAndIndex(String id) {
    SceneContainerNode? foundParent;
    int foundIndex = -1;

    void search(SceneContainerNode parent) {
      if (foundParent != null) return;
      for (var i = 0; i < parent.children.length; i++) {
        final child = parent.children[i];
        if (child.id == id) {
          foundParent = parent;
          foundIndex = i;
          return;
        }
        if (child is SceneContainerNode) {
          search(child);
        }
      }
    }

    search(state.scene.root);
    return (foundParent, foundIndex);
  }

  SceneNode? _findNodeById(String id, SceneNode node) {
    if (node.id == id) return node;
    if (node is SceneContainerNode) {
      for (final child in node.children) {
        final res = _findNodeById(id, child);
        if (res != null) return res;
      }
    }
    return null;
  }

  SceneNode? getNode(String id) => _findNodeById(id, state.scene.root);

  /// Move an existing node into a container at a given child index.
  /// If [newIndex] is null, appends at the end.
  void moveNodeToContainer({
    required String nodeId,
    required String? targetContainerId,
    int? newIndex,
  }) {
    if (nodeId == targetContainerId) return;

    final (oldParent, oldIndex) = findParentAndIndex(nodeId);
    if (oldParent == null || oldIndex < 0) return;

    final node = oldParent.children[oldIndex];

    // Remove from old parent
    oldParent.children = List.of(oldParent.children)..removeAt(oldIndex);

    // Determine new parent
    SceneContainerNode targetParent;
    if (targetContainerId == null || state.scene.root.id == targetContainerId) {
      targetParent = state.scene.root;
    } else {
      final targetNode = getNode(targetContainerId);
      if (targetNode is! SceneContainerNode) return;
      targetParent = targetNode;
    }

    final children = List.of(targetParent.children);
    if (newIndex == null || newIndex < 0 || newIndex > children.length) {
      children.add(node);
    } else {
      children.insert(newIndex, node);
    }
    targetParent.children = children;

    _updateState();
  }

  /// Add a new child node inside an existing container.
  void addChildToContainer({
    required String parentId,
    required SceneNode child,
  }) {
    final parent = getNode(parentId);
    if (parent is! SceneContainerNode) return;

    parent.children = [...parent.children, child];
    _updateState();
  }

  /// Returns true if the node is a container.
  bool isContainer(String id) {
    final node = getNode(id);
    return node is SceneContainerNode;
  }

  /// Get the id of the single selected node, if any.
  String? get singleSelectedId {
    String? result;

    void walk(SceneNode node) {
      if (node.selected) {
        if (result == null) {
          result = node.id;
        } else {
          // More than one selected
          result = null;
          return;
        }
      }
      if (node is SceneContainerNode) {
        for (final c in node.children) {
          if (result == null || !c.selected) {
            walk(c);
          }
        }
      }
    }

    walk(state.scene.root);
    return result;
  }

  void addTopLevelNode(SceneNode node, SceneElementFrame frame) {
    state.scene.root.children = [...state.scene.root.children, node];
    state.framesByNodeId[node.id] = frame;
    _updateState();
  }

  /// Detach a node from its parent container and make it a free top-level
  /// element with its own frame. If already top-level, this is a no-op.
  void detachNodeToTopLevel(String nodeId) {
    final (parent, index) = findParentAndIndex(nodeId);
    if (parent == null || index < 0) return;
    if (identical(parent, state.scene.root)) return; // already top-level

    final node = parent.children[index];
    parent.children = List.of(parent.children)..removeAt(index);

    // Place near the parent container using its frame if present.
    final parentFrame = framesByNodeId[parent.id];
    final position = parentFrame?.position ?? const Offset(100, 100);
    final size = parentFrame?.size ?? const Size(200, 120);

    state.framesByNodeId[node.id] = SceneElementFrame(
      nodeId: node.id,
      position: position + const Offset(20, 20),
      size: size,
    );
    state.scene.root.children = [...state.scene.root.children, node];

    _updateState();
  }

  /// Attach a free top-level node into a container and remove its frame.
  void attachNodeToContainer({
    required String nodeId,
    required String targetContainerId,
  }) {
    final targetNode = getNode(targetContainerId);
    if (targetNode is! SceneContainerNode) return;

    // Only attach nodes that currently live directly under root.
    final (parent, index) = findParentAndIndex(nodeId);
    if (parent == null || index < 0 || !identical(parent, state.scene.root)) {
      return;
    }

    final node = parent.children[index];
    parent.children = List.of(parent.children)..removeAt(index);
    state.framesByNodeId.remove(node.id);

    targetNode.children = [...targetNode.children, node];
    _updateState();
  }

  /// Check if a node is a free top-level element (direct child of root with a frame).
  bool isFreeTopLevel(String id) {
    final (parent, index) = findParentAndIndex(id);
    return parent != null &&
        identical(parent, state.scene.root) &&
        state.framesByNodeId.containsKey(id);
  }

  /// Check if a node is inside a container (not top-level root).
  bool isInsideContainer(String id) {
    final (parent, _) = findParentAndIndex(id);
    return parent != null && !identical(parent, state.scene.root);
  }

  /// Find containers that overlap with the given node's frame.
  /// Returns list of container ids that the node overlaps with.
  List<String> findOverlappingContainers(String nodeId) {
    final frame = state.framesByNodeId[nodeId];
    if (frame == null) return [];

    final nodeRect = Rect.fromLTWH(
      frame.position.dx,
      frame.position.dy,
      frame.size.width,
      frame.size.height,
    );

    final result = <String>[];

    for (final topNode in topLevelNodes) {
      if (topNode.id == nodeId) continue; // skip self
      if (topNode is! SceneContainerNode) continue;

      final containerFrame = state.framesByNodeId[topNode.id];
      if (containerFrame == null) continue;

      final containerRect = Rect.fromLTWH(
        containerFrame.position.dx,
        containerFrame.position.dy,
        containerFrame.size.width,
        containerFrame.size.height,
      );

      if (nodeRect.overlaps(containerRect)) {
        result.add(topNode.id);
      }
    }

    return result;
  }

  void removeSelected() {
    void removeFrom(SceneContainerNode parent) {
      parent.children = parent.children.where((n) {
        if (!n.selected || n.locked) return true;
        state.framesByNodeId.remove(n.id);
        return false;
      }).toList();

      for (final child in parent.children) {
        if (child is SceneContainerNode) {
          removeFrom(child);
        }
      }
    }

    removeFrom(state.scene.root);
    _updateState();
  }

  void clearSelection() {
    void clear(SceneNode node) {
      node.selected = false;
      if (node is SceneContainerNode) {
        for (final child in node.children) {
          clear(child);
        }
      }
    }

    clear(state.scene.root);
    _updateState();
  }

  void toggleSelection(String id, {bool multi = false}) {
    final node = getNode(id);
    if (node == null) return;

    if (!multi) {
      clearSelection();
      node.selected = true;
    } else {
      node.selected = !node.selected;
    }
    _updateState();
  }

  void setLocked(String id, bool locked) {
    final node = getNode(id);
    if (node == null) return;
    node.locked = locked;
    _updateState();
  }

  // Pan background
  void pan(Offset delta) {
    state = state.copyWith(sceneOffset: state.sceneOffset + delta);
  }

  // (Optional) Zoom
  void setScale(double scale, Offset pivot) {
    state = state.copyWith(sceneScale: scale.clamp(0.2, 4.0));
  }

  // Coordinate transforms
  Offset globalToScene(Offset globalPosition) {
    return (globalPosition - sceneOffset) / sceneScale;
  }

  Offset sceneToGlobal(Offset scenePosition) {
    return scenePosition * sceneScale + sceneOffset;
  }

  // Dragging frame by node id
  void startDragFrame(String id, Offset pointerGlobal) {
    final frame = state.framesByNodeId[id];
    final node = getNode(id);
    if (frame == null || node == null || node.locked) return;

    _draggingFrame = frame;
    _dragStartScenePos = frame.position;
    _dragStartPointerScenePos = globalToScene(pointerGlobal);
  }

  void updateDragFrame(String id, Offset pointerGlobal) {
    final frame = _draggingFrame;
    if (frame == null) return;

    final node = getNode(id);
    if (node == null || node.locked) return;

    final currentPointerScenePos = globalToScene(pointerGlobal);
    final delta = currentPointerScenePos - _dragStartPointerScenePos;
    frame.position = _dragStartScenePos + delta;
    _updateState();
  }

  void endDragFrame(String id) {
    _draggingFrame = null;
  }

  // Resize frame from a given handle
  void resizeFrame(String id, Offset pointerGlobal, ResizeHandle handle) {
    final frame = state.framesByNodeId[id];
    final node = getNode(id);
    if (frame == null || node == null || node.locked) return;

    final pointerScene = globalToScene(pointerGlobal);
    var pos = frame.position;
    var size = frame.size;

    const double minSize = 40;

    switch (handle) {
      case ResizeHandle.topLeft:
        final bottomRight = pos + Offset(size.width, size.height);
        pos = Offset(
          pointerScene.dx.clamp(bottomRight.dx - 600, bottomRight.dx - minSize),
          pointerScene.dy.clamp(bottomRight.dy - 600, bottomRight.dy - minSize),
        );
        size = Size(bottomRight.dx - pos.dx, bottomRight.dy - pos.dy);
        break;

      case ResizeHandle.topRight:
        final bottomLeft = pos + Offset(0, size.height);
        final newRight = pointerScene.dx;
        final newTop = pointerScene.dy;
        final clampedRight = newRight.clamp(
          bottomLeft.dx + minSize,
          bottomLeft.dx + 600,
        );
        final clampedTop = newTop.clamp(
          bottomLeft.dy - 600,
          bottomLeft.dy - minSize,
        );

        pos = Offset(bottomLeft.dx, clampedTop);
        size = Size(clampedRight - bottomLeft.dx, bottomLeft.dy - clampedTop);
        break;

      case ResizeHandle.bottomLeft:
        final topRight = pos + Offset(size.width, 0);
        final newLeft = pointerScene.dx;
        final newBottom = pointerScene.dy;

        final clampedLeft = newLeft.clamp(
          topRight.dx - 600,
          topRight.dx - minSize,
        );
        final clampedBottom = newBottom.clamp(
          topRight.dy + minSize,
          topRight.dy + 600,
        );

        pos = Offset(clampedLeft, topRight.dy);
        size = Size(topRight.dx - clampedLeft, clampedBottom - topRight.dy);
        break;

      case ResizeHandle.bottomRight:
        final newRight = pointerScene.dx;
        final newBottom = pointerScene.dy;

        final clampedRight = newRight.clamp(pos.dx + minSize, pos.dx + 600);
        final clampedBottom = newBottom.clamp(pos.dy + minSize, pos.dy + 600);

        size = Size(clampedRight - pos.dx, clampedBottom - pos.dy);
        break;
    }

    frame.position = pos;
    frame.size = size;
    _updateState();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Save / Load / New Scene
  // ─────────────────────────────────────────────────────────────────────────

  /// Update state and mark as dirty
  void _updateState() {
    state = state.copyWith(isDirty: true);
    _scheduleAutoSave();
  }

  /// Schedule auto-save after a delay
  void _scheduleAutoSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(seconds: 5), () {
      _performAutoSave();
    });
  }

  Future<void> _performAutoSave() async {
    final data = _createSceneData(
      id: state.currentSceneId ?? 'autosave',
      name: state.currentSceneName,
    );
    await _storage.saveAutoSave(data);
  }

  /// Create SceneData from current state
  SceneData _createSceneData({required String id, required String name}) {
    final sceneJson = state.scene.root.toJson();
    final framesJson = <String, dynamic>{};
    for (final entry in state.framesByNodeId.entries) {
      framesJson[entry.key] = entry.value.toJson();
    }

    return SceneData(
      meta: SceneMeta(id: id, name: name, savedAt: DateTime.now()),
      sceneJson: sceneJson,
      framesJson: framesJson,
      sceneScale: state.sceneScale,
      sceneOffset: state.sceneOffset,
    );
  }

  /// Save current scene with a name
  Future<void> saveScene({String? name}) async {
    final id =
        state.currentSceneId ??
        DateTime.now().millisecondsSinceEpoch.toString();
    final sceneName = name ?? state.currentSceneName;

    final data = _createSceneData(id: id, name: sceneName);
    await _storage.saveScene(data);

    state = state.copyWith(
      currentSceneId: id,
      currentSceneName: sceneName,
      isDirty: false,
    );
    await _storage.clearAutoSave();
  }

  /// Save current scene with a new name (Save As)
  Future<void> saveSceneAs(String name) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();

    final data = _createSceneData(id: id, name: name);
    await _storage.saveScene(data);

    state = state.copyWith(
      currentSceneId: id,
      currentSceneName: name,
      isDirty: false,
    );
    await _storage.clearAutoSave();
  }

  /// Load a scene by id
  Future<bool> loadScene(
    String id,
    Widget Function(BuildContext, Map<String, dynamic>) leafWidgetBuilder,
  ) async {
    final data = await _storage.loadScene(id);
    if (data == null) return false;

    _applySceneData(data, leafWidgetBuilder);
    return true;
  }

  /// Apply loaded scene data
  void _applySceneData(
    SceneData data,
    Widget Function(BuildContext, Map<String, dynamic>) leafWidgetBuilder,
  ) {
    final deserializer = SceneNodeDeserializer(
      leafWidgetBuilder: leafWidgetBuilder,
    );

    final rootNode = deserializer.fromJson(data.sceneJson);
    SceneRoot newScene = state.scene;
    if (rootNode is SceneContainerNode) {
      newScene = SceneRoot(root: rootNode);
    }

    final newFrames = <String, SceneElementFrame>{};
    for (final entry in data.framesJson.entries) {
      final frameJson = entry.value as Map<String, dynamic>;
      newFrames[entry.key] = SceneElementFrameSerialization.fromJson(frameJson);
    }

    state = state.copyWith(
      scene: newScene,
      framesByNodeId: newFrames,
      sceneScale: data.sceneScale,
      sceneOffset: data.sceneOffset,
      currentSceneId: data.meta.id,
      currentSceneName: data.meta.name,
      isDirty: false,
    );
  }

  /// Try to load auto-saved scene
  Future<bool> loadAutoSave(
    Widget Function(BuildContext, Map<String, dynamic>) leafWidgetBuilder,
  ) async {
    final data = await _storage.loadAutoSave();
    if (data == null) return false;

    _applySceneData(data, leafWidgetBuilder);
    return true;
  }

  /// Create a new empty scene
  void newScene({String name = 'Untitled Scene'}) {
    state = SceneControllerState(
      scene: SceneRoot(
        root: SceneContainerNode(
          id: 'root',
          name: 'Root',
          type: SceneContainerType.stack,
          children: [],
        ),
      ),
      framesByNodeId: {},
      sceneOffset: Offset.zero,
      sceneScale: 1.0,
      currentSceneId: null,
      currentSceneName: name,
      isDirty: false,
    );
  }

  /// Get list of saved scenes
  Future<List<SceneMeta>> getSavedScenes() async {
    return _storage.getSavedScenes();
  }

  /// Delete a saved scene
  Future<void> deleteScene(String id) async {
    await _storage.deleteScene(id);
  }

  /// Rename current scene
  void renameCurrentScene(String newName) {
    state = state.copyWith(currentSceneName: newName, isDirty: true);
    _scheduleAutoSave();
  }

  /// Update configuration of a node (used by DartBlock scripts)
  void updateNodeConfig(String nodeId, Map<String, dynamic> config) {
    final node = getNode(nodeId);
    if (node == null) return;

    if (node is SceneContainerNode) {
      // Update container config
      node.config = {...node.config, ...config};
    } else if (node is SceneLeafNode) {
      // For leaf nodes, we might store config in a custom way
      // This is a placeholder - actual implementation depends on widget types
      // For now, we'll just mark as dirty to trigger rebuild
    }

    _updateState();
  }

  /// Execute interaction script for a node
  Future<void> executeNodeInteraction(
    String nodeId,
    Widget Function(BuildContext, Map<String, dynamic>) leafWidgetBuilder,
  ) async {
    final node = getNode(nodeId);
    if (node is! SceneLeafNode || node.onInteractionScript == null) {
      return;
    }

    // Import the executor here to avoid circular dependencies
    final executor = _createExecutor(leafWidgetBuilder);
    await executor.execute(node.onInteractionScript!);
  }

  /// Create a DartBlock executor with SceneController context
  dynamic _createExecutor(
    Widget Function(BuildContext, Map<String, dynamic>) leafWidgetBuilder,
  ) {
    // This will be implemented with actual dartblock_code imports
    // For now, create a minimal executor
    final context = {
      'sceneController': this,
      'leafWidgetBuilder': leafWidgetBuilder,
      'scene': scene,
      'frames': framesByNodeId,
    };

    // Return a basic executor (placeholder)
    return _BasicExecutor(context: context);
  }

  /// Dispose timer
  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    super.dispose();
  }
}

/// Placeholder executor - will be replaced with actual DartBlockExecutor
class _BasicExecutor {
  final Map<String, dynamic> context;

  _BasicExecutor({required this.context});

  Future<void> execute(dynamic program) async {
    // Placeholder - actual implementation will use dartblock_code package
    print('Executing program: $program');
  }
}

/// State class for SceneController
class SceneControllerState {
  final SceneRoot scene;
  final Map<String, SceneElementFrame> framesByNodeId;
  final Offset sceneOffset;
  final double sceneScale;
  final String? currentSceneId;
  final String currentSceneName;
  final bool isDirty;

  SceneControllerState({
    required this.scene,
    required this.framesByNodeId,
    this.sceneOffset = Offset.zero,
    this.sceneScale = 1.0,
    this.currentSceneId,
    this.currentSceneName = 'Untitled Scene',
    this.isDirty = false,
  });

  SceneControllerState copyWith({
    SceneRoot? scene,
    Map<String, SceneElementFrame>? framesByNodeId,
    Offset? sceneOffset,
    double? sceneScale,
    String? currentSceneId,
    String? currentSceneName,
    bool? isDirty,
  }) {
    return SceneControllerState(
      scene: scene ?? this.scene,
      framesByNodeId: framesByNodeId ?? this.framesByNodeId,
      sceneOffset: sceneOffset ?? this.sceneOffset,
      sceneScale: sceneScale ?? this.sceneScale,
      currentSceneId: currentSceneId ?? this.currentSceneId,
      currentSceneName: currentSceneName ?? this.currentSceneName,
      isDirty: isDirty ?? this.isDirty,
    );
  }
}

/// Provider for SceneController
final sceneControllerProvider =
    StateNotifierProvider<SceneController, SceneControllerState>((ref) {
      final scene = SceneRoot(
        root: SceneContainerNode(
          id: 'root',
          name: 'Root',
          type: SceneContainerType.stack,
          children: [],
        ),
      );

      return SceneController(
        SceneControllerState(scene: scene, framesByNodeId: {}),
      );
    });
