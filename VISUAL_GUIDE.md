# Visual Guide to SceneTreeRenderer Refactoring

## Before and After Comparison

### BEFORE: Simple Container Rendering
```
┌─────────────────────────────────┐
│  Container (plain background)   │
│  ┌──────────────────────────┐  │
│  │ Child 1                  │  │
│  └──────────────────────────┘  │
│  ┌──────────────────────────┐  │
│  │ Child 2                  │  │
│  └──────────────────────────┘  │
│  ┌──────────────────────────┐  │
│  │ Child 3                  │  │
│  └──────────────────────────┘  │
└─────────────────────────────────┘
```

### AFTER: Styled Container with DartBlock Look
```
╔═══════════════════════════════════╗
║ 📊 Column Header (Green)          ║ ← Colored header
╠═══════════════════════════════════╣
║ ☰  ┌────────────────────────┐   ║ ← Drag handle
║    │ Child 1                │   ║
║    └────────────────────────┘   ║
║ ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  ║ ← Drop indicator
║ ☰  ┌────────────────────────┐   ║
║    │ Child 2                │   ║
║    └────────────────────────┘   ║
║ ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  ║
║ ☰  ┌────────────────────────┐   ║
║    │ Child 3                │   ║
║    └────────────────────────┘   ║
║ ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  ║ ← End drop target
╚═══════════════════════════════════╝
└── Card elevation (shadow)
```

## Container Type Color Scheme

```
┏━━━━━━━━━━━━━━━━━━┓
┃ 📊 Row (Blue)    ┃  Colors.blue.shade100 + Icons.view_week
┗━━━━━━━━━━━━━━━━━━┛

┏━━━━━━━━━━━━━━━━━━┓
┃ 📋 Column (Green)┃  Colors.green.shade100 + Icons.view_agenda
┗━━━━━━━━━━━━━━━━━━┛

┏━━━━━━━━━━━━━━━━━━┓
┃ 📚 Stack (Purple)┃  Colors.purple.shade100 + Icons.layers
┗━━━━━━━━━━━━━━━━━━┛

┏━━━━━━━━━━━━━━━━━━┓
┃ 🎯 Grid (Orange) ┃  Colors.orange.shade100 + Icons.grid_view
┗━━━━━━━━━━━━━━━━━━┛

┏━━━━━━━━━━━━━━━━━━┓
┃ 🏗️ Scaffold (Teal)┃  Colors.teal.shade100 + Icons.crop_landscape
┗━━━━━━━━━━━━━━━━━━┛

┏━━━━━━━━━━━━━━━━━━┓
┃ 🔧 Custom (Gray) ┃  Colors.grey.shade200 + Icons.widgets
┗━━━━━━━━━━━━━━━━━━┛
```

## Drag-and-Drop States

### 1. Normal State
```
┌────────────────────┐
│ ☰ Item A           │  ← Drag handle visible
└────────────────────┘
┌────────────────────┐
│ ☰ Item B           │
└────────────────────┘
```

### 2. Dragging Item A
```
┌────────────────────┐
│ ☰ Item A           │  ← Being dragged (moves with cursor)
└────────────────────┘
        ↓
━━━━━━━━━━━━━━━━━━━━  ← Blue line appears (drop indicator)
┌────────────────────┐
│ ☰ Item B (50%)     │  ← Ghost effect (opacity 0.5)
└────────────────────┘
```

### 3. Dropping Item A Above Item B
```
┌────────────────────┐
│ ☰ Item A           │  ← Dropped here
└────────────────────┘
┌────────────────────┐
│ ☰ Item B           │  ← Was here before
└────────────────────┘
```

## Empty Container State

### No Children
```
╔═══════════════════════════════╗
║ 📋 Column Header (Green)      ║
╠═══════════════════════════════╣
║                               ║
║    ┌─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┐   ║
║    │  Empty container   │   ║
║    │  Drag items here   │   ║ ← Placeholder with dashed border
║    └─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┘   ║
║                               ║
╚═══════════════════════════════╝
```

### Dragging Over Empty Container
```
╔═══════════════════════════════╗
║ 📋 Column Header (Green)      ║
╠═══════════════════════════════╣
║                               ║
║    ┏━━━━━━━━━━━━━━━━━━━━┓   ║
║    ┃   Drop here        ┃   ║ ← Highlighted (blue background)
║    ┃                    ┃   ║
║    ┗━━━━━━━━━━━━━━━━━━━━┛   ║
║                               ║
╚═══════════════════════════════╝
```

