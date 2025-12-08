import 'package:flutter/material.dart';
import 'package:flutter_monaco_crossplatform/flutter_monaco_crossplatform.dart';

class MultiEditorView extends StatefulWidget {
  @override
  State<MultiEditorView> createState() => _MultiEditorViewState();
}

class _MultiEditorViewState extends State<MultiEditorView> {
  MonacoController? _dartController;
  MonacoController? _jsController;
  MonacoController? _markdownController;

  @override
  void initState() {
    super.initState();
    _initializeEditors();
  }

  Future<void> _initializeEditors() async {
    // Create three independent editors with type-safe configurations
    _dartController = await MonacoController.create(
      options: const EditorOptions(
        language: MonacoLanguage.dart,
        theme: MonacoTheme.vsDark,
        fontSize: 14,
        minimap: true,
      ),
    );
    
    _jsController = await MonacoController.create(
      options: const EditorOptions(
        language: MonacoLanguage.javascript,
        theme: MonacoTheme.vs,  // Light theme
        fontSize: 14,
        minimap: true,
      ),
    );
    
    _markdownController = await MonacoController.create(
      options: const EditorOptions(
        language: MonacoLanguage.markdown,
        theme: MonacoTheme.vsDark,
        fontSize: 15,
        wordWrap: true,
        minimap: false,
        lineNumbers: false,
      ),
    );
    
    // Set initial content
    await _dartController!.setValue('// Dart code');
    await _jsController!.setValue('// JavaScript code');
    await _markdownController!.setValue('# Markdown content');
    
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_dartController == null) {
      return const Center(child: CircularProgressIndicator());
    }
    
    return Column(
      children: [
        // Top row - Dart and JavaScript side by side
        Expanded(
          flex: 2,
          child: Row(
            children: [
              Expanded(child: _dartController!.webViewWidget),
              const VerticalDivider(width: 1),
              Expanded(child: _jsController!.webViewWidget),
            ],
          ),
        ),
        const Divider(height: 1),
        // Bottom - Markdown editor
        Expanded(
          child: _markdownController!.webViewWidget,
        ),
      ],
    );
  }

  @override
  void dispose() {
    _dartController?.dispose();
    _jsController?.dispose();
    _markdownController?.dispose();
    super.dispose();
  }
}