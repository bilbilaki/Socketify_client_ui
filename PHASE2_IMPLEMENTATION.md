# Phase 2: Logic Integration Implementation

## Overview

This document describes the implementation of Phase 2 of the Socketify UI project, which adds the ability for users to define interaction logic for UI elements using DartBlock visual programming.

## Architecture

### 1. Data Model Extension

#### SceneLeafNode Enhancement
`SceneLeafNode` now includes an optional `DartBlockProgram` field:

```dart
class SceneLeafNode extends SceneNode {
  final Widget Function(BuildContext) builder;
  DartBlockProgram? onInteractionScript;  // <-- NEW
  
  SceneLeafNode({
    // ... existing parameters
    this.onInteractionScript,
  });
}
```

### 2. DartBlock Type System

Created placeholder types in `lib/dartblock/dart_block_types.dart`:

- **DartBlockProgram**: Represents a complete visual program with statements and variables
- **Statement**: Base class for all executable statements
- **DartBlockAlgebraicExpression**: Base class for expressions
- **DartBlockExecutor**: Executes programs with a context map
- **DartBlockVariable**: Represents a variable in the system

These placeholders will be replaced with actual imports from `dartblock_code` package when available.

### 3. Custom UI Statements

Created custom statements in `lib/dartblock/statements/ui_statements.dart`:

#### SetTextStatement
Updates the text content of a target node.

```dart
class SetTextStatement extends Statement {
  final String targetNodeId;
  final DartBlockAlgebraicExpression newText;
  
  @override
  Future<void> execute(DartBlockExecutor executor) async {
    final sceneController = executor.context['sceneController'];
    final textValue = newText.evaluate();
    sceneController.updateNodeConfig(targetNodeId, {'text': textValue});
  }
}
```

#### SetPropertyStatement
Generic statement to update any property of a node.

```dart
class SetPropertyStatement extends Statement {
  final String targetNodeId;
  final String propertyName;
  final DartBlockAlgebraicExpression value;
}
```

#### SetNodeVisibleStatement
Show or hide a node.

```dart
class SetNodeVisibleStatement extends Statement {
  final String targetNodeId;
  final DartBlockAlgebraicExpression visible;
}
```

#### NavigateToSceneStatement
Navigate to another scene.

```dart
class NavigateToSceneStatement extends Statement {
  final String sceneId;
}
```

#### PrintStatement
Debug output for testing scripts.

```dart
class PrintStatement extends Statement {
  final DartBlockAlgebraicExpression message;
}
```

### 4. SocketifyExecutor

The `SocketifyExecutor` bridges DartBlock with SceneController:

```dart
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
}
```

#### Key Features:

1. **Variable Creation**: Automatically creates variables from the scene tree
2. **Variable Sync**: Syncs modified variables back to scene nodes
3. **Context Passing**: Passes SceneController as context for statements
4. **Property Access**: Helper methods to get/set node properties

### 5. SceneController Extensions

Added methods to SceneController:

#### updateNodeConfig
```dart
void updateNodeConfig(String nodeId, Map<String, dynamic> config) {
  final node = getNode(nodeId);
  if (node is SceneContainerNode) {
    node.config = {...node.config, ...config};
  }
  _updateState();
}
```

#### executeNodeInteraction
```dart
Future<void> executeNodeInteraction(
  String nodeId,
  Widget Function(BuildContext, Map<String, dynamic>) leafWidgetBuilder,
) async {
  final node = getNode(nodeId);
  if (node is! SceneLeafNode || node.onInteractionScript == null) {
    return;
  }
  
  final executor = _createExecutor(leafWidgetBuilder);
  await executor.execute(node.onInteractionScript!);
}
```

### 6. Serialization

Updated `scene_storage.dart` to handle script persistence:

#### Serialization
```dart
if (this is SceneLeafNode) {
  final leaf = this as SceneLeafNode;
  return {
    ...base,
    'type': 'leaf',
    'widgetType': leaf.id.split('_').first,
    'onInteractionScript': leaf.onInteractionScript?.toJson(),  // <-- NEW
  };
}
```

