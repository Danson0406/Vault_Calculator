import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'encryption_service.dart';
import 'vault_folders_screen.dart';

class VaultHomeScreen extends StatefulWidget {
  const VaultHomeScreen({super.key});

  @override
  State<VaultHomeScreen> createState() => _VaultHomeScreenState();
}

class _VaultHomeScreenState extends State<VaultHomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _pageIndex = 0;
  bool _importing = false;

  void _openMenu() => _scaffoldKey.currentState?.openDrawer();

  void _selectPage(int index) {
    Navigator.of(context).pop(); // close drawer
    setState(() => _pageIndex = index);
  }

  void _exitVault() {
    EncryptionService.lock(); // wipe session key from memory
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  // ── Import (Home tab FAB) ────────────────────────────────────
  Future<void> _importFiles() async {
    // Guard: session key must be set
    if (!EncryptionService.isUnlocked) {
      _showSnack('Vault is locked. Please log in again.');
      return;
    }

    FilePickerResult? res;
    try {
      res = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.any,
      );
    } catch (e) {
      _showSnack('Could not open file picker: $e');
      return;
    }

    if (res == null || res.files.isEmpty || !mounted) return;

    setState(() => _importing = true);

    int imported = 0;
    final errors = <String>[];

    for (final picked in res.files) {
      final path = picked.path;
      if (path == null) {
        errors.add('${picked.name}: path unavailable');
        continue;
      }
      try {
        final bytes = await File(path).readAsBytes();
        // importRawFile is the correct method name in EncryptionService
        await EncryptionService.importRawFile(
          data: bytes,
          originalName: picked.name,
          category: 'general', // home imports go to a shared 'general' folder
        );
        imported++;
      } catch (e) {
        errors.add('${picked.name}: $e');
      }
    }

    if (!mounted) return;
    setState(() => _importing = false);

    if (errors.isEmpty) {
      _showSnack(imported == 1
          ? '1 file imported'
          : '$imported files imported');
    } else {
      _showSnack(
        imported > 0
            ? '$imported imported, ${errors.length} failed'
            : 'Import failed: ${errors.first}',
        isError: true,
      );
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red.shade700 : null,
      behavior: SnackBarBehavior.floating,
    ));
  }

  // ── Build ─────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final pages = [
      _HomeWelcomePage(onMenuTap: _openMenu),
      VaultFoldersScreen(onMenuTap: _openMenu),
      _SimplePage(
        onMenuTap: _openMenu,
        title: 'Notifications',
        icon: Icons.notifications_none,
        message: 'No notifications yet',
      ),
      _SimplePage(
        onMenuTap: _openMenu,
        title: 'Bookmarks',
        icon: Icons.bookmark_border,
        message: 'No bookmarks yet',
      ),
    ];

    final showFab = _pageIndex == 0;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      floatingActionButton: showFab
          ? FloatingActionButton(
              onPressed: _importing ? null : _importFiles,
              backgroundColor: Colors.black,
              elevation: 2,
              tooltip: 'Import files',
              child: _importing
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.upload_rounded, color: Colors.white),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      drawer: Drawer(
        backgroundColor: Colors.white,
        width: 230,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 14, 10, 14),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back, size: 18),
                  ),
                ),
                const Divider(height: 24, color: Color(0xFFEFEFEF)),
                _DrawerItem(
                  icon: Icons.home_outlined,
                  label: 'Home',
                  onTap: () => _selectPage(0),
                ),
                _DrawerItem(
                  icon: Icons.insert_drive_file_outlined,
                  label: 'Files',
                  onTap: () => _selectPage(1),
                ),
                _DrawerItem(
                  icon: Icons.notifications_none,
                  label: 'Notifications',
                  onTap: () => _selectPage(2),
                ),
                _DrawerItem(
                  icon: Icons.bookmark_border,
                  label: 'Bookmarks',
                  onTap: () => _selectPage(3),
                ),
                _DrawerItem(
                  icon: Icons.logout,
                  label: 'Exit',
                  onTap: _exitVault,
                ),
              ],
            ),
          ),
        ),
      ),
      body: pages[_pageIndex],
    );
  }
}

// ─────────────────────────────
// DRAWER ITEM
// ─────────────────────────────

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      minLeadingWidth: 20,
      leading: Icon(icon, color: Colors.black, size: 15),
      title: Text(
        label,
        style: const TextStyle(
            color: Colors.black, fontSize: 11, fontWeight: FontWeight.w500),
      ),
      onTap: onTap,
    );
  }
}

// ─────────────────────────────
// HOME WELCOME PAGE
// ─────────────────────────────

class _HomeWelcomePage extends StatelessWidget {
  final VoidCallback onMenuTap;
  const _HomeWelcomePage({required this.onMenuTap});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                    onPressed: onMenuTap,
                    icon: const Icon(Icons.menu, size: 18)),
                const Text(
                  'Vault',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1B1B1B)),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lock, color: Colors.white, size: 20),
                  SizedBox(height: 10),
                  Text('Vault secured',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700)),
                  SizedBox(height: 6),
                  Text('Your files are safely hidden',
                      style: TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
            const Spacer(),
            const Center(
              child: Text(
                'Everything here stays private',
                style: TextStyle(fontSize: 11, color: Colors.black38),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────
// PLACEHOLDER PAGE
// ─────────────────────────────

class _SimplePage extends StatelessWidget {
  final VoidCallback onMenuTap;
  final String title;
  final IconData icon;
  final String message;

  const _SimplePage({
    required this.onMenuTap,
    required this.title,
    required this.icon,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                    onPressed: onMenuTap,
                    icon: const Icon(Icons.menu, size: 18)),
                Text(title,
                    style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1B1B1B))),
              ],
            ),
            const Spacer(),
            Center(
              child: Column(
                children: [
                  Icon(icon, size: 54, color: Colors.black),
                  const SizedBox(height: 12),
                  Text(message, style: const TextStyle(fontSize: 13)),
                ],
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}