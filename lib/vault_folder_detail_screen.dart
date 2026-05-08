import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';

import 'encryption_service.dart';
import 'vault_session.dart';

class VaultFolderDetailScreen extends StatelessWidget {
  final String folderName;

  const VaultFolderDetailScreen({
    super.key,
    required this.folderName,
  });

  static const List<_Cat> _categories = [
    _Cat('Images', 'images', Icons.image_outlined),
    _Cat('Documents', 'documents', Icons.insert_drive_file_outlined),
    _Cat('Videos', 'videos', Icons.video_library_outlined),
    _Cat('Audios', 'audios', Icons.music_note),
  ];

  void _openCategory(BuildContext context, _Cat cat) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VaultCategoryScreen(
          folderName: folderName,
          category: cat,
        ),
      ),
    );
  }

  Future<void> _showAddMenu(BuildContext context) async {
    final selected = await showModalBottomSheet<_Cat>(
      context: context,
      backgroundColor: Colors.white,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: _categories.map((cat) {
                return ListTile(
                  leading: Icon(cat.icon, color: Colors.black),
                  title: Text('Add ${cat.label}'),
                  onTap: () => Navigator.of(context).pop(cat),
                );
              }).toList(),
            ),
          ),
        );
      },
    );

    if (selected != null && context.mounted) {
      _openCategory(context, selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back, size: 18),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          folderName,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Text(
                          'Categories',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 8,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => _showAddMenu(context),
                    icon: const Icon(Icons.add, size: 22),
                  ),
                ],
              ),
              const SizedBox(height: 34),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 34,
                  crossAxisSpacing: 18,
                  childAspectRatio: 1.8,
                  children: _categories.map((cat) {
                    return GestureDetector(
                      onTap: () => _openCategory(context, cat),
                      child: Row(
                        children: [
                          Icon(cat.icon, size: 25, color: Colors.black),
                          const SizedBox(width: 12),
                          Text(
                            cat.label,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class VaultCategoryScreen extends StatefulWidget {
  final String folderName;
  final _Cat category;

  const VaultCategoryScreen({
    super.key,
    required this.folderName,
    required this.category,
  });

  @override
  State<VaultCategoryScreen> createState() => _VaultCategoryScreenState();
}

class _VaultCategoryScreenState extends State<VaultCategoryScreen> {
  List<VaultFile> _files = [];
  bool _loading = false;

  String get _categoryKey =>
      '${_safeName(widget.folderName)}_${widget.category.key}';

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  String _safeName(String value) {
    return value.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
  }

  Future<void> _loadFiles() async {
    final files = await EncryptionService.listFiles(_categoryKey);
    if (!mounted) return;
    setState(() => _files = files);
  }

  Future<void> _importFiles() async {
    if (!VaultSession.isUnlocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vault is locked. Log in again.')),
      );
      return;
    }

    final result = await FilePicker.platform.pickFiles(allowMultiple: true);
    if (result == null) return;

    setState(() => _loading = true);

    try {
      for (final picked in result.files) {
        if (picked.path == null) continue;

        await EncryptionService.importFile(
          sourceFile: File(picked.path!),
          originalName: picked.name,
          category: _categoryKey,
        );
      }

      await _loadFiles();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Import failed: $error')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openFile(VaultFile file) async {
    if (!VaultSession.isUnlocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vault is locked. Log in again.')),
      );
      return;
    }

    try {
      final path = await EncryptionService.exportForViewing(file.encPath);
      await OpenFilex.open(path);

      Future.delayed(const Duration(minutes: 2), () {
        File(path).delete().catchError((_) {});
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open file: $error')),
      );
    }
  }

  Future<void> _deleteFile(VaultFile file) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete File?'),
        content: Text('Delete "${file.displayName}"?'),
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

    if (ok == true) {
      await EncryptionService.deleteFile(file.encPath);
      await _loadFiles();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        onPressed: _importFiles,
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back, size: 18),
                      ),
                      Expanded(
                        child: Text(
                          widget.category.label,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _files.isEmpty
                        ? const Center(
                            child: Text(
                              'No files yet',
                              style: TextStyle(color: Colors.black54),
                            ),
                          )
                        : ListView.separated(
                            itemCount: _files.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final file = _files[index];

                              return ListTile(
                                leading: Icon(
                                  widget.category.icon,
                                  color: Colors.black,
                                ),
                                title: Text(
                                  file.displayName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(file.sizeLabel),
                                onTap: () => _openFile(file),
                                trailing: IconButton(
                                  onPressed: () => _deleteFile(file),
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.red,
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
            if (_loading)
              Container(
                color: Colors.white.withOpacity(0.65),
                child: const Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }
}

class _Cat {
  final String label;
  final String key;
  final IconData icon;

  const _Cat(this.label, this.key, this.icon);
}