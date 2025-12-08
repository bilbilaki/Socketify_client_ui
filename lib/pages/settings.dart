import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_monaco_crossplatform/flutter_monaco_crossplatform.dart';

// Define enums if not already defined elsewhere
enum MonacoLanguage { javascript } // Placeholder; add others if needed
enum MonacoTheme { vs, vsDark, hcBlack, hcLight }
enum CursorBlinking { blink, smooth, phase, expand, solid }
enum CursorStyle { line, block, underline, lineThin, blockOutline, underlineThin }
enum RenderWhitespace { none, boundary, selection, trailing, all }
enum AutoClosingBehavior { always, languageDefined, beforeWhitespace, never }

// Default values based on provided EditorOptions
var defaultOptions = EditorOptions(
  language: MonacoLanguage.javascript,
  theme: MonacoTheme.vsDark,
  fontSize: 14,
  fontFamily: 'Consolas, monospace',
  lineHeight: 1.4,
  wordWrap: true,
  minimap: false,
  lineNumbers: true,
  rulers: [80, 120],
  tabSize: 2,
  insertSpaces: true,
  readOnly: false,
  automaticLayout: true,
  scrollBeyondLastLine: true,
  smoothScrolling: false,
  cursorBlinking: CursorBlinking.blink,
  cursorStyle: CursorStyle.line,
  renderWhitespace: RenderWhitespace.selection,
  bracketPairColorization: true,
  formatOnPaste: false,
  formatOnType: false,
  quickSuggestions: true,
  parameterHints: true,
  hover: true,
  contextMenu: true,
  mouseWheelZoom: false,
  autoClosingBehavior: AutoClosingBehavior.languageDefined,
);

class EditorOptions {
  MonacoLanguage language;
  MonacoTheme theme;
  int fontSize;
  String fontFamily;
  double lineHeight;
  bool wordWrap;
  bool minimap;
  bool lineNumbers;
  List<int> rulers;
  int tabSize;
  bool insertSpaces;
  bool readOnly;
  bool automaticLayout;
  bool scrollBeyondLastLine;
  bool smoothScrolling;
  CursorBlinking cursorBlinking;
  CursorStyle cursorStyle;
  RenderWhitespace renderWhitespace;
  bool bracketPairColorization;
  bool formatOnPaste;
  bool formatOnType;
  bool quickSuggestions;
  bool parameterHints;
  bool hover;
  bool contextMenu;
  bool mouseWheelZoom;
  AutoClosingBehavior autoClosingBehavior;

  EditorOptions({
    required this.language,
    required this.theme,
    required this.fontSize,
    required this.fontFamily,
    required this.lineHeight,
    required this.wordWrap,
    required this.minimap,
    required this.lineNumbers,
    required this.rulers,
    required this.tabSize,
    required this.insertSpaces,
    required this.readOnly,
    required this.automaticLayout,
    required this.scrollBeyondLastLine,
    required this.smoothScrolling,
    required this.cursorBlinking,
    required this.cursorStyle,
    required this.renderWhitespace,
    required this.bracketPairColorization,
    required this.formatOnPaste,
    required this.formatOnType,
    required this.quickSuggestions,
    required this.parameterHints,
    required this.hover,
    required this.contextMenu,
    required this.mouseWheelZoom,
    required this.autoClosingBehavior,
  });

  Map<String, dynamic> toJson() => {
        'language': language.name,
        'theme': theme.name,
        'fontSize': fontSize,
        'fontFamily': fontFamily,
        'lineHeight': lineHeight,
        'wordWrap': wordWrap,
        'minimap': minimap,
        'lineNumbers': lineNumbers,
        'rulers': rulers,
        'tabSize': tabSize,
        'insertSpaces': insertSpaces,
        'readOnly': readOnly,
        'automaticLayout': automaticLayout,
        'scrollBeyondLastLine': scrollBeyondLastLine,
        'smoothScrolling': smoothScrolling,
        'cursorBlinking': cursorBlinking.name,
        'cursorStyle': cursorStyle.name,
        'renderWhitespace': renderWhitespace.name,
        'bracketPairColorization': bracketPairColorization,
        'formatOnPaste': formatOnPaste,
        'formatOnType': formatOnType,
        'quickSuggestions': quickSuggestions,
        'parameterHints': parameterHints,
        'hover': hover,
        'contextMenu': contextMenu,
        'mouseWheelZoom': mouseWheelZoom,
        'autoClosingBehavior': autoClosingBehavior.name,
      };

