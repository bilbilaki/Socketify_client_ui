# Phase 2: Usage Examples

## Overview

This document provides practical examples of how to use the Phase 2 Logic Integration features in Socketify UI.

## Basic Usage

### 1. Opening the Properties Panel

**User Action**: Double-tap any node on the canvas

**What Happens**:
```
User double-taps button widget
    ↓
SceneCanvas detects gesture
    ↓
Opens PropertiesPanel modal
    ↓
Shows node information and script editor
```

**Code**:
```dart
// In scene_canvas.dart
GestureDetector(
  onDoubleTap: () {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PropertiesPanel(node: node),
    );
  },
  // ...
)
```

### 2. Creating a Simple Script

**Scenario**: Make a button print a message when clicked

**Visual Blocks** (when DartBlock editor is available):
```
┌─────────────────────────┐
│ Print                   │
│ message: "Hello World!" │
└─────────────────────────┘
```

**Equivalent Code**:
```dart
final program = DartBlockProgram(
  statements: [
    PrintStatement(
      message: _StringLiteralExpression("Hello World!"),
    ),
  ],
  variables: [],
);

leafNode.onInteractionScript = program;
```

### 3. Updating Node Text

**Scenario**: Change button text when clicked

**Visual Blocks**:
```
┌──────────────────────────────┐
│ Set Text                     │
│ targetNodeId: "button1"      │
│ newText: "Clicked!"          │
└──────────────────────────────┘
```

**Equivalent Code**:
```dart
final program = DartBlockProgram(
  statements: [
    SetTextStatement(
      targetNodeId: "button1",
      newText: _StringLiteralExpression("Clicked!"),
    ),
  ],
  variables: [],
);
```

## Intermediate Usage

### 4. Multiple Actions

**Scenario**: When button is clicked, update text and print message

**Visual Blocks**:
```
┌──────────────────────────────┐
│ Set Text                     │
│ targetNodeId: "button1"      │
│ newText: "Clicked!"          │
└──────────────────────────────┘
        ↓
┌──────────────────────────────┐
│ Print                        │
│ message: "Button was clicked"│
└──────────────────────────────┘
```

**Equivalent Code**:
```dart
final program = DartBlockProgram(
  statements: [
    SetTextStatement(
      targetNodeId: "button1",
      newText: _StringLiteralExpression("Clicked!"),
    ),
    PrintStatement(
      message: _StringLiteralExpression("Button was clicked"),
    ),
  ],
  variables: [],
);
```

### 5. Show/Hide Elements

**Scenario**: Toggle visibility of a menu

**Visual Blocks**:
```
┌──────────────────────────────┐
│ Set Visible                  │
│ targetNodeId: "menu_panel"   │
│ visible: false               │
└──────────────────────────────┘
```

**Equivalent Code**:
```dart
final program = DartBlockProgram(
  statements: [
    SetNodeVisibleStatement(
      targetNodeId: "menu_panel",
      visible: _BoolLiteralExpression(false),
    ),
  ],
  variables: [],
);
```

### 6. Navigate to Another Scene

**Scenario**: Navigate to settings scene when button clicked

**Visual Blocks**:
```
┌──────────────────────────────┐
│ Navigate to Scene            │
│ sceneId: "scene_settings"    │
└──────────────────────────────┘
```

**Equivalent Code**:
```dart
final program = DartBlockProgram(
  statements: [
    NavigateToSceneStatement(
      sceneId: "scene_settings",
    ),
  ],
  variables: [],
);
```

## Advanced Usage

### 7. Using Variables (Future Enhancement)

**Scenario**: Increment a counter when button is clicked

**Visual Blocks**:
```
Variables:
  clickCount: Number = 0

┌──────────────────────────────┐
│ Set Variable                 │
│ variable: clickCount         │
│ value: clickCount + 1        │
└──────────────────────────────┘
        ↓
┌──────────────────────────────┐
│ Set Text                     │
│ targetNodeId: "counter_label"│
│ newText: "Clicks: " +        │
│          clickCount          │
└──────────────────────────────┘
```

