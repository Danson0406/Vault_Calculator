import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'pin_pad_widget.dart';
import 'vault_service.dart';
import 'vault_pin_ready_screen.dart';

class VaultSetPinScreen extends StatefulWidget {
  final bool isNewPin;
  const VaultSetPinScreen({super.key, this.isNewPin = true});

  @override
  State<VaultSetPinScreen> createState() => _VaultSetPinScreenState();
}

class _VaultSetPinScreenState extends State<VaultSetPinScreen> {
  List<String> _pin = [];
  List<String>? _firstPin;
  bool _isConfirming = false;
  bool _hasError = false;
  static const int _pinLength = 6;

  void _onKeyTap(String key) {
    if (_pin.length >= _pinLength) return;
    HapticFeedback.lightImpact();
    setState(() {
      _pin.add(key);
      _hasError = false;
    });

    if (_pin.length == _pinLength) {
      Future.delayed(const Duration(milliseconds: 200), _handleComplete);
    }
  }

  void _onDelete() {
    if (_pin.isEmpty) return;
    HapticFeedback.lightImpact();
    setState(() => _pin.removeLast());
  }

  void _handleComplete() {
    if (!_isConfirming) {
      setState(() {
        _firstPin = List.from(_pin);
        _pin = [];
        _isConfirming = true;
      });
    } else {
      // Verify pins match
      if (_pin.join() == _firstPin!.join()) {
        VaultService.setPin(_pin.join()).then((_) {
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const VaultPinReadyScreen()),
            );
          }
        });
      } else {
        HapticFeedback.heavyImpact();
        setState(() {
          _pin = [];
          _hasError = true;
          _isConfirming = false;
          _firstPin = null;
        });
      }
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
              const SizedBox(height: 32),
              Text(
                _isConfirming ? 'Confirm your PIN' : 'Let us get you\na new PIN',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _hasError
                    ? 'PINs did not match. Try again.'
                    : _isConfirming
                        ? 'Re-enter your PIN to confirm'
                        : 'Choose a 6-digit PIN for your vault',
                style: TextStyle(
                  fontSize: 14,
                  color: _hasError ? Colors.red : Colors.grey[500],
                ),
              ),
              const SizedBox(height: 48),
              // Enter new pin label
              Text(
                _isConfirming ? 'Confirm PIN' : 'Enter New PIN',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[400],
                  letterSpacing: 0.5,
                ),
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
      ),
    );
  }
}