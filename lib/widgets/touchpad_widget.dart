import 'package:flutter/material.dart';

class TouchpadWidget extends StatefulWidget {
  final Function(List<int>) onSendCommand;

  const TouchpadWidget({super.key, required this.onSendCommand});

  @override
  State<TouchpadWidget> createState() => _TouchpadWidgetState();
}

class _TouchpadWidgetState extends State<TouchpadWidget> {
  Offset? _lastPosition;
  DateTime? _lastTap;
  int _tapCount = 0;
  
  // Sensitivity multiplier
  double sensitivity = 2.0;

  void _onPanStart(DragStartDetails details) {
    _lastPosition = details.localPosition;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_lastPosition == null) return;

    final delta = details.localPosition - _lastPosition!;
    _lastPosition = details. localPosition;

    // Apply sensitivity and send mouse move command
    final deltaX = (delta.dx * sensitivity).round();
    final deltaY = (delta. dy * sensitivity).round();

    if (deltaX != 0 || deltaY != 0) {
      widget.onSendCommand(_encodeMouseMove(deltaX, deltaY));
    }
  }

  void _onPanEnd(DragEndDetails details) {
    _lastPosition = null;
  }

  void _onTap() {
    // Single tap = left click
    widget.onSendCommand(_encodeMouseClick(1, true));
    widget.onSendCommand(_encodeMouseClick(1, false));
  }

  void _onDoubleTap() {
    // Double tap = double click
    widget. onSendCommand(_encodeMouseClick(1, true));
    widget.onSendCommand(_encodeMouseClick(1, false));
    widget.onSendCommand(_encodeMouseClick(1, true));
    widget.onSendCommand(_encodeMouseClick(1, false));
  }

  void _onLongPress() {
    // Long press = right click
    widget.onSendCommand(_encodeMouseClick(2, true));
    widget.onSendCommand(_encodeMouseClick(2, false));
  }

  void _onScroll(double delta) {
    final scrollAmount = delta > 0 ? -1 : 1; // Invert for natural scrolling
    widget.onSendCommand(_encodeMouseScroll(scrollAmount));
  }

  // Protocol encoding functions
  List<int> _encodeMouseMove(int deltaX, int deltaY) {
    return [
      0x01, // mouseMove command
      (deltaX >> 8) & 0xFF,
      deltaX & 0xFF,
      (deltaY >> 8) & 0xFF,
      deltaY & 0xFF,
    ];
  }

  List<int> _encodeMouseClick(int button, bool isDown) {
    return [0x02, button, isDown ? 1 : 0];
  }

  List<int> _encodeMouseScroll(int delta) {
    return [
      0x03,
      (delta >> 8) & 0xFF,
      delta & 0xFF,
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Sensitivity slider
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Text('Sensitivity:'),
              Expanded(
                child: Slider(
                  value: sensitivity,
                  min: 0.5,
                  max: 5.0,
                  onChanged: (value) => setState(() => sensitivity = value),
                ),
              ),
              Text(sensitivity.toStringAsFixed(1)),
            ],
          ),
        ),
        
        // Touchpad area
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: GestureDetector(
              onPanStart: _onPanStart,
              onPanUpdate: _onPanUpdate,
              onPanEnd: _onPanEnd,
              onTap: _onTap,
              onDoubleTap: _onDoubleTap,
              onLongPress: _onLongPress,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius. circular(16),
                  border: Border.all(color: Colors.grey[600]! ),
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.touch_app, size: 48, color: Colors. grey),
                      SizedBox(height: 16),
                      Text('Touchpad Area', style: TextStyle(color: Colors. grey)),
                      SizedBox(height: 8),
                      Text('Tap: Left Click', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      Text('Long Press: Right Click', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      Text('Two Finger Scroll: Scroll', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        
        // Mouse buttons
        Padding(
          padding: const EdgeInsets. all(16),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    widget.onSendCommand(_encodeMouseClick(1, true));
                    widget.onSendCommand(_encodeMouseClick(1, false));
                  },
                  style: ElevatedButton. styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                  ),
                  child: const Text('Left Click'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    widget.onSendCommand(_encodeMouseClick(3, true));
                    widget.onSendCommand(_encodeMouseClick(3, false));
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                  ),
                  child: const Text('Middle'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    widget. onSendCommand(_encodeMouseClick(2, true));
                    widget.onSendCommand(_encodeMouseClick(2, false));
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets. symmetric(vertical: 20),
                  ),
                  child: const Text('Right Click'),
                ),
              ),
            ],
          ),
        ),
        
        // Scroll buttons
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_upward),
                onPressed: () => widget.onSendCommand(_encodeMouseScroll(1)),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_downward),
                onPressed: () => widget.onSendCommand(_encodeMouseScroll(-1)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}