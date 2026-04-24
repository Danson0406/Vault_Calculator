import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'pin_pad_widget.dart';
import 'vault_service.dart';
import 'vault_pin_ready_screen.dart';

class VaultSetPinScreen extends StatefulWidget {
  const VaultSetPinScreen({super.key});
 
  @override
  State<VaultSetPinScreen> createState() => _VaultSetPinScreenState();
}
 
class _VaultSetPinScreenState extends State<VaultSetPinScreen>
    with SingleTickerProviderStateMixin {
  List<String> _pin = [];
  List<String>? _firstPin;
  bool _isConfirming = false;
  bool _hasError = false;
  static const int _len = 6;
 
  late AnimationController _errCtrl;
  late Animation<double> _shake;
 
  @override
  void initState() {
    super.initState();
    _errCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _shake = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -10.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -10.0, end: 10.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 10.0, end: -6.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -6.0, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _errCtrl, curve: Curves.easeInOut));
  }
 
  @override
  void dispose() {
    _errCtrl.dispose();
    super.dispose();
  }
 
  void _onKey(String k) {
    if (_pin.length >= _len) return;
    HapticFeedback.lightImpact();
    setState(() { _pin.add(k); _hasError = false; });
    if (_pin.length == _len) {
      Future.delayed(const Duration(milliseconds: 180), _done);
    }
  }
 
  void _onDel() {
    if (_pin.isEmpty) return;
    HapticFeedback.lightImpact();
    setState(() => _pin.removeLast());
  }
 
  void _done() {
    if (!_isConfirming) {
      setState(() {
        _firstPin = List.from(_pin);
        _pin = [];
        _isConfirming = true;
      });
    } else {
      if (_pin.join() == _firstPin!.join()) {
        VaultService.setPin(_pin.join()).then((_) {
          if (mounted) Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const VaultPinReadyScreen()),
          );
        });
      } else {
        HapticFeedback.heavyImpact();
        _errCtrl.forward(from: 0);
        setState(() { _pin = []; _hasError = true; _isConfirming = false; _firstPin = null; });
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
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(builder: (ctx, c) {
          final h = c.maxHeight;
          final w = c.maxWidth;
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: h),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: w * 0.07),
                child: Column(
                  children: [
                    SizedBox(height: h * 0.04),
                    // Header
                    Text(
                      _isConfirming ? 'Confirm your PIN' : 'Let us get you\na new PIN',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                        height: 1.15,
                        letterSpacing: -0.5,
                      ),
                    ),
                    SizedBox(height: h * 0.015),
                    Text(
                      _hasError
                          ? 'PINs did not match. Please try again.'
                          : _isConfirming
                              ? 'Re-enter your 6-digit PIN'
                              : 'Choose a 6-digit PIN for your vault',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: _hasError ? Colors.red : Colors.grey[400],
                      ),
                    ),
                    SizedBox(height: h * 0.045),
                    Text(
                      _isConfirming ? 'Confirm PIN' : 'Enter New PIN',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[400],
                        letterSpacing: 1.0,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: h * 0.022),
                    // Shake wrapper
                    AnimatedBuilder(
                      animation: _shake,
                      builder: (_, child) => Transform.translate(
                        offset: Offset(_shake.value, 0),
                        child: child,
                      ),
                      child: PinPadWidget(
                        pinDots: _pin,
                        pinLength: _len,
                        onKeyTap: _onKey,
                        onDelete: _onDel,
                        dotColor: Colors.black,
                      ),
                    ),
                    SizedBox(height: h * 0.04),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}