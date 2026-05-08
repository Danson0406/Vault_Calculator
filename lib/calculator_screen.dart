import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'vault_pin_login_screen.dart';
import 'vault_service.dart';
import 'vault_welcome_screen.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  String _display = 'Value';
  double? _firstNumber;
  String? _operator;
  bool _resetNext = false;

  static const Color _screenBg = Color(0xFF303030);
  static const Color _displayBg = Color(0xFF111111);
  static const Color _keyBg = Color(0xFF5A5A5A);
  static const Color _keyDark = Color(0xFF3F3F3F);
  static const Color _yellow = Color(0xFFFFC928);
  static const Color _red = Color(0xFFE53935);

  final List<String> _keys = const [
    'AC', '%', 'x', 'π', '⌫',
    'eˣ', 'x²', 'x³', 'sin', 'cos',
    'tan', '√', '1/x', 'log', 'ln',
    '7', '8', '9', '÷', '×',
    '4', '5', '6', '−', '+',
    '1', '2', '3', 'n!', '=',
    '0', '.', '(', ')', '',
  ];

  double get _number => double.tryParse(_display) ?? 0;

  Future<void> _openVault() async {
    HapticFeedback.heavyImpact();

    final isSetup = await VaultService.isVaultSetup();
    if (!mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            isSetup ? const VaultPinLoginScreen() : const VaultWelcomeScreen(),
      ),
    );
  }

  void _tap(String key) {
    HapticFeedback.lightImpact();

    if (key.isEmpty) return;

    if (key == 'x') {
      _openVault();
      return;
    }

    setState(() {
      switch (key) {
        case 'AC':
          _display = 'Value';
          _firstNumber = null;
          _operator = null;
          _resetNext = false;
          break;

        case '⌫':
          if (_display == 'Value' || _display.length <= 1) {
            _display = 'Value';
          } else {
            _display = _display.substring(0, _display.length - 1);
          }
          break;

        case '%':
          _display = _format(_number / 100);
          _resetNext = true;
          break;

        case 'π':
          _display = _format(pi);
          _resetNext = true;
          break;

        case 'eˣ':
          _display = _format(exp(_number));
          _resetNext = true;
          break;

        case 'x²':
          _display = _format(pow(_number, 2).toDouble());
          _resetNext = true;
          break;

        case 'x³':
          _display = _format(pow(_number, 3).toDouble());
          _resetNext = true;
          break;

        case '√':
          _display = _number < 0 ? 'Error' : _format(sqrt(_number));
          _resetNext = true;
          break;

        case '1/x':
          _display = _number == 0 ? 'Error' : _format(1 / _number);
          _resetNext = true;
          break;

        case 'log':
          _display = _number <= 0 ? 'Error' : _format(log(_number) / log(10));
          _resetNext = true;
          break;

        case 'ln':
          _display = _number <= 0 ? 'Error' : _format(log(_number));
          _resetNext = true;
          break;

        case 'sin':
          _display = _format(sin(_number * pi / 180));
          _resetNext = true;
          break;

        case 'cos':
          _display = _format(cos(_number * pi / 180));
          _resetNext = true;
          break;

        case 'tan':
          _display = _format(tan(_number * pi / 180));
          _resetNext = true;
          break;

        case 'n!':
          _display = _factorialText(_number);
          _resetNext = true;
          break;

        case '+':
        case '−':
        case '×':
        case '÷':
          _firstNumber = _number;
          _operator = key;
          _resetNext = true;
          break;

        case '=':
          _calculate();
          break;

        case '.':
          if (_resetNext || _display == 'Value' || _display == 'Error') {
            _display = '0.';
            _resetNext = false;
          } else if (!_display.contains('.')) {
            _display += '.';
          }
          break;

        case '(':
        case ')':
          // Visual only for the Figma scientific layout.
          break;

        default:
          if (_resetNext || _display == 'Value' || _display == 'Error') {
            _display = key;
            _resetNext = false;
          } else {
            _display += key;
          }
          break;
      }
    });
  }

  void _calculate() {
    if (_firstNumber == null || _operator == null) return;

    final second = _number;
    double result;

    switch (_operator) {
      case '+':
        result = _firstNumber! + second;
        break;
      case '−':
        result = _firstNumber! - second;
        break;
      case '×':
        result = _firstNumber! * second;
        break;
      case '÷':
        result = second == 0 ? double.nan : _firstNumber! / second;
        break;
      default:
        return;
    }

    _display = _format(result);
    _firstNumber = null;
    _operator = null;
    _resetNext = true;
  }

  String _factorialText(double value) {
    if (value < 0 || value != value.roundToDouble() || value > 20) {
      return 'Error';
    }

    int result = 1;
    for (int i = 2; i <= value.toInt(); i++) {
      result *= i;
    }

    return result.toString();
  }

  String _format(double value) {
    if (value.isNaN || value.isInfinite) return 'Error';
    if (value == value.truncateToDouble() && value.abs() < 1000000000) {
      return value.toInt().toString();
    }
    return double.parse(value.toStringAsFixed(8)).toString();
  }

  Color _buttonColor(String key) {
    if (key == 'AC') return _yellow;
    if (key == 'x') return _red;
    if (key == '=' || key == '÷' || key == '×' || key == '−' || key == '+') {
      return _keyDark;
    }
    return _keyBg;
  }

  Color _textColor(String key) {
    if (key == 'AC') return Colors.black;
    return Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _screenBg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 390),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
              child: Column(
                children: [
                  const Spacer(),
                  Container(
                    width: double.infinity,
                    height: 82,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    alignment: Alignment.centerLeft,
                    decoration: BoxDecoration(
                      color: _displayBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: FittedBox(
                      alignment: Alignment.centerLeft,
                      fit: BoxFit.scaleDown,
                      child: Text(
                        _display,
                        maxLines: 1,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Press red X button to enter Vault',
                      style: TextStyle(
                        color: Color(0xFFCFCFCF),
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    flex: 5,
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _keys.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 5,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        childAspectRatio: 1.1,
                      ),
                      itemBuilder: (context, index) {
                        final key = _keys[index];

                        if (key.isEmpty) return const SizedBox.shrink();

                        return GestureDetector(
                          onTap: () => _tap(key),
                          child: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: _buttonColor(key),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              key,
                              style: TextStyle(
                                color: _textColor(key),
                                fontSize: key.length > 3 ? 12 : 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}