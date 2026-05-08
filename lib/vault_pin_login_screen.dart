import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'pin_pad_widget.dart';
import 'vault_home_screen.dart';
import 'vault_service.dart';
import 'vault_set_pin_screen.dart';

class VaultPinLoginScreen extends StatefulWidget {
  const VaultPinLoginScreen({super.key});

  @override
  State<VaultPinLoginScreen> createState() => _VaultPinLoginScreenState();
}

class _VaultPinLoginScreenState extends State<VaultPinLoginScreen> {
  static const int _pinLength = 4;

  List<String> _pin = [];
  bool _wrongPin = false;

  void _onKeyTap(String value) {
    if (_pin.length >= _pinLength) return;

    HapticFeedback.lightImpact();

    setState(() {
      _pin.add(value);
      _wrongPin = false;
    });

    if (_pin.length == _pinLength) {
      Future.delayed(const Duration(milliseconds: 200), _verify);
    }
  }

  void _onDelete() {
    if (_pin.isEmpty) return;
    HapticFeedback.lightImpact();
    setState(() => _pin.removeLast());
  }

  Future<void> _verify() async {
    final ok = await VaultService.verifyPin(_pin.join());

    if (!mounted) return;

    if (ok) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const VaultHomeScreen()),
      );
    } else {
      HapticFeedback.heavyImpact();
      setState(() {
        _pin = [];
        _wrongPin = true;
      });
    }
  }

  Future<void> _forgotPin() async {
    final reset = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Vault?'),
        content: const Text('This will delete your saved vault files and PIN.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Reset', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (reset == true) {
      await VaultService.resetVault();

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const VaultSetPinScreen()),
      );
    }
  }

  String get _maskedPin {
    if (_pin.isEmpty) return 'Ex. 1234';
    return List.generate(_pin.length, (_) => '•').join();
  }

  @override
  Widget build(BuildContext context) {
    final title = _wrongPin ? 'Wrong Pin' : '';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(26, 14, 26, 24),
          child: Column(
            children: [
              const Icon(Icons.lock_outline, size: 88, color: Colors.black),
              const SizedBox(height: 14),
              if (title.isNotEmpty)
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                  ),
                )
              else
                const SizedBox(height: 36),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                height: 34,
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFFE8E8E8)),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _maskedPin,
                  style: TextStyle(
                    color: _pin.isEmpty ? const Color(0xFFCFCFCF) : Colors.black,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 13),
              Text(
                _wrongPin ? 'Enter PIN AGAIN' : 'Enter PIN',
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 18),
              PinPadWidget(
                pinDots: _pin,
                pinLength: _pinLength,
                onKeyTap: _onKeyTap,
                onDelete: _onDelete,
              ),
              const SizedBox(height: 18),
              TextButton(
                onPressed: _forgotPin,
                child: const Text(
                  'Forgot Pin',
                  style: TextStyle(color: Colors.black, fontSize: 11),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}