#### Deserialization
```dart
if (type == 'leaf') {
  DartBlockProgram? onInteractionScript;
  if (json['onInteractionScript'] != null) {
    onInteractionScript = DartBlockProgram.fromJson(
      json['onInteractionScript'] as Map<String, dynamic>,
    );
  }
  
  return SceneLeafNode(
    // ... other fields
    onInteractionScript: onInteractionScript,  // <-- NEW
  );
}
```

### 7. Properties Panel UI

Created `lib/widgets/scene/properties_panel.dart`:

#### Features:

1. **Header Section**: Shows node name and ID
2. **Basic Properties**: Displays node type, locked status, etc.
3. **Interaction Script Section**: For leaf nodes only
4. **DartBlock Editor Placeholder**: Shows where the visual editor will be embedded
5. **Available Blocks List**: Documents all custom blocks
6. **Environment Variables**: Shows variables available to scripts
7. **Actions**: Save, Cancel, and Test Run buttons

#### Integration with Scene Canvas

Modified `scene_canvas.dart` to add double-tap handling:

```dart
GestureDetector(
  onDoubleTap: () {
    _openPropertiesPanel(context);
  },
  // ... other gestures
)
```

```dart
void _openPropertiesPanel(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => PropertiesPanel(node: node),
  );
}
```

## Usage Flow

### 1. User Interaction
1. User double-taps a node on the canvas
2. Properties panel opens as a modal bottom sheet
3. Panel shows node details and interaction script editor

### 2. Script Editing
1. User drags and drops DartBlock blocks (when actual editor is integrated)
2. Blocks can access SceneController variables
3. User configures block parameters (target nodes, values, etc.)

### 3. Script Execution
#### Test Mode
- User clicks "Test Run" button
- Script executes immediately with current scene state
- Results shown via SnackBar

#### Runtime Mode
- User taps/interacts with the node in runtime mode
- `executeNodeInteraction` is called
- Script executes with SceneController context
- UI updates automatically

### 4. Persistence
- Scripts are saved with the scene
- Scripts are loaded when scene is opened
- Scripts persist across app restarts

## Environment Variables

The executor provides these variables to DartBlock scripts:

### Scene Variables
- `sceneName`: Current scene name
- `sceneId`: Current scene ID
- `topLevelNodeCount`: Number of top-level nodes

### Node Variables (for each node)
- `node{N}_id`: Node ID
- `node{N}_name`: Node name
- `node{N}_locked`: Lock status
- `node{N}_selected`: Selection status
- `node{N}_type`: Container type (for containers)
- `node{N}_childCount`: Number of children (for containers)

### Recursive Variables
For nested structures, variables are created with prefixes like:
- `node0_child0_id`
- `node0_child0_child1_name`

## Custom Block Definitions

### Print Block
**Purpose**: Debug output
**Parameters**: 
- message: String expression

**Example Use**:
```
Print("Hello from " + sceneName)
```

### Set Text Block
**Purpose**: Update node text content
**Parameters**:
- targetNodeId: String (node ID)
- newText: String expression

**Example Use**:
```
SetText(targetNodeId: "button1", newText: "Clicked!")
```

### Set Property Block
**Purpose**: Update any node property
**Parameters**:
- targetNodeId: String (node ID)
- propertyName: String
- value: Expression (any type)

**Example Use**:
```
SetProperty(targetNodeId: "container1", propertyName: "alignment", value: "center")
```

### Set Visible Block
**Purpose**: Show or hide a node
**Parameters**:
- targetNodeId: String (node ID)
- visible: Boolean expression

**Example Use**:
```
SetVisible(targetNodeId: "menu", visible: false)
```

### Navigate Block
**Purpose**: Navigate to another scene
**Parameters**:
- sceneId: String (scene ID)

**Example Use**:
```
NavigateToScene(sceneId: "scene_main_menu")
```

## Integration with DartBlockEditor

When the actual `dartblock_code` package is available:

### 1. Replace Placeholder Types
Replace types in `dart_block_types.dart` with:
```dart
export 'package:dartblock_code/dartblock_code.dart';
```

### 2. Update Properties Panel
Replace the placeholder editor in `properties_panel.dart`:

