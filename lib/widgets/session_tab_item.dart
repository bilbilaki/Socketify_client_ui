import 'package:flutter/material.dart';

class SessionTabItem extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onClose;
  final VoidCallback onDuplicate;
  final VoidCallback onPortForward;
  final VoidCallback onTunnel;
  final VoidCallback onFirewall;
  final VoidCallback onDeployApp;

  const SessionTabItem({
    Key? key,
    required this.label,
    required this.isActive,
    required this.onTap,
    required this.onClose,
    required this.onDuplicate,
    required this.onPortForward,
    required this.onTunnel,
    required this.onFirewall,
    required this.onDeployApp,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Colors.blue : Colors.grey[300],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive
                ? Colors.blue.shade700
                : Colors.grey[400] ?? Colors.grey,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Close button on the left
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Tooltip(
                message: 'Close session',
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onClose,
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        Icons.close,
                        size: 14,
                        color: isActive ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Session label
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isActive ? Colors.white : Colors.black,
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            // Menu button on the right
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'duplicate':
                    onDuplicate();
                    break;
                  case 'portforward':
                    onPortForward();
                    break;
                  case 'tunnel':
                    onTunnel();
                    break;
                  case 'firewall':
                    onFirewall();
                    break;
                  case 'deploy':
                    onDeployApp();
                    break;
                }
              },
              itemBuilder: (BuildContext context) => [
                const PopupMenuItem(
                  value: 'duplicate',
                  child: Row(
                    children: [
                      Icon(Icons.content_copy, size: 16),
                      SizedBox(width: 8),
                      Text('Duplicate Session'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'portforward',
                  child: Row(
                    children: [
                      Icon(Icons.router, size: 16),
                      SizedBox(width: 8),
                      Text('Port Forward'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'tunnel',
                  child: Row(
                    children: [
                      Icon(Icons.lan, size: 16),
                      SizedBox(width: 8),
                      Text('Tunnel'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'firewall',
                  child: Row(
                    children: [
                      Icon(Icons.security, size: 16),
                      SizedBox(width: 8),
                      Text('Firewall Rules'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'deploy',
                  child: Row(
                    children: [
                      Icon(Icons.cloud_upload, size: 16),
                      SizedBox(width: 8),
                      Text('Deploy App'),
                    ],
                  ),
                ),
              ],
              child: Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Icon(
                  Icons.more_vert,
                  size: 14,
                  color: isActive ? Colors.white : Colors.black,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
