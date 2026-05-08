import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'vault_folder_detail_screen.dart';

class VaultFoldersScreen extends StatefulWidget {
  final VoidCallback? onMenuTap;

  const VaultFoldersScreen({
    super.key,
    this.onMenuTap,
  });

  @override
  State<VaultFoldersScreen> createState() => _VaultFoldersScreenState();
}

class _VaultFoldersScreenState extends State<VaultFoldersScreen> {
  final List<String> _folders = ['Folder 1', 'Folder 2', 'Folder 3'];

  Future<void> _createFolder() async {
    final controller = TextEditingController();

    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Folder'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Folder name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (name != null && name.isNotEmpty) {
      HapticFeedback.lightImpact();
      setState(() => _folders.add(name));
    }
  }

  Future<void> _deleteFolder(int index) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Folder?'),
        content: Text('Delete "${_folders[index]}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (ok == true) setState(() => _folders.removeAt(index));
  }

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
                  onPressed: widget.onMenuTap,
                  icon: const Icon(Icons.menu, size: 18),
                ),
                const Text(
                  'Folders',
                  style: TextStyle(
                    fontSize: 27,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1B1B1B),
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: _createFolder,
                  icon: const Icon(Icons.add, size: 22),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Expanded(
              child: ListView.separated(
                itemCount: _folders.length,
                separatorBuilder: (_, __) => const SizedBox(height: 22),
                itemBuilder: (context, index) {
                  final folder = _folders[index];

                  return GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              VaultFolderDetailScreen(folderName: folder),
                        ),
                      );
                    },
                    onLongPress: () => _deleteFolder(index),
                    child: Row(
                      children: [
                        const Icon(Icons.folder_outlined, size: 36),
                        const SizedBox(width: 16),
                        Text(
                          folder,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}