### 8. Conditional Logic (Future Enhancement)

**Scenario**: Show different messages based on click count

**Visual Blocks**:
```
Variables:
  clickCount: Number = 0

┌──────────────────────────────┐
│ If clickCount < 5            │
│   ┌──────────────────────┐  │
│   │ Set Text             │  │
│   │ targetNodeId: "msg"  │  │
│   │ newText: "Keep going"│  │
│   └──────────────────────┘  │
│ Else                         │
│   ┌──────────────────────┐  │
│   │ Set Text             │  │
│   │ targetNodeId: "msg"  │  │
│   │ newText: "Well done!"│  │
│   └──────────────────────┘  │
└──────────────────────────────┘
```

### 9. Animation Sequence (Future Enhancement)

**Scenario**: Create a color animation when button is pressed

**Visual Blocks**:
```
┌──────────────────────────────┐
│ Set Property                 │
│ targetNodeId: "button1"      │
│ propertyName: "color"        │
│ value: Colors.red            │
└──────────────────────────────┘
        ↓
┌──────────────────────────────┐
│ Wait                         │
│ duration: 500ms              │
└──────────────────────────────┘
        ↓
┌──────────────────────────────┐
│ Set Property                 │
│ targetNodeId: "button1"      │
│ propertyName: "color"        │
│ value: Colors.blue           │
└──────────────────────────────┘
```

## Programming Patterns

### Pattern 1: Toggle Button

**Use Case**: Create a button that toggles between two states

**Implementation**:
```dart
// Use a variable to track state (when variables are supported)
Variables:
  isOn: Boolean = false

On Click:
  If isOn:
    Set Text(targetNodeId: "toggle_btn", newText: "OFF")
    Set Variable(isOn, false)
  Else:
    Set Text(targetNodeId: "toggle_btn", newText: "ON")
    Set Variable(isOn, true)
```

### Pattern 2: Navigation Menu

**Use Case**: Create a menu with multiple navigation buttons

**Implementation**:
```dart
// Button 1 Script
On Click:
  Navigate to Scene(sceneId: "scene_home")

// Button 2 Script
On Click:
  Navigate to Scene(sceneId: "scene_settings")

// Button 3 Script
On Click:
  Navigate to Scene(sceneId: "scene_about")
```

### Pattern 3: Form Validation (Future)

**Use Case**: Validate input before navigation

**Implementation**:
```dart
Variables:
  username: String = ""
  password: String = ""

On Submit Button Click:
  If username is empty:
    Set Text(targetNodeId: "error_msg", newText: "Username required")
  Else If password is empty:
    Set Text(targetNodeId: "error_msg", newText: "Password required")
  Else:
    Navigate to Scene(sceneId: "scene_dashboard")
```

### Pattern 4: Multi-Step Wizard

**Use Case**: Create a wizard with multiple steps

**Implementation**:
```dart
Variables:
  currentStep: Number = 1

On Next Button Click:
  Set Variable(currentStep, currentStep + 1)
  
  If currentStep == 2:
    Set Visible(targetNodeId: "step1_panel", visible: false)
    Set Visible(targetNodeId: "step2_panel", visible: true)
  Else If currentStep == 3:
    Set Visible(targetNodeId: "step2_panel", visible: false)
    Set Visible(targetNodeId: "step3_panel", visible: true)

On Back Button Click:
  Set Variable(currentStep, currentStep - 1)
  // Similar visibility toggling
```

## Integration with Scene Controller

### Accessing Scene Variables

**Available Variables**:
```dart
sceneName        // String: Current scene name
sceneId          // String: Current scene ID
topLevelNodeCount // Number: Count of top-level nodes

// For each node (example):
node0_id         // String: Node ID
node0_name       // String: Node name
node0_locked     // Boolean: Lock status
node0_selected   // Boolean: Selection status
node0_type       // String: Container type (for containers)
node0_childCount // Number: Children count (for containers)
```

**Using in Scripts**:
```dart
// Print scene name
┌──────────────────────────────┐
│ Print                        │
│ message: "Current scene: " + │
│          sceneName           │
└──────────────────────────────┘
```

