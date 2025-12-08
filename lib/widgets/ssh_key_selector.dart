import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sizer/sizer.dart';
import '../models/ssh_key_model.dart';
import '../providers/app_providers.dart';
import '../pages/ssh_key_management_page.dart';

class SshKeySelector extends ConsumerWidget {
  final String? selectedKeyId;
  final ValueChanged<String?> onChanged;
  final bool allowNull;

  const SshKeySelector({
    Key? key,
    required this.selectedKeyId,
    required this.onChanged,
    this.allowNull = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sshKeys = ref.watch(sshKeysProvider);
    final selectedKey = selectedKeyId != null
        ? sshKeys.cast<SshKey?>().firstWhere(
            (k) => k?.id == selectedKeyId,
            orElse: () => null,
          )
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SSH Key',
          style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 0.5.h),
        GestureDetector(
          onTap: () => _showKeySelectionDialog(context, ref, sshKeys),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.2.h),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey.shade50,
            ),
            child: Row(
              children: [
                Icon(Icons.vpn_key, size: 18.sp, color: Colors.blue),
                SizedBox(width: 1.5.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selectedKey?.name ?? 'No key selected',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: selectedKey != null
                              ? Colors.black
                              : Colors.grey,
                        ),
                      ),
                      if (selectedKey != null)
                        Text(
                          '${selectedKey.keyType.toUpperCase()} • ${_formatDate(selectedKey.createdAt)}',
                          style: TextStyle(
                            fontSize: 9.sp,
                            color: Colors.grey.shade600,
                          ),
                        ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_drop_down, color: Colors.grey),
              ],
            ),
          ),
        ),
        SizedBox(height: 0.5.h),
        Row(
          children: [
            TextButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SshKeyManagementPage(),
                  ),
                );
              },
              icon: const Icon(Icons.settings, size: 16),
              label: const Text('Manage Keys'),
            ),
            if (selectedKey != null)
              TextButton.icon(
                onPressed: () => onChanged(null),
                icon: const Icon(Icons.clear, size: 16),
                label: const Text('Clear'),
              ),
          ],
        ),
      ],
    );
  }

  void _showKeySelectionDialog(
    BuildContext context,
    WidgetRef ref,
    List<SshKey> keys,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select SSH Key'),
        content: keys.isEmpty
            ? SizedBox(
                width: double.maxFinite,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.vpn_key_off, size: 48, color: Colors.grey),
                      SizedBox(height: 1.h),
                      const Text('No SSH keys available'),
                      SizedBox(height: 1.h),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const SshKeyManagementPage(),
                            ),
                          );
                        },
                        child: const Text('Create one now'),
                      ),
                    ],
                  ),
                ),
              )
            : SingleChildScrollView(
                child: SizedBox(
                  width: double.maxFinite,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (allowNull)
                        ListTile(
                          leading: const Icon(Icons.clear),
                          title: const Text('None'),
                          onTap: () {
                            onChanged(null);
                            Navigator.pop(context);
                          },
                        ),
                      ...keys.map((key) {
                        final isSelected = selectedKeyId == key.id;
                        return Container(
                          margin: EdgeInsets.only(bottom: 0.5.h),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.blue.shade50 : null,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ListTile(
                            leading: Icon(
                              Icons.vpn_key,
                              color: isSelected ? Colors.blue : Colors.grey,
                            ),
                            title: Text(key.name),
                            subtitle: Text(
                              '${key.keyType.toUpperCase()} • ${_formatDate(key.createdAt)}',
                              style: TextStyle(fontSize: 10.sp),
                            ),
                            trailing: isSelected
                                ? const Icon(Icons.check, color: Colors.blue)
                                : null,
                            onTap: () {
                              onChanged(key.id);
                              Navigator.pop(context);
                            },
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton.icon(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SshKeyManagementPage(),
                ),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Add Key'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';
}
