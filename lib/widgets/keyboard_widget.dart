import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class KeyboardWidget extends StatefulWidget {
  final Function(List<int>) onSendCommand;

  const KeyboardWidget({super.key, required this.onSendCommand});

  @override
  State<KeyboardWidget> createState() => _KeyboardWidgetState();
}

class _KeyboardWidgetState extends State<KeyboardWidget> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  void _sendKeyPress(int keyCode) {
    widget.onSendCommand([
      0x04, // keyPress command
      (keyCode >> 8) & 0xFF,
      keyCode & 0xFF,
    ]);
  }

  void _sendText(String text) {
    // Send as key type command (0x06)
    final bytes = text.codeUnits;
    widget.onSendCommand([0x06, ...bytes]);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Text input field
          TextField(
            controller: _textController,
            focusNode: _focusNode,
            decoration: InputDecoration(
              hintText: 'Type text to send...',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: const Icon(Icons. send),
                onPressed: () {
                  if (_textController.text.isNotEmpty) {
                    _sendText(_textController.text);
                    _textController. clear();
                  }
                },
              ),
            ),
            onSubmitted: (text) {
              if (text.isNotEmpty) {
                _sendText(text);
                _textController.clear();
              }
            },
          ),
          
          const SizedBox(height: 24),
          
          // Special keys
          const Text('Special Keys', style: TextStyle(fontWeight: FontWeight. bold)),
          const SizedBox(height: 8),
          
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildKeyButton('Esc', 27),
              _buildKeyButton('Tab', 9),
              _buildKeyButton('Enter', 13),
              _buildKeyButton('Backspace', 8),
              _buildKeyButton('Delete', 46),
              _buildKeyButton('Space', 32),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Arrow keys
          const Text('Arrow Keys', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          
          Column(
            children: [
              _buildKeyButton('↑', 38),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildKeyButton('←', 37),
                  const SizedBox(width: 48),
                  _buildKeyButton('→', 39),
                ],
              ),
              _buildKeyButton('↓', 40),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Function keys
          const Text('Function Keys', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(12, (i) => _buildKeyButton('F${i + 1}', 112 + i)),
          ),
          
          const SizedBox(height: 24),
          
          // Media keys
          const Text('Media Keys', style: TextStyle(fontWeight: FontWeight. bold)),
          const SizedBox(height: 8),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: const Icon(Icons.skip_previous, size: 32),
                onPressed: () => _sendKeyPress(177), // Media Previous
              ),
              IconButton(
                icon: const Icon(Icons.play_arrow, size: 32),
                onPressed: () => _sendKeyPress(179), // Media Play/Pause
              ),
              IconButton(
                icon: const Icon(Icons.skip_next, size: 32),
                onPressed: () => _sendKeyPress(176), // Media Next
              ),
              IconButton(
                icon: const Icon(Icons.volume_down, size: 32),
                onPressed: () => _sendKeyPress(174), // Volume Down
              ),
              IconButton(
                icon: const Icon(Icons.volume_up, size: 32),
                onPressed: () => _sendKeyPress(175), // Volume Up
              ),
              IconButton(
                icon: const Icon(Icons.volume_off, size: 32),
                onPressed: () => _sendKeyPress(173), // Mute
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Modifier combinations
          const Text('Quick Actions', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildComboButton('Ctrl+C', [17, 67]),
              _buildComboButton('Ctrl+V', [17, 86]),
              _buildComboButton('Ctrl+X', [17, 88]),
              _buildComboButton('Ctrl+Z', [17, 90]),
              _buildComboButton('Ctrl+A', [17, 65]),
              _buildComboButton('Ctrl+S', [17, 83]),
              _buildComboButton('Alt+Tab', [18, 9]),
              _buildComboButton('Alt+F4', [18, 115]),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKeyButton(String label, int keyCode) {
    return ElevatedButton(
      onPressed: () => _sendKeyPress(keyCode),
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.all(12),
      ),
      child: Text(label),
    );
  }

  Widget _buildComboButton(String label, List<int> keyCodes) {
    return ElevatedButton(
      onPressed: () {
        // Send key combo (simplified - desktop needs to handle this)
        for (var code in keyCodes) {
          _sendKeyPress(code);
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue[700],
      ),
      child: Text(label),
    );
  }
}