### Programmatic Execution

**Trigger from Code**:
```dart
// In your Flutter widget
await sceneController.executeNodeInteraction(
  'button1',
  leafWidgetBuilder,
);
```

**Create Executor**:
```dart
// Create custom executor
final executor = SocketifyExecutor(
  sceneController: sceneController,
  leafWidgetBuilder: leafWidgetBuilder,
);

// Execute a program
await executor.execute(program);
```

## Testing Scripts

### Test Mode

1. **Open Properties Panel**: Double-tap a node
2. **Edit Script**: Use DartBlock editor (when available)
3. **Click "Test Run"**: Executes script immediately
4. **See Results**: Check console output and UI changes

### Runtime Mode

1. **Save Scene**: Save your scene with scripts attached
2. **Enter Runtime Mode**: Switch to runtime/preview mode
3. **Interact**: Tap/click nodes with scripts
4. **Scripts Execute**: Automatically on interaction

### Debugging

**Using Print Statements**:
```dart
┌──────────────────────────────┐
│ Print                        │
│ message: "Starting script"   │
└──────────────────────────────┘
        ↓
┌──────────────────────────────┐
│ Set Text                     │
│ targetNodeId: "button1"      │
│ newText: "Updated"           │
└──────────────────────────────┘
        ↓
┌──────────────────────────────┐
│ Print                        │
│ message: "Script complete"   │
└──────────────────────────────┘
```

**Check Console Output**:
```
[DartBlock] Starting script
[DartBlock] Script complete
```

## Error Handling

### Common Errors

**1. Node Not Found**
```
Error: SceneController not found in executor context
Solution: Ensure executor is created with valid SceneController
```

**2. Invalid Node ID**
```
Error: Node with ID 'invalid_id' not found
Solution: Verify node IDs in your scene before referencing them
```

**3. Type Mismatch**
```
Error: Cannot set property 'visible' to value of type String
Solution: Ensure property types match expected types (Boolean for visible)
```

### Error Recovery

All script errors are caught and displayed:
```dart
try {
  await executor.execute(program);
  // Show success message
} catch (e) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('Script execution failed: $e'),
      backgroundColor: Colors.red,
    ),
  );
}
```

## Best Practices

### 1. Node ID Management
- Use descriptive node IDs: `"login_button"` not `"button1"`
- Keep IDs consistent across saves
- Document node IDs in comments

### 2. Script Organization
- Keep scripts simple and focused
- Use one script per interaction type
- Comment complex logic

### 3. Performance
- Avoid long-running scripts
- Use async operations when available
- Minimize DOM updates

### 4. Testing
- Test scripts in isolation first
- Test with different scene states
- Test error cases (missing nodes, etc.)

### 5. Maintainability
- Use descriptive variable names
- Group related scripts
- Document expected behavior

## Migration Guide

### From Placeholder to Real DartBlock

When migrating from placeholders to the actual `dartblock_code` package:

1. **Update Imports**:
```dart
// Before
import '../dartblock/dart_block_types.dart';

// After
import 'package:dartblock_code/dartblock_code.dart';
```

2. **Update Properties Panel**:
```dart
// Replace placeholder with real editor
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
)
```

3. **Register Custom Blocks**:
```dart
// Register Socketify-specific blocks
DartBlockRegistry.registerBlock(SetTextBlock());
DartBlockRegistry.registerBlock(SetPropertyBlock());
DartBlockRegistry.registerBlock(SetNodeVisibleBlock());
DartBlockRegistry.registerBlock(NavigateToSceneBlock());
```

## Conclusion

This implementation provides a powerful yet simple way to add interactive logic to UI elements. The visual programming approach makes it accessible to non-programmers while remaining flexible enough for advanced use cases.

The system is designed to grow with your needs:
- Start with simple print statements
- Add text updates and property changes
- Implement navigation and complex logic
- Create custom blocks for your specific needs

For questions or issues, refer to the [PHASE2_IMPLEMENTATION.md](PHASE2_IMPLEMENTATION.md) document for technical details.
