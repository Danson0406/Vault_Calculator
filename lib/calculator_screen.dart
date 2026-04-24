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
  bool _isScientific = false;
 
  static const _orange  = Color(0xFFFF9F0A);
  static const _dark    = Color(0xFF333333);
  static const _light   = Color(0xFFA5A5A5);
  static const _sciColor= Color(0xFF1C1C1E);
 
  // ── Fixed, cross-platform safe sizes ───────────────────────────
  static const double _kBtnSize   = 72.0;  // circle button diameter
  static const double _kBtnFont   = 28.0;  // number/op label inside button
  static const double _kSciBtnH   = 40.0;  // scientific row button height
  static const double _kSciBtnFont= 13.0;  // scientific label font
  static const double _kDisplayFont = 64.0; // main result display
  static const double _kExprFont  = 18.0;  // secondary expression
  static const double _kGap       = 10.0;  // gap between buttons
 
  // ── Vault trigger ───────────────────────────────────────────────
  void _handleXPress() async {
    final now = DateTime.now();
    if (_lastXPress != null && now.difference(_lastXPress!).inSeconds > 3) _xPressCount = 0;
    _lastXPress = now;
    _xPressCount++;
    if (_xPressCount >= 3) {
      _xPressCount = 0;
      HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 80));
      _openVault();
      return;
    }
    _handleOperator('×');
  }
 
  void _openVault() async {
    final isSetup = await VaultService.isVaultSetup();
    if (!mounted) return;
    Navigator.of(context).push(PageRouteBuilder(
      pageBuilder: (_, __, ___) =>
          isSetup ? const VaultPinLoginScreen() : const VaultWelcomeScreen(),
      transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
      transitionDuration: const Duration(milliseconds: 350),
    ));
  }
 
  // ── Button logic ─────────────────────────────────────────────────
  void _tap(String label) {
    HapticFeedback.lightImpact();
    setState(() {
      switch (label) {
        case 'AC':
          _display = '0'; _expression = ''; _firstOperand = null;
          _operator = null; _shouldResetDisplay = false;
          break;
        case '+/-':
          if (_display != '0')
            _display = _display.startsWith('-') ? _display.substring(1) : '-$_display';
          break;
        case '%':
          _display = _fmt((double.tryParse(_display) ?? 0) / 100); break;
        case '÷': case '-': case '+':
          _handleOperator(label); break;
        case '×': _handleXPress(); return;
        case '=': _calcResult(); break;
        case '.':
          if (_shouldResetDisplay) { _display = '0.'; _shouldResetDisplay = false; }
          else if (!_display.contains('.')) _display = '$_display.';
          break;
        case 'xʸ': _handleOperator('^'); break;
        case 'x²': _display = _fmt(pow(double.tryParse(_display)??0, 2).toDouble()); break;
        case 'x³': _display = _fmt(pow(double.tryParse(_display)??0, 3).toDouble()); break;
        case '√x': _display = _fmt(sqrt(double.tryParse(_display)??0)); break;
        case '1/x':
          final v = double.tryParse(_display)??0;
          _display = v != 0 ? _fmt(1/v) : 'Error'; break;
        case 'ln':  _display = _fmt(log(double.tryParse(_display)??0)); break;
        case 'log': _display = _fmt(log(double.tryParse(_display)??0)/log(10)); break;
        case 'eˣ': _display = _fmt(exp(double.tryParse(_display)??0)); break;
        case '10ˣ': _display = _fmt(pow(10, double.tryParse(_display)??0).toDouble()); break;
        case 'sin': _display = _fmt(sin((double.tryParse(_display)??0)*pi/180)); break;
        case 'cos': _display = _fmt(cos((double.tryParse(_display)??0)*pi/180)); break;
        case 'tan': _display = _fmt(tan((double.tryParse(_display)??0)*pi/180)); break;
        case 'π': _display = _fmt(pi); _shouldResetDisplay = true; return;
        case 'e': _display = _fmt(e); _shouldResetDisplay = true; return;
        case 'Rand': _display = _fmt(Random().nextDouble()); _shouldResetDisplay = true; return;
        default:
          if (_shouldResetDisplay) { _display = label; _shouldResetDisplay = false; }
          else _display = _display == '0' ? label : '$_display$label';
          if (_display.length > 10) _display = _display.substring(0, 10);
      }
    });
  }
 
  void _handleOperator(String op) {
    _firstOperand = double.tryParse(_display);
    _operator = op; _expression = '$_display $op'; _shouldResetDisplay = true;
  }
 
  void _calcResult() {
    if (_firstOperand == null || _operator == null) return;
    final b = double.tryParse(_display) ?? 0;
    double r;
    switch (_operator) {
      case '+': r = _firstOperand! + b; break;
      case '-': r = _firstOperand! - b; break;
      case '×': r = _firstOperand! * b; break;
      case '÷': r = b != 0 ? _firstOperand! / b : double.nan; break;
      case '^': r = pow(_firstOperand!, b).toDouble(); break;
      default: return;
    }
    _expression = ''; _display = _fmt(r);
    _firstOperand = null; _operator = null; _shouldResetDisplay = true;
  }
 
  String _fmt(double v) {
    if (v.isNaN || v.isInfinite) return 'Error';
    if (v == v.truncateToDouble() && v.abs() < 1e10) return v.toInt().toString();
    return double.parse(v.toStringAsFixed(8)).toString();
  }
 
  // ── BUILD ────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    // Constrain total width to phone-like 420px max so it looks good on web/tablet too
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              children: [
                // ── Display area ──────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (_expression.isNotEmpty)
                        Text(_expression,
                            style: const TextStyle(
                                color: Color(0xFF888888), fontSize: _kExprFont)),
                      const SizedBox(height: 4),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Text(_display,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: _kDisplayFont,
                                fontWeight: FontWeight.w200,
                                letterSpacing: -1.5)),
                      ),
                    ],
                  ),
                ),
 
                // ── Scientific toggle ──────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      GestureDetector(
                        onTap: () => setState(() => _isScientific = !_isScientific),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: _isScientific ? _orange : const Color(0xFF2A2A2A),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _isScientific ? 'Scientific ON' : 'Scientific',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
 
                // ── Scientific rows ───────────────────────────────
                if (_isScientific) ...[
                  _sciRow(['2ⁿᵈ', 'x²', 'x³', 'xʸ', 'eˣ', '10ˣ']),
                  const SizedBox(height: 6),
                  _sciRow(['1/x', '√x', 'ln', 'log', 'sin', 'cos']),
                  const SizedBox(height: 6),
                  _sciRow(['(', ')', 'tan', 'π', 'e', 'Rand']),
                  const SizedBox(height: 10),
                ],
 
                // ── Main buttons ──────────────────────────────────
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(_kGap, 0, _kGap, _kGap),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _mainRow(['AC', '+/-', '%', '÷']),
                        _mainRow(['7', '8', '9', '×']),
                        _mainRow(['4', '5', '6', '-']),
                        _mainRow(['1', '2', '3', '+']),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _btn('0', wide: true),
                            _btn('.'),
                            _btn('='),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
 
  Widget _sciRow(List<String> labels) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _kGap),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: labels.map((l) => GestureDetector(
          onTap: () => _tap(l),
          child: Container(
            height: _kSciBtnH,
            // Each of 6 keys gets equal space; subtract gaps
            width: (420 - _kGap * 2 - 5 * 6.0) / 6,
            decoration: BoxDecoration(
                color: _sciColor, borderRadius: BorderRadius.circular(8)),
            alignment: Alignment.center,
            child: Text(l,
                style: const TextStyle(
                    color: Colors.white, fontSize: _kSciBtnFont, fontWeight: FontWeight.w400),
                textAlign: TextAlign.center),
          ),
        )).toList(),
      ),
    );
  }
 
  Widget _mainRow(List<String> labels) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: labels.map((l) => _btn(l)).toList(),
    );
  }
 
  Widget _btn(String label, {bool wide = false}) {
    Color bg;
    Color fg = Colors.white;
    if (label == 'AC' || label == '+/-' || label == '%') {
      bg = _light; fg = Colors.black;
    } else if ('÷×-+='.contains(label) && label.isNotEmpty) {
      bg = _orange;
    } else {
      bg = _dark;
    }
 
    return GestureDetector(
      onTap: () => label == '×' ? _handleXPress() : _tap(label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 60),
        width:  wide ? _kBtnSize * 2 + _kGap : _kBtnSize,
        height: _kBtnSize,
        decoration: BoxDecoration(
          color: bg,
          shape: wide ? BoxShape.rectangle : BoxShape.circle,
          borderRadius: wide ? BorderRadius.circular(_kBtnSize / 2) : null,
        ),
        alignment: wide ? Alignment.centerLeft : Alignment.center,
        padding: wide ? const EdgeInsets.only(left: _kBtnSize * 0.34) : EdgeInsets.zero,
        child: Text(label,
            style: TextStyle(
              color: fg,
              fontSize: _kBtnFont,
              fontWeight: FontWeight.w400,
            )),
      ),
    );
  }
}
 