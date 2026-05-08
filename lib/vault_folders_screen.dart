import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'encryption_service.dart';
import 'vault_folder_detail_screen.dart';

class VaultFoldersScreen extends StatefulWidget {
  final VoidCallback? onMenuTap;

  const VaultFoldersScreen({super.key, this.onMenuTap});

  @override
  State<VaultFoldersScreen> createState() => _VaultFoldersScreenState();
}

class _VaultFoldersScreenState extends State<VaultFoldersScreen> {
  // Each folder maps: name -> category key (used as the subfolder name on disk)
  // We keep them in insertion order so the list is stable.
  final List<_FolderEntry> _folders = [
    const _FolderEntry(name: 'Folder 1', categoryKey: 'folder_1'),
    const _FolderEntry(name: 'Folder 2', categoryKey: 'folder_2'),
    const _FolderEntry(name: 'Folder 3', categoryKey: 'folder_3'),
  ];

  final _colors = [
    const Color(0xFFE8F4FD),
    const Color(0xFFF0F8E8),
    const Color(0xFFFFF3E8),
    const Color(0xFFF8E8F8),
    const Color(0xFFE8F8F8),
  ];

  // ── Create ────────────────────────────────────────────────────

  Future<void> _createFolder() async {
    final ctrl = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('New Folder',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            hintText: 'Folder name',
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Create',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (name == null || name.isEmpty) return;

    HapticFeedback.lightImpact();

    // Build a safe disk key from the folder name + timestamp so it's unique
    final key =
        '${name.toLowerCase().replaceAll(RegExp(r'[^\w]'), '_')}_${DateTime.now().millisecondsSinceEpoch}';

    setState(() {
      _folders.add(_FolderEntry(name: name, categoryKey: key));
    });
  }

  // ── Delete ────────────────────────────────────────────────────

  Future<void> _deleteFolder(int index) async {
    final folder = _folders[index];

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Folder?',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: Text(
          'Delete "${folder.name}" and all its files? This cannot be undone.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete',
                style: TextStyle(
                    color: Colors.red, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Delete the actual encrypted files on disk
    try {
      final vaultDir = await EncryptionService.vaultDir();
      final dir = Directory('${vaultDir.path}/${folder.categoryKey}');
      if (await dir.exists()) {
        await for (final entity in dir.list(recursive: true)) {
          try {
            if (entity is File) {
            await entity.delete();
            } else if (entity is Directory) {
            await entity.delete(recursive: true);
        }
          } catch (_) {}
        }

      if (await dir.exists()) {
        await dir.delete(recursive: true);
    }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not delete files: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() => _folders.removeAt(index));
  }

  // ── Build ─────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 12),
            child: Row(
              children: [
                if (widget.onMenuTap != null)
                  IconButton(
                    onPressed: widget.onMenuTap,
                    icon: const Icon(Icons.menu, size: 18),
                  ),
                const Text(
                  'Folders',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1B1B1B)),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: _createFolder,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add, color: Colors.white, size: 15),
                        SizedBox(width: 4),
                        Text('Add',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Folder list
          Expanded(
            child: _folders.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.folder_outlined,
                            size: 48, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text('No folders yet',
                            style: TextStyle(
                                color: Colors.grey.shade400, fontSize: 15)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                    itemCount: _folders.length,
                    itemBuilder: (ctx, i) {
                      final f = _folders[i];
                      final color = _colors[i % _colors.length];
                      return _FolderTile(
                        folder: f,
                        color: color,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => VaultFolderDetailScreen(
                              folderName: f.name,
                              categoryKey: f.categoryKey,
                            ),
                          ),
                        ),
                        onDelete: () => _deleteFolder(i),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Folder tile ───────────────────────────────────────────────

class _FolderTile extends StatelessWidget {
  final _FolderEntry folder;
  final Color color;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _FolderTile({
    required this.folder,
    required this.color,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.folder_rounded,
              color: Colors.black54, size: 22),
        ),
        title: Text(
          folder.name,
          style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: Colors.black87),
        ),
        subtitle: Text(
          'Tap to open  •  Hold to delete',
          style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline,
              color: Colors.redAccent, size: 20),
          tooltip: 'Delete folder',
          onPressed: onDelete,
        ),
      ),
    );
  }
}

// ── Data class ────────────────────────────────────────────────

class _FolderEntry {
  final String name;
  final String categoryKey; // disk subfolder name

  const _FolderEntry({required this.name, required this.categoryKey});
}