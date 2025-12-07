import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sizer/sizer.dart';
import '../providers/app_providers.dart';
import '../models/server_config.dart';
import 'add_edit_server_page.dart';

class HostsServersPage extends ConsumerWidget {
  const HostsServersPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final serversAsync = ref.watch(serverListProvider);

    return Scaffold(
      body: Column(
        children: [
          // Action buttons bar
          Container(
            padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.h),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Row(
              children: [
                _buildActionButton(
                  context: context,
                  icon: Icons.add,
                  label: 'Add',
                  color: Colors.green,
                  onPressed: () => _navigateToAddServer(context, ref),
                ),
                SizedBox(width: 1.w),
                _buildActionButton(
                  context: context,
                  icon: Icons.edit,
                  label: 'Edit',
                  color: Colors.blue,
                  onPressed:
                      serversAsync.hasValue && serversAsync.value!.isNotEmpty
                      ? () => _showEditDialog(context, ref, serversAsync.value!)
                      : null,
                ),
                SizedBox(width: 1.w),
                _buildActionButton(
                  context: context,
                  icon: Icons.content_copy,
                  label: 'Duplicate',
                  color: Colors.orange,
                  onPressed:
                      serversAsync.hasValue && serversAsync.value!.isNotEmpty
                      ? () => _showDuplicateDialog(
                          context,
                          ref,
                          serversAsync.value!,
                        )
                      : null,
                ),
                SizedBox(width: 1.w),
                _buildActionButton(
                  context: context,
                  icon: Icons.drive_file_rename_outline,
                  label: 'Rename',
                  color: Colors.purple,
                  onPressed:
                      serversAsync.hasValue && serversAsync.value!.isNotEmpty
                      ? () =>
                            _showRenameDialog(context, ref, serversAsync.value!)
                      : null,
                ),
                SizedBox(width: 1.w),
                _buildActionButton(
                  context: context,
                  icon: Icons.delete,
                  label: 'Remove',
                  color: Colors.red,
                  onPressed:
                      serversAsync.hasValue && serversAsync.value!.isNotEmpty
                      ? () =>
                            _showDeleteDialog(context, ref, serversAsync.value!)
                      : null,
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    ref.read(serverListProvider.notifier).loadServers();
                  },
                  tooltip: 'Refresh',
                ),
              ],
            ),
          ),
          // Server list
          Expanded(
            child: serversAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 15.w,
                      color: Colors.red.shade300,
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'Error loading servers',
                      style: TextStyle(fontSize: 14.sp, color: Colors.red),
                    ),
                    SizedBox(height: 1.h),
                    Text(
                      error.toString(),
                      style: TextStyle(fontSize: 10.sp, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              data: (servers) {
                if (servers.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.dns_outlined,
                          size: 20.w,
                          color: Colors.grey.shade300,
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          'No servers configured',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        SizedBox(height: 1.h),
                        Text(
                          'Tap the Add button to create a new server',
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: EdgeInsets.all(2.w),
                  itemCount: servers.length,
                  itemBuilder: (context, index) {
                    final server = servers[index];
                    return _buildServerCard(context, ref, server);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16.sp),
      label: Text(label, style: TextStyle(fontSize: 11.sp)),
      style: ElevatedButton.styleFrom(
        backgroundColor: onPressed == null ? Colors.grey.shade300 : color,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.h),
        disabledBackgroundColor: Colors.grey.shade300,
        disabledForegroundColor: Colors.grey.shade500,
      ),
    );
  }

  Widget _buildServerCard(
    BuildContext context,
    WidgetRef ref,
    ServerConfig server,
  ) {
    return Card(
      margin: EdgeInsets.only(bottom: 1.h),
      elevation: 2,
      child: InkWell(
        onTap: () => _navigateToEditServer(context, ref, server),
        child: Padding(
          padding: EdgeInsets.all(2.w),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.dns,
                  color: Colors.blue.shade700,
                  size: 20.sp,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      server.name,
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      '${server.username}@${server.address}:${server.port}',
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    SizedBox(height: 0.5.h),
                    Row(
                      children: [
                        _buildChip('OS: ${server.osType}', Colors.orange),
                        SizedBox(width: 1.w),
                        if (server.gatewayProxy != null)
                          _buildChip('Gateway', Colors.purple),
                        if (server.chainConnection != null)
                          _buildChip('Chained', Colors.teal),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      _navigateToEditServer(context, ref, server);
                      break;
                    case 'duplicate':
                      _duplicateServer(ref, server.id);
                      break;
                    case 'rename':
                      _showSingleRenameDialog(context, ref, server);
                      break;
                    case 'delete':
                      _deleteServer(context, ref, server.id, server.name);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  const PopupMenuItem(
                    value: 'duplicate',
                    child: Text('Duplicate'),
                  ),
                  const PopupMenuItem(value: 'rename', child: Text('Rename')),
                  const PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChip(String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 1.5.w, vertical: 0.5.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9.sp,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  void _navigateToAddServer(BuildContext context, WidgetRef ref) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddEditServerPage()),
    );
  }

  void _navigateToEditServer(
    BuildContext context,
    WidgetRef ref,
    ServerConfig server,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditServerPage(server: server),
      ),
    );
  }

  void _showEditDialog(
    BuildContext context,
    WidgetRef ref,
    List<ServerConfig> servers,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Server to Edit'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: servers.length,
            itemBuilder: (context, index) {
              final server = servers[index];
              return ListTile(
                title: Text(server.name),
                subtitle: Text(server.address),
                onTap: () {
                  Navigator.pop(context);
                  _navigateToEditServer(context, ref, server);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showDuplicateDialog(
    BuildContext context,
    WidgetRef ref,
    List<ServerConfig> servers,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Server to Duplicate'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: servers.length,
            itemBuilder: (context, index) {
              final server = servers[index];
              return ListTile(
                title: Text(server.name),
                subtitle: Text(server.address),
                onTap: () {
                  Navigator.pop(context);
                  _duplicateServer(ref, server.id);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showRenameDialog(
    BuildContext context,
    WidgetRef ref,
    List<ServerConfig> servers,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Server to Rename'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: servers.length,
            itemBuilder: (context, index) {
              final server = servers[index];
              return ListTile(
                title: Text(server.name),
                subtitle: Text(server.address),
                onTap: () {
                  Navigator.pop(context);
                  _showSingleRenameDialog(context, ref, server);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showSingleRenameDialog(
    BuildContext context,
    WidgetRef ref,
    ServerConfig server,
  ) {
    final controller = TextEditingController(text: server.name);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Server'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Server Name',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                ref
                    .read(serverListProvider.notifier)
                    .updateServer(
                      server.copyWith(name: newName, updatedAt: DateTime.now()),
                    );
                Navigator.pop(context);
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Server renamed')));
              }
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(
    BuildContext context,
    WidgetRef ref,
    List<ServerConfig> servers,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Server to Delete'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: servers.length,
            itemBuilder: (context, index) {
              final server = servers[index];
              return ListTile(
                title: Text(server.name),
                subtitle: Text(server.address),
                trailing: const Icon(Icons.delete, color: Colors.red),
                onTap: () {
                  Navigator.pop(context);
                  _deleteServer(context, ref, server.id, server.name);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _duplicateServer(WidgetRef ref, String serverId) {
    ref.read(serverListProvider.notifier).duplicateServer(serverId);
    // Note: SnackBar will be shown after navigation or in the context of the calling widget
  }

  void _deleteServer(
    BuildContext context,
    WidgetRef ref,
    String serverId,
    String serverName,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete "$serverName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              ref.read(serverListProvider.notifier).deleteServer(serverId);
              Navigator.pop(context);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Server deleted')));
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
