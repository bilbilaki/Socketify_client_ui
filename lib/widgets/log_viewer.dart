import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A reusable widget to display logs in a scrollable list.
/// Supports filtering, auto-scroll, and copying to clipboard.
class LogViewer extends StatefulWidget {
  final List<String> logs;
  final String? title;
  final bool autoScroll;
  final double height;
  final Color? backgroundColor;
  final TextStyle? logStyle;

  const LogViewer({
    super.key,
    required this.logs,
    this.title = 'Application Logs',
    this.autoScroll = true,
    this.height = 300,
    this.backgroundColor,
    this.logStyle,
  });

  @override
  State<LogViewer> createState() => _LogViewerState();
}

class _LogViewerState extends State<LogViewer> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  String _filter = '';
  bool _autoScroll = true;

  @override
  void initState() {
    super.initState();
    _autoScroll = widget.autoScroll;
  }

  @override
  void didUpdateWidget(LogViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_autoScroll && widget.logs.length != oldWidget.logs.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _copyLogs() {
    final text = widget.logs.join('\n');
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Logs copied to clipboard')));
  }

  @override
  Widget build(BuildContext context) {
    final filteredLogs = widget.logs
        .where((log) => log.toLowerCase().contains(_filter.toLowerCase()))
        .toList();

    final bgColor = widget.backgroundColor ?? const Color(0xFF1E1E1E);
    final textColor = widget.logStyle?.color ?? const Color(0xFFD4D4D4);

    return Card(
      elevation: 4,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Row(
              children: [
                if (widget.title != null)
                  Text(
                    widget.title!,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                const Spacer(),
                // Search Bar
                SizedBox(
                  width: 200,
                  height: 36,
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Filter logs...',
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 0,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surface,
                      prefixIcon: const Icon(Icons.search, size: 16),
                      suffixIcon: _filter.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 16),
                              onPressed: () {
                                setState(() {
                                  _searchController.clear();
                                  _filter = '';
                                });
                              },
                            )
                          : null,
                    ),
                    style: const TextStyle(fontSize: 13),
                    onChanged: (value) {
                      setState(() {
                        _filter = value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                // Auto-scroll toggle
                IconButton(
                  tooltip: 'Auto-scroll',
                  icon: Icon(
                    Icons.vertical_align_bottom,
                    color: _autoScroll
                        ? Theme.of(context).colorScheme.primary
                        : null,
                  ),
                  onPressed: () {
                    setState(() {
                      _autoScroll = !_autoScroll;
                      if (_autoScroll) _scrollToBottom();
                    });
                  },
                ),
                // Copy button
                IconButton(
                  tooltip: 'Copy all',
                  icon: const Icon(Icons.copy),
                  onPressed: _copyLogs,
                ),
              ],
            ),
          ),
          // Log List
          Container(
            height: widget.height,
            color: bgColor,
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(8),
              itemCount: filteredLogs.length,
              itemBuilder: (context, index) {
                return SelectableText(
                  filteredLogs[index],
                  style:
                      widget.logStyle ??
                      TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: textColor,
                      ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
