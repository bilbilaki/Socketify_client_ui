// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sizer/sizer.dart';
import '../models/ssh_key_model.dart';
import '../providers/app_providers.dart';
import '../services/ssh_key_service.dart';

class SshKeyManagementPage extends ConsumerStatefulWidget {
  const SshKeyManagementPage({Key? key}) : super(key: key);

  @override
  ConsumerState<SshKeyManagementPage> createState() =>
      _SshKeyManagementPageState();
}

class _SshKeyManagementPageState extends ConsumerState<SshKeyManagementPage> {
  @override
  Widget build(BuildContext context) {
    final sshKeysAsync = ref.watch(sshKeysProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('SSH Key Management'), elevation: 0),
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
                ElevatedButton.icon(
                  onPressed: () => _showImportKeyDialog(context),
                  icon: const Icon(Icons.vpn_key),
                  label: const Text('Generate Key'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
                SizedBox(width: 1.w),
                ElevatedButton.icon(
                  onPressed: () => _showImportKeyDialog(context),
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Import Key'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    ref.read(sshKeysProvider.notifier).loadKeys();
                  },
                  tooltip: 'Refresh',
                ),
                IconButton(
                  icon: const Icon(Icons.clear_all),
                  onPressed: () => _showClearAllConfirmation(context),
                  tooltip: 'Clear All Keys',
                  color: Colors.red,
                ),
              ],
            ),
          ),
          // SSH Keys list with loading/error handling
          Expanded(
            child: sshKeysAsync.when(
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
                      'Error loading keys',
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
              data: (sshKeys) {
                if (sshKeys.isEmpty) {
                  return _buildEmptyState();
                }
                return ListView.builder(
                  padding: EdgeInsets.all(2.w),
                  itemCount: sshKeys.length,
                  itemBuilder: (context, index) =>
                      _buildKeyCard(context, sshKeys[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.vpn_key_off, size: 20.w, color: Colors.grey.shade300),
          SizedBox(height: 2.h),
          Text(
            'No SSH Keys',
            style: TextStyle(fontSize: 14.sp, color: Colors.grey.shade600),
          ),
          SizedBox(height: 1.h),
          Text(
            'Generate or import an SSH key to get started',
            style: TextStyle(fontSize: 11.sp, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyCard(BuildContext context, SshKey key) {
    return Card(
      margin: EdgeInsets.only(bottom: 1.h),
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(2.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(1.5.w),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.vpn_key,
                    color: Colors.blue.shade700,
                    size: 18.sp,
                  ),
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        key.name,
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 0.3.h),
                      Text(
                        '${key.keyType.toUpperCase()} • Created ${_formatDate(key.createdAt)}',
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildKeyMenu(context, key),
              ],
            ),
            SizedBox(height: 1.h),
            Wrap(
              spacing: 1.w,
              children: [
                _buildChip(key.keyType.toUpperCase(), Colors.blue),
                if (key.keySize != null)
                  _buildChip('${key.keySize} bit', Colors.orange),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeyMenu(BuildContext context, SshKey key) {
    return PopupMenuButton<String>(
      onSelected: (value) {
        switch (value) {
          case 'copy_public':
            _copyToClipboard(context, key.publicKey, 'Public Key');
            break;
          case 'copy_private':
            _copyToClipboard(context, key.privateKey, 'Private Key');
            break;
          case 'rename':
            _showRenameDialog(context, key);
            break;
        
          case 'delete':
            _showDeleteConfirmation(context, key);
            break;
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'copy_public',
          child: Text('Copy Public Key'),
        ),
        const PopupMenuItem(
          value: 'copy_private',
          child: Text('Copy Private Key'),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(value: 'rename', child: Text('Rename')),
        const PopupMenuItem(value: 'duplicate', child: Text('Duplicate')),
        const PopupMenuItem(value: 'delete', child: Text('Delete')),
      ],
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

  void _copyToClipboard(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('$label copied to clipboard')));
  }

  void _showImportKeyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const _ImportKeyDialog(),
    );
  }

  void _showRenameDialog(BuildContext context, SshKey key) {
    final controller = TextEditingController(text: key.name);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename SSH Key'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Key Name',
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
              if (controller.text.isNotEmpty) {
                ref.read(sshKeysProvider.notifier).updateKey(
                      key.copyWith(name: controller.text),
                    );
                Navigator.pop(context);
                ScaffoldMessenger.of(context)
                    .showSnackBar(const SnackBar(content: Text('Key renamed')));
              }
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }


  void _showDeleteConfirmation(BuildContext context, SshKey key) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete SSH Key'),
        content: Text('Delete "${key.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              ref.read(sshKeysProvider.notifier).removeKey(key.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context)
                  .showSnackBar(const SnackBar(content: Text('Key deleted')));
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showClearAllConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All SSH Keys'),
        content: const Text('This will delete all SSH keys. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              ref.read(sshKeysProvider.notifier).clearAllKeys();
              Navigator.pop(context);
              ScaffoldMessenger.of(context)
                  .showSnackBar(const SnackBar(content: Text('All keys cleared')));
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) =>
      '${date.day}/${date.month}/${date.year}';
}

class _ImportKeyDialog extends ConsumerStatefulWidget {
  const _ImportKeyDialog();

  @override
  ConsumerState<_ImportKeyDialog> createState() => _ImportKeyDialogState();
}

class _ImportKeyDialogState extends ConsumerState<_ImportKeyDialog> {
  late TextEditingController _nameController;
  late TextEditingController _publicKeyController;
  late TextEditingController _privateKeyController;
  bool _isImport = true; // Track if user wants to import or generate

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _publicKeyController = TextEditingController();
    _privateKeyController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _publicKeyController.dispose();
    _privateKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(2.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'SSH Key Management',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 1.5.h),
              // Radio buttons to choose Import or Generate
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<bool>(
                      title: const Text('Import Existing Key'),
                      value: true,
                      groupValue: _isImport,
                      onChanged: (value) =>
                          setState(() => _isImport = value!),
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<bool>(
                      title: const Text('Generate New Key'),
                      value: false,
                      groupValue: _isImport,
                      onChanged: (value) =>
                          setState(() => _isImport = value!),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 1.5.h),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Key Name',
                  border: OutlineInputBorder(),
                ),
                autofocus: true,
              ),
              if (_isImport) ...[
                // Show fields only for import
                SizedBox(height: 1.h),
                TextField(
                  controller: _publicKeyController,
                  decoration: const InputDecoration(
                    labelText: 'Public Key (ssh-rsa, ssh-ed25519...)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 4,
                ),
                SizedBox(height: 1.h),
                TextField(
                  controller: _privateKeyController,
                  decoration: const InputDecoration(
                    labelText: 'Private Key',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 6,
                ),
              ],
              SizedBox(height: 2.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  SizedBox(width: 1.w),
                  ElevatedButton(
                    onPressed: _isImport ? _importKey : _genkey,
                    child: Text(_isImport ? 'Import' : 'Generate'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _importKey() {
    final name = _nameController.text.trim();
    final publicKey = _publicKeyController.text.trim();
    final privateKey = _privateKeyController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Enter key name')));
      return;
    }

    if (!SshKeyService.validatePublicKey(publicKey)) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Invalid public key')));
      return;
    }

    if (!SshKeyService.validatePrivateKey(privateKey)) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Invalid private key')));
      return;
    }

    final sshKey = SshKeyService.createKeyFromImport(
      name: name,
      publicKey: publicKey,
      privateKey: privateKey,
    );

    ref.read(sshKeysProvider.notifier).addKey(sshKey);
    Navigator.pop(context);
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Key imported')));
  }

  void _genkey() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Enter key name')));
      return;
    }
    final keys = await SshKeyService().generateSSHKeys();
    final sshKey = SshKeyService.createKeyFromImport(
      name: name,
      publicKey: keys["public"]!,
      privateKey: keys["private"]!,
    );
    ref.read(sshKeysProvider.notifier).addKey(sshKey);
    Navigator.pop(context);
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Key generated')));
  }
}