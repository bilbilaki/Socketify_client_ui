# DartBlock Migration Examples

This document provides side-by-side examples of the placeholder code and the real dartblock_code implementations.

## Example 1: DartBlockProgram

### Before (Placeholder)
```dart
/// Placeholder types for DartBlock integration
class DartBlockProgram {
  final List<dynamic> statements;
  final List<dynamic> variables;

  DartBlockProgram({
    required this.statements,
    required this.variables,
  });

  factory DartBlockProgram.init(
    List<dynamic> statements,
    List<dynamic> variables,
  ) {
    return DartBlockProgram(
      statements: statements,
      variables: variables,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'statements': statements.map((s) => _statementToJson(s)).toList(),
      'variables': variables.map((v) => _variableToJson(v)).toList(),
    };
  }

  factory DartBlockProgram.fromJson(Map<String, dynamic> json) {
    return DartBlockProgram(
      statements: (json['statements'] as List<dynamic>?) ?? [],
      variables: (json['variables'] as List<dynamic>?) ?? [],
    );
  }
}
```

### After (Real Implementation)
```dart
// Import from dartblock_code
export 'package:dartblock_code/core/dartblock_program.dart' 
    show DartBlockProgram;

// Real DartBlockProgram from dartblock_code includes:
// - Typed statements: List<Statement>
// - Custom functions: List<DartBlockCustomFunction>
// - Main function: DartBlockCustomFunction
// - Language support: DartBlockTypedLanguage
// - Full serialization: toJson(), fromJson()
// - Code generation: toScript()
// - Tree representation: buildTree()
```

## Example 2: Statement Expressions

### Before (Placeholder)
```dart
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

// Usage in statement:
class SetTextStatement extends Statement {
  final DartBlockAlgebraicExpression newText;
  
  factory SetTextStatement.fromJson(Map<String, dynamic> json) {
    final newTextValue = json['newText'];
    final newTextExpr = _StringLiteralExpression(
      newTextValue as String? ?? ''
    );
    return SetTextStatement(
      targetNodeId: json['targetNodeId'] as String,
      newText: newTextExpr,
    );
  }
}
```

### After (Real Implementation)
```dart
// Import from dartblock_code
export 'package:dartblock_code/models/dartblock_value.dart' 
    show DartBlockStringValue, DartBlockValue;

// Usage in statement:
class SetTextStatement extends SocketifyStatement {
  final DartBlockValue newText;
  
  factory SetTextStatement.fromJson(Map<String, dynamic> json) {
    final newTextValue = json['newText'];
    final DartBlockValue newTextExpr;
    
    if (newTextValue is Map) {
      try {
        // Deserialize complex DartBlock value (expressions, variables, etc.)
        newTextExpr = DartBlockValue.fromJson(newTextValue);
      } catch (e) {
        // Fallback to simple string
        newTextExpr = DartBlockStringValue.init(
          newTextValue['value'] as String? ?? ''
        );
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
```

**Benefits**:
- Supports complex expressions (variables, operators, function calls)
- Proper type system (string, int, double, boolean)
- Full serialization/deserialization
- Tree-based expression evaluation

## Example 3: Boolean Expressions

### Before (Placeholder)
```dart
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

// Usage
visible: _BoolLiteralExpression(json['visible'] as bool? ?? true)
```

### After (Real Implementation)
```dart
// Import from dartblock_code
export 'package:dartblock_code/models/dartblock_value.dart' 
    show DartBlockBooleanExpression;

// Usage
final visibleValue = json['visible'];
final DartBlockBooleanExpression visibleExpr;

if (visibleValue is Map) {
  try {
    // Full boolean expression support (comparisons, logical operators, etc.)
    visibleExpr = DartBlockBooleanExpression.fromJson(visibleValue);
  } catch (e) {
    // Simple constant
    visibleExpr = DartBlockBooleanExpression.fromConstant(
      visibleValue['value'] as bool? ?? true
    );
  }
} else {
  // Simple constant
  visibleExpr = DartBlockBooleanExpression.fromConstant(
    visibleValue as bool? ?? true
  );
}
```

**Benefits**:
- Supports complex boolean expressions
- Comparison operators (<, >, ==, !=, etc.)
- Logical operators (AND, OR, NOT)
- Proper type checking

## Example 4: Executor

### Before (Placeholder)
```dart
class _BasicExecutor {
  final Map<String, dynamic> context;
  
  _BasicExecutor({required this.context});
  
  Future<void> execute(dynamic program) async {
    print('Executing program: $program');
  }
}

// Usage
final executor = _BasicExecutor(context: {
  'sceneController': this,
  'leafWidgetBuilder': leafWidgetBuilder,
});
await executor.execute(program);
```

