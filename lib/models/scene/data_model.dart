import 'package:flutter/material.dart';

/// Base node in the logical scene tree.
abstract class SceneNode {
  final String id;
  String name;
  bool locked;
  bool selected;

  /// Optional rect in the parent node's local space (for future hit-testing).
  Rect? localRect;

  SceneNode({
    required this.id,
    String? name,
    this.locked = false,
    this.selected = false,
    this.localRect,
  }) : name = name ?? id;
}

/// Leaf node: wraps any arbitrary widget.
class SceneLeafNode extends SceneNode {
  final Widget Function(BuildContext) builder;

  SceneLeafNode({
    required super.id,
    super.name,
    required this.builder,
    super.locked,
    super.selected,
    super.localRect,
  });
}

/// Supported built‑in container types.
enum SceneContainerType { column, row, stack, grid, scaffold, custom }

/// Container node: can have children that are other containers or leaves.
class SceneContainerNode extends SceneNode {
  SceneContainerType type;
  List<SceneNode> children;

  /// Free‑form configuration: alignment, axis counts, slots, etc.
  Map<String, dynamic> config;

  SceneContainerNode({
    required super.id,
    super.name,
    required this.type,
    this.children = const [],
    this.config = const {},
    super.locked,
    super.selected,
    super.localRect,
  });
}

/// Logical root of a scene tree.
class SceneRoot {
  SceneContainerNode root;

  SceneRoot({required this.root});
}

/// Canvas‑space frame for any node (leaf or container).
class SceneElementFrame {
  final String nodeId;
  Offset position; // on canvas
  Size size; // on canvas

  SceneElementFrame({
    required this.nodeId,
    required this.position,
    required this.size,
  });
}

/// Builder signature for pluggable container types.
typedef SceneContainerBuilder =
    Widget Function(
      BuildContext context,
      SceneContainerNode node,
      List<Widget> children,
    );

/// Registry for dynamic container/layout types.
class ContainerRegistry {
  static final Map<String, SceneContainerBuilder> _registry = {};

  static void register(String key, SceneContainerBuilder builder) {
    _registry[key] = builder;
  }

  static SceneContainerBuilder? get(String key) => _registry[key];

  /// Register a useful set of built‑in containers.
  static void registerBuiltIns() {
    if (_registry.isNotEmpty) return; // idempotent

    register('row', (context, node, children) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: children,
      );
    });

    register('column', (context, node, children) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      );
    });

    register('stack', (context, node, children) {
      return Stack(clipBehavior: Clip.none, children: children);
    });

    register('grid', (context, node, children) {
      final crossAxisCount = node.config['crossAxisCount'] as int? ?? 3;
      return GridView.count(
        crossAxisCount: crossAxisCount,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: children,
      );
    });

    register('scaffold', (context, node, children) {
      final bodyIndex = node.config['bodyIndex'] as int? ?? 0;
      final body = bodyIndex < children.length ? children[bodyIndex] : null;
      return Scaffold(
        appBar: AppBar(title: const Text('Dynamic Scaffold')),
        body: body,
      );
    });
  }
}
