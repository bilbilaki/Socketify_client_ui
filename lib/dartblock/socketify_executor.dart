import 'package:flutter/material.dart';

import '../controlers/scene_controler.dart';
import '../models/scene/data_model.dart';
import 'dart_block_types.dart';
import 'socketify_arbiter.dart';

/// Custom executor that bridges DartBlock with Socketify SceneController
/// This is a simplified wrapper around SocketifyArbiter that provides
/// the execution interface used throughout the Socketify application.
class SocketifyExecutor {
  final SceneController sceneController;
  final Widget Function(BuildContext, Map<String, dynamic>)? leafWidgetBuilder;
  final SocketifyArbiter _arbiter;

  SocketifyExecutor({
    required this.sceneController,
    required DartBlockProgram program,
    this.leafWidgetBuilder,
  }) : _arbiter = SocketifyArbiter(
         program: program,
         sceneController: sceneController,
       );

  /// Execute the program with SceneController context
  /// The program runs using SocketifyArbiter which provides access to
  /// all registered native functions (setText, setProperty, etc.)
  Future<void> execute() async {
    await _arbiter.execute();
  }

  /// Get the console output from execution
  List<String> get consoleOutput => _arbiter.consoleOutput;

  /// Get any exception thrown during execution
  dynamic get thrownException => _arbiter.thrownException;

  /// Create a variable for a specific node
  DartBlockVariableDefinition createVariableForNode(String nodeId) {
    final node = sceneController.getNode(nodeId);
    if (node == null) {
      return DartBlockVariableDefinition(
        'node_$nodeId',
        DartBlockDataType.stringType,
      );
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