### After (Real Implementation)
```dart
import 'package:dartblock_code/core/dartblock_executor.dart';
import 'package:dartblock_code/core/dartblock_program.dart';

class SocketifyExecutor {
  final SceneController sceneController;
  final DartBlockExecutor _executor;
  
  SocketifyExecutor({
    required this.sceneController,
    required DartBlockProgram program,
    this.leafWidgetBuilder,
  }) : _executor = DartBlockExecutor(program);
  
  Future<void> execute() async {
    await _executor.execute();
  }
  
  List<String> get consoleOutput => _executor.consoleOutput;
  dynamic get thrownException => _executor.thrownException;
}

// Usage
final executor = SocketifyExecutor(
  sceneController: this,
  program: node.onInteractionScript!,
  leafWidgetBuilder: leafWidgetBuilder,
);
await executor.execute();
```

**Benefits**:
- Full DartBlock execution engine
- Variable scoping and environments
- Exception handling
- Console output tracking
- Isolate-based execution (for performance)
- Timeout protection
- Function calls (native and custom)

## Example 5: DartBlockEditor Integration

### Before (Placeholder)
```dart
Widget _buildDartBlockEditorPlaceholder(
  BuildContext context,
  SceneController controller,
) {
  return Container(
    padding: const EdgeInsets.all(16),
    child: Text('The DartBlock visual programming editor will appear here.'),
  );
}
```

### After (Real Implementation)
```dart
import 'package:dartblock_code/widgets/dartblock_editor.dart';

Widget _buildDartBlockEditor(
  BuildContext context,
  SceneController controller,
) {
  return DartBlockEditor(
    program: _program,
    canChange: true,    // Allow adding/editing
    canDelete: true,    // Allow deletion
    canReorder: true,   // Allow reordering
    canRun: true,       // Show run button
    onChanged: (changedProgram) {
      setState(() {
        _program = changedProgram;
        _hasChanges = true;
      });
    },
    onInteraction: (interaction) {
      // Handle user interactions
      print('DartBlock interaction: ${interaction.type}');
    },
  );
}
```

**Benefits**:
- Full visual programming interface
- Drag-and-drop statement creation
- Expression editor
- Variable management
- Custom function support
- Console output display
- Code export (Java, etc.)
- Built-in help system

## Type System Comparison

### Placeholder Types
```dart
class DartBlockVariable {
  final String name;
  final String type;  // Just a string!
  dynamic value;      // No type safety
}
```

### Real Types
```dart
// Strong type system
enum DartBlockDataType {
  integerType,
  doubleType,
  booleanType,
  stringType,
}

class DartBlockVariableDefinition {
  final String name;
  final DartBlockDataType dataType;  // Typed!
}

// Type-safe values
sealed class DartBlockValue<T> {
  T getValue(DartBlockArbiter arbiter);
  DartBlockValue copy();
  String toScript({DartBlockTypedLanguage language});
}

// Specific implementations
class DartBlockStringValue extends DartBlockValue<String> { ... }
class DartBlockVariable extends DartBlockDynamicValue { ... }
class DartBlockAlgebraicExpression 
    extends DartBlockExpressionValue<num, DartBlockValueTreeAlgebraicNode> { ... }
```

## Summary of Improvements

| Feature | Placeholder | Real Implementation |
|---------|------------|---------------------|
| Type Safety | ❌ dynamic types | ✅ Strong typing |
| Expressions | ❌ String literals only | ✅ Full expressions (variables, operators, functions) |
| Execution | ❌ Print only | ✅ Full interpreter with scoping |
| Editor | ❌ Placeholder text | ✅ Full visual editor |
| Serialization | ❌ Basic JSON | ✅ Complete with validation |
| Code Generation | ❌ None | ✅ Java export |
| Error Handling | ❌ Basic exceptions | ✅ Typed exceptions with context |
| Functions | ❌ Not supported | ✅ Custom + native functions |
| Testing | ❌ No infrastructure | ✅ Built-in validation |

## Migration Checklist

- [x] Replace dart_block_types.dart with exports
- [x] Update executor to use real DartBlockExecutor
- [x] Replace placeholder expressions with real value types
- [x] Update statement deserialization
- [x] Add DartBlockEditor import
- [x] Fix DartBlockProgram.init() calls
- [x] Remove all placeholder classes
- [ ] Integrate DartBlockEditor in UI (optional, has placeholder)
- [ ] Add comprehensive tests
- [ ] Document Socketify-specific extensions
