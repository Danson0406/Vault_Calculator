import 'package:flutter/material.dart';
import 'vault_folders_screen.dart';

class VaultHomeScreen extends StatefulWidget {
  const VaultHomeScreen({super.key});

  @override
  State<VaultHomeScreen> createState() => _VaultHomeScreenState();
}

class _VaultHomeScreenState extends State<VaultHomeScreen> {
  int _selectedIndex = 0;

  final List<Map<String, dynamic>> _navItems = [
    {'icon': Icons.home_outlined, 'label': 'Home'},
    {'icon': Icons.folder_outlined, 'label': 'Files'},
    {'icon': Icons.notifications_outlined, 'label': 'Notifications'},
    {'icon': Icons.bookmark_outline, 'label': 'Bookmarks'},
    {'icon': Icons.exit_to_app, 'label': 'Exit'},
  ];

  void _onNavTap(int index) {
    if (_navItems[index]['label'] == 'Exit') {
      Navigator.of(context).popUntil((route) => route.isFirst);
      return;
    }
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  const Text(
                    'Vault',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.search, color: Colors.black),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert, color: Colors.black),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
            // Content area
            Expanded(
              child: _selectedIndex == 1
                  ? const VaultFoldersScreen()
                  : _buildHomeContent(),
            ),
            // Bottom nav
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                children: List.generate(_navItems.length, (i) {
                  final item = _navItems[i];
                  final isSelected = _selectedIndex == i;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => _onNavTap(i),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              item['icon'] as IconData,
                              color: isSelected ? Colors.black : Colors.grey,
                              size: 22,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item['label'] as String,
                              style: TextStyle(
                                fontSize: 10,
                                color: isSelected ? Colors.black : Colors.grey,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeContent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_open_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'Welcome',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your vault is empty.\nTap Files to add content.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }
}