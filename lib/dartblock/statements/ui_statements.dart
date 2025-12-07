import '../../controlers/scene_controler.dart';
import '../dart_block_types.dart';

/// Base class for Socketify-specific UI statements
/// These are custom statements for Socketify operations, not part of dartblock_code
abstract class SocketifyStatement {
  /// Execute this statement with access to SceneController
  Future<void> execute(SceneController sceneController);
  
  /// Convert to JSON
  Map<String, dynamic> toJson();
  
  /// Helper method to extract string value from DartBlockValue
  /// Handles DartBlockStringValue and falls back to toString()
  static String _extractStringValue(DartBlockValue value) {
    if (value is DartBlockStringValue) {
      return value.value;
    }
    // For other types, convert to string representation
    return value.toString();
  }
  
  /// Helper method to extract boolean value from DartBlockBooleanExpression
  /// Note: Proper evaluation would require a DartBlockArbiter with proper execution context
  /// TODO: Integrate DartBlockArbiter for proper expression evaluation
  /// See: https://github.com/aryobarzan/dartblock - DartBlockBooleanExpression.getValue()
  static bool _extractBooleanValue(DartBlockBooleanExpression expr, {bool defaultValue = true}) {
    // For constant boolean expressions, try to extract the value
    // This is a simplified approach - full evaluation requires DartBlockArbiter
    try {
      // Check if this is a constant expression by examining the compositionNode
      // In dartblock_code, constant nodes have a getValue that doesn't need context
      // For now, return the default as we don't have arbiter context
      // TODO: Add arbiter-based evaluation when execution context is available
      return defaultValue;
    } catch (e) {
      return defaultValue;
    }
  }
}

/// Statement to set text content of a node
class SetTextStatement extends SocketifyStatement {
  final String targetNodeId;
  final DartBlockValue newText;

  SetTextStatement({
    required this.targetNodeId,
    required this.newText,
  });

  @override
  Future<void> execute(SceneController sceneController) async {
    // Extract string value from DartBlockValue
    final textValue = _extractStringValue(newText);
    sceneController.updateNodeConfig(targetNodeId, {'text': textValue});
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'SetTextStatement',
      'targetNodeId': targetNodeId,
      'newText': newText.toJson(),
    };
  }

  factory SetTextStatement.fromJson(Map<String, dynamic> json) {
    // Use proper DartBlockStringValue instead of placeholder
    final newTextValue = json['newText'];
    final DartBlockValue newTextExpr;
    
    if (newTextValue is Map) {
      // Try to deserialize as DartBlockValue
      try {
        newTextExpr = DartBlockValue.fromJson(newTextValue);
      } catch (e) {
        // Fallback to string value
        newTextExpr = DartBlockStringValue.init(newTextValue['value'] as String? ?? '');
      }
    } else {
      // Simple string value
      newTextExpr = DartBlockStringValue.init(newTextValue as String? ?? '');
    }
    
    return SetTextStatement(
      targetNodeId: json['targetNodeId'] as String,
      newText: newTextExpr,
    );
  }
}

/// Generic statement to set any property of a node
class SetPropertyStatement extends SocketifyStatement {
  final String targetNodeId;
  final String propertyName;
  final DartBlockValue value;

  SetPropertyStatement({
    required this.targetNodeId,
    required this.propertyName,
    required this.value,
  });

  @override
  Future<void> execute(SceneController sceneController) async {
    // Extract value from DartBlockValue
    final propertyValue = _extractStringValue(value);
    sceneController.updateNodeConfig(targetNodeId, {propertyName: propertyValue});
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'SetPropertyStatement',
      'targetNodeId': targetNodeId,
      'propertyName': propertyName,
      'value': value.toJson(),
    };
  }

  factory SetPropertyStatement.fromJson(Map<String, dynamic> json) {
    final valueData = json['value'];
    final DartBlockValue propertyValue;
    
    if (valueData is Map) {
      try {
        propertyValue = DartBlockValue.fromJson(valueData);
      } catch (e) {
        propertyValue = DartBlockStringValue.init(valueData.toString());
      }
    } else {
      propertyValue = DartBlockStringValue.init(valueData.toString());
    }
    
    return SetPropertyStatement(
      targetNodeId: json['targetNodeId'] as String,
      propertyName: json['propertyName'] as String,
      value: propertyValue,
    );
  }
}

