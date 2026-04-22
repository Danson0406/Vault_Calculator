import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'vault_welcome_screen.dart';
import 'vault_pin_login_screen.dart';
import 'vault_service.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  String _display = '0';
  String _expression = '';
  double? _firstOperand;
  String? _operator;
  bool _shouldResetDisplay = false;
  int _xPressCount = 0;
  DateTime? _lastXPress;

  // Secret trigger: press × three times quickly
  void _handleXPress() async {
    final now = DateTime.now();
    if (_lastXPress != null && now.difference(_lastXPress!).inSeconds > 3) {
      _xPressCount = 0;
    }
    _lastXPress = now;
    _xPressCount++;

    if (_xPressCount >= 3) {
      _xPressCount = 0;
      HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 100));
      _openVault();
      return;
    }

    // Normal × behavior
    _handleOperator('×');
  }

  void _openVault() async {
    final isSetup = await VaultService.isVaultSetup();
    if (!mounted) return;

    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            isSetup ? const VaultPinLoginScreen() : const VaultWelcomeScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  void _handleButton(String label) {
    HapticFeedback.lightImpact();
    setState(() {
      if (label == 'AC' || label == 'C') {
        _display = '0';
        _expression = '';
        _firstOperand = null;
        _operator = null;
        _shouldResetDisplay = false;
      } else if (label == '+/-') {
        if (_display != '0') {
          if (_display.startsWith('-')) {
            _display = _display.substring(1);
          } else {
            _display = '-$_display';
          }
        }
      } else if (label == '%') {
        final val = double.tryParse(_display) ?? 0;
        _display = _formatResult(val / 100);
      } else if (['+', '-', '×', '÷'].contains(label)) {
        if (label == '×') {
          _handleXPress();
          return;
        }
        _handleOperator(label);
      } else if (label == '=') {
        _calculateResult();
      } else if (label == '.') {
        if (_shouldResetDisplay) {
          _display = '0.';
          _shouldResetDisplay = false;
        } else if (!_display.contains('.')) {
          _display = '$_display.';
        }
      } else if (label == 'sin' ||
          label == 'cos' ||
          label == 'tan' ||
          label == 'sin⁻¹' ||
          label == 'cos⁻¹' ||
          label == 'tan⁻¹') {
        _applyTrig(label);
      } else if (label == 'xʸ') {
        _handleOperator('^');
      } else if (label == '√x') {
        final val = double.tryParse(_display) ?? 0;
        _display = _formatResult(sqrt(val));
      } else if (label == 'x²') {
        final val = double.tryParse(_display) ?? 0;
        _display = _formatResult(val * val);
      } else if (label == '1/x') {
        final val = double.tryParse(_display) ?? 0;
        _display = val != 0 ? _formatResult(1 / val) : 'Error';
      } else if (label == 'ln') {
        final val = double.tryParse(_display) ?? 0;
        _display = _formatResult(log(val));
      } else if (label == 'log₁₀') {
        final val = double.tryParse(_display) ?? 0;
        _display = _formatResult(log(val) / log(10));
      } else if (label == 'eˣ') {
        final val = double.tryParse(_display) ?? 0;
        _display = _formatResult(exp(val));
      } else if (label == '10ˣ') {
        final val = double.tryParse(_display) ?? 0;
        _display = _formatResult(pow(10, val).toDouble());
      } else if (label == 'π') {
        _display = _formatResult(pi);
        _shouldResetDisplay = true;
      } else if (label == 'e') {
        _display = _formatResult(e);
        _shouldResetDisplay = true;
      } else if (label == 'Rand') {
        _display = _formatResult(Random().nextDouble());
        _shouldResetDisplay = true;
      } else if (label == '(' || label == ')') {
        // Simplified parentheses handling
      } else {
        // Number input
        if (_shouldResetDisplay) {
          _display = label;
          _shouldResetDisplay = false;
        } else {
          _display = _display == '0' ? label : '$_display$label';
        }
        if (_display.length > 12) {
          _display = _display.substring(0, 12);
        }
      }
    });
  }

  void _handleOperator(String op) {
    _firstOperand = double.tryParse(_display);
    _operator = op;
    _expression = '$_display $op';
    _shouldResetDisplay = true;
  }

  void _calculateResult() {
    if (_firstOperand == null || _operator == null) return;
    final secondOperand = double.tryParse(_display) ?? 0;
    double result;
    switch (_operator) {
      case '+':
        result = _firstOperand! + secondOperand;
        break;
      case '-':
        result = _firstOperand! - secondOperand;
        break;
      case '×':
        result = _firstOperand! * secondOperand;
        break;
      case '÷':
        result = secondOperand != 0 ? _firstOperand! / secondOperand : 0;
        break;
      case '^':
        result = pow(_firstOperand!, secondOperand).toDouble();
        break;
      default:
        return;
    }
    _expression = '';
    _display = _formatResult(result);
    _firstOperand = null;
    _operator = null;
    _shouldResetDisplay = true;
  }

  void _applyTrig(String func) {
    final val = double.tryParse(_display) ?? 0;
    double result;
    switch (func) {
      case 'sin':
        result = sin(val * pi / 180);
        break;
      case 'cos':
        result = cos(val * pi / 180);
        break;
      case 'tan':
        result = tan(val * pi / 180);
        break;
      case 'sin⁻¹':
        result = asin(val) * 180 / pi;
        break;
      case 'cos⁻¹':
        result = acos(val) * 180 / pi;
        break;
      case 'tan⁻¹':
        result = atan(val) * 180 / pi;
        break;
      default:
        return;
    }
    setState(() => _display = _formatResult(result));
  }

  String _formatResult(double val) {
    if (val.isNaN || val.isInfinite) return 'Error';
    if (val == val.truncateToDouble() && val.abs() < 1e12) {
      return val.toInt().toString();
    }
    return val.toStringAsPrecision(8).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Display
            Expanded(
              flex: 3,
              child: Container(
                alignment: Alignment.bottomRight,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (_expression.isNotEmpty)
                      Text(
                        _expression,
                        style: const TextStyle(
                          color: Color(0xFF888888),
                          fontSize: 20,
                        ),
                      ),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        _display,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 72,
                          fontWeight: FontWeight.w300,
                          letterSpacing: -2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Scientific row hint
            const Divider(color: Color(0xFF222222), height: 1),
            // Buttons
            Expanded(
              flex: 7,
              child: _buildButtonGrid(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButtonGrid() {
    // iOS-style calculator layout (scientific)
    final scientificRow = [
      ['(', ')', 'mc', 'm+', 'm-', 'mr'],
      ['2ⁿᵈ', 'x²', 'x³', 'xʸ', 'eˣ', '10ˣ'],
      ['1/x', '√x', '∛x', 'ʸ√x', 'ln', 'log₁₀'],
      ['x!', 'sin', 'cos', 'tan', 'e', 'EE'],
      ['Rad', 'sinh', 'cosh', 'tanh', 'π', 'Rand'],
    ];

    final mainButtons = [
      ['AC', '+/-', '%', '÷'],
      ['7', '8', '9', '×'],
      ['4', '5', '6', '-'],
      ['1', '2', '3', '+'],
      ['0', '.', '='],
    ];

    return Column(
      children: [
        // Scientific rows
        ...scientificRow.map((row) => Expanded(
              child: Row(
                children: row.map((label) => _buildScientificButton(label)).toList(),
              ),
            )),
        // Main rows
        ...mainButtons.map((row) => Expanded(
              child: Row(
                children: row.map((label) => _buildMainButton(label)).toList(),
              ),
            )),
      ],
    );
  }

  Widget _buildScientificButton(String label) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _handleButton(label),
        child: Container(
          margin: const EdgeInsets.all(1),
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C1E),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainButton(String label) {
    Color bgColor;
    Color textColor = Colors.white;
    bool isWide = label == '0';

    if (label == 'AC' || label == '+/-' || label == '%') {
      bgColor = const Color(0xFFA5A5A5);
      textColor = Colors.black;
    } else if (label == '÷' || label == '×' || label == '-' || label == '+' || label == '=') {
      bgColor = const Color(0xFFFF9F0A);
    } else {
      bgColor = const Color(0xFF333333);
    }

    return Expanded(
      flex: isWide ? 2 : 1,
      child: GestureDetector(
        onTap: () => label == '×' ? _handleXPress() : _handleButton(label),
        child: Container(
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(50),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: label == '0' ? 28 : 32,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ),
      ),
    );
  }
}