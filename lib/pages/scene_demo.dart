import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controlers/scene_controler.dart';
import '../models/scene/data_model.dart';
import '../services/scene_storage.dart';
import '../widgets/scene/scene_canvas.dart';

void main() {
  // Initialize container registry before app starts
  ContainerRegistry.registerBuiltIns();
  runApp(const SceneApp());
}

/// Build a widget from saved leaf node data
Widget buildLeafWidget(BuildContext ctx, Map<String, dynamic> json) {
  final widgetType = json['widgetType'] as String? ?? 'widget';

  switch (widgetType) {
    case 'titleText':
      return const Text(
        'Hello Title',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      );
    case 'form1':
      return const _SampleForm();
    case 'player1':
      return const _MockPlayer();
    default:
      return Center(child: Text('Widget: ${json['id']}'));
  }
}

class SceneApp extends StatelessWidget {
  const SceneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [
        sceneControllerProvider.overrideWith((ref) {
          // Build an example scene tree with a Column holder
          final rootContainer = SceneContainerNode(
            id: 'root',
            type: SceneContainerType.stack,
            children: [
              SceneContainerNode(
                id: 'col1',
                type: SceneContainerType.column,
                children: [
                  SceneLeafNode(
                    id: 'titleText',
                    builder: (ctx) => const Text(
                      'Hello Title',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SceneLeafNode(
                    id: 'form1',
                    builder: (ctx) => const _SampleForm(),
                  ),
                ],
              ),
              SceneLeafNode(
                id: 'player1',
                builder: (ctx) => const _MockPlayer(),
              ),
            ],
          );

          final scene = SceneRoot(root: rootContainer);

          final frames = <String, SceneElementFrame>{
            'col1': SceneElementFrame(
              nodeId: 'col1',
              position: const Offset(50, 50),
              size: const Size(320, 220),
            ),
            'player1': SceneElementFrame(
              nodeId: 'player1',
              position: const Offset(420, 120),
              size: const Size(320, 180),
            ),
          };

          return SceneController(
            SceneControllerState(scene: scene, framesByNodeId: frames),
          );
        }),
      ],
      child: MaterialApp(home: const _SceneEditorPage()),
    );
  }
}

