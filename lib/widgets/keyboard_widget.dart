import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../services/remote_control_client.dart';

class KeyboardWidget extends StatefulWidget {
  final Function(List<int>)? onSendCommand;

  const KeyboardWidget({super.key, this.onSendCommand});

  @override
  State<KeyboardWidget> createState() => _KeyboardWidgetState();
}

class _KeyboardWidgetState extends State<KeyboardWidget> {
  final _textController = TextEditingController();
  final _focusNode = FocusNode();
  final _client = RemoteControlClient();

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _sendText(String text) {
    if (text.isEmpty || !_client.connected.value) return;
    _client.typeString(text);
    widget.onSendCommand?.call(_encodeTypeString(text));
  }

  List<int> _encodeTypeString(String text) {
    final bytes = text.codeUnits;
    return [0x06, ...bytes];
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: _client.connected,
      builder: (context, isConnected, _) {
        return SingleChildScrollView(
          padding: EdgeInsets.all(2.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Text input field
              TextField(
                controller: _textController,
                focusNode: _focusNode,
                enabled: isConnected,
                decoration: InputDecoration(
                  hintText: 'Type text to send...',
                  labelText: isConnected ? 'Text Input' : 'Connect to Enable',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: isConnected
                        ? () {
                            if (_textController.text.isNotEmpty) {
                              _sendText(_textController.text);
                              _textController.clear();
                            }
                          }
                        : null,
                  ),
                ),
                onSubmitted: isConnected
                    ? (text) {
                        if (text.isNotEmpty) {
                          _sendText(text);
                          _textController.clear();
                        }
                      }
                    : null,
              ),

              SizedBox(height: 2.5.h),

              // Special keys
              Text(
                'Special Keys',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.sp),
              ),
              SizedBox(height: 1.h),

              Wrap(
                spacing: 1.w,
                runSpacing: 1.h,
                children: [
                  // _buildKeyButton('Esc', 27, isConnected),
                  // _buildKeyButton('Tab', 9, isConnected),
                  // _buildKeyButton('Enter', 13, isConnected),
                  // _buildKeyButton('Backspace', 8, isConnected),
                  // _buildKeyButton('Delete', 46, isConnected),
                  // _buildKeyButton('Space', 32, isConnected),
                ],
              ),

              SizedBox(height: 2.5.h),

              // Arrow keys
              Text(
                'Arrow Keys',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.sp),
              ),
              SizedBox(height: 1.h),

              Center(
                child: Column(
                  children: [
                    // _buildKeyButton('↑', 38, isConnected),
                    // SizedBox(height: 0.5.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // _buildKeyButton('←', 37, isConnected),
                        // SizedBox(width: 8.w),
                        // _buildKeyButton('→', 39, isConnected),
                      ],
                    ),
                    // SizedBox(height: 0.5.h),
                    // _buildKeyButton('↓', 40, isConnected),
                  ],
                ),
              ),

              SizedBox(height: 2.5.h),

              // Function keys
              Text(
                'Function Keys',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.sp),
              ),
              SizedBox(height: 1.h),

              // Wrap(
              //   spacing: 1.w,
              //   runSpacing: 1.h,
              //   children: List.generate(
              //     12,
              //     (i) => _buildKeyButton('F${i + 1}', 112 + i, isConnected),
              //   ),
              // ),

              SizedBox(height: 2.5.h),

              // Media keys
              Text(
                'Media Keys',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.sp),
              ),
              SizedBox(height: 1.h),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // _buildMediaButton(
                  //   Icons.skip_previous,
                  //   177,
                  //   'Previous',
                  //   isConnected,
                  // ),
                  // _buildMediaButton(Icons.play_arrow, 179, 'Play', isConnected),
                  // _buildMediaButton(Icons.skip_next, 176, 'Next', isConnected),
                  // _buildMediaButton(
                  //   Icons.volume_down,
                  //   174,
                  //   'Vol-',
                  //   isConnected,
                  // ),
                  // _buildMediaButton(Icons.volume_up, 175, 'Vol+', isConnected),
                ],
              ),

              SizedBox(height: 2.5.h),

              // Quick Actions
              Text(
                'Quick Actions',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.sp),
              ),
              SizedBox(height: 1.h),

              Wrap(
                spacing: 1.w,
                runSpacing: 1.h,
                children: [
                  _buildComboButton(
                    'Ctrl+C',
                    () => _client.pressCopy(),
                    isConnected,
                  ),
                  _buildComboButton(
                    'Ctrl+V',
                    () => _client.pressPaste(),
                    isConnected,
                  ),
                  _buildComboButton(
                    'Ctrl+X',
                    () => _client.pressCut(),
                    isConnected,
                  ),
                  _buildComboButton(
                    'Ctrl+Z',
                    () => _client.pressUndo(),
                    isConnected,
                  ),
                  _buildComboButton(
                    'Ctrl+A',
                    () => _client.pressSelectAll(),
                    isConnected,
                  ),
                  _buildComboButton(
                    'Ctrl+S',
                    () => _client.pressSave(),
                    isConnected,
                  ),
                  // _buildComboButton(
                  //   'Alt+Tab',
                  //   () => _client.hotkey([18, 9]),
                  //   isConnected,
                  // ),
                  // _buildComboButton(
                  //   'Win+D',
                  //   () => _client.hotkey([91, 68]),
                  //   isConnected,
                  // ),
                ],
              ),

              SizedBox(height: 2.h),
            ],
          ),
        );
      },
    );
  }

  Widget _buildKeyButton(String label, String keyCode, bool enabled) {
    return ElevatedButton(
      onPressed: enabled ? () => _client.keyPress(keyCode) : null,
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.h),
        minimumSize: Size(8.w, 5.h),
        backgroundColor: Colors.blue.shade600,
        disabledBackgroundColor: Colors.grey.shade400,
      ),
      child: Text(label, style: TextStyle(fontSize: 11.sp)),
    );
  }

  Widget _buildMediaButton(
    IconData icon,
    String keyCode,
    String tooltip,
    bool enabled,
  ) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        icon: Icon(icon, size: 20.sp),
        onPressed: enabled ? () => _client.keyPress(keyCode) : null,
        color: enabled ? Colors.blue.shade600 : Colors.grey.shade400,
      ),
    );
  }

  Widget _buildComboButton(String label, VoidCallback onPressed, bool enabled) {
    return ElevatedButton(
      onPressed: enabled ? onPressed : null,
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.h),
        backgroundColor: Colors.green.shade600,
        disabledBackgroundColor: Colors.grey.shade400,
      ),
      child: Text(label, style: TextStyle(fontSize: 10.sp)),
    );
  }
}
