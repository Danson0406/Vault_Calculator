import 'package:flutter/material.dart';

class PinPadWidget extends StatelessWidget {
  final List<String> pinDots;
  final int pinLength;
  final Function(String) onKeyTap;
  final VoidCallback onDelete;
  final Color dotColor;
 
  const PinPadWidget({
    super.key,
    required this.pinDots,
    required this.pinLength,
    required this.onKeyTap,
    required this.onDelete,
    this.dotColor = Colors.black,
  });
 
  // ── Fixed, consistent sizes regardless of platform ──
  static const double _kKeyW   = 76.0;
  static const double _kKeyH   = 54.0;
  static const double _kKeyFont= 24.0;
  static const double _kDelFont= 20.0;
  static const double _kHGap   = 12.0;
  static const double _kVGap   = 10.0;
  static const double _kDotSize= 13.0;
  static const double _kDotGap = 9.0;
 
  @override
  Widget build(BuildContext context) {
    final rows = [
      ['1','2','3'],
      ['4','5','6'],
      ['7','8','9'],
      ['','0','⌫'],
    ];
 
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── PIN dots ──────────────────────────────────────
        SizedBox(
          height: _kDotSize,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(pinLength, (i) {
              final filled = i < pinDots.length;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.symmetric(horizontal: _kDotGap / 2),
                width: _kDotSize,
                height: _kDotSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: filled ? dotColor : Colors.transparent,
                  border: Border.all(
                    color: filled ? dotColor : Colors.grey.shade400,
                    width: 1.5,
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 28),
 
        // ── Numpad rows ───────────────────────────────────
        ...rows.map((row) => Padding(
          padding: const EdgeInsets.only(bottom: _kVGap),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: row.map((key) {
              if (key.isEmpty) {
                return const SizedBox(width: _kKeyW, height: _kKeyH);
              }
              final isDel = key == '⌫';
              return GestureDetector(
                onTap: () => isDel ? onDelete() : onKeyTap(key),
                child: Container(
                  width: _kKeyW,
                  height: _kKeyH,
                  margin: const EdgeInsets.symmetric(horizontal: _kHGap / 2),
                  decoration: BoxDecoration(
                    color: isDel ? Colors.transparent : const Color(0xFF1C1C1E),
                    borderRadius: BorderRadius.circular(_kKeyH / 2),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    key,
                    style: TextStyle(
                      color: isDel ? Colors.black87 : Colors.white,
                      fontSize: isDel ? _kDelFont : _kKeyFont,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        )),
      ],
    );
  }
}