/// Statement to show or hide a node
class SetNodeVisibleStatement extends SocketifyStatement {
  final String targetNodeId;
  final DartBlockBooleanExpression visible;

  SetNodeVisibleStatement({
    required this.targetNodeId,
    required this.visible,
  });

  @override
  Future<void> execute(SceneController sceneController) async {
    // Extract boolean value from expression
    // Note: Full evaluation requires DartBlockArbiter, which isn't available in this context
    // For now, we use a simple default value approach
    final isVisible = _extractBooleanValue(visible, defaultValue: true);
    sceneController.updateNodeConfig(targetNodeId, {'visible': isVisible});
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'SetNodeVisibleStatement',
      'targetNodeId': targetNodeId,
      'visible': visible.toJson(),
    };
  }

  factory SetNodeVisibleStatement.fromJson(Map<String, dynamic> json) {
    final visibleValue = json['visible'];
    final DartBlockBooleanExpression visibleExpr;
    
    if (visibleValue is Map) {
      try {
        visibleExpr = DartBlockBooleanExpression.fromJson(visibleValue);
      } catch (e) {
        visibleExpr = DartBlockBooleanExpression.fromConstant(visibleValue['value'] as bool? ?? true);
      }
    } else {
      visibleExpr = DartBlockBooleanExpression.fromConstant(visibleValue as bool? ?? true);
    }
    
    return SetNodeVisibleStatement(
      targetNodeId: json['targetNodeId'] as String,
      visible: visibleExpr,
    );
  }
}

/// Statement to navigate to another scene
class NavigateToSceneStatement extends SocketifyStatement {
  final String sceneId;

  NavigateToSceneStatement({
    required this.sceneId,
  });

  @override
  Future<void> execute(SceneController sceneController) async {
    // TODO: Navigation requires a leafWidgetBuilder callback which isn't available
    // in this execution context. This needs to be passed through SocketifyExecutor
    // or a different mechanism. 
    // Issue: Need to design execution context that provides leafWidgetBuilder to statements
    // For now, throw a clear error rather than silently failing
    throw UnimplementedError(
      'NavigateToSceneStatement requires execution context with leafWidgetBuilder. '
      'Scene navigation is not yet fully integrated with DartBlock execution. '
      'Target scene: $sceneId'
    );
    
    // Future implementation should be:
    // await sceneController.loadScene(sceneId, leafWidgetBuilder);
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'NavigateToSceneStatement',
      'sceneId': sceneId,
    };
  }

  factory NavigateToSceneStatement.fromJson(Map<String, dynamic> json) {
    return NavigateToSceneStatement(
      sceneId: json['sceneId'] as String,
    );
  }
}

/// Print statement for debugging
class SocketifyPrintStatement extends SocketifyStatement {
  final DartBlockValue message;

  SocketifyPrintStatement({
    required this.message,
  });

  @override
  Future<void> execute(SceneController sceneController) async {
    final value = _extractStringValue(message);
    print('[Socketify] $value');
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'SocketifyPrintStatement',
      'message': message.toJson(),
    };
  }

  factory SocketifyPrintStatement.fromJson(Map<String, dynamic> json) {
    final messageData = json['message'];
    final DartBlockValue messageValue;
    
    if (messageData is Map) {
      try {
        messageValue = DartBlockValue.fromJson(messageData);
      } catch (e) {
        messageValue = DartBlockStringValue.init(messageData.toString());
      }
    } else {
      messageValue = DartBlockStringValue.init(messageData as String? ?? '');
    }
    
    return SocketifyPrintStatement(
      message: messageValue,
    );
  }
}
