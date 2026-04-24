import 'package:flutter/material.dart';
import 'vault_set_pin_screen.dart';

class VaultWelcomeScreen extends StatelessWidget {
  const VaultWelcomeScreen({super.key});
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(builder: (ctx, c) {
          final h = c.maxHeight;
          final w = c.maxWidth;
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: w * 0.08),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: h * 0.06),
                // Icon badge
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.lock_rounded, color: Colors.white, size: 30),
                ),
                SizedBox(height: h * 0.04),
                const Text(
                  'Welcome\nto Vault',
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                    height: 1.1,
                    letterSpacing: -1,
                  ),
                ),
                SizedBox(height: h * 0.02),
                Text(
                  'Your private space for photos, videos, documents, and more — protected by your personal PIN.',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey[500],
                    height: 1.6,
                  ),
                ),
                const Spacer(),
                // Feature chips
                _featureRow(Icons.image_outlined, 'Photos & Videos'),
                SizedBox(height: h * 0.012),
                _featureRow(Icons.description_outlined, 'Documents & Files'),
                SizedBox(height: h * 0.012),
                _featureRow(Icons.music_note_outlined, 'Music & Audio'),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const VaultSetPinScreen()),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(27),
                      ),
                      elevation: 0,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Enter PIN', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward_rounded, size: 18),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: h * 0.02),
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('Cancel', style: TextStyle(color: Colors.grey[400], fontSize: 14)),
                  ),
                ),
                SizedBox(height: h * 0.02),
              ],
            ),
          );
        }),
      ),
    );
  }
 
  Widget _featureRow(IconData icon, String label) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: Colors.grey[700]),
        ),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.black87)),
      ],
    );
  }
}