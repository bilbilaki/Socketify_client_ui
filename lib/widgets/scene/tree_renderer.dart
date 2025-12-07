import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controlers/scene_controler.dart';
import '../../models/scene/data_model.dart';

/// Renders a SceneNode tree into real Flutter widgets, with drag targets
/// to reorder children and move nodes between containers.
class SceneTreeRenderer extends ConsumerWidget {
  final SceneNode node;

  const SceneTreeRenderer({super.key, required this.node});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (node is SceneLeafNode) {
      final leaf = node as SceneLeafNode;
      return _buildDraggableLeaf(context, leaf);
    }

    if (node is SceneContainerNode) {
      final container = node as SceneContainerNode;
      return _buildContainer(context, ref, container);
    }

    return const SizedBox.shrink();
  }

  Widget _buildDraggableLeaf(BuildContext context, SceneLeafNode leaf) {
    return LongPressDraggable<String>(
      data: leaf.id,
      feedback: Material(
        color: Colors.transparent,
        child: Opacity(opacity: 0.8, child: leaf.builder(context)),
      ),
      childWhenDragging: Opacity(opacity: 0.4, child: leaf.builder(context)),
      child: leaf.builder(context),
    );
  }

  Widget _buildContainer(
    BuildContext context,
    WidgetRef ref,
    SceneContainerNode container,
  ) {
    // Ensure built-in containers are available for registry-based builds
    ContainerRegistry.registerBuiltIns();

    final childrenWidgets = <Widget>[];
    for (var i = 0; i < container.children.length; i++) {
      final childNode = container.children[i];

      // Drop area before each child for reordering/moving into this container
      childrenWidgets.add(
        _buildDropTarget(
          context: context,
          ref: ref,
          targetContainer: container,
          insertIndex: i,
        ),
      );

      childrenWidgets.add(SceneTreeRenderer(node: childNode));
    }

    // Drop area at the end of the list
    childrenWidgets.add(
      _buildDropTarget(
        context: context,
        ref: ref,
        targetContainer: container,
        insertIndex: container.children.length,
      ),
    );

    // Prefer registry if available (including custom types)
    final key = container.type.name; // row/column/grid/etc.
    final customKey = container.config['customType'] as String?;
    final builder = (customKey != null)
        ? ContainerRegistry.get(customKey)
        : ContainerRegistry.get(key);

    Widget inner;
    if (builder != null) {
      inner = builder(context, container, childrenWidgets);
    } else {
      // Fallback: simple Column
      inner = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: childrenWidgets,
      );
    }

    final isSelected = container.selected;

    // Light background so containers are visually distinct.
    return Container(
      decoration: BoxDecoration(
        color: (isSelected
            ? Colors.blueGrey.withOpacity(0.12)
            : Colors.blueGrey.withOpacity(0.05)),
        borderRadius: BorderRadius.circular(6),
      ),
      padding: const EdgeInsets.all(4),
      child: inner,
    );
  }

  Widget _buildDropTarget({
    required BuildContext context,
    required WidgetRef ref,
    required SceneContainerNode targetContainer,
    required int insertIndex,
  }) {
    return DragTarget<String>(
      onWillAccept: (data) => data != null,
      onAccept: (nodeId) {
        final controller = ref.read(sceneControllerProvider.notifier);
        controller.moveNodeToContainer(
          nodeId: nodeId,
          targetContainerId: targetContainer.id,
          newIndex: insertIndex,
        );
      },
      builder: (context, candidateData, rejectedData) {
        final isActive = candidateData.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          height: isActive ? 12 : 4,
          margin: const EdgeInsets.symmetric(vertical: 2),
          decoration: BoxDecoration(
            color: isActive
                ? Colors.blueAccent.withOpacity(0.25)
                : Colors.transparent,
          ),
        );
      },
    );
  }
}