  factory EditorOptions.fromJson(Map<String, dynamic> json) => EditorOptions(
        language: MonacoLanguage.values.firstWhere((e) => e.name == json['language']),
        theme: MonacoTheme.values.firstWhere((e) => e.name == json['theme']),
        fontSize: json['fontSize'],
        fontFamily: json['fontFamily'],
        lineHeight: json['lineHeight'],
        wordWrap: json['wordWrap'],
        minimap: json['minimap'],
        lineNumbers: json['lineNumbers'],
        rulers: List<int>.from(json['rulers']),
        tabSize: json['tabSize'],
        insertSpaces: json['insertSpaces'],
        readOnly: json['readOnly'],
        automaticLayout: json['automaticLayout'],
        scrollBeyondLastLine: json['scrollBeyondLastLine'],
        smoothScrolling: json['smoothScrolling'],
        cursorBlinking: CursorBlinking.values.firstWhere((e) => e.name == json['cursorBlinking']),
        cursorStyle: CursorStyle.values.firstWhere((e) => e.name == json['cursorStyle']),
        renderWhitespace: RenderWhitespace.values.firstWhere((e) => e.name == json['renderWhitespace']),
        bracketPairColorization: json['bracketPairColorization'],
        formatOnPaste: json['formatOnPaste'],
        formatOnType: json['formatOnType'],
        quickSuggestions: json['quickSuggestions'],
        parameterHints: json['parameterHints'],
        hover: json['hover'],
        contextMenu: json['contextMenu'],
        mouseWheelZoom: json['mouseWheelZoom'],
        autoClosingBehavior: AutoClosingBehavior.values.firstWhere((e) => e.name == json['autoClosingBehavior']),
      );
}

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late EditorOptions _currentOptions;
  late EditorOptions _savedOptions;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? optionsJson = prefs.getString('editor_options');
    if (optionsJson != null) {
      _savedOptions = EditorOptions.fromJson(jsonDecode(optionsJson));
    } else {
      _savedOptions = defaultOptions;
    }
    setState(() {
      _currentOptions = _savedOptions;
    });
  }

  Future<void> _saveSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('editor_options', jsonEncode(_currentOptions.toJson()));
    _savedOptions = _currentOptions;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Settings saved')));
  }

  void _resetToDefaults() {
    setState(() {
      _currentOptions = defaultOptions;
    });
  }

  void _clearChanges() {
    setState(() {
      _currentOptions = _savedOptions;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Editor Settings')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // Language Dropdown
            DropdownButtonFormField<MonacoLanguage>(
              value: _currentOptions.language,
              items: MonacoLanguage.values.map((lang) => DropdownMenuItem(value: lang, child: Text(lang.name))).toList(),
              onChanged: (value) => setState(() => _currentOptions.language = value!),
              decoration: InputDecoration(labelText: 'Language'),
            ),
            // Theme Dropdown
            DropdownButtonFormField<MonacoTheme>(
              value: _currentOptions.theme,
              items: MonacoTheme.values.map((theme) => DropdownMenuItem(value: theme, child: Text(theme.name))).toList(),
              onChanged: (value) => setState(() => _currentOptions.theme = value!),
              decoration: InputDecoration(labelText: 'Theme'),
            ),
            // Font Size
            TextFormField(
              initialValue: _currentOptions.fontSize.toString(),
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Font Size'),
              onChanged: (value) => setState(() => _currentOptions.fontSize = int.tryParse(value) ?? _currentOptions.fontSize),
            ),
            // Font Family
            TextFormField(
              initialValue: _currentOptions.fontFamily,
              decoration: InputDecoration(labelText: 'Font Family'),
              onChanged: (value) => setState(() => _currentOptions.fontFamily = value),
            ),
            // Line Height
            TextFormField(
              initialValue: _currentOptions.lineHeight.toString(),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(labelText: 'Line Height'),
              onChanged: (value) => setState(() => _currentOptions.lineHeight = double.tryParse(value) ?? _currentOptions.lineHeight),
            ),
            // Word Wrap
            SwitchListTile(
              title: Text('Word Wrap'),
              value: _currentOptions.wordWrap,
              onChanged: (value) => setState(() => _currentOptions.wordWrap = value),
            ),
            // Minimap
            SwitchListTile(
              title: Text('Minimap'),
              value: _currentOptions.minimap,
              onChanged: (value) => setState(() => _currentOptions.minimap = value),
            ),
            // Line Numbers
            SwitchListTile(
              title: Text('Line Numbers'),
              value: _currentOptions.lineNumbers,
              onChanged: (value) => setState(() => _currentOptions.lineNumbers = value),
            ),
            // Rulers
            TextFormField(
              initialValue: _currentOptions.rulers.join(', '),
              decoration: InputDecoration(labelText: 'Rulers (comma-separated)'),
              onChanged: (value) => setState(() => _currentOptions.rulers = value.split(',').map((e) => int.tryParse(e.trim()) ?? 0).toList()),
            ),
            // Tab Size
            TextFormField(
              initialValue: _currentOptions.tabSize.toString(),
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Tab Size'),
              onChanged: (value) => setState(() => _currentOptions.tabSize = int.tryParse(value) ?? _currentOptions.tabSize),
            ),
            // Insert Spaces
            SwitchListTile(
              title: Text('Insert Spaces'),
              value: _currentOptions.insertSpaces,
              onChanged: (value) => setState(() => _currentOptions.insertSpaces = value),
            ),
            // Read Only
            SwitchListTile(
              title: Text('Read Only'),
              value: _currentOptions.readOnly,
              onChanged: (value) => setState(() => _currentOptions.readOnly = value),
            ),
            // Automatic Layout
            SwitchListTile(
              title: Text('Automatic Layout'),
              value: _currentOptions.automaticLayout,
              onChanged: (value) => setState(() => _currentOptions.automaticLayout = value),
            ),
            // Scroll Beyond Last Line
            SwitchListTile(
              title: Text('Scroll Beyond Last Line'),
              value: _currentOptions.scrollBeyondLastLine,
              onChanged: (value) => setState(() => _currentOptions.scrollBeyondLastLine = value),
            ),
            // Smooth Scrolling
            SwitchListTile(
              title: Text('Smooth Scrolling'),
              value: _currentOptions.smoothScrolling,
              onChanged: (value) => setState(() => _currentOptions.smoothScrolling = value),
            ),
            // Cursor Blinking
            DropdownButtonFormField<CursorBlinking>(
              value: _currentOptions.cursorBlinking,
              items: CursorBlinking.values.map((blinking) => DropdownMenuItem(value: blinking, child: Text(blinking.name))).toList(),
              onChanged: (value) => setState(() => _currentOptions.cursorBlinking = value!),
              decoration: InputDecoration(labelText: 'Cursor Blinking'),
            ),
            // Cursor Style
            DropdownButtonFormField<CursorStyle>(
              value: _currentOptions.cursorStyle,
              items: CursorStyle.values.map((style) => DropdownMenuItem(value: style, child: Text(style.name))).toList(),
              onChanged: (value) => setState(() => _currentOptions.cursorStyle = value!),
              decoration: InputDecoration(labelText: 'Cursor Style'),
            ),
            // Render Whitespace
            DropdownButtonFormField<RenderWhitespace>(
              value: _currentOptions.renderWhitespace,
              items: RenderWhitespace.values.map((whitespace) => DropdownMenuItem(value: whitespace, child: Text(whitespace.name))).toList(),
              onChanged: (value) => setState(() => _currentOptions.renderWhitespace = value!),
              decoration: InputDecoration(labelText: 'Render Whitespace'),
            ),
            // Bracket Pair Colorization
            SwitchListTile(
              title: Text('Bracket Pair Colorization'),
              value: _currentOptions.bracketPairColorization,
              onChanged: (value) => setState(() => _currentOptions.bracketPairColorization = value),
            ),
            // Format on Paste
            SwitchListTile(
              title: Text('Format on Paste'),
              value: _currentOptions.formatOnPaste,
              onChanged: (value) => setState(() => _currentOptions.formatOnPaste = value),
            ),
            // Format on Type
            SwitchListTile(
              title: Text('Format on Type'),
              value: _currentOptions.formatOnType,
              onChanged: (value) => setState(() => _currentOptions.formatOnType = value),
            ),
            // Quick Suggestions
            SwitchListTile(
              title: Text('Quick Suggestions'),
              value: _currentOptions.quickSuggestions,
              onChanged: (value) => setState(() => _currentOptions.quickSuggestions = value),
            ),
            // Parameter Hints
            SwitchListTile(
              title: Text('Parameter Hints'),
              value: _currentOptions.parameterHints,
              onChanged: (value) => setState(() => _currentOptions.parameterHints = value),
            ),
            // Hover
            SwitchListTile(
              title: Text('Hover'),
              value: _currentOptions.hover,
              onChanged: (value) => setState(() => _currentOptions.hover = value),
            ),
            // Context Menu
            SwitchListTile(
              title: Text('Context Menu'),
              value: _currentOptions.contextMenu,
              onChanged: (value) => setState(() => _currentOptions.contextMenu = value),
            ),
            // Mouse Wheel Zoom
            SwitchListTile(
              title: Text('Mouse Wheel Zoom'),
              value: _currentOptions.mouseWheelZoom,
              onChanged: (value) => setState(() => _currentOptions.mouseWheelZoom = value),
            ),
            // Auto Closing Behavior
            DropdownButtonFormField<AutoClosingBehavior>(
              value: _currentOptions.autoClosingBehavior,
              items: AutoClosingBehavior.values.map((behavior) => DropdownMenuItem(value: behavior, child: Text(behavior.name))).toList(),
              onChanged: (value) => setState(() => _currentOptions.autoClosingBehavior = value!),
              decoration: InputDecoration(labelText: 'Auto Closing Behavior'),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(onPressed: _clearChanges, child: Text('Clear')),
                ElevatedButton(onPressed: _saveSettings, child: Text('Save')),
                ElevatedButton(onPressed: _resetToDefaults, child: Text('Reset')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}