import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';

import 'encryption_service.dart';

class VaultFolderDetailScreen extends StatefulWidget {
  final String folderName;
  final String categoryKey;

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
    if (!EncryptionService.isUnlocked) {
      _showError('Vault is locked. Please log in again.');
      return;
    }

    FilePickerResult? result;
    try {
      result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.any,
      );
    } catch (e) {
      _showError('Could not open file picker: $e');
      return;
    }

    if (result == null || result.files.isEmpty) return;

    setState(() => _loading = true);

    int imported = 0;
    final errors = <String>[];

    for (final picked in result.files) {
      final path = picked.path;
      if (path == null) {
        errors.add('${picked.name}: path unavailable');
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

    await _loadFiles(); // refresh list

    if (!mounted) return;
    setState(() => _loading = false);

    if (errors.isEmpty) {
      _showSnack(imported == 1
          ? '1 file imported successfully'
          : '$imported files imported successfully');
    } else {
      _showError(imported > 0
          ? '$imported imported, ${errors.length} failed'
          : 'Import failed: ${errors.first}');
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
        _showError('Cannot open file: ${result.message}');
      }

      // Auto-delete temp file after 2 minutes
      Future.delayed(const Duration(minutes: 2), () {
        File(tmpPath).delete().catchError((_) {});
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
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete File?',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content:
            Text('Delete "${f.displayName}"?\nThis cannot be undone.'),
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
      await _loadFiles();
    } catch (e) {
      if (mounted) _showError('Could not delete: $e');
    }
  }

  // ── Helpers ───────────────────────────────────────────────────

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      behavior: SnackBarBehavior.floating,
    ));
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Colors.red.shade700,
      behavior: SnackBarBehavior.floating,
    ));
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
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              onPressed: _loading ? null : _importFiles,
              tooltip: 'Import files',
              icon: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.black))
                  : const Icon(Icons.upload_rounded,
                      color: Colors.black, size: 22),
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
                    itemBuilder: (ctx, i) => _FileTile(
                      file: _files[i],
                      onTap: () => _openFile(_files[i]),
                      onDelete: () => _deleteFile(_files[i]),
                    ),
                  ),
                ),
    );
  }
}

// ─────────────────────────────
// EMPTY STATE
// ─────────────────────────────

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
          Text('Tap ↑ above to import files',
              style:
                  TextStyle(fontSize: 13, color: Colors.grey.shade400)),
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
              padding: const EdgeInsets.symmetric(
                  horizontal: 24, vertical: 12),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────
// FILE TILE
// ─────────────────────────────

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
    final name = file.displayName;
    final ext =
        name.contains('.') ? name.split('.').last.toLowerCase() : '';
    if (['jpg', 'jpeg', 'png', 'gif', 'heic', 'webp'].contains(ext)) {
      return Icons.image_outlined;
    }
    if (['mp4', 'mov', 'avi', 'mkv'].contains(ext)) {
      return Icons.video_file_outlined;
    }
    if (['mp3', 'aac', 'wav', 'm4a', 'flac'].contains(ext)) {
      return Icons.audio_file_outlined;
    }
    if (ext == 'pdf') return Icons.picture_as_pdf_outlined;
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
          '${file.sizeLabel}  •  ${_fmt(file.modified)}',
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

  String _fmt(DateTime d) => '${d.day}/${d.month}/${d.year}';
}