## Selection State

### Normal Container
```
╔═══════════════════════════════╗  ← Gray border
║ 📋 Column Header (Green)      ║
╠═══════════════════════════════╣
║ [Children...]                 ║
╚═══════════════════════════════╝
```

### Selected Container
```
╔═══════════════════════════════╗  ← Blue border (2px)
║ 📋 Column Header (Green)      ║
╠═══════════════════════════════╣
║ [Children...]                 ║
╚═══════════════════════════════╝
```

## Component Architecture

```
SceneTreeRenderer
    │
    ├─→ SceneLeafNode → LongPressDraggable
    │                       (draggable widget)
    │
    └─→ SceneContainerNode → ContainerWidget
                                  │
                                  ├─→ Card (with elevation)
                                  │   │
                                  │   ├─→ Header (colored)
                                  │   │   ├─→ Icon
                                  │   │   └─→ Label
                                  │   │
                                  │   └─→ Body
                                  │       └─→ ContainerChildrenListView
                                  │               │
                                  │               ├─→ Empty Placeholder
                                  │               │   └─→ DragTarget
                                  │               │
                                  │               └─→ ReorderableListView
                                  │                   ├─→ Child Items
                                  │                   │   ├─→ DragTarget (drop indicator)
                                  │                   │   ├─→ ReorderableDragStartListener
                                  │                   │   ├─→ Drag Handle Icon
                                  │                   │   └─→ SceneTreeRenderer (recursive)
                                  │                   │
                                  │                   └─→ End Drop Target
                                  │
                                  └─→ Circular Reference Checking
                                      └─→ _isDescendantOf()
```

## Drag-and-Drop Flow

```
1. User long-presses drag handle
   │
   ├─→ ReorderableDragStartListener activated
   │
   └─→ Item enters "dragging" state

2. User moves item over positions
   │
   ├─→ DragTarget.onWillAccept called
   │   │
   │   ├─→ _canAcceptDrop validates
   │   │   │
   │   │   ├─→ Check not null
   │   │   ├─→ Check not self
   │   │   └─→ Check not descendant (_isDescendantOf)
   │   │
   │   └─→ Returns true/false
   │
   └─→ If accepted, show blue line indicator

3. User releases item
   │
   ├─→ DragTarget.onAccept called
   │   │
   │   └─→ controller.moveNodeToContainer()
   │
   └─→ State updates, UI rebuilds with new order
```

## Safety Features Visualization

### Circular Reference Prevention

```
ALLOWED:
Container A
    ├─ Container B
    │   └─ Widget X
    └─ Widget Y

✅ Can drag Widget X to Container A
✅ Can drag Widget Y to Container B


NOT ALLOWED:
Container A
    └─ Container B
        └─ Widget X

❌ Cannot drag Container A to Container B (circular!)
❌ Cannot drag Container A to Widget X position (descendant!)

The _isDescendantOf() method checks entire tree recursively.
```

## Performance Characteristics

```
Operation                    Complexity
─────────────────────────── ───────────
Render Container            O(1)
Render N Children           O(N)
Reorder Item                O(N)
Check Circular Reference    O(D×C)
    where D = tree depth
          C = children per level

Typical: D=3, C=5 → ~15 checks (fast)
```

## Integration Points

```
Scene Canvas (Top Level)
    │
    └─→ _SceneItemWidget (frame-based positioning)
            │
            └─→ SceneTreeRenderer
                    │
                    └─→ ContainerWidget (our new component)
                            │
                            └─→ Manages child list with drag-drop
```

## User Experience Flow

```
1. User sees container with colored header
   "Ah, this is a Column (green header)"

2. User sees drag handles on items
   "I can reorder these"

3. User drags an item
   "Blue line shows where it will go"
   "Ghost effect shows I'm dragging over something"

4. User drops item
   "List reorders smoothly"

5. User tries to drag container onto itself
   "Nothing happens - prevented"
   "System is protecting me from errors"
```

This visual guide helps understand the before/after differences and the
internal workings of the refactored SceneTreeRenderer.
