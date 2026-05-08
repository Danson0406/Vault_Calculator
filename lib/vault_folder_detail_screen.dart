import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';

import 'encryption_service.dart';

class VaultFolderDetailScreen extends StatefulWidget {
  final String folderName;
  final String categoryKey; // disk subfolder name passed from VaultFoldersScreen

  const VaultFolderDetailScreen({
    super.key,
    required this.folderName,
    required this.categoryKey,
  });

  @override
  State<VaultFolderDetailScreen> createState() =>
      _VaultFolderDetailScreenState();
}

class _VaultFolderDetailScreenState extends State<VaultFolderDetailScreen> {
  List<VaultFile> _files = [];
  bool _loading = false;
  bool _initialLoad = true;

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  // ── Load ──────────────────────────────────────────────────────

  Future<void> _loadFiles() async {
    try {
      final files = await EncryptionService.listFiles(widget.categoryKey);
      if (mounted) {
        setState(() {
          _files = files;
          _initialLoad = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _initialLoad = false);
        _showError('Could not load files: $e');
      }
    }
  }

  // ── Import ────────────────────────────────────────────────────

  Future<void> _importFiles() async {
    // 1. Guard: vault must be unlocked
    if (!EncryptionService.isUnlocked) {
      _showError('Vault is locked. Please log in again.');
      return;
    }

    // 2. Open the system file picker (no type filter = any file)
    FilePickerResult? result;
    try {
      result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.any,
      );
    } catch (e) {
      _showError('File picker error: $e');
      return;
    }

    if (result == null || result.files.isEmpty) return; // user cancelled

    setState(() => _loading = true);

    int imported = 0;
    final errors = <String>[];

    for (final picked in result.files) {
  final path = picked.path;

  if (path == null) {
    errors.add('${picked.name}: no path available');
    continue;
  }

  try {
    final bytes = await File(path).readAsBytes();

    await EncryptionService.importRawFile(
      data: bytes,
      originalName: picked.name,
      category: widget.categoryKey,
    );

    imported++;
  } catch (e) {
    errors.add('${picked.name}: $e');
  }
}

    // 3. Refresh the list
    await _loadFiles();

    if (!mounted) return;
    setState(() => _loading = false);

    // 4. Show result
    if (errors.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(imported == 1
              ? '1 file imported successfully'
              : '$imported files imported successfully'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            imported > 0
                ? '$imported imported, ${errors.length} failed:\n${errors.join('\n')}'
                : 'Import failed:\n${errors.join('\n')}',
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 6),
        ),
      );
    }
  }

  // ── Open (decrypt + view) ─────────────────────────────────────

  Future<void> _openFile(VaultFile f) async {
    if (!EncryptionService.isUnlocked) {
      _showError('Vault is locked. Please log in again.');
      return;
    }

    setState(() => _loading = true);
    try {
      final tmpPath = await EncryptionService.exportForViewing(f.encPath);
      final result = await OpenFilex.open(tmpPath);

      if (result.type != ResultType.done && mounted) {
        _showError('Cannot open this file type: ${result.message}');
      }

      // Auto-delete temp file after 2 minutes
      Future.microtask(() async {
      await Future.delayed(const Duration(seconds: 10));

  try {
    final f = File(tmpPath);
    if (await f.exists()) {
      await f.delete();
    }
    } catch (_) {}
    });
    } catch (e) {
      if (mounted) _showError('Could not open file: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Delete file ───────────────────────────────────────────────

  Future<void> _deleteFile(VaultFile f) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete File?',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: Text('Delete "${f.displayName}"? This cannot be undone.'),
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

    try {
      await EncryptionService.deleteFile(f.encPath);
      await _loadFiles(); // refresh
    } catch (e) {
      if (mounted) _showError('Could not delete file: $e');
    }
  }

  // ── Helpers ───────────────────────────────────────────────────

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 18, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.folderName,
          style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.black),
        ),
        actions: [
          // Import button in the top-right corner
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              onPressed: _loading ? null : _importFiles,
              icon: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.black),
                    )
                  : const Icon(Icons.upload_rounded,
                      color: Colors.black, size: 22),
              tooltip: 'Import files',
            ),
          ),
        ],
      ),
      body: _initialLoad
          ? const Center(child: CircularProgressIndicator())
          : _files.isEmpty
              ? _EmptyState(onImport: _importFiles)
              : RefreshIndicator(
                  onRefresh: _loadFiles,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: _files.length,
                    itemBuilder: (ctx, i) {
                      final f = _files[i];
                      return _FileTile(
                        file: f,
                        onTap: () => _openFile(f),
                        onDelete: () => _deleteFile(f),
                      );
                    },
                  ),
                ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final VoidCallback onImport;

  const _EmptyState({required this.onImport});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.folder_open_rounded,
              size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 14),
          Text('No files yet',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade400)),
          const SizedBox(height: 6),
          Text('Tap the import button to add files',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade400)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onImport,
            icon: const Icon(Icons.upload_rounded, size: 18),
            label: const Text('Import Files'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24)),
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }
}

// ── File tile ─────────────────────────────────────────────────

class _FileTile extends StatelessWidget {
  final VaultFile file;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _FileTile({
    required this.file,
    required this.onTap,
    required this.onDelete,
  });

  IconData get _icon {
    final ext = file.displayName.split('.').last.toLowerCase();
    if (['jpg', 'jpeg', 'png', 'gif', 'heic', 'webp'].contains(ext)) {
      return Icons.image_outlined;
    }
    if (['mp4', 'mov', 'avi', 'mkv'].contains(ext)) {
      return Icons.video_file_outlined;
    }
    if (['mp3', 'aac', 'wav', 'm4a'].contains(ext)) {
      return Icons.audio_file_outlined;
    }
    if (['pdf'].contains(ext)) return Icons.picture_as_pdf_outlined;
    if (['doc', 'docx'].contains(ext)) return Icons.description_outlined;
    return Icons.insert_drive_file_outlined;
  }

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
              color: const Color(0xFFF2F2F2),
              borderRadius: BorderRadius.circular(12)),
          child: Icon(_icon, color: Colors.black54, size: 22),
        ),
        title: Text(
          file.displayName,
          style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Colors.black87),
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${file.sizeLabel}  •  ${_formatDate(file.modified)}',
          style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline,
              color: Colors.redAccent, size: 20),
          tooltip: 'Delete file',
          onPressed: onDelete,
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    return '${d.day}/${d.month}/${d.year}';
  }
}