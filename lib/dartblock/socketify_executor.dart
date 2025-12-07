import 'package:flutter/material.dart';

import '../controlers/scene_controler.dart';
import '../models/scene/data_model.dart';
import 'dart_block_types.dart';

/// Custom executor that bridges DartBlock with Socketify SceneController
class SocketifyExecutor extends DartBlockExecutor {
  final SceneController sceneController;
  final Widget Function(BuildContext, Map<String, dynamic>)? leafWidgetBuilder;

  SocketifyExecutor({
    required this.sceneController,
    this.leafWidgetBuilder,
    Map<String, dynamic>? initialVariables,
  }) : super(
          context: {
            'sceneController': sceneController,
            'leafWidgetBuilder': leafWidgetBuilder,
            'scene': sceneController.scene,
            'frames': sceneController.framesByNodeId,
          },
          variables: initialVariables ?? _createVariablesFromScene(sceneController),
        );

  /// Create DartBlock variables from scene node properties
  static Map<String, dynamic> _createVariablesFromScene(SceneController controller) {
    final variables = <String, dynamic>{};

    // Add scene-level variables
    variables['sceneName'] = controller.currentSceneName;
    variables['sceneId'] = controller.currentSceneId ?? '';

    // Walk the scene tree and extract node properties as variables
    void walkNodes(SceneNode node, String prefix) {
      // Add node-level variables
      variables['${prefix}_id'] = node.id;
      variables['${prefix}_name'] = node.name;
      variables['${prefix}_locked'] = node.locked;
      variables['${prefix}_selected'] = node.selected;

      if (node is SceneContainerNode) {
        variables['${prefix}_type'] = node.type.name;
        variables['${prefix}_childCount'] = node.children.length;

        // Recursively add child variables
        for (var i = 0; i < node.children.length; i++) {
          walkNodes(node.children[i], '${prefix}_child$i');
        }
      }
    }

    // Start with root container
    walkNodes(controller.scene.root, 'root');

    // Add top-level nodes
    final topLevelNodes = controller.topLevelNodes;
    variables['topLevelNodeCount'] = topLevelNodes.length;
    for (var i = 0; i < topLevelNodes.length; i++) {
      walkNodes(topLevelNodes[i], 'node$i');
    }

    return variables;
  }

  /// Synchronize variables back to scene
  void syncVariablesToScene() {
    // When DartBlock modifies variables, sync them back to the scene
    // This is called after script execution

    for (final entry in variables.entries) {
      final key = entry.key;
      final value = entry.value;

      // Parse variable name to determine what to update
      // Example: "node0_name" -> update name of node0
      if (key.contains('_name')) {
        final nodePrefix = key.split('_name').first;
        final nodeId = variables['${nodePrefix}_id'] as String?;
        if (nodeId != null) {
          // Use SceneController method to update node name
          sceneController.updateNodeName(nodeId, value as String);
        }
      }
    }

    // State is already updated by SceneController methods
  }

  @override
  Future<void> execute(DartBlockProgram program) async {
    // Execute the program
    await super.execute(program);

    // Sync variables back to scene
    syncVariablesToScene();
  }

  /// Create a variable for a specific node
  DartBlockVariable createVariableForNode(String nodeId) {
    final node = sceneController.getNode(nodeId);
    if (node == null) {
      return DartBlockVariable(
        name: 'node_$nodeId',
        type: 'unknown',
        value: null,
      );
    }

    return DartBlockVariable(
      name: 'node_${node.id}',
      type: node is SceneContainerNode ? 'container' : 'leaf',
      value: {
        'id': node.id,
        'name': node.name,
        'locked': node.locked,
        'selected': node.selected,
      },
    );
  }

  /// Get all available nodes as a list of variables
  List<DartBlockVariable> getNodeVariables() {
    final variables = <DartBlockVariable>[];

    void walkNodes(SceneNode node) {
      variables.add(createVariableForNode(node.id));

      if (node is SceneContainerNode) {
        for (final child in node.children) {
          walkNodes(child);
        }
      }
    }

    walkNodes(sceneController.scene.root);

    return variables;
  }

  /// Update a node property from script
  void setNodeProperty(String nodeId, String propertyName, dynamic value) {
    sceneController.updateNodeConfig(nodeId, {propertyName: value});
  }

  /// Get a node property
  dynamic getNodeProperty(String nodeId, String propertyName) {
    final node = sceneController.getNode(nodeId);
    if (node == null) return null;

    switch (propertyName) {
      case 'id':
        return node.id;
      case 'name':
        return node.name;
      case 'locked':
        return node.locked;
      case 'selected':
        return node.selected;
      default:
        if (node is SceneContainerNode) {
          return node.config[propertyName];
        }
        return null;
    }
  }
}
