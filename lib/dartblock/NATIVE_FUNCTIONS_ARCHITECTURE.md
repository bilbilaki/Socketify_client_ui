# DartBlock Native Functions Architecture

## Overview

This document describes the **Native Functions** architecture for integrating Socketify UI operations with the DartBlock visual programming system.

## The Problem (Previous Approach)

Previously, we attempted to create custom `SocketifyStatement` classes that extended a base class but didn't integrate with the dartblock core. This was a **dead end** because:

1. **Language Extension Error**: We were trying to extend the *language syntax* instead of adding *library features*
2. **Parser Incompatibility**: The `DartBlockProgram.fromJson` parser doesn't recognize custom statement types
3. **Missing Context**: Custom statements expected `SceneController` but the standard executor only provides `DartBlockArbiter`

## The Solution: Native Functions

Instead of creating new statement types, we implement UI operations as **Native Functions**. This is how standard programming languages work (e.g., `print` is a native function, not a keyword).

### Architecture Components

```
┌─────────────────────────────────────────────────────────┐
│                  DartBlock Visual Editor                 │
│  User drags "Call Function" blocks and selects from     │
│  dropdown: setText, setProperty, setVisible, etc.       │
└─────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────┐
│              SocketifyNativeFunctions.all                │
│  Registry of all available UI manipulation functions     │
│  - setText(nodeId, text)                                │
│  - setProperty(nodeId, propName, value)                 │
│  - setVisible(nodeId, visible)                          │
│  - navigateToScene(sceneId)                             │
│  - printDebug(message)                                  │
│  - getNodeProperty(nodeId, propName)                    │
└─────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────┐
│                  SocketifyArbiter                        │
│  Custom DartBlockExecutor that holds SceneController    │
│  Provides execution context for native functions        │
└─────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────┐
│                  SceneController                         │
│  Performs actual UI updates (updateNodeConfig, etc.)    │
└─────────────────────────────────────────────────────────┘
```

## File Structure

### 1. `socketify_arbiter.dart`
Custom executor that extends `DartBlockExecutor` and holds a reference to `SceneController`.

```dart
class SocketifyArbiter extends DartBlockExecutor {
  final SceneController sceneController;
  // Provides execution context for native functions
}
```

### 2. `native_functions.dart`
Registry of all UI manipulation functions available in the visual editor.

```dart
class SocketifyNativeFunctions {
  static List<DartBlockNativeFunction> get all => [
    setText,      // Updates text property
    setProperty,  // Updates any property
    setVisible,   // Shows/hides nodes
    // ... more functions
  ];
}
```

Each function:
- Defines parameters with proper types
- Validates arbiter type (must be `SocketifyArbiter`)
- Extracts arguments and performs UI operations
- Returns appropriate values or null (for void functions)

### 3. `socketify_executor.dart`
Simplified wrapper around `SocketifyArbiter` that provides the execution interface used throughout Socketify.

```dart
class SocketifyExecutor {
  final SocketifyArbiter _arbiter;
  
  Future<void> execute() async {
    await _arbiter.execute();
  }
}
```

### 4. `dart_block_types.dart`
Central export file that re-exports dartblock_code types plus native function types.

## Integration Points

### In PropertiesPanel (Visual Editor)

```dart
// TODO: When integrating DartBlockEditor widget:
DartBlockEditor(
  program: _program,
  nativeFunctions: SocketifyNativeFunctions.all,  // <-- Register UI functions
  canChange: true,
  onChanged: (changedProgram) {
    setState(() {
      _program = changedProgram;
      _hasChanges = true;
    });
  },
)
```

Users will see the native functions in the toolbox and can drag "Call Function" blocks to use them.

### In SceneController (Execution)

```dart
Future<void> executeNodeInteraction(String nodeId, ...) async {
  final executor = SocketifyExecutor(
    sceneController: this,
    program: node.onInteractionScript!,
  );
  await executor.execute();
}
```

## Available Native Functions

| Function | Parameters | Description |
|----------|-----------|-------------|
| `setText` | `nodeId: String, newText: String` | Updates the text property of a node |
| `setProperty` | `nodeId: String, propertyName: String, value: String` | Updates any property of a node |
| `setVisible` | `nodeId: String, visible: Boolean` | Shows or hides a node |
| `getNodeProperty` | `nodeId: String, propertyName: String` | Retrieves a property value from a node (returns String) |
| `printDebug` | `message: String` | Prints a debug message to console |
| `navigateToScene` | `sceneId: String` | Navigates to another scene (pending leafWidgetBuilder context) |

## Usage Example (Visual Programming)

In the DartBlock visual editor, a user would:

1. Drag a "Call Function" block
2. Select `setText` from the dropdown
3. Provide arguments:
   - `nodeId`: `"button_1"` (string literal or variable)
   - `newText`: `"Clicked!"` (string literal or variable)
4. The visual block executes as a function call using the registered native function

This generates a `FunctionCallStatement` that uses the standard dartblock execution flow.

## Benefits

✅ **Clean Integration**: Uses existing `FunctionCallStatement` blocks  
✅ **Standard Pattern**: Follows how real programming languages work  
✅ **No Parser Modification**: Doesn't require changing dartblock core  
✅ **Proper Context**: `SocketifyArbiter` provides SceneController access  
✅ **Maintainable**: Easy to add new functions without modifying language syntax  
✅ **Type Safe**: Proper parameter and return type definitions  

## Future Enhancements

- [ ] Complete `navigateToScene` by storing `leafWidgetBuilder` in `SocketifyArbiter`
- [ ] Add more native functions for animations, styling, etc.
- [ ] Create custom `DartBlockNativeFunctionCategory` for better organization in toolbox
- [ ] Add validation helpers for node existence and property types
- [ ] Implement async native functions for network operations

## Migration Notes

The old `ui_statements.dart` file with custom `SocketifyStatement` classes is now **deprecated** and should be replaced with native functions when needed. The architecture is fundamentally different:

**Old (Dead End)**:
- Custom Statement classes
- Direct SceneController access in execute()
- No integration with dartblock parser

**New (Correct)**:
- Native Functions registered in editor
- SocketifyArbiter provides context
- Standard FunctionCallStatement execution

## Reference

- DartBlock Package: https://github.com/aryobarzan/dartblock
- `DartBlockNativeFunction` API in dartblock_code package
- `DartBlockExecutor` and `DartBlockArbiter` execution model
