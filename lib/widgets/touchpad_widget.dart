import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../services/remote_control_client.dart';

class TouchpadWidget extends StatefulWidget {
  final Function(List<int>)? onSendCommand;

  const TouchpadWidget({super.key, this.onSendCommand});

  @override
  State<TouchpadWidget> createState() => _TouchpadWidgetState();
}

class _TouchpadWidgetState extends State<TouchpadWidget> {
  final _client = RemoteControlClient();
  Offset? _lastPosition;
  DateTime? _lastTap;

  // Sensitivity multiplier
  double sensitivity = 2.0;

  void _onPanStart(DragStartDetails details) {
    _lastPosition = details.localPosition;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_lastPosition == null || !_client.connected.value) return;

    final delta = details.localPosition - _lastPosition!;
    _lastPosition = details.localPosition;

    // Apply sensitivity
    final deltaX = (delta.dx * sensitivity).round();
    final deltaY = (delta.dy * sensitivity).round();

    if (deltaX != 0 || deltaY != 0) {
      _client.mouseMoveRelative(deltaX, deltaY);
      widget.onSendCommand?.call(_encodeMouseMove(deltaX, deltaY));
    }
  }

  void _onPanEnd(DragEndDetails details) {
    _lastPosition = null;
  }

  void _onTap() {
    if (!_client.connected.value) return;

    final now = DateTime.now();
    if (_lastTap != null && now.difference(_lastTap!).inMilliseconds < 300) {
      // Double tap
      _client.mouseDoubleClick();
    } else {
      // Single tap
      _client.mouseClick();
    }
    _lastTap = now;
  }

  void _onLongPress() {
    if (!_client.connected.value) return;
    // Right click
    _client.mouseClick(button: 2);
  }

  // Protocol encoding functions
  List<int> _encodeMouseMove(int deltaX, int deltaY) {
    return [
      0x01,
      (deltaX >> 8) & 0xFF,
      deltaX & 0xFF,
      (deltaY >> 8) & 0xFF,
      deltaY & 0xFF,
    ];
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: _client.connected,
      builder: (context, isConnected, _) {
        return Column(
          children: [
            // Sensitivity slider
            Padding(
              padding: EdgeInsets.all(2.w),
              child: Row(
                children: [
                  Text('Sensitivity:', style: TextStyle(fontSize: 12.sp)),
                  Expanded(
                    child: Slider(
                      value: sensitivity,
                      min: 0.5,
                      max: 5.0,
                      onChanged: isConnected
                          ? (value) => setState(() => sensitivity = value)
                          : null,
                    ),
                  ),
                  Text(
                    sensitivity.toStringAsFixed(1),
                    style: TextStyle(fontSize: 12.sp),
                  ),
                ],
              ),
            ),

            // Touchpad area
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(2.w),
                child: GestureDetector(
                  onPanStart: isConnected ? _onPanStart : null,
                  onPanUpdate: isConnected ? _onPanUpdate : null,
                  onPanEnd: isConnected ? _onPanEnd : null,
                  onTap: isConnected ? _onTap : null,
                  onLongPress: isConnected ? _onLongPress : null,
                  child: Container(
                    decoration: BoxDecoration(
                      color: isConnected
                          ? Colors.grey.shade800
                          : Colors.grey.shade500,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isConnected
                            ? Colors.blue.shade400
                            : Colors.grey.shade600,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.touch_app,
                            size: 15.w,
                            color: isConnected
                                ? Colors.blue.shade300
                                : Colors.grey.shade600,
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            isConnected
                                ? 'Touchpad Active'
                                : 'Connect to Enable',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: isConnected
                                  ? Colors.blue.shade300
                                  : Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 1.h),
                          if (isConnected)
                            Column(
                              children: [
                                Text(
                                  'Tap: Left Click',
                                  style: TextStyle(
                                    fontSize: 10.sp,
                                    color: Colors.grey.shade400,
                                  ),
                                ),
                                Text(
                                  'Long Press: Right Click',
                                  style: TextStyle(
                                    fontSize: 10.sp,
                                    color: Colors.grey.shade400,
                                  ),
                                ),
                                Text(
                                  'Drag: Move Mouse',
                                  style: TextStyle(
                                    fontSize: 10.sp,
                                    color: Colors.grey.shade400,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Mouse buttons
            Padding(
              padding: EdgeInsets.all(2.w),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: isConnected ? _client.mouseClick : null,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 1.5.h),
                        backgroundColor: Colors.blue.shade600,
                        disabledBackgroundColor: Colors.grey.shade500,
                      ),
                      child: Text('Left', style: TextStyle(fontSize: 11.sp)),
                    ),
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: isConnected
                          ? () => _client.mouseClick(button: 3)
                          : null,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 1.5.h),
                        backgroundColor: Colors.blue.shade600,
                        disabledBackgroundColor: Colors.grey.shade500,
                      ),
                      child: Text('Middle', style: TextStyle(fontSize: 11.sp)),
                    ),
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: isConnected
                          ? () => _client.mouseClick(button: 2)
                          : null,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 1.5.h),
                        backgroundColor: Colors.blue.shade600,
                        disabledBackgroundColor: Colors.grey.shade500,
                      ),
                      child: Text('Right', style: TextStyle(fontSize: 11.sp)),
                    ),
                  ),
                ],
              ),
            ),

            // Scroll buttons
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_upward),
                    onPressed: isConnected
                        ? () => _client.mouseScroll(3)
                        : null,
                    tooltip: 'Scroll Up',
                  ),
                  SizedBox(width: 5.w),
                  IconButton(
                    icon: const Icon(Icons.arrow_downward),
                    onPressed: isConnected
                        ? () => _client.mouseScroll(-3)
                        : null,
                    tooltip: 'Scroll Down',
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
