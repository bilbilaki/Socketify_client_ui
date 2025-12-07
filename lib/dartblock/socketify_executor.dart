import 'package:flutter/material.dart';

import '../controlers/scene_controler.dart';
import '../models/scene/data_model.dart';
import 'dart_block_types.dart';

/// Custom executor that bridges DartBlock with Socketify SceneController
/// Note: DartBlockExecutor from dartblock_code takes a DartBlockProgram in constructor,
/// so we compose it instead of extending it directly
class SocketifyExecutor {
  final SceneController sceneController;
  final Widget Function(BuildContext, Map<String, dynamic>)? leafWidgetBuilder;
  final DartBlockExecutor _executor;

  SocketifyExecutor({
    required this.sceneController,
    required DartBlockProgram program,
    this.leafWidgetBuilder,
  }) : _executor = DartBlockExecutor(program);

  /// Execute the program with SceneController context
  Future<void> execute() async {
    // TODO: Design proper execution context mechanism for Socketify statements
    // Current architecture limitation: Socketify-specific statements (SetTextStatement, etc.)
    // receive SceneController directly, but dartblock_code's standard statements use
    // DartBlockArbiter's environment which only supports primitive DartBlockValue types.
    // 
    // Potential solutions to explore:
    // 1. Extend DartBlockValue to support custom object types
    // 2. Use dependency injection pattern for SceneController
    // 3. Create custom DartBlockArbiter subclass with SceneController access
    // 4. Implement callback-based architecture for Socketify operations
    //
    // See: https://github.com/aryobarzan/dartblock for DartBlockArbiter design
    
    // Execute the program
    await _executor.execute();
  }

  /// Get the console output from execution
  List<String> get consoleOutput => _executor.consoleOutput;

  /// Get any exception thrown during execution
  dynamic get thrownException => _executor.thrownException;

  /// Create a variable for a specific node
  DartBlockVariableDefinition createVariableForNode(String nodeId) {
    final node = sceneController.getNode(nodeId);
    if (node == null) {
      return DartBlockVariableDefinition('node_$nodeId', DartBlockDataType.stringType);
    }

    return DartBlockVariableDefinition(
      'node_${node.id}',
      DartBlockDataType.stringType,
    );
  }

  /// Get all available nodes as a list of variable definitions
  List<DartBlockVariableDefinition> getNodeVariables() {
    final variables = <DartBlockVariableDefinition>[];

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
