import 'package:client_ui/models/scene/data_model.dart';
import 'package:dartblock_code/models/function.dart';
import 'package:dartblock_code/models/dartblock_value.dart';
import 'package:dartblock_code/core/dartblock_executor.dart';
import 'socketify_arbiter.dart';

/// Registry of all native functions available in Socketify for visual programming.
/// These functions are the "API" that users can call from DartBlock visual editor.
class SocketifyNativeFunctions {
  /// Returns all available UI functions to be registered in the DartBlock editor
  static List<DartBlockNativeFunction> get all => [
    setText,
    setProperty,
    setVisible,
    navigateToScene,
    printDebug,
    getNodeProperty,
  ];

  /// Updates the text property of a specific node
  static final setText = DartBlockNativeFunction(
    name: 'setText',
    description: 'Updates the text property of a specific node',
    returnType: null, // void function
    category: DartBlockNativeFunctionCategory.string,
    type: DartBlockNativeFunctionType.abs,

    parameters: [
      DartBlockVariableDefinition('nodeId', DartBlockDataType.stringType),
      DartBlockVariableDefinition('newText', DartBlockDataType.stringType),
    ],

    implementation: (arbiter, args) {
      if (arbiter is! SocketifyArbiter) {
        throw Exception('setText requires SocketifyArbiter execution context');
      }

      final nodeId = args[0].getValue(arbiter) as String;
      final text = args[1].getValue(arbiter) as String;

      arbiter.sceneController.updateNodeConfig(nodeId, {'text': text});

      return null;
    },
  );

  /// Sets any property on a node
  static final setProperty = DartBlockNativeFunction(
    name: 'setProperty',
    description: 'Updates any property of a specific node',
    returnType: null,
    category: DartBlockNativeFunctionCategory.string,
    type: DartBlockNativeFunctionType.startsWith,

    parameters: [
      DartBlockVariableDefinition('nodeId', DartBlockDataType.stringType),
      DartBlockVariableDefinition('propertyName', DartBlockDataType.stringType),
      DartBlockVariableDefinition('value', DartBlockDataType.stringType),
    ],

    implementation: (arbiter, args) {
      if (arbiter is! SocketifyArbiter) {
        throw Exception(
          'setProperty requires SocketifyArbiter execution context',
        );
      }

      final nodeId = args[0].getValue(arbiter) as String;
      final propertyName = args[1].getValue(arbiter) as String;
      final value = args[2].getValue(arbiter);

      arbiter.sceneController.updateNodeConfig(nodeId, {propertyName: value});

      return null;
    },
  );

  /// Shows or hides a node
  static final setVisible = DartBlockNativeFunction(
    name: 'setVisible',
    description: 'Shows or hides a specific node',
    returnType: null,
    category: DartBlockNativeFunctionCategory.math,
    type: DartBlockNativeFunctionType.substring,

    parameters: [
      DartBlockVariableDefinition('nodeId', DartBlockDataType.stringType),
      DartBlockVariableDefinition('visible', DartBlockDataType.booleanType),
    ],

    implementation: (arbiter, args) {
      if (arbiter is! SocketifyArbiter) {
        throw Exception(
          'setVisible requires SocketifyArbiter execution context',
        );
      }

      final nodeId = args[0].getValue(arbiter) as String;
      final visible = args[1].getValue(arbiter) as bool;

      arbiter.sceneController.updateNodeConfig(nodeId, {'visible': visible});

      return null;
    },
  );

  /// Navigates to a different scene
  static final navigateToScene = DartBlockNativeFunction(
    name: 'navigateToScene',
    description: 'Switch to a different scene',
    returnType: null,
    category: DartBlockNativeFunctionCategory.math,
    type: DartBlockNativeFunctionType.contains,

    parameters: [
      DartBlockVariableDefinition('sceneId', DartBlockDataType.stringType),
    ],

    implementation: (arbiter, args) {
      if (arbiter is! SocketifyArbiter) {
        throw Exception(
          'navigateToScene requires SocketifyArbiter execution context',
        );
      }

      final sceneId = args[0].getValue(arbiter) as String;

      // TODO: Navigation requires leafWidgetBuilder callback which isn't available
      // in this execution context. This needs to be stored in SocketifyArbiter
      // For now, throw a clear error
      throw UnimplementedError(
        'Navigation requires leafWidgetBuilder context. '
        'Scene navigation integration is pending. '
        'Target scene: $sceneId',
      );

      // Future implementation:
      // arbiter.sceneController.loadScene(sceneId, arbiter.leafWidgetBuilder);
    },
  );

  /// Prints a debug message to console
  static final printDebug = DartBlockNativeFunction(
    name: 'printDebug',
    description: 'Prints a debug message to the console',
    returnType: null,
    category: DartBlockNativeFunctionCategory.string,
    type: DartBlockNativeFunctionType.endsWith,

    parameters: [
      DartBlockVariableDefinition('message', DartBlockDataType.stringType),
    ],

    implementation: (arbiter, args) {
      final message = args[0].getValue(arbiter) as String;
      print('[Socketify Debug] $message');

      return null;
    },
  );

  /// Gets a property value from a node
  static final getNodeProperty = DartBlockNativeFunction(
    name: 'getNodeProperty',
    description: 'Retrieves a property value from a specific node',
    returnType: DartBlockDataType.stringType,
    category: DartBlockNativeFunctionCategory.string,
    type: DartBlockNativeFunctionType.round,

    parameters: [
      DartBlockVariableDefinition('nodeId', DartBlockDataType.stringType),
      DartBlockVariableDefinition('propertyName', DartBlockDataType.stringType),
    ],

    implementation: (arbiter, args) {
      if (arbiter is! SocketifyArbiter) {
        throw Exception(
          'getNodeProperty requires SocketifyArbiter execution context',
        );
      }

      final nodeId = args[0].getValue(arbiter) as String;
      final propertyName = args[1].getValue(arbiter) as String;

      final node = arbiter.sceneController.getNode(nodeId);
      if (node == null) {
        return DartBlockStringValue.init('');
      }

      // Get property value based on property name
      dynamic value;
      switch (propertyName) {
        case 'id':
          value = node.id;
          break;
        case 'name':
          value = node.name;
          break;
        case 'locked':
          value = node.locked.toString();
          break;
        case 'selected':
          value = node.selected.toString();
          break;
        default:
          // Try to get from config
          if (node is SceneContainerNode) {
            value = node.config[propertyName]?.toString() ?? '';
          } else if (node is SceneLeafNode) {
           // value = node[propertyName]?.toString() ?? '';
          } else {
            value = '';
          }
      }

      return DartBlockStringValue.init(value.toString());
    },
  );
}
