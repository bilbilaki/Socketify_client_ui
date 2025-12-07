import '../../controlers/scene_controler.dart';
import '../dart_block_types.dart';

/// Statement to set text content of a node
class SetTextStatement extends Statement {
  final String targetNodeId;
  final DartBlockAlgebraicExpression newText;

  SetTextStatement({
    required this.targetNodeId,
    required this.newText,
  });

  @override
  Future<void> execute(DartBlockExecutor executor) async {
    // Access the SceneController via the executor's context
    final sceneController = executor.context['sceneController'] as SceneController?;
    if (sceneController == null) {
      throw Exception('SceneController not found in executor context');
    }

    final textValue = newText.evaluate();
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
    // PLACEHOLDER: This is a simplified deserialization.
    // When dartblock_code package is available, replace with proper
    // DartBlockAlgebraicExpression deserialization that supports
    // all expression types (variables, operators, function calls, etc.)
    final newTextValue = json['newText'];
    final newTextExpr = newTextValue is Map
        ? _StringLiteralExpression(newTextValue['value'] as String? ?? '')
        : _StringLiteralExpression(newTextValue as String? ?? '');
    
    return SetTextStatement(
      targetNodeId: json['targetNodeId'] as String,
      newText: newTextExpr,
    );
  }
}

/// Generic statement to set any property of a node
class SetPropertyStatement extends Statement {
  final String targetNodeId;
  final String propertyName;
  final DartBlockAlgebraicExpression value;

  SetPropertyStatement({
    required this.targetNodeId,
    required this.propertyName,
    required this.value,
  });

  @override
  Future<void> execute(DartBlockExecutor executor) async {
    final sceneController = executor.context['sceneController'] as SceneController?;
    if (sceneController == null) {
      throw Exception('SceneController not found in executor context');
    }

    final propertyValue = value.evaluate();
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
    return SetPropertyStatement(
      targetNodeId: json['targetNodeId'] as String,
      propertyName: json['propertyName'] as String,
      value: _StringLiteralExpression(json['value'].toString()),
    );
  }
}

/// Statement to show or hide a node
class SetNodeVisibleStatement extends Statement {
  final String targetNodeId;
  final DartBlockAlgebraicExpression visible;

  SetNodeVisibleStatement({
    required this.targetNodeId,
    required this.visible,
  });

  @override
  Future<void> execute(DartBlockExecutor executor) async {
    final sceneController = executor.context['sceneController'] as SceneController?;
    if (sceneController == null) {
      throw Exception('SceneController not found in executor context');
    }

    final isVisible = visible.evaluate() as bool;
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
    return SetNodeVisibleStatement(
      targetNodeId: json['targetNodeId'] as String,
      visible: _BoolLiteralExpression(json['visible'] as bool? ?? true),
    );
  }
}

/// Statement to navigate to another scene
class NavigateToSceneStatement extends Statement {
  final String sceneId;

  NavigateToSceneStatement({
    required this.sceneId,
  });

  @override
  Future<void> execute(DartBlockExecutor executor) async {
    final sceneController = executor.context['sceneController'] as SceneController?;
    if (sceneController == null) {
      throw Exception('SceneController not found in executor context');
    }

    // Load the target scene
    // Note: This requires a leafWidgetBuilder callback
    final leafWidgetBuilder = executor.context['leafWidgetBuilder'];
    if (leafWidgetBuilder != null) {
      await sceneController.loadScene(sceneId, leafWidgetBuilder);
    }
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
class PrintStatement extends Statement {
  final DartBlockAlgebraicExpression message;

  PrintStatement({
    required this.message,
  });

  @override
  Future<void> execute(DartBlockExecutor executor) async {
    final value = message.evaluate();
    print('[DartBlock] $value');
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'PrintStatement',
      'message': message.toJson(),
    };
  }

  factory PrintStatement.fromJson(Map<String, dynamic> json) {
    return PrintStatement(
      message: _StringLiteralExpression(json['message'] as String? ?? ''),
    );
  }
}

// Placeholder expression implementations
// These should be replaced with actual dartblock_code implementations

class _StringLiteralExpression extends DartBlockAlgebraicExpression {
  final String value;

  _StringLiteralExpression(this.value);

  @override
  dynamic evaluate() => value;

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'StringLiteral',
      'value': value,
    };
  }
}

class _BoolLiteralExpression extends DartBlockAlgebraicExpression {
  final bool value;

  _BoolLiteralExpression(this.value);

  @override
  dynamic evaluate() => value;

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'BoolLiteral',
      'value': value,
    };
  }
}
