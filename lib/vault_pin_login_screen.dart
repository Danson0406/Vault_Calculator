import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'pin_pad_widget.dart';
import 'vault_service.dart';
import 'vault_home_screen.dart';

class VaultPinLoginScreen extends StatefulWidget {
  const VaultPinLoginScreen({super.key});

  @override
  State<VaultPinLoginScreen> createState() => _VaultPinLoginScreenState();
}

class _VaultPinLoginScreenState extends State<VaultPinLoginScreen>
    with SingleTickerProviderStateMixin {
  List<String> _pin = [];
  bool _hasError = false;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  static const int _pinLength = 6;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _onKeyTap(String key) {
    if (_pin.length >= _pinLength) return;
    HapticFeedback.lightImpact();
    setState(() {
      _pin.add(key);
      _hasError = false;
    });
    if (_pin.length == _pinLength) {
      Future.delayed(const Duration(milliseconds: 200), _verifyPin);
    }
  }

  void _onDelete() {
    if (_pin.isEmpty) return;
    HapticFeedback.lightImpact();
    setState(() => _pin.removeLast());
  }

  void _verifyPin() async {
    final correct = await VaultService.verifyPin(_pin.join());
    if (!mounted) return;
    if (correct) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const VaultHomeScreen()),
      );
    } else {
      HapticFeedback.heavyImpact();
      _shakeController.forward(from: 0);
      setState(() {
        _pin = [];
        _hasError = true;
      });
    }
  }

  void _forgotPin() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Vault'),
        content: const Text('This will delete all vault data and reset your PIN. Continue?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Reset', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      await VaultService.resetVault();
      if (mounted) Navigator.of(context).pop();
    }
  }

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
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 24),
              Icon(Icons.lock_outline, size: 56, color: Colors.grey.shade400),
              const SizedBox(height: 24),
              AnimatedBuilder(
                animation: _shakeAnimation,
                builder: (context, child) {
                  final offset = _hasError ? sin(_shakeAnimation.value * 3 * pi) * 8 : 0.0;
                  return Transform.translate(offset: Offset(offset, 0), child: child);
                },
                child: Column(
                  children: [
                    Text(
                      _hasError ? '' : 'Enter PIN',
                      style: TextStyle(fontSize: 13, color: Colors.grey[400], letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 16),
                    PinPadWidget(
                      pinDots: _pin,
                      pinLength: _pinLength,
                      onKeyTap: _onKeyTap,
                      onDelete: _onDelete,
                    ),
                  ],
                ),
              ),
              if (_hasError) ...[
                const SizedBox(height: 8),
                const Text('Wrong Pin', style: TextStyle(color: Colors.red, fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text('Enter Pin Again', style: TextStyle(fontSize: 13, color: Colors.grey[400])),
              ],
              const SizedBox(height: 24),
              TextButton(
                onPressed: _forgotPin,
                child: Text('Forgot Pin', style: TextStyle(color: Colors.grey[500], fontSize: 14)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}