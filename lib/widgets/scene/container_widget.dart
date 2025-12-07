import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controlers/scene_controler.dart';
import '../../models/scene/data_model.dart';
import 'tree_renderer.dart';

/// A widget that renders a SceneContainerNode with a styled header and body,
/// similar to StatementWidget in DartBlock.
class ContainerWidget extends ConsumerWidget {
  static const double _cardElevation = 8.0;
  
  final SceneContainerNode container;

  const ContainerWidget({super.key, required this.container});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Determine container type label and color
    final String label;
    final Color headerColor;
    final IconData? iconData;

    switch (container.type) {
      case SceneContainerType.row:
        label = 'Row';
        headerColor = Colors.blue.shade100;
        iconData = Icons.view_week;
        break;
      case SceneContainerType.column:
        label = 'Column';
        headerColor = Colors.green.shade100;
        iconData = Icons.view_agenda;
        break;
      case SceneContainerType.stack:
        label = 'Stack';
        headerColor = Colors.purple.shade100;
        iconData = Icons.layers;
        break;
      case SceneContainerType.grid:
        label = 'Grid';
        headerColor = Colors.orange.shade100;
        iconData = Icons.grid_view;
        break;
      case SceneContainerType.scaffold:
        label = 'Scaffold';
        headerColor = Colors.teal.shade100;
        iconData = Icons.crop_landscape;
        break;
      case SceneContainerType.custom:
        label = container.config['customType'] as String? ?? 'Custom';
        headerColor = Colors.grey.shade200;
        iconData = Icons.widgets;
        break;
    }

    final isSelected = container.selected;

    return Card(
      elevation: _cardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? Colors.blueAccent : Theme.of(context).colorScheme.outline,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header section
          Container(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
            decoration: BoxDecoration(
              color: headerColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (iconData != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Icon(iconData, size: 16),
                  ),
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),
          // Body section with children
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: _buildContainerBody(context, ref, container),
          ),
        ],
      ),
    );
  }

  /// Build the body of the container, showing the children list view
  Widget _buildContainerBody(
    BuildContext context,
    WidgetRef ref,
    SceneContainerNode container,
  ) {
    // Return the children list view which manages drag-and-drop and reordering
    return ContainerChildrenListView(container: container);
  }
}

/// A ListView-like widget for rendering and managing children of a SceneContainerNode,
/// adapted from StatementListView logic in DartBlock.
class ContainerChildrenListView extends ConsumerWidget {
  static const double _dropTargetActiveHeight = 20.0;
  static const double _dropTargetInactiveHeight = 8.0;
  
  final SceneContainerNode container;

  const ContainerChildrenListView({super.key, required this.container});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (container.children.isEmpty) {
      return _buildEmptyPlaceholder(context, ref);
    }