class _SceneEditorPage extends ConsumerWidget {
  const _SceneEditorPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(sceneControllerProvider.notifier);
    final state = ref.watch(sceneControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: () => _showRenameDialog(context, controller,state),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(controller.currentSceneName),
              if (controller.isDirty)
                const Padding(
                  padding: EdgeInsets.only(left: 4),
                  child: Text('*', style: TextStyle(color: Colors.red)),
                ),
              const SizedBox(width: 4),
              const Icon(Icons.edit, size: 14),
            ],
          ),
        ),
        actions: [
          // New Scene
          IconButton(
            icon: const Icon(Icons.insert_drive_file_outlined),
            tooltip: 'New Scene',
            onPressed: () => _confirmNewScene(context, controller, state),
          ),
          // Save
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: 'Save Scene',
            onPressed: () => _saveScene(context, controller, state),
          ),
          // Save As
          IconButton(
            icon: const Icon(Icons.save_as),
            tooltip: 'Save Scene As...',
            onPressed: () => _saveSceneAs(context, controller, state),
          ),
          // Load (Scene History)
          IconButton(
            icon: const Icon(Icons.folder_open),
            tooltip: 'Load Scene',
            onPressed: () => _showLoadDialog(context, controller),
          ),
          const VerticalDivider(
            width: 16,
            thickness: 1,
            indent: 12,
            endIndent: 12,
          ),
          // Add empty container (Row or Column)
          PopupMenuButton<SceneContainerType>(
            icon: const Icon(Icons.dashboard_outlined),
            tooltip: 'Add empty container',
            onSelected: (type) {
              final id = 'container_${DateTime.now().millisecondsSinceEpoch}';

              final node = SceneContainerNode(
                id: id,
                name: '${type.name}_$id',
                type: type,
                children: const [],
              );

              controller.addTopLevelNode(
                node,
                SceneElementFrame(
                  nodeId: id,
                  position: const Offset(150, 150),
                  size: const Size(260, 200),
                ),
              );
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: SceneContainerType.column,
                child: Text('Column'),
              ),
              const PopupMenuItem(
                value: SceneContainerType.row,
                child: Text('Row'),
              ),
              const PopupMenuItem(
                value: SceneContainerType.stack,
                child: Text('Stack'),
              ),
              const PopupMenuItem(
                value: SceneContainerType.grid,
                child: Text('Grid'),
              ),
            ],
          ),
          // Add widget inside selected container
          Builder(
            builder: (builderContext) {
              final selectedId = controller.singleSelectedId;
              final canAddInside =
                  selectedId != null && controller.isContainer(selectedId);

              return IconButton(
                icon: Icon(
                  Icons.add_circle_outline,
                  color: canAddInside ? Colors.green : null,
                ),
                tooltip: canAddInside
                    ? 'Add widget inside selected container'
                    : 'Select a container first',
                onPressed: canAddInside
                    ? () {
                        final newId =
                            'widget_${DateTime.now().millisecondsSinceEpoch}';

                        final newNode = SceneLeafNode(
                          id: newId,
                          name: 'Widget $newId',
                          builder: (ctx) =>
                              const Center(child: Text('New Widget')),
                        );

                        controller.addChildToContainer(
                          parentId: selectedId,
                          child: newNode,
                        );
                      }
                    : null,
              );
            },
          ),
          // Add free widget (top-level)
          IconButton(
            icon: const Icon(Icons.add_box),
            tooltip: 'Add free widget',
            onPressed: () {
              final id = 'widget_${DateTime.now().millisecondsSinceEpoch}';

              final node = SceneLeafNode(
                id: id,
                name: 'Free Widget',
                builder: (ctx) => const Center(child: Text('Free Widget')),
              );

              controller.addTopLevelNode(
                node,
                SceneElementFrame(
                  nodeId: id,
                  position: const Offset(100, 100),
                  size: const Size(200, 120),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: 'Delete selected (if unlocked)',
            onPressed: () => controller.removeSelected(),
          ),
        ],
      ),
      body: const SceneCanvas(),
      bottomNavigationBar: const _BottomBar(),
    );
  }

  void _showRenameDialog(
    BuildContext context,
    SceneController controller,
    SceneControllerState state,
  ) {
    final textController = TextEditingController(text: state.currentSceneName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename Scene'),
        content: TextField(
          controller: textController,
          decoration: const InputDecoration(labelText: 'Scene Name'),
          autofocus: true,
          onSubmitted: (value) {
            if (value.isNotEmpty) {
              controller.renameCurrentScene(value);
            }
            Navigator.of(ctx).pop();
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (textController.text.isNotEmpty) {
                controller.renameCurrentScene(textController.text);
              }
              Navigator.of(ctx).pop();
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  void _confirmNewScene(
    BuildContext context,
    SceneController controller,
    SceneControllerState state,
  ) {
    if (!state.isDirty) {
      controller.newScene();
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Scene'),
        content: const Text(
          'You have unsaved changes. Do you want to save before creating a new scene?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              controller.newScene();
            },
            child: const Text('Don\'t Save'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await controller.saveScene();
              controller.newScene();
            },
            child: const Text('Save & New'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveScene(
    BuildContext context,
    SceneController controller,
    SceneControllerState state,
  ) async {
    if (state.currentSceneId == null) {
      // First time save, show Save As dialog
      _saveSceneAs(context, controller, state);
      return;
    }

    await controller.saveScene();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saved: ${state.currentSceneName}')),
      );
    }
  }

  void _saveSceneAs(
    BuildContext context,
    SceneController controller,
    SceneControllerState state,
  ) {
    final textController = TextEditingController(text: state.currentSceneName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Save Scene As'),
        content: TextField(
          controller: textController,
          decoration: const InputDecoration(labelText: 'Scene Name'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (textController.text.isEmpty) return;
              Navigator.of(ctx).pop();
              await controller.saveSceneAs(textController.text);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Saved: ${textController.text}')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showLoadDialog(BuildContext context, SceneController controller) {
    showDialog(
      context: context,
      builder: (ctx) => _SceneHistoryDialog(controller: controller),
    );
  }
}

/// Dialog showing scene history for loading
class _SceneHistoryDialog extends ConsumerStatefulWidget {
  final SceneController controller;

  const _SceneHistoryDialog({required this.controller});

  @override
  ConsumerState<_SceneHistoryDialog> createState() =>
      _SceneHistoryDialogState();
}

class _SceneHistoryDialogState extends ConsumerState<_SceneHistoryDialog> {
  List<SceneMeta>? _scenes;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadScenes();
  }

  Future<void> _loadScenes() async {
    final scenes = await widget.controller.getSavedScenes();
    if (mounted) {
      setState(() {
        _scenes = scenes;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Load Scene'),
      content: SizedBox(
        width: 400,
        height: 300,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _scenes == null || _scenes!.isEmpty
            ? const Center(
                child: Text(
                  'No saved scenes.\n\nSave a scene first to see it here.',
                  textAlign: TextAlign.center,
                ),
              )
            : ListView.builder(
                itemCount: _scenes!.length,
                itemBuilder: (ctx, index) {
                  final scene = _scenes![index];
                  final state = ref.read(sceneControllerProvider);
                  final isCurrentScene = scene.id == state.currentSceneId;

                  return ListTile(
                    leading: Icon(
                      isCurrentScene
                          ? Icons.check_circle
                          : Icons.insert_drive_file_outlined,
                      color: isCurrentScene ? Colors.green : null,
                    ),
                    title: Text(scene.name),
                    subtitle: Text(
                      _formatDate(scene.savedAt),
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.delete, size: 20),
                          tooltip: 'Delete',
                          onPressed: () => _confirmDelete(scene),
                        ),
                      ],
                    ),
                    onTap: isCurrentScene ? null : () => _loadScene(scene.id),
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _loadScene(String id) async {
    Navigator.of(context).pop();
    final controller = ref.read(sceneControllerProvider.notifier);
    final success = await controller.loadScene(id, buildLeafWidget);
    if (mounted && success) {
      final state = ref.read(sceneControllerProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Loaded: ${state.currentSceneName}')),
      );
    }
  }

  void _confirmDelete(SceneMeta scene) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Scene'),
        content: Text('Are you sure you want to delete "${scene.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final controller = ref.read(sceneControllerProvider.notifier);
              await controller.deleteScene(scene.id);
              _loadScenes();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _BottomBar extends ConsumerWidget {
  const _BottomBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(sceneControllerProvider.notifier);
    final selectedId = controller.singleSelectedId;
    final selectedNode = selectedId != null
        ? controller.getNode(selectedId)
        : null;

    // Check if selected node is inside a container (can be detached)
    final canDetach =
        selectedId != null && controller.isInsideContainer(selectedId);

    // Check if selected node is free top-level and overlaps a container (can be attached)
    final isFree = selectedId != null && controller.isFreeTopLevel(selectedId);
    final overlappingContainers = isFree
        ? controller.findOverlappingContainers(selectedId)
        : <String>[];
    final canAttach = overlappingContainers.isNotEmpty;

    return Container(
      color: Colors.grey.shade200,
      height: 56,
      child: Row(
        children: [
          const SizedBox(width: 8),
          Text('Selected: ${selectedId == null ? 0 : 1}'),
          const SizedBox(width: 16),
          if (selectedId != null)
            Builder(
              builder: (context) {
                final node = selectedNode;
                final locked = node?.locked ?? false;
                return TextButton.icon(
                  onPressed: () {
                    controller.setLocked(selectedId, !locked);
                  },
                  icon: Icon(locked ? Icons.lock_open : Icons.lock),
                  label: Text(locked ? 'Unlock' : 'Lock'),
                );
              },
            ),
          const SizedBox(width: 8),
          // Simple inline name editor for the selected node
          if (selectedNode != null)
            SizedBox(
              width: 140,
              child: TextField(
                controller: TextEditingController(text: selectedNode.name),
                decoration: const InputDecoration(
                  isDense: true,
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (value) {
                  if (value.isEmpty) return;
                  selectedNode.name = value;
                },
              ),
            ),
          const SizedBox(width: 8),
          // Detach button: only if node is inside a container
          if (canDetach)
            TextButton.icon(
              onPressed: () {
                controller.detachNodeToTopLevel(selectedId);
              },
              icon: const Icon(Icons.open_with, size: 18),
              label: const Text('Detach'),
            ),
          // Attach button: only if free node overlaps a container
          if (canAttach)
            TextButton.icon(
              onPressed: () {
                // Attach to the first overlapping container
                controller.attachNodeToContainer(
                  nodeId: selectedId!,
                  targetContainerId: overlappingContainers.first,
                );
              },
              icon: const Icon(Icons.input, size: 18),
              label: Text(
                'Attach to ${controller.getNode(overlappingContainers.first)?.name ?? overlappingContainers.first}',
              ),
            ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.zoom_out),
            onPressed: () {
              controller.setScale(controller.sceneScale - 0.1, Offset.zero);
            },
          ),
          Text(controller.sceneScale.toStringAsFixed(2)),
          IconButton(
            icon: const Icon(Icons.zoom_in),
            onPressed: () {
              controller.setScale(controller.sceneScale + 0.1, Offset.zero);
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}

// Example custom widget: "form" element
class _SampleForm extends StatelessWidget {
  const _SampleForm();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: const [
          Text('User Form', style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          TextField(decoration: InputDecoration(labelText: 'Name')),
          SizedBox(height: 8),
          TextField(decoration: InputDecoration(labelText: 'Email')),
        ],
      ),
    );
  }
}

// Example custom widget: "player" element
class _MockPlayer extends StatelessWidget {
  const _MockPlayer();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black87,
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.play_arrow, color: Colors.white),
            SizedBox(width: 8),
            Text('Player Widget', style: TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }
}
