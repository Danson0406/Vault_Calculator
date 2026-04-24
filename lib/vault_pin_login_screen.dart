import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'pin_pad_widget.dart';
import 'vault_service.dart';
import 'vault_home_screen.dart';
import 'vault_set_pin_screen.dart';

class VaultPinLoginScreen extends StatefulWidget {
  const VaultPinLoginScreen({super.key});

  @override
  State<VaultPinLoginScreen> createState() => _VaultPinLoginScreenState();
}

class _VaultPinLoginScreenState extends State<VaultPinLoginScreen>
    with SingleTickerProviderStateMixin {
  List<String> _pin = [];
  bool _hasError = false;
  static const int _len = 6;

  late AnimationController _errCtrl;
  late Animation<double> _shake;

  @override
  void initState() {
    super.initState();
    _errCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
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
    setState(() {
      _pin.add(k);
      _hasError = false;
    });
    if (_pin.length == _len) {
      Future.delayed(const Duration(milliseconds: 180), _verify);
    }
  }

  void _onDel() {
    if (_pin.isEmpty) return;
    HapticFeedback.lightImpact();
    setState(() => _pin.removeLast());
  }

  Future<void> _verify() async {
    // VaultService.verifyPin calls EncryptionService.unlock() internally,
    // which derives the key and stores it as the session key on success.
    final ok = await VaultService.verifyPin(_pin.join());
    if (!mounted) return;

    if (ok) {
      // Session is already unlocked — navigate straight to the vault.
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const VaultHomeScreen()),
      );
    } else {
      HapticFeedback.heavyImpact();
      _errCtrl.forward(from: 0);
      setState(() {
        _pin = [];
        _hasError = true;
      });
    }
  }

  Future<void> _forgotPin() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Reset Vault',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text(
            'This will erase all vault data and reset your PIN.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Reset',
                style: TextStyle(
                    color: Colors.red, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (ok == true && mounted) {
      await VaultService.resetVault();
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const VaultSetPinScreen()),
        );
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
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.black, size: 20),
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
                    // Lock icon
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.lock_outline_rounded,
                          size: 34, color: Colors.grey.shade500),
                    ),
                    SizedBox(height: h * 0.03),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: _hasError
                          ? Column(
                              key: const ValueKey('error'),
                              children: [
                                const Text('Wrong Pin',
                                    style: TextStyle(
                                        color: Colors.red,
                                        fontSize: 22,
                                        fontWeight: FontWeight.w700)),
                                const SizedBox(height: 6),
                                Text('Try again',
                                    style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[400])),
                              ],
                            )
                          : Column(
                              key: const ValueKey('normal'),
                              children: [
                                const Text('Enter PIN',
                                    style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.black)),
                                const SizedBox(height: 6),
                                Text('Enter your 6-digit vault PIN',
                                    style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[400])),
                              ],
                            ),
                    ),
                    SizedBox(height: h * 0.04),
                    AnimatedBuilder(
                      animation: _shake,
                      builder: (_, child) => Transform.translate(
                          offset: Offset(_shake.value, 0), child: child),
                      child: PinPadWidget(
                        pinDots: _pin,
                        pinLength: _len,
                        onKeyTap: _onKey,
                        onDelete: _onDel,
                        dotColor: Colors.black,
                      ),
                    ),
                    SizedBox(height: h * 0.04),
                    TextButton(
                      onPressed: _forgotPin,
                      child: Text('Forgot Pin',
                          style:
                              TextStyle(color: Colors.grey[400], fontSize: 14)),
                    ),
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