    // Use Column with ReorderableListView for better drag-and-drop with visual feedback
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ReorderableListView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          buildDefaultDragHandles: false,
          onReorder: (oldIndex, newIndex) {
            _handleReorder(ref, oldIndex, newIndex);
          },
          children: container.children
              .asMap()
              .entries
              .map(
                (entry) => _buildReorderableListItem(
                  context: context,
                  ref: ref,
                  childNode: entry.value,
                  index: entry.key,
                ),
              )
              .toList(),
        ),
        // Drop target at the end
        _buildEndDropTarget(context, ref),
      ],
    );
  }

  Widget _buildEmptyPlaceholder(BuildContext context, WidgetRef ref) {
    return DragTarget<String>(
      onWillAccept: (data) => _canAcceptDrop(data, container.id),
      onAccept: (nodeId) {
        final controller = ref.read(sceneControllerProvider.notifier);
        controller.moveNodeToContainer(
          nodeId: nodeId,
          targetContainerId: container.id,
          newIndex: 0,
        );
      },
      builder: (context, candidateData, rejectedData) {
        final isActive = candidateData.isNotEmpty;
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isActive ? Colors.blue.shade50 : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isActive ? Colors.blueAccent : Colors.grey.shade300,
              width: isActive ? 2 : 1,
              style: BorderStyle.solid,
            ),
          ),
          child: Text(
            isActive ? 'Drop here' : 'Empty container\nDrag items here',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isActive ? Colors.blueAccent : Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                ),
          ),
        );
      },
    );
  }

  Widget _buildReorderableListItem({
    required BuildContext context,
    required WidgetRef ref,
    required SceneNode childNode,
    required int index,
  }) {
    // Build the drag target wrapper for dropping items
    return DragTarget<String>(
      key: ValueKey(childNode.id),
      onWillAccept: (data) => _canAcceptDrop(data, childNode.id, childNode),
      onAccept: (nodeId) {
        final controller = ref.read(sceneControllerProvider.notifier);
        controller.moveNodeToContainer(
          nodeId: nodeId,
          targetContainerId: container.id,
          newIndex: index,
        );
      },
      builder: (context, candidateData, rejectedData) {
        final isActive = candidateData.isNotEmpty;
        
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Blue line indicator when dragging over
            if (isActive)
              Container(
                height: 3,
                margin: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blueAccent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            // The actual child item with drag handle
            ReorderableDragStartListener(
              index: index,
              enabled: container.children.length > 1,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Drag handle (only show if more than 1 child)
                    if (container.children.length > 1)
                      Padding(
                        padding: const EdgeInsets.only(top: 4, right: 4),
                        child: Icon(
                          Icons.drag_handle,
                          size: 20,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    Expanded(
                      child: Opacity(
                        opacity: isActive ? 0.5 : 1.0,
                        child: SceneTreeRenderer(node: childNode),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEndDropTarget(BuildContext context, WidgetRef ref) {
    return DragTarget<String>(
      onWillAccept: (data) => _canAcceptDrop(data, container.id),
      onAccept: (nodeId) {
        final controller = ref.read(sceneControllerProvider.notifier);
        controller.moveNodeToContainer(
          nodeId: nodeId,
          targetContainerId: container.id,
          newIndex: container.children.length,
        );
      },
      builder: (context, candidateData, rejectedData) {
        final isActive = candidateData.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: isActive ? _dropTargetActiveHeight : _dropTargetInactiveHeight,
          margin: const EdgeInsets.symmetric(vertical: 2),
          decoration: BoxDecoration(
            color: isActive
                ? Colors.blueAccent.withOpacity(0.2)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: isActive
              ? Center(
                  child: Container(
                    height: 3,
                    decoration: BoxDecoration(
                      color: Colors.blueAccent,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                )
              : null,
        );
      },
    );
  }

  void _handleReorder(WidgetRef ref, int oldIndex, int newIndex) {
    final controller = ref.read(sceneControllerProvider.notifier);

    // Adjust newIndex if moving down
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    // Get the child node ID
    final nodeId = container.children[oldIndex].id;

    // Use the controller's moveNodeToContainer method
    controller.moveNodeToContainer(
      nodeId: nodeId,
      targetContainerId: container.id,
      newIndex: newIndex,
    );
  }

  /// Check if a drag operation can be accepted
  /// Prevents self-drops and circular references
  bool _canAcceptDrop(String? data, String targetId, [SceneNode? targetNode]) {
    if (data == null || data == targetId) return false;
    
    // If target is a container, check for circular references
    if (targetNode is SceneContainerNode) {
      return !_isDescendantOf(data, targetNode);
    }
    
    // For non-container targets, use container's descendant check
    return !_isDescendantOf(data, container);
  }

  /// Check if nodeId is a descendant of the given container (to prevent circular references)
  bool _isDescendantOf(String nodeId, SceneContainerNode container) {
    for (final child in container.children) {
      if (child.id == nodeId) return true;
      
      if (child is SceneContainerNode) {
        if (_isDescendantOf(nodeId, child)) return true;
      }
    }
    
    return false;
  }
}
