import 'package:flutter/material.dart';

class VaultFolderDetailScreen extends StatelessWidget {
  final String folderName;

  const VaultFolderDetailScreen({super.key, required this.folderName});

  static const List<Map<String, dynamic>> _categories = [
    {'icon': Icons.image_outlined, 'label': 'Add Images', 'color': Color(0xFF4CAF50)},
    {'icon': Icons.videocam_outlined, 'label': 'Add Videos', 'color': Color(0xFF2196F3)},
    {'icon': Icons.description_outlined, 'label': 'Add Documents', 'color': Color(0xFFFF9800)},
    {'icon': Icons.music_note_outlined, 'label': 'Add Music', 'color': Color(0xFF9C27B0)},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          folderName,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Categories',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[400],
                letterSpacing: 0.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            // 2x2 grid
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.6,
                children: _categories.map((cat) {
                  return GestureDetector(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${cat['label']} - Coming soon'),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            cat['icon'] as IconData,
                            color: cat['color'] as Color,
                            size: 28,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            cat['label'] as String,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}