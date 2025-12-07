import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dartblock_code/widgets/dartblock_editor.dart' show DartBlockEditor;

import '../../controlers/scene_controler.dart';
import '../../models/scene/data_model.dart';
import '../../dartblock/dart_block_types.dart';
import '../../dartblock/socketify_executor.dart';

/// Properties panel for editing node properties and interaction scripts
class PropertiesPanel extends ConsumerStatefulWidget {
  final SceneNode node;

  const PropertiesPanel({
    super.key,
    required this.node,
  });

  @override
  ConsumerState<PropertiesPanel> createState() => _PropertiesPanelState();
}

class _PropertiesPanelState extends ConsumerState<PropertiesPanel> {
  late DartBlockProgram _program;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    
    // Initialize with existing script or create new empty program
    // DartBlockProgram.init takes List<Statement> and List<DartBlockCustomFunction>
    if (widget.node is SceneLeafNode) {
      final leaf = widget.node as SceneLeafNode;
      _program = leaf.onInteractionScript ?? 
          DartBlockProgram.init([], []); // Empty statements and custom functions
    } else {
      _program = DartBlockProgram.init([], []); // Empty statements and custom functions
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(sceneControllerProvider.notifier);
    final isLeafNode = widget.node is SceneLeafNode;

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Icon(
                  isLeafNode ? Icons.widgets : Icons.folder,
                  color: Colors.blue.shade700,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.node.name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'ID: ${widget.node.id}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Basic Properties Section
                  _buildSection(
                    'Basic Properties',
                    [
                      _buildPropertyRow('Name', widget.node.name),
                      _buildPropertyRow('ID', widget.node.id),
                      _buildPropertyRow('Type', isLeafNode ? 'Leaf Node' : 'Container Node'),
                      _buildPropertyRow('Locked', widget.node.locked ? 'Yes' : 'No'),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Interaction Script Section (only for leaf nodes)
                  if (isLeafNode) ...[
                    _buildSection(
                      'Interaction Script',
                      [
                        Text(
                          'Define what happens when the user interacts with this element.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // DartBlock Editor Placeholder
                        _buildDartBlockEditorPlaceholder(context, controller),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Footer Actions
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border(top: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _hasChanges ? () => _saveChanges(controller) : null,
                  child: const Text('Save'),
                ),
                if (isLeafNode) ...[
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () => _testScript(controller),
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Test Run'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildPropertyRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildDartBlockEditorPlaceholder(
    BuildContext context,
    SceneController controller,
  ) {
    // TODO: Integrate real DartBlockEditor widget from dartblock_code package
    // Example usage:
    // return DartBlockEditor(
    //   program: _program,
    //   canChange: true,
    //   canDelete: true,
    //   canReorder: true,
    //   canRun: true,
    //   onChanged: (changedProgram) {
    //     setState(() {
    //       _program = changedProgram;
    //       _hasChanges = true;
    //     });
    //   },
    // );
    
    // Placeholder for now
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey.shade50,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.code, color: Colors.blue.shade700),
              const SizedBox(width: 8),
              const Text(
                'DartBlock Editor',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'The DartBlock visual programming editor will appear here.',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            'Available blocks:',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 8),
          _buildBlockExample('Print', 'Print a message to console'),
          _buildBlockExample('Set Text', 'Change the text of a node'),
          _buildBlockExample('Set Property', 'Update any node property'),
          _buildBlockExample('Set Visible', 'Show or hide a node'),
          _buildBlockExample('Navigate', 'Navigate to another scene'),
          _buildBlockExample('If/Else', 'Conditional logic'),
          const SizedBox(height: 16),
          Text(
            'Environment Variables Available:',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 8),
          _buildAvailableVariables(controller),
        ],
      ),
    );
  }

  Widget _buildBlockExample(String name, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.blue.shade300,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.black87),
                children: [
                  TextSpan(
                    text: name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  TextSpan(
                    text: ' - $description',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailableVariables(SceneController controller) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildVariableItem('sceneName', controller.currentSceneName),
          _buildVariableItem('sceneId', controller.currentSceneId ?? 'null'),
          _buildVariableItem('topLevelNodeCount', '${controller.topLevelNodes.length}'),
        ],
      ),
    );
  }

  Widget _buildVariableItem(String name, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          children: [
            TextSpan(
              text: name,
              style: const TextStyle(
                color: Colors.blue,
                fontWeight: FontWeight.bold,
              ),
            ),
            const TextSpan(
              text: ' = ',
              style: TextStyle(color: Colors.black54),
            ),
            TextSpan(
              text: '"$value"',
              style: const TextStyle(color: Colors.green),
            ),
          ],
        ),
      ),
    );
  }

  void _saveChanges(SceneController controller) {
    if (widget.node is SceneLeafNode) {
      final leaf = widget.node as SceneLeafNode;
      
      // Update via SceneController to ensure proper state management
      controller.updateNodeInteractionScript(leaf.id, _program);
      
      setState(() {
        _hasChanges = false;
      });

      Navigator.of(context).pop();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Interaction script saved successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _testScript(SceneController controller) async {
    try {
      // Create executor with SceneController context
      final executor = SocketifyExecutor(
        sceneController: controller,
      );

      // Execute the program
      await executor.execute(_program);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Script executed successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Script execution failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
