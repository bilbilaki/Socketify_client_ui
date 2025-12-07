import '../../controlers/scene_controler.dart';
import '../dart_block_types.dart';

/// Base class for Socketify-specific UI statements
/// These are custom statements for Socketify operations, not part of dartblock_code
abstract class SocketifyStatement {
  /// Execute this statement with access to SceneController
  Future<void> execute(SceneController sceneController);
  
  /// Convert to JSON
  Map<String, dynamic> toJson();
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
    // For now, since we don't have a DartBlockArbiter available here,
    // we'll assume the value is a DartBlockStringValue and access it directly
    // In a full integration, this would be passed through proper execution context
    final textValue = newText is DartBlockStringValue 
        ? (newText as DartBlockStringValue).value
        : newText.toString();
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
    // Get the value from the DartBlockValue
    final propertyValue = value is DartBlockStringValue
        ? (value as DartBlockStringValue).value
        : value.toString();
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
    // For boolean expressions, we'd need a DartBlockArbiter to evaluate
    // For now, use fromConstant pattern
    final isVisible = visible is DartBlockBooleanExpression
        ? true // Default to true, proper evaluation would need arbiter
        : true;
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
    // Note: Navigation requires a leafWidgetBuilder which isn't available here
    // This would need to be passed through a different mechanism
    // For now, just log the intent
    print('[Socketify] Navigate to scene: $sceneId');
    // In a real implementation:
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
    final value = message is DartBlockStringValue
        ? (message as DartBlockStringValue).value
        : message.toString();
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
