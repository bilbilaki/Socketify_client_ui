import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:xterm/xterm.dart';

class VirtualKeyBar extends StatefulWidget {
  final Terminal terminal;

  VirtualKeyBar({required this.terminal, super.key});

  @override
  _VirtualKeyBarState createState() => _VirtualKeyBarState();
}

class _VirtualKeyBarState extends State<VirtualKeyBar> {
  bool _ctrlActive = false;
  bool _altActive = false;

  bool ctrlkey() => _ctrlActive;
  bool altkey() => _altActive;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 45,
      color: Colors.grey[900], // Dark background for contrast
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _modifierButton(
            "CTRL",
            _ctrlActive,
            () => setState(() => _ctrlActive = !_ctrlActive),
          ),
          _modifierButton(
            "ALT",
            _altActive,
            () => setState(() => _altActive = !_altActive),
          ),
          _keyButton("TAB", TerminalKey.tab),
          _keyButton("ESC", TerminalKey.escape),
          _keyButton("▲", TerminalKey.arrowUp),
          _keyButton("▼", TerminalKey.arrowDown),
          _keyButton("◀", TerminalKey.arrowLeft),
          _keyButton("▶", TerminalKey.arrowRight),
          _actionButton("PASTE", () => _handlePaste()),
        ],
      ),
    );
  }

  // Handle Standard Keys (Arrows, Tab, Esc)
  Widget _keyButton(String label, TerminalKey key) {
    return _baseButton(label, () => widget.terminal.keyInput(key));
  }

  // Handle Modifiers (Toggle styling)
  Widget _modifierButton(String label, bool isActive, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Material(
        color: isActive ? Colors.blueAccent : Colors.grey[800],
        borderRadius: BorderRadius.circular(4),
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            alignment: Alignment.center,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Generic Action Button
  Widget _actionButton(String label, VoidCallback onTap) {
    return _baseButton(label, onTap);
  }

  Widget _baseButton(String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Material(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(4),
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            alignment: Alignment.center,
            child: Text(label, style: const TextStyle(color: Colors.white)),
          ),
        ),
      ),
    );
  }

  Future<void> _handlePaste() async {
    try {
      final data = await Clipboard.getData('text/plain');
      if (data?.text != null) {
        widget.terminal.paste(data!.text!);
      }
    } catch (e) {
      debugPrint('Failed to paste: $e');
    }
  }
}
