import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'encryption_service.dart';
import 'vault_folder_detail_screen.dart';

// ─────────────────────────────
// FOLDER MODEL
// ─────────────────────────────

class FolderEntry {
  final String name;
  final String categoryKey;

  const FolderEntry({required this.name, required this.categoryKey});

  Map<String, dynamic> toJson() =>
      {'name': name, 'categoryKey': categoryKey};

  factory FolderEntry.fromJson(Map<String, dynamic> j) => FolderEntry(
        name: j['name'] as String,
        categoryKey: j['categoryKey'] as String,
      );
}

// ─────────────────────────────
// PERSISTENCE HELPER
// ─────────────────────────────

class _FolderStore {
  static const _filename = 'vault_folders.json';

  static Future<File> _file() async {
    final dir = await EncryptionService.vaultDir();
    return File('${dir.path}/$_filename');
  }

  static Future<List<FolderEntry>> load() async {
    try {
      final f = await _file();
      if (!await f.exists()) {
        // First launch — save defaults to disk so they persist
        final defaults = _defaults();
        await save(defaults);
        return defaults;
      }
      final raw = await f.readAsString();
      final list = jsonDecode(raw) as List<dynamic>;
      // ✅ Wrap in List.from() so the list is mutable (add/removeAt work)
      return List<FolderEntry>.from(
        list.map((e) => FolderEntry.fromJson(e as Map<String, dynamic>)),
      );
    } catch (_) {
      // On any error return a fresh mutable list of defaults
      return _defaults();
    }
  }

  static Future<void> save(List<FolderEntry> folders) async {
    try {
      final f = await _file();
      await f.writeAsString(
        jsonEncode(folders.map((e) => e.toJson()).toList()),
        flush: true,
      );
    } catch (_) {}
  }

  // ✅ Returns a regular mutable List (no const keyword)
  static List<FolderEntry> _defaults() => [
        const FolderEntry(name: 'Folder 1', categoryKey: 'folder_1'),
        const FolderEntry(name: 'Folder 2', categoryKey: 'folder_2'),
        const FolderEntry(name: 'Folder 3', categoryKey: 'folder_3'),
      ];
}

// ─────────────────────────────
// SCREEN
// ─────────────────────────────

class VaultFoldersScreen extends StatefulWidget {
  final VoidCallback? onMenuTap;
  const VaultFoldersScreen({super.key, this.onMenuTap});

  @override
  State<VaultFoldersScreen> createState() => _VaultFoldersScreenState();
}

class _VaultFoldersScreenState extends State<VaultFoldersScreen> {
  // ✅ Explicitly typed as a mutable List — never assigned a const value
  List<FolderEntry> _folders = [];
  bool _loading = true;

  static const _tileColors = [
    Color(0xFFE8F4FD),
    Color(0xFFF0F8E8),
    Color(0xFFFFF3E8),
    Color(0xFFF8E8F8),
    Color(0xFFE8F8F8),
  ];

  @override
  void initState() {
    super.initState();
    _loadFolders();
  }

  // ── Load from disk ────────────────────────────────────────────

  Future<void> _loadFolders() async {
    final folders = await _FolderStore.load();
    if (mounted) {
      setState(() {
        // ✅ Always assign a mutable copy
        _folders = List<FolderEntry>.from(folders);
        _loading = false;
      });
    }
  }

  /// Persist current list to disk immediately after every mutation.
  Future<void> _persist() => _FolderStore.save(_folders);

  // ── Create ────────────────────────────────────────────────────

  Future<void> _createFolder() async {
    final ctrl = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
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
          onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
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

    final safe = name.toLowerCase().replaceAll(RegExp(r'[^\w]'), '_');
    final key = '${safe}_${DateTime.now().millisecondsSinceEpoch}';

    // ✅ _folders is mutable — add() works
    setState(() => _folders.add(FolderEntry(name: name, categoryKey: key)));
    await _persist();
  }

  // ── Delete ────────────────────────────────────────────────────

  Future<void> _deleteFolder(int index) async {
    final folder = _folders[index];

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Folder?',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: Text(
            'Delete "${folder.name}" and all its files?\nThis cannot be undone.'),
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

    // Delete encrypted files from disk
    try {
      final root = await EncryptionService.vaultDir();
      final catDir =
          Directory('${root.path}/${folder.categoryKey}');
      if (await catDir.exists()) await catDir.delete(recursive: true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Could not delete files: $e'),
          behavior: SnackBarBehavior.floating,
        ));
      }
      return;
    }

    HapticFeedback.mediumImpact();

    // ✅ _folders is mutable — removeAt() works
    setState(() => _folders.removeAt(index));
    await _persist();
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
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
            child: Row(
              children: [
                if (widget.onMenuTap != null)
                  IconButton(
                      onPressed: widget.onMenuTap,
                      icon: const Icon(Icons.menu, size: 18)),
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(20)),
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
                const SizedBox(width: 8),
              ],
            ),
          ),

          // Body
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _folders.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.folder_outlined,
                                size: 48,
                                color: Colors.grey.shade300),
                            const SizedBox(height: 12),
                            Text('No folders yet',
                                style: TextStyle(
                                    color: Colors.grey.shade400,
                                    fontSize: 15)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding:
                            const EdgeInsets.fromLTRB(16, 4, 16, 20),
                        itemCount: _folders.length,
                        itemBuilder: (ctx, i) {
                          final f = _folders[i];
                          return _FolderTile(
                            folder: f,
                            color: _tileColors[i % _tileColors.length],
                            onTap: () async {
                              await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      VaultFolderDetailScreen(
                                    folderName: f.name,
                                    categoryKey: f.categoryKey,
                                  ),
                                ),
                              );
                            },
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

// ─────────────────────────────
// FOLDER TILE
// ─────────────────────────────

class _FolderTile extends StatelessWidget {
  final FolderEntry folder;
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
              color: color,
              borderRadius: BorderRadius.circular(12)),
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
        subtitle: Text('Tap to open',
            style:
                TextStyle(color: Colors.grey.shade400, fontSize: 11)),
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