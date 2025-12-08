import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:xterm/ui.dart';
import 'package:xterm/xterm.dart';

import 'terminal_virtual_keys_widget.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/terminal_session.dart';
import '../providers/app_providers.dart';
import 'session_tab_item.dart';

class TerminalScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(sessionsProvider);
    final currentSessionIndex = ref.watch(activeSessionIndexProvider);

    // DEBUG PRINTS
    print('=== TerminalScreen DEBUG ===');
    print('Total sessions: ${sessions.length}');
    print('Current session index: $currentSessionIndex');
    if (sessions.isNotEmpty) {
      print('Sessions list:');
      for (int i = 0; i < sessions.length; i++) {
        final session = sessions[i];
        print('  [$i] ID: ${session.id}');
        print('      Host: ${session.host}');
        print('      Port: ${session.port}');
        print('      Username: ${session.username}');
        print('      Connected: ${session.isConnected}');
        print('      Terminal: ${session.terminal}');
      }

      if (currentSessionIndex < sessions.length) {
        final currentSession = sessions[currentSessionIndex];
        print('Current session:');
        print('  Host: ${currentSession.host}');
        print('  Connected: ${currentSession.isConnected}');
        print('  Terminal lines: ${currentSession.terminal.buffer.height}');
      } else {
        print('ERROR: Current session index out of range!');
      }
    } else {
      print('ERROR: No sessions available!');
    }
    print('=============================');

    if (sessions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text("Terminal Sessions")),
        body: const Center(child: Text('No sessions connected')),
      );
    }

    if (currentSessionIndex >= sessions.length) {
      // Reset to last session if index is out of bounds
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(activeSessionIndexProvider.notifier).state =
            sessions.length - 1;
      });
      return const SizedBox.shrink();
    }

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

    Future<void> closeSession(int index) async {
      print('Closing session at index: $index');
      print('Current sessions: ${sessions.length}');

      final session = sessions[index];
      print('Session to close:');
      print('  ID: ${session.id}');
      print('  Host: ${session.host}:${session.port}');
      print('  Username: ${session.username}');

      // Determine which session to show after closing
      int newIndex = currentSessionIndex;

      if (index == currentSessionIndex) {
        // We're closing the current session
        if (index > 0) {
          // Show previous session
          newIndex = index - 1;
        } else if (sessions.length > 1) {
          // Current is first, show next
          newIndex = 0; // After removal, next becomes first
        } else {
          // Only session being closed
          newIndex = -1;
        }
      } else if (index < currentSessionIndex) {
        // Closing a session before current, adjust index
        newIndex = currentSessionIndex - 1;
      }

      // Remove the session
      await ref.read(sessionsProvider.notifier).removeSession(session.id);

      // Update active session index
      final remainingSessions = ref.read(sessionsProvider);
      print('Remaining sessions: ${remainingSessions.length}');
      for (int i = 0; i < remainingSessions.length; i++) {
        print(
          '  [$i] ${remainingSessions[i].host}:${remainingSessions[i].port} - ID: ${remainingSessions[i].id}',
        );
      }
      print('New index: $newIndex');

      if (remainingSessions.isEmpty) {
        print('No more sessions, navigating back');
        if (context.mounted) {
          Navigator.pop(context);
        }
      } else {
        // Ensure new index is valid
        if (newIndex >= remainingSessions.length) {
          newIndex = remainingSessions.length - 1;
        }
        print('Setting active session to index: $newIndex');
        ref.read(activeSessionIndexProvider.notifier).state = newIndex;
      }
    }

    // Imagine we have a provider that holds a List<TerminalSession>
    ScrollController scrollController = ScrollController();
    TerminalController terminalController = TerminalController();

    return Scaffold(
      // appBar: AppBar(
      //   title: sessions.isNotEmpty
      //       ? Text(
      //           "Session: ${sessions[currentSessionIndex].host}:${sessions[currentSessionIndex].port}",
      //         )
      //       : const Text("Terminal Sessions"),
      // actions: [

      // ],
      //),
      body: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
                tooltip: 'Back to servers',
              ),
              Spacer(),
              // Session tabs bar - better scrolling for desktop
              if (sessions.isNotEmpty)
                Container(
                  color: const Color.fromARGB(255, 26, 52, 92),
                  padding: const EdgeInsets.symmetric(
                    vertical: 4,
                    horizontal: 8,
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: List.generate(sessions.length, (index) {
                        final session = sessions[index];
                        final isActive = index == currentSessionIndex;

                        // Count how many sessions to this same host
                        final sameSessions = sessions
                            .where((s) => s.host == session.host)
                            .toList();
                        final sessionLabel = sameSessions.length > 1
                            ? '${session.host}:${session.port} (${sameSessions.indexOf(session) + 1})'
                            : '${session.host}:${session.port}';

                        return SessionTabItem(
                          label: sessionLabel,
                          isActive: isActive,
                          onTap: () {
                            print('Switching to session at index: $index');
                            ref
                                    .read(activeSessionIndexProvider.notifier)
                                    .state =
                                index;
                          },
                          onClose: () => closeSession(index),
                          onDuplicate: () async{
                            var term = TerminalSession(
                              Uuid().v4(),
                              session.host,
                              session.port,
                              session.username,
                              session.password,
                              session.privKey
                            );
    try {
      await term.connect();
      print('Connection successful');
      print('Connected status: ${term.isConnected}');
    } catch (e) {
      print('Connection error: $e');
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Connection failed: $e')));
      return;
    }

    ref.read(sessionsProvider.notifier).addSession(term);
    print('Session added to provider');

    final sessions = ref.read(sessionsProvider);
    print('Sessions in provider after adding: ${sessions.length}');

    // Update the active session index to the newly added session
    final newSessionIndex = sessions.length - 1;
    ref.read(activeSessionIndexProvider.notifier).state = newSessionIndex;
    print('Active session index set to: $newSessionIndex');

    // Navigate to terminal screen
    if (!context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => TerminalScreen()),
    );
                            print('Duplicating session at index: $index');
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Duplicate session: ${session.host}:${session.port}',
                                ),
                              ),
                            );
                          },
                          onPortForward: () {
                            print('Port forward for session at index: $index');
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Port Forward: ${session.host}:${session.port}',
                                ),
                              ),
                            );
                          },
                          onTunnel: () {
                            print('Tunnel for session at index: $index');
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Tunnel: ${session.host}:${session.port}',
                                ),
                              ),
                            );
                          },
                          onFirewall: () {
                            print(
                              'Firewall rules for session at index: $index',
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Firewall: ${session.host}:${session.port}',
                                ),
                              ),
                            );
                          },
                          onDeployApp: () {
                            print('Deploy app for session at index: $index');
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Deploy: ${session.host}:${session.port}',
                                ),
                              ),
                            );
                          },
                        );
                      }),
                    ),
                  ),
                ),
            ],
          ),
          // Terminal view
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
