import 'package:flutter/material.dart';
import 'vault_folder_detail_screen.dart';
import 'package:flutter/services.dart';

class VaultFoldersScreen extends StatefulWidget {
  const VaultFoldersScreen({super.key});
 
  @override
  State<VaultFoldersScreen> createState() => _VaultFoldersScreenState();
}
 
class _VaultFoldersScreenState extends State<VaultFoldersScreen> {
  final List<Map<String, dynamic>> _folders = [
    {'name': 'Folder 1', 'count': 0, 'color': const Color(0xFFE8F4FD)},
    {'name': 'Folder 2', 'count': 0, 'color': const Color(0xFFF0F8E8)},
    {'name': 'Folder 3', 'count': 0, 'color': const Color(0xFFFFF3E8)},
  ];
 
  final _colors = [
    const Color(0xFFE8F4FD),
    const Color(0xFFF0F8E8),
    const Color(0xFFFFF3E8),
    const Color(0xFFF8E8F8),
    const Color(0xFFE8F8F8),
  ];
 
  void _createFolder() async {
    final ctrl = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('New Folder', style: TextStyle(fontWeight: FontWeight.w700)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
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
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Create', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (name != null && name.isNotEmpty) {
      HapticFeedback.lightImpact();
      setState(() {
        _folders.add({
          'name': name,
          'count': 0,
          'color': _colors[_folders.length % _colors.length],
        });
      });
    }
  }
 
  void _deleteFolder(int i) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Folder?', style: TextStyle(fontWeight: FontWeight.w700)),
        content: Text('Delete "${_folders[i]['name']}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (ok == true) setState(() => _folders.removeAt(i));
  }
 
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 16, 12),
          child: Row(
            children: [
              const Text('Folders',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.black)),
              const Spacer(),
              GestureDetector(
                onTap: _createFolder,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, color: Colors.white, size: 15),
                      SizedBox(width: 4),
                      Text('Add', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
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
                      Icon(Icons.folder_outlined, size: 48, color: Colors.grey.shade300),
                      const SizedBox(height: 12),
                      Text('No folders yet', style: TextStyle(color: Colors.grey.shade400, fontSize: 15)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                  itemCount: _folders.length,
                  itemBuilder: (ctx, i) {
                    final f = _folders[i];
                    return GestureDetector(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => VaultFolderDetailScreen(folderName: f['name'] as String),
                        ),
                      ),
                      onLongPress: () => _deleteFolder(i),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: f['color'] as Color,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.folder_rounded, color: Colors.black54, size: 22),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(f['name'] as String,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600, fontSize: 15, color: Colors.black87)),
                                  const SizedBox(height: 2),
                                  Text(
                                    f['count'] == 0 ? 'Empty' : '${f['count']} items',
                                    style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right_rounded, color: Colors.grey.shade300, size: 20),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}