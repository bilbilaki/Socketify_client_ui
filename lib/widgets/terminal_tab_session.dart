import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xterm/ui.dart';
import 'package:xterm/xterm.dart';

import 'terminal_virtual_keys_widget.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/terminal_session.dart';
import '../providers/app_providers.dart';

class TerminalScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(sessionsProvider);
    final currentSessionIndex = ref.watch(activeSessionIndexProvider);

    void onClipb() async {
      // Get current session terminal
      final currentTerminal = sessions[currentSessionIndex].terminal;

      // Paste from clipboard into terminal
      final data = await Clipboard.getData('text/plain');
      if (data?.text != null) {
        currentTerminal.paste(data!.text!);
      }

      // Copy selection to clipboard
      final selection = currentTerminal.buffer.getText();
      if (selection.isNotEmpty) {
        Clipboard.setData(ClipboardData(text: selection));
      }
    }

    // Imagine we have a provider that holds a List<TerminalSession>
    ScrollController scrollController = ScrollController();
    TerminalController terminalController = TerminalController();
    return Scaffold(
      appBar: AppBar(
        title: Text("Session: ${sessions[currentSessionIndex].host}"),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () => /* Add new session logic */ null,
          ),
        ],
      ),
      // Use IndexedStack to keep off-screen terminals alive/rendering
      body: Column(
        children: [
          Expanded(
            child: IndexedStack(
              index: currentSessionIndex,
              children: sessions.map((session) {
                return TerminalView(
                  session.terminal,
                  keyboardType: TextInputType.multiline,
                  onTapUp: (details, offset) => onClipb(),
                  textStyle: TerminalStyle(
                    fontFamily:
                        GoogleFonts.jetBrainsMono().fontFamilyFallback!.first,
                  ),
                  scrollController: scrollController,
                  controller: terminalController,
                  // Auto-handle focus so keyboard pops up when tapped
                  autofocus: true,
                  // Desktop Support: map hardware keys
                  hardwareKeyboardOnly:
                      Platform.isWindows ||
                      Platform.isMacOS ||
                      Platform.isLinux,
                );
              }).toList(),
            ),
          ),
          // Add the virtual keys at the bottom
          if (Platform.isAndroid || Platform.isIOS)
            VirtualKeyBar(terminal: sessions[currentSessionIndex].terminal),
        ],
      ),
    );
  }
}
