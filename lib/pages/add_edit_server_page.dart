import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sizer/sizer.dart';
import 'package:uuid/uuid.dart';
import '../models/server_config.dart';
import '../providers/app_providers.dart';

class AddEditServerPage extends ConsumerStatefulWidget {
  final ServerConfig? server;

  const AddEditServerPage({Key? key, this.server}) : super(key: key);

  @override
  ConsumerState<AddEditServerPage> createState() => _AddEditServerPageState();
}

class _AddEditServerPageState extends ConsumerState<AddEditServerPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _ipv4Controller;
  late TextEditingController _ipv6Controller;
  late TextEditingController _portController;
  late TextEditingController _usernameController;
  late TextEditingController _gatewayProxyController;
  late TextEditingController _passwordController;
  late TextEditingController _privKeyController;
  late TextEditingController _chainConnectionController;

  String _selectedOsType = 'Linux';
  String _selectedConnectionType = 'ssh';
  final List<String> _connectionTypeOptions = [
    'ssh',
    'telnet',
    'rdp',
    'ws',
    'sftp',
    'smb',
  ];
  final Map<String, ConnectionType> _connectionTypes = {
    'ssh': ConnectionType.ssh,
    'telnet': ConnectionType.telnet,
    'rdp': ConnectionType.rdp,
    'ws': ConnectionType.ws,
    'sftp': ConnectionType.sftp,
    'smb': ConnectionType.smb,
  };
  bool _obscurePassword = true;

  final List<String> _osTypes = [
    'Linux',
    'Windows',
    'macOS',
    'Unix',
    'BSD',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.server?.name ?? '');
    _addressController = TextEditingController(
      text: widget.server?.address ?? '',
    );
    _ipv4Controller = TextEditingController(
      text: widget.server?.ipv4Address ?? '',
    );
    _ipv6Controller = TextEditingController(
      text: widget.server?.ipv6Address ?? '',
    );
    _portController = TextEditingController(
      text: widget.server?.port.toString() ?? '22',
    );
    _usernameController = TextEditingController(
      text: widget.server?.username ?? '',
    );
    _gatewayProxyController = TextEditingController(
      text: widget.server?.gatewayProxy ?? '',
    );
    _passwordController = TextEditingController(
      text: widget.server?.password ?? '',
    );
    _privKeyController = TextEditingController(
      text: widget.server?.privKey ?? '',
    );
    _chainConnectionController = TextEditingController(
      text: widget.server?.chainConnection ?? '',
    );

    if (widget.server != null) {
      _selectedOsType = widget.server!.osType;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _ipv4Controller.dispose();
    _ipv6Controller.dispose();
    _portController.dispose();
    _usernameController.dispose();
    _gatewayProxyController.dispose();
    _passwordController.dispose();
    _privKeyController.dispose();
    _chainConnectionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.server != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing ? 'Edit Server' : 'Add Server',
          style: TextStyle(fontSize: 18.sp),
        ),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveServer,
            tooltip: 'Save',
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(3.w),
          children: [
            Text(
              'Server Information',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade700,
              ),
            ),
            SizedBox(height: 2.h),
            _buildTextField(
              controller: _nameController,
              label: 'Server Name *',
              icon: Icons.label,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Server name is required';
                }
                return null;
              },
            ),
            SizedBox(height: 2.h),
            _buildTextField(
              controller: _addressController,
              label: 'Address *',
              icon: Icons.dns,
              hint: 'e.g., example.com or 192.168.1.1',
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Address is required';
                }
                return null;
              },
            ),
            SizedBox(height: 2.h),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _ipv4Controller,
                    label: 'IPv4 Address',
                    icon: Icons.network_check,
                    hint: '192.168.1.1',
                  ),
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: _buildTextField(
                    controller: _ipv6Controller,
                    label: 'IPv6 Address',
                    icon: Icons.network_check,
                    hint: '2001:db8::1',
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _buildTextField(
                    controller: _portController,
                    label: 'Port *',
                    icon: Icons.settings_ethernet,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Port is required';
                      }
                      final port = int.tryParse(value);
                      if (port == null || port < 1 || port > 65535) {
                        return 'Enter valid port (1-65535)';
                      }
                      return null;
                    },
                  ),
                ),
                SizedBox(width: 2.w),
                Expanded(
                  flex: 3,
                  child: DropdownButtonFormField<String>(
                    value: _selectedOsType,
                    decoration: InputDecoration(
                      labelText: 'OS Type *',
                      prefixIcon: const Icon(Icons.computer),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    items: _osTypes.map((os) {
                      return DropdownMenuItem(value: os, child: Text(os));
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedOsType = value!;
                      });
                    },
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: DropdownButtonFormField<String>(
                    value: _selectedConnectionType,
                    decoration: InputDecoration(
                      labelText: 'Connection Type *',
                      prefixIcon: const Icon(Icons.computer),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    items: _connectionTypeOptions.map((connection) {
                      return DropdownMenuItem(value: connection, child: Text(connection));
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedConnectionType = value!;
                      });
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 3.h),
            Text(
              'Authentication',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade700,
              ),
            ),
            SizedBox(height: 2.h),
            _buildTextField(
              controller: _usernameController,
              label: 'Username *',
              icon: Icons.person,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Username is required';
                }
                return null;
              },
            ),
            SizedBox(height: 2.h),
            _buildTextField(
              controller: _passwordController,
              label: 'Password',
              icon: Icons.lock,
              obscureText: _obscurePassword,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
            ),
            SizedBox(height: 2.h),
            _buildTextField(
              controller: _privKeyController,
              label: 'Private Key',
              icon: Icons.vpn_key,
              maxLines: 3,
              hint: 'Enter private key or path to key file',
            ),
            SizedBox(height: 3.h),
            Text(
              'Advanced Options',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade700,
              ),
            ),
            SizedBox(height: 2.h),
            _buildTextField(
              controller: _gatewayProxyController,
              label: 'Gateway/Proxy',
              icon: Icons.router,
              hint: 'e.g., proxy.example.com:8080',
            ),
            SizedBox(height: 2.h),
            _buildTextField(
              controller: _chainConnectionController,
              label: 'Chain Connection',
              icon: Icons.link,
              hint: 'Server ID for chain connection',
            ),
            SizedBox(height: 4.h),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 1.5.h),
                      side: BorderSide(color: Colors.grey.shade400),
                    ),
                    child: Text('Cancel', style: TextStyle(fontSize: 12.sp)),
                  ),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saveServer,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 1.5.h),
                    ),
                    child: Text(
                      isEditing ? 'Update' : 'Save',
                      style: TextStyle(fontSize: 12.sp),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    bool obscureText = false,
    int maxLines = 1,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      obscureText: obscureText,
      maxLines: maxLines,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
    );
  }

  void _saveServer() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final server = ServerConfig(
      id: widget.server?.id ?? const Uuid().v4(),
      name: _nameController.text.trim(),
      address: _addressController.text.trim(),
      ipv4Address: _ipv4Controller.text.trim().isEmpty
          ? null
          : _ipv4Controller.text.trim(),
      ipv6Address: _ipv6Controller.text.trim().isEmpty
          ? null
          : _ipv6Controller.text.trim(),
      port: int.parse(_portController.text.trim()),
      osType: _selectedOsType,
      username: _usernameController.text.trim(),
      gatewayProxy: _gatewayProxyController.text.trim().isEmpty
          ? null
          : _gatewayProxyController.text.trim(),
      password: _passwordController.text.trim().isEmpty
          ? null
          : _passwordController.text.trim(),
      privKey: _privKeyController.text.trim().isEmpty
          ? null
          : _privKeyController.text.trim(),
      chainConnection: _chainConnectionController.text.trim().isEmpty
          ? null
          : _chainConnectionController.text.trim(),
      createdAt: widget.server?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
      connectionType: "ssh",
      isOnline: widget.server?.isOnline,
      osVersion: widget.server?.osVersion,
    );

    if (widget.server == null) {
      ref.read(serverListProvider.notifier).addServer(server);
    } else {
      ref.read(serverListProvider.notifier).updateServer(server);
    }

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.server == null
              ? 'Server added successfully'
              : 'Server updated successfully',
        ),
      ),
    );
  }
}
