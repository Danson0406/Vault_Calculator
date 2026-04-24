import 'package:flutter/material.dart';
import 'vault_folders_screen.dart';
import 'vault_session.dart';

class VaultHomeScreen extends StatefulWidget {
  const VaultHomeScreen({super.key});

  @override
  State<VaultHomeScreen> createState() => _VaultHomeScreenState();
}

class _VaultHomeScreenState extends State<VaultHomeScreen> {
  int _idx = 0;

  final _tabs = const [
    _TabDef(Icons.home_outlined, Icons.home_rounded, 'Home'),
    _TabDef(Icons.folder_outlined, Icons.folder_rounded, 'Files'),
    _TabDef(Icons.notifications_outlined, Icons.notifications_rounded,
        'Alerts'),
    _TabDef(Icons.bookmark_outline, Icons.bookmark_rounded, 'Saved'),
    _TabDef(Icons.exit_to_app_rounded, Icons.exit_to_app_rounded, 'Exit'),
  ];

  void _onTab(int i) {
    if (_tabs[i].label == 'Exit') {
      // Lock the session so the key is wiped from memory on exit.
      VaultSession.clear();
      Navigator.of(context).popUntil((r) => r.isFirst);
      return;
    }
    setState(() => _idx = i);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar ──────────────────────────────
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(20, 14, 8, 14),
              child: Row(
                children: [
                  const Text('Vault',
                      style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: Colors.black)),
                  const Spacer(),
                  IconButton(
                      icon: const Icon(Icons.search_rounded,
                          color: Colors.black),
                      onPressed: () {}),
                  IconButton(
                      icon: const Icon(Icons.more_horiz_rounded,
                          color: Colors.black),
                      onPressed: () {}),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFEEEEEE)),

            // ── Content ──────────────────────────────
            Expanded(
              child: IndexedStack(
                index: _idx,
                children: const [
                  _HomeTab(),
                  VaultFoldersScreen(),
                  _PlaceholderTab(
                      Icons.notifications_outlined, 'No Notifications'),
                  _PlaceholderTab(
                      Icons.bookmark_outline, 'No Saved Items'),
                  SizedBox.shrink(),
                ],
              ),
            ),

            // ── Bottom nav ────────────────────────────
            Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                border:
                    Border(top: BorderSide(color: Color(0xFFEEEEEE))),
              ),
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: List.generate(_tabs.length, (i) {
                  final t = _tabs[i];
                  final sel = _idx == i;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => _onTab(i),
                      behavior: HitTestBehavior.opaque,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            sel ? t.activeIcon : t.icon,
                            color: sel
                                ? Colors.black
                                : Colors.grey.shade400,
                            size: 22,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            t.label,
                            style: TextStyle(
                              fontSize: 10,
                              color: sel
                                  ? Colors.black
                                  : Colors.grey.shade400,
                              fontWeight: sel
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                            ),
                          ),
                        ],
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
}

class _TabDef {
  final IconData icon, activeIcon;
  final String label;
  const _TabDef(this.icon, this.activeIcon, this.label);
}

class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.lock_open_rounded,
                size: 36, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 16),
          const Text('Welcome',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87)),
          const SizedBox(height: 8),
          Text(
            'Your vault is ready.\nTap Files to add content.',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade400,
                height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _PlaceholderTab extends StatelessWidget {
  final IconData icon;
  final String message;
  const _PlaceholderTab(this.icon, this.message);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(message,
              style:
                  TextStyle(fontSize: 15, color: Colors.grey.shade400)),
        ],
      ),
    );
  }
}