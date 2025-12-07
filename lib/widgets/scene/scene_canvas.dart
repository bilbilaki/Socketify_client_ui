import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controlers/scene_controler.dart';
import '../../models/scene/data_model.dart';
import 'tree_renderer.dart';

class SceneCanvas extends ConsumerWidget {
  const SceneCanvas({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(sceneControllerProvider.notifier);
    final state = ref.watch(sceneControllerProvider);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanUpdate: (details) {
        controller.pan(details.delta);
      },
      child: CustomPaint(
        painter: _GridPainter(
          offset: state.sceneOffset,
          scale: state.sceneScale,
        ),
        child: Transform.translate(
          offset: state.sceneOffset,
          child: Transform.scale(
            scale: state.sceneScale,
            alignment: Alignment.topLeft,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                for (final node in state.scene.root.children)
                  _SceneItemWidget(node: node),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  final Offset offset;
  final double scale;

  _GridPainter({required this.offset, required this.scale});

  @override
  void paint(Canvas canvas, Size size) {
    // Basic infinite grid illusion
    final paint = Paint()
      ..color = Colors.grey.withOpacity(0.2)
      ..strokeWidth = 1.0;

    const baseStep = 50.0; // logical units
    final step = baseStep * scale;

    final startX = (offset.dx % step) - step;
    final startY = (offset.dy % step) - step;

    for (double x = startX; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = startY; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Optional axes
    final axisPaint = Paint()
      ..color = Colors.blueAccent.withOpacity(0.4)
      ..strokeWidth = 1.5;

    final origin = offset;
    canvas.drawLine(
      Offset(0, origin.dy),
      Offset(size.width, origin.dy),
      axisPaint,
    );
    canvas.drawLine(
      Offset(origin.dx, 0),
      Offset(origin.dx, size.height),
      axisPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) {
    return oldDelegate.offset != offset || oldDelegate.scale != scale;
  }
}

class _SceneItemWidget extends ConsumerWidget {
  final SceneNode node;

  const _SceneItemWidget({required this.node});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(sceneControllerProvider.notifier);
    final state = ref.watch(sceneControllerProvider);
    final frame = state.framesByNodeId[node.id]!;
    final isContainer = node is SceneContainerNode;

    final borderColor = node.locked
        ? Colors.redAccent
        : (node.selected
              ? (isContainer ? Colors.deepPurple : Colors.blueAccent)
              : (isContainer ? Colors.grey.shade600 : Colors.grey));

    return Positioned(
      left: frame.position.dx,
      top: frame.position.dy,
      width: frame.size.width,
      height: frame.size.height,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTapDown: (details) {
          final multi = _isMultiSelectPressed();
          controller.toggleSelection(node.id, multi: multi);
        },
        onPanStart: (details) {
          controller.startDragFrame(node.id, details.globalPosition);
        },
        onPanUpdate: (details) {
          controller.updateDragFrame(node.id, details.globalPosition);
        },
        onPanEnd: (_) => controller.endDragFrame(node.id),
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: borderColor, width: 1.5),
                color: node.locked
                    ? Colors.grey.withOpacity(0.2)
                    : Colors.white.withOpacity(0.8),
              ),
              child: ClipRect(child: SceneTreeRenderer(node: node)),
            ),
            if (!node.locked) ...[
              _buildHandle(
                context,
                ref,
                Alignment.topLeft,
                ResizeHandle.topLeft,
              ),
              _buildHandle(
                context,
                ref,
                Alignment.topRight,
                ResizeHandle.topRight,
              ),
              _buildHandle(
                context,
                ref,
                Alignment.bottomLeft,
                ResizeHandle.bottomLeft,
              ),
              _buildHandle(
                context,
                ref,
                Alignment.bottomRight,
                ResizeHandle.bottomRight,
              ),
            ],
            if (node.locked)
              const Positioned(
                top: 4,
                right: 4,
                child: Icon(Icons.lock, size: 16, color: Colors.redAccent),
              ),
          ],
        ),
      ),
    );
  }

  static bool _isMultiSelectPressed() {
    final pressed = RawKeyboard.instance.keysPressed;
    return pressed.contains(LogicalKeyboardKey.controlLeft) ||
        pressed.contains(LogicalKeyboardKey.controlRight) ||
        pressed.contains(LogicalKeyboardKey.metaLeft) ||
        pressed.contains(LogicalKeyboardKey.metaRight);
  }

  Widget _buildHandle(
    BuildContext context,
    WidgetRef ref,
    Alignment alignment,
    ResizeHandle handle,
  ) {
    final controller = ref.read(sceneControllerProvider.notifier);

    return Align(
      alignment: alignment,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onPanUpdate: (details) {
          controller.resizeFrame(node.id, details.globalPosition, handle);
        },
        child: Container(
          width: 10,
          height: 10,
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: node.locked ? Colors.redAccent : Colors.blueAccent,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
