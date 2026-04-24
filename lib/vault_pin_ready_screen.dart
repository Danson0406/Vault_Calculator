import 'package:flutter/material.dart';
import 'vault_home_screen.dart';

class VaultPinReadyScreen extends StatefulWidget {
  const VaultPinReadyScreen({super.key});
 
  @override
  State<VaultPinReadyScreen> createState() => _VaultPinReadyScreenState();
}
 
class _VaultPinReadyScreenState extends State<VaultPinReadyScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _fade;
 
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _fade = CurvedAnimation(parent: _ctrl, curve: const Interval(0.0, 0.5));
    _ctrl.forward();
  }
 
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(builder: (ctx, c) {
          final h = c.maxHeight;
          final w = c.maxWidth;
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: w * 0.08),
            child: Column(
              children: [
                SizedBox(height: h * 0.12),
                // Animated check circle
                ScaleTransition(
                  scale: _scale,
                  child: FadeTransition(
                    opacity: _fade,
                    child: Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black, width: 2.5),
                      ),
                      child: const Icon(Icons.check_rounded, size: 44, color: Colors.black),
                    ),
                  ),
                ),
                SizedBox(height: h * 0.05),
                FadeTransition(
                  opacity: _fade,
                  child: const Text(
                    'Your new PIN\nis ready',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                      height: 1.15,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                SizedBox(height: h * 0.02),
                Text(
                  'Your vault is secured. Remember your PIN — it cannot be recovered.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey[500], height: 1.6),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const VaultHomeScreen()),
                      (r) => false,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(27)),
                      elevation: 0,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Get Started', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward_rounded, size: 18),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: h * 0.06),
              ],
            ),
          );
        }),
      ),
    );
  }
}