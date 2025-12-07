import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controlers/scene_controler.dart';
import '../../models/scene/data_model.dart';
import 'container_widget.dart';

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
    // Use the new ContainerWidget for styled rendering
    return ContainerWidget(container: container);
  }
}
