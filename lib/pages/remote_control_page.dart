import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'dart:typed_data';
import 'dart:convert';
import '../services/remote_control_client.dart';
import '../widgets/touchpad_widget.dart';
import '../widgets/keyboard_widget.dart';

class RemoteControlPage extends StatefulWidget {
  const RemoteControlPage({Key? key}) : super(key: key);

  @override
  State<RemoteControlPage> createState() => _RemoteControlPageState();
}

class _RemoteControlPageState extends State<RemoteControlPage>
    with SingleTickerProviderStateMixin {
  final _client = RemoteControlClient();
  late TabController _tabController;
  final _hostController = TextEditingController();
  final _portController = TextEditingController(text: '8765');
  Uint8List? _screenshotData;
  bool _isLoadingScreenshot = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _hostController.dispose();
    _portController.dispose();
    super.dispose();
  }

  void _handleConnect() {
    final host = _hostController.text.trim();
    final portStr = _portController.text.trim();

    if (host.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter host address')));
      return;
    }

    final port = int.tryParse(portStr) ?? 8765;
    _client.connect(host, port: port);
  }

  Future<void> _captureScreen() async {
    setState(() => _isLoadingScreenshot = true);
    try {
      final response = await _client.captureFullScreen();
      if (response.success && response.data != null) {
        String? base64String;

        // Handle different response data formats
        if (response.data is String) {
          base64String = response.data as String;
        } else if (response.data is Map<String, dynamic>) {
          final dataMap = response.data as Map<String, dynamic>;
          base64String = dataMap['base64_png'] as String?;
        }

        if (base64String != null && base64String.isNotEmpty) {
          setState(() {
            _screenshotData = base64Decode(base64String!);
          });
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed: Invalid image data')),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed: ${response.error ?? 'Unknown error'}'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      setState(() => _isLoadingScreenshot = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Remote Control',
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelStyle: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w600),
          tabs: const [
            Tab(icon: Icon(Icons.touch_app), text: 'Touchpad'),
            Tab(icon: Icon(Icons.keyboard), text: 'Keyboard'),
            Tab(icon: Icon(Icons.screenshot), text: 'Screenshot'),
            Tab(icon: Icon(Icons.history), text: 'History'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Connection panel
          ValueListenableBuilder<bool>(
            valueListenable: _client.connected,
            builder: (context, isConnected, _) {
              return ValueListenableBuilder<String?>(
                valueListenable: _client.activeServer,
                builder: (context, activeServer, _) {
                  return ValueListenableBuilder<bool>(
                    valueListenable: _client.isConnecting,
                    builder: (context, isConnecting, _) {
                      return ValueListenableBuilder<String?>(
                        valueListenable: _client.errorMessage,
                        builder: (context, errorMsg, _) {
                          return Container(
                            padding: EdgeInsets.all(2.w),
                            decoration: BoxDecoration(
                              color: isConnected
                                  ? Colors.green.shade50
                                  : Colors.orange.shade50,
                              border: Border(
                                bottom: BorderSide(
                                  color: isConnected
                                      ? Colors.green.shade300
                                      : Colors.orange.shade300,
                                ),
                              ),
                            ),
                            child: Column(
                              children: [
                                if (!isConnected)
                                  Column(
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            flex: 2,
                                            child: TextField(
                                              controller: _hostController,
                                              enabled: !isConnecting,
                                              decoration: InputDecoration(
                                                labelText: 'Host / IP',
                                                hintText: 'localhost',
                                                prefixIcon: const Icon(
                                                  Icons.dns,
                                                ),
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                contentPadding:
                                                    EdgeInsets.symmetric(
                                                      horizontal: 2.w,
                                                      vertical: 1.h,
                                                    ),
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: 2.w),
                                          Expanded(
                                            child: TextField(
                                              controller: _portController,
                                              enabled: !isConnecting,
                                              keyboardType:
                                                  TextInputType.number,
                                              decoration: InputDecoration(
                                                labelText: 'Port',
                                                prefixIcon: const Icon(
                                                  Icons.settings_ethernet,
                                                ),
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                contentPadding:
                                                    EdgeInsets.symmetric(
                                                      horizontal: 2.w,
                                                      vertical: 1.h,
                                                    ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 1.5.h),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: ElevatedButton.icon(
                                              onPressed: isConnecting
                                                  ? null
                                                  : _handleConnect,
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    Colors.green.shade600,
                                                padding: EdgeInsets.symmetric(
                                                  vertical: 1.5.h,
                                                ),
                                              ),
                                              icon: isConnecting
                                                  ? SizedBox(
                                                      height: 5.w,
                                                      width: 5.w,
                                                      child: const CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        valueColor:
                                                            AlwaysStoppedAnimation<
                                                              Color
                                                            >(Colors.white),
                                                      ),
                                                    )
                                                  : const Icon(Icons.power),
                                              label: Text(
                                                isConnecting
                                                    ? 'Connecting...'
                                                    : 'Connect',
                                                style: TextStyle(
                                                  fontSize: 12.sp,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  )
                                else
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.cloud_done,
                                        color: Colors.green.shade600,
                                        size: 20.sp,
                                      ),
                                      SizedBox(width: 2.w),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Connected',
                                              style: TextStyle(
                                                fontSize: 12.sp,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.green.shade700,
                                              ),
                                            ),
                                            Text(
                                              activeServer ?? 'Unknown',
                                              style: TextStyle(
                                                fontSize: 10.sp,
                                                color: Colors.green.shade600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      ElevatedButton.icon(
                                        onPressed: _client.disconnect,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red.shade600,
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 2.w,
                                            vertical: 1.h,
                                          ),
                                        ),
                                        icon: const Icon(Icons.power_off),
                                        label: Text(
                                          'Disconnect',
                                          style: TextStyle(fontSize: 10.sp),
                                        ),
                                      ),
                                    ],
                                  ),
                                if (errorMsg != null && errorMsg.isNotEmpty)
                                  Column(
                                    children: [
                                      SizedBox(height: 1.h),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.error_outline,
                                            color: Colors.red.shade600,
                                            size: 16.sp,
                                          ),
                                          SizedBox(width: 1.w),
                                          Expanded(
                                            child: Text(
                                              errorMsg,
                                              style: TextStyle(
                                                fontSize: 10.sp,
                                                color: Colors.red.shade600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              );
            },
          ),
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                // Touchpad tab
                TouchpadWidget(
                  onSendCommand: (command) {
                    if (kDebugMode) {
                      print('Touchpad command: $command');
                    }
                  },
                ),
                // Keyboard tab
                KeyboardWidget(
                  onSendCommand: (command) {
                    if (kDebugMode) {
                      print('Keyboard command: $command');
                    }
                  },
                ),
                // Screenshot tab
                Center(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: EdgeInsets.all(3.w),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton.icon(
                            onPressed:
                                _client.connected.value && !_isLoadingScreenshot
                                ? _captureScreen
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade600,
                              padding: EdgeInsets.symmetric(
                                horizontal: 4.w,
                                vertical: 2.h,
                              ),
                            ),
                            icon: _isLoadingScreenshot
                                ? SizedBox(
                                    height: 6.w,
                                    width: 6.w,
                                    child: const CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Icon(Icons.screenshot),
                            label: Text(
                              _isLoadingScreenshot
                                  ? 'Capturing...'
                                  : 'Capture Screen',
                              style: TextStyle(fontSize: 13.sp),
                            ),
                          ),
                          SizedBox(height: 3.h),
                          if (_screenshotData != null)
                            Column(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.memory(
                                    _screenshotData!,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                                SizedBox(height: 2.h),
                                Text(
                                  'Screenshot captured',
                                  style: TextStyle(
                                    fontSize: 11.sp,
                                    color: Colors.green.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            )
                          else if (!_isLoadingScreenshot &&
                              _client.connected.value)
                            Column(
                              children: [
                                Icon(
                                  Icons.image_not_supported_outlined,
                                  size: 20.w,
                                  color: Colors.grey.shade400,
                                ),
                                SizedBox(height: 2.h),
                                Text(
                                  'No screenshot yet',
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            )
                          else
                            Text(
                              'Connect to a server first',
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: Colors.orange.shade600,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                // History tab
                ValueListenableBuilder<List<String>>(
                  valueListenable: _client.commandHistory,
                  builder: (context, history, _) {
                    return history.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.history,
                                  size: 20.w,
                                  color: Colors.grey.shade300,
                                ),
                                SizedBox(height: 2.h),
                                Text(
                                  'No command history',
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Column(
                            children: [
                              Padding(
                                padding: EdgeInsets.all(2.w),
                                child: Row(
                                  children: [
                                    Text(
                                      'Commands: ${history.length}',
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const Spacer(),
                                    OutlinedButton.icon(
                                      onPressed: _client.clearHistory,
                                      icon: const Icon(Icons.delete_outline),
                                      label: const Text('Clear'),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: ListView.builder(
                                  reverse: true,
                                  padding: EdgeInsets.all(2.w),
                                  itemCount: history.length,
                                  itemBuilder: (context, index) {
                                    final cmd =
                                        history[history.length - 1 - index];
                                    return Card(
                                      margin: EdgeInsets.only(bottom: 1.h),
                                      child: Padding(
                                        padding: EdgeInsets.all(2.w),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.check_circle,
                                              color: Colors.green.shade600,
                                              size: 16.sp,
                                            ),
                                            SizedBox(width: 2.w),
                                            Expanded(
                                              child: Text(
                                                cmd,
                                                style: TextStyle(
                                                  fontSize: 11.sp,
                                                  fontFamily: 'monospace',
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

const bool kDebugMode = true;
