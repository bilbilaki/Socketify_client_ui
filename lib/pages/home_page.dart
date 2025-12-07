import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sizer/sizer.dart';
import '../providers/app_providers.dart';
import 'hosts_servers_page.dart';

class HomePage extends ConsumerWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(navigationIndexProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Socketify',
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.blue.shade700, Colors.blue.shade900],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(Icons.dns_outlined, size: 5.w, color: Colors.white),
                  SizedBox(height: 1.h),
                  Text(
                    'Socketify',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Server Management',
                    style: TextStyle(color: Colors.white70, fontSize: 10.sp),
                  ),
                ],
              ),
            ),
            _buildDrawerItem(
              context: context,
              ref: ref,
              icon: Icons.dns,
              title: 'Hosts and Servers',
              index: 0,
              selectedIndex: selectedIndex,
            ),
            _buildDrawerItem(
              context: context,
              ref: ref,
              icon: Icons.vpn_key,
              title: 'KeyStore',
              index: 1,
              selectedIndex: selectedIndex,
            ),
            _buildDrawerItem(
              context: context,
              ref: ref,
              icon: Icons.folder,
              title: 'SFTP',
              index: 2,
              selectedIndex: selectedIndex,
            ),
            _buildDrawerItem(
              context: context,
              ref: ref,
              icon: Icons.info_outline,
              title: 'Status',
              index: 3,
              selectedIndex: selectedIndex,
            ),
            _buildDrawerItem(
              context: context,
              ref: ref,
              icon: Icons.settings,
              title: 'Settings',
              index: 4,
              selectedIndex: selectedIndex,
            ),
            _buildDrawerItem(
              context: context,
              ref: ref,
              icon: Icons.swap_horiz,
              title: 'Proxy and Forward',
              index: 5,
              selectedIndex: selectedIndex,
            ),
            _buildDrawerItem(
              context: context,
              ref: ref,
              icon: Icons.security,
              title: 'Firewalls',
              index: 6,
              selectedIndex: selectedIndex,
            ),
            _buildDrawerItem(
              context: context,
              ref: ref,
              icon: Icons.inventory_2,
              title: 'Container',
              index: 7,
              selectedIndex: selectedIndex,
            ),
            _buildDrawerItem(
              context: context,
              ref: ref,
              icon: Icons.terminal,
              title: 'Runcmd',
              index: 8,
              selectedIndex: selectedIndex,
            ),
            _buildDrawerItem(
              context: context,
              ref: ref,
              icon: Icons.code,
              title: 'Snip and Code Gallery',
              index: 9,
              selectedIndex: selectedIndex,
            ),
          ],
        ),
      ),
      body: _getSelectedPage(selectedIndex),
    );
  }

  Widget _buildDrawerItem({
    required BuildContext context,
    required WidgetRef ref,
    required IconData icon,
    required String title,
    required int index,
    required int selectedIndex,
  }) {
    final isSelected = index == selectedIndex;
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? Colors.blue.shade700 : Colors.grey.shade700,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? Colors.blue.shade700 : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 12.sp,
        ),
      ),
      selected: isSelected,
      selectedTileColor: Colors.blue.shade50,
      onTap: () {
        ref.read(navigationIndexProvider.notifier).state = index;
        Navigator.pop(context);
      },
    );
  }

  Widget _getSelectedPage(int index) {
    switch (index) {
      case 0:
        return const HostsServersPage();
      case 1:
        return _buildPlaceholderPage('KeyStore', Icons.vpn_key);
      case 2:
        return _buildPlaceholderPage('SFTP', Icons.folder);
      case 3:
        return _buildPlaceholderPage('Status', Icons.info_outline);
      case 4:
        return _buildPlaceholderPage('Settings', Icons.settings);
      case 5:
        return _buildPlaceholderPage('Proxy and Forward', Icons.swap_horiz);
      case 6:
        return _buildPlaceholderPage('Firewalls', Icons.security);
      case 7:
        return _buildPlaceholderPage('Container', Icons.inventory_2);
      case 8:
        return _buildPlaceholderPage('Runcmd', Icons.terminal);
      case 9:
        return _buildPlaceholderPage('Snip and Code Gallery', Icons.code);
      default:
        return const HostsServersPage();
    }
  }

  Widget _buildPlaceholderPage(String title, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20.w, color: Colors.grey.shade400),
          SizedBox(height: 2.h),
          Text(
            title,
            style: TextStyle(
              fontSize: 16.sp,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Coming Soon',
            style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}