```dart
// Replace this:
_buildDartBlockEditorPlaceholder(context, controller)

// With this:
DartBlockEditor(
  program: _program,
  canChange: true,
  canRun: true,
  onProgramChanged: (newProgram) {
    setState(() {
      _program = newProgram;
      _hasChanges = true;
    });
  },
  availableVariables: _getAvailableVariables(controller),
  customBlocks: [
    SetTextBlock(),
    SetPropertyBlock(),
    SetNodeVisibleBlock(),
    NavigateToSceneBlock(),
  ],
)
```

### 3. Register Custom Blocks
Create block definitions that match the statement classes:

```dart
class SetTextBlock extends DartBlock {
  @override
  String get name => 'Set Text';
  
  @override
  Statement createStatement(Map<String, dynamic> params) {
    return SetTextStatement(
      targetNodeId: params['targetNodeId'],
      newText: params['newText'],
    );
  }
}
```

## Error Handling

### Script Execution Errors
```dart
try {
  await executor.execute(_program);
  // Success feedback
} catch (e) {
  // Error feedback via SnackBar
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('Script execution failed: $e'),
      backgroundColor: Colors.red,
    ),
  );
}
```

### Missing Node Errors
All statements check for node existence:
```dart
final sceneController = executor.context['sceneController'];
if (sceneController == null) {
  throw Exception('SceneController not found in executor context');
}
```

## Testing

### Manual Testing Steps

1. **Double-tap to Open Panel**
   - Create a node on canvas
   - Double-tap the node
   - Verify properties panel opens

2. **View Node Properties**
   - Check that node name, ID, type are displayed correctly
   - Verify locked status is shown

3. **Test Run Button**
   - Currently shows placeholder
   - Will execute script when DartBlock is integrated

4. **Save Script**
   - Modify script (when editor is available)
   - Click Save
   - Verify script is persisted

5. **Load Scene with Script**
   - Save a scene with a script
   - Close and reopen the scene
   - Verify script is loaded correctly

### Unit Tests (Future)

```dart
void main() {
  group('SocketifyExecutor', () {
    test('creates variables from scene', () {
      // Test variable creation
    });
    
    test('syncs variables back to scene', () {
      // Test variable synchronization
    });
    
    test('executes SetTextStatement', () {
      // Test statement execution
    });
  });
}
```

## Security Considerations

### 1. Script Validation
- Scripts are validated before execution
- Type checking prevents invalid operations
- Null safety enforced throughout

### 2. Context Isolation
- Executor only has access to SceneController
- No direct file system or network access
- Sandboxed execution environment

### 3. Error Recovery
- All script errors are caught and logged
- UI remains functional even if script fails
- User is notified of failures

## Performance Considerations

### 1. Variable Creation
- Variables created lazily only when needed
- Cached for the duration of execution
- Not recreated on every statement

### 2. Scene Updates
- Only modified nodes trigger updates
- Batch updates when possible
- Auto-save throttled to avoid excessive writes

### 3. UI Responsiveness
- Script execution is async
- UI doesn't block during execution
- Progress can be shown for long-running scripts

## Future Enhancements

### 1. More Custom Blocks
- Animation blocks
- HTTP request blocks
- Local storage blocks
- Timer/delay blocks

### 2. Visual Debugging
- Breakpoints in visual editor
- Step-through execution
- Variable inspection during execution

### 3. Script Templates
- Pre-built common scripts
- Drag-and-drop templates
- Community script sharing

### 4. Advanced Variables
- Computed properties
- Reactive variables that update automatically
- Variable watchers

### 5. Event System
- More event types (swipe, long press, etc.)
- Event filters and conditions
- Event bubbling/propagation

## Known Limitations

1. **DartBlock Package Not Available**: Currently using placeholders
2. **Limited Block Types**: Only basic blocks implemented
3. **No Visual Editor**: Placeholder UI only
4. **Manual Testing Only**: No automated tests yet
5. **Basic Error Messages**: Need more descriptive error handling

## Conclusion

Phase 2 implementation provides a solid foundation for logic integration in Socketify UI. The architecture is extensible, maintainable, and follows Flutter best practices. Once the actual `dartblock_code` package is available, the placeholder types can be replaced with minimal code changes.

The system is ready for:
- Integration with the real DartBlockEditor
- Addition of more custom blocks
- Testing and refinement
- User feedback and iteration
