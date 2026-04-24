import 'package:flutter/material.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:open_filex/open_filex.dart';

import 'encryption_service.dart';
import 'vault_session.dart';

class VaultFolderDetailScreen extends StatefulWidget {
  final String folderName;

  const VaultFolderDetailScreen({super.key, required this.folderName});

  @override
  State<VaultFolderDetailScreen> createState() =>
      _VaultFolderDetailScreenState();
}

class _VaultFolderDetailScreenState extends State<VaultFolderDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  bool _loading = false;
  int _refresh = 0;

  static const _cats = [
    _Cat('Images', 'images', Icons.image, Color(0xFFE3F2FD), Colors.blue),
    _Cat('Videos', 'videos', Icons.video_call, Color(0xFFE8F5E9),
        Colors.green),
    _Cat('Docs', 'documents', Icons.description, Color(0xFFFFF8E1),
        Colors.orange),
    _Cat('Music', 'music', Icons.music_note, Color(0xFFF3E5F5),
        Colors.purple),
  ];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: _cats.length, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _import(String category) async {
    // Guard: vault must be unlocked before we try to encrypt anything.
    if (!VaultSession.isUnlocked) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vault is locked. Please log in again.')),
        );
      }
      return;
    }

    final res = await FilePicker.platform.pickFiles(allowMultiple: true);
    if (res == null) return;

    setState(() => _loading = true);

    try {
      await Future.wait(
        res.files.map((f) async {
          if (f.path == null) return;
          // importFile uses the session key stored in EncryptionService — no pin needed.
          await EncryptionService.importFile(
            sourceFile: File(f.path!),
            originalName: f.name,
            category: category,
          );
        }),
      );

      setState(() => _refresh++);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.folderName),
        bottom: TabBar(
          controller: _tabs,
          tabs: _cats.map((e) => Tab(text: e.label)).toList(),
        ),
      ),
      body: Stack(
        children: [
          TabBarView(
            controller: _tabs,
            children: _cats.map((c) {
              return _Tab(
                cat: c,
                refresh: _refresh,
                onImport: () => _import(c.key),
              );
            }).toList(),
          ),
          if (_loading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}

// ─────────────────────────────
// TAB WIDGET
// ─────────────────────────────

class _Tab extends StatefulWidget {
  final _Cat cat;
  final int refresh;
  final VoidCallback onImport;

  const _Tab({
    required this.cat,
    required this.refresh,
    required this.onImport,
  });

  @override
  State<_Tab> createState() => _TabState();
}

class _TabState extends State<_Tab> {
  List<VaultFile> files = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant _Tab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refresh != widget.refresh) _load();
  }

  Future<void> _load() async {
    final loaded = await EncryptionService.listFiles(widget.cat.key);
    if (mounted) setState(() => files = loaded);
  }

  Future<void> _open(VaultFile f) async {
    if (!VaultSession.isUnlocked) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Vault is locked. Please log in again.')),
        );
      }
      return;
    }

    try {
      // exportForViewing uses the session key — no pin param needed.
      final tmp = await EncryptionService.exportForViewing(f.encPath);
      await OpenFilex.open(tmp);

      // Auto-delete the temp file after 2 minutes.
      Future.delayed(const Duration(minutes: 2), () {
        File(tmp).delete().catchError((_) {});
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open file: $e')),
        );
      }
    }
  }

  Future<void> _delete(VaultFile f) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete File?',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: Text('Delete "${f.displayName}"?'),
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

    if (ok == true) {
      await EncryptionService.deleteFile(f.encPath);
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        ElevatedButton.icon(
          onPressed: widget.onImport,
          icon: const Icon(Icons.add),
          label: const Text('Import Files'),
        ),
        const SizedBox(height: 8),
        if (files.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: Text('No files yet',
                  style: TextStyle(color: Colors.grey)),
            ),
          )
        else
          ...files.map(
            (f) => ListTile(
              leading: Icon(widget.cat.icon, color: widget.cat.iconColor),
              title: Text(f.displayName),
              subtitle: Text(f.sizeLabel),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () => _delete(f),
              ),
              onTap: () => _open(f),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────
// CATEGORY MODEL
// ─────────────────────────────

class _Cat {
  final String label;
  final String key;
  final IconData icon;
  final Color bg;
  final Color iconColor;

  const _Cat(this.label, this.key, this.icon, this.bg, this.iconColor);
}