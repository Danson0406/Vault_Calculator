import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'pin_pad_widget.dart';
import 'vault_pin_ready_screen.dart';
import 'vault_service.dart';

class VaultSetPinScreen extends StatefulWidget {
  const VaultSetPinScreen({super.key});

  @override
  State<VaultSetPinScreen> createState() => _VaultSetPinScreenState();
}

class _VaultSetPinScreenState extends State<VaultSetPinScreen> {
  static const int _pinLength = 4;

  List<String> _pin = [];
  List<String>? _firstPin;
  bool _confirming = false;
  String? _error;

  void _onKeyTap(String value) {
    if (_pin.length >= _pinLength) return;

    HapticFeedback.lightImpact();

    setState(() {
      _pin.add(value);
      _error = null;
    });

    if (_pin.length == _pinLength) {
      Future.delayed(const Duration(milliseconds: 200), _submit);
    }
  }

  void _onDelete() {
    if (_pin.isEmpty) return;
    HapticFeedback.lightImpact();
    setState(() => _pin.removeLast());
  }

  Future<void> _submit() async {
    if (!_confirming) {
      setState(() {
        _firstPin = List<String>.from(_pin);
        _pin = [];
        _confirming = true;
      });
      return;
    }

    if (_pin.join() != _firstPin!.join()) {
      HapticFeedback.heavyImpact();
      setState(() {
        _pin = [];
        _firstPin = null;
        _confirming = false;
        _error = 'PINs did not match. Please try again.';
      });
      return;
    }

    await VaultService.setPin(_pin.join());

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const VaultPinReadyScreen()),
    );
  }

  String get _maskedPin {
    if (_pin.isEmpty) return 'Ex. 1234';
    return List.generate(_pin.length, (_) => '•').join();
  }

  @override
  Widget build(BuildContext context) {
    final title = _confirming ? 'Confirm\nyour new PIN' : 'Let us\nget you a\nnew PIN';

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
          padding: const EdgeInsets.fromLTRB(26, 8, 26, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 31,
                  height: 1.02,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1B1B1B),
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 32),
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
              Center(
                child: Text(
                  _error ?? (_confirming ? 'Confirm New PIN' : 'Enter new PIN'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _error == null ? Colors.black : Colors.red,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              PinPadWidget(
                pinDots: _pin,
                pinLength: _pinLength,
                onKeyTap: _onKeyTap,
                onDelete: _onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}