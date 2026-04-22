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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // PIN dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(pinLength, (i) {
            final filled = i < pinDots.length;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 10),
              width: 14,
              height: 14,
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
        const SizedBox(height: 32),
        // Number pad
        _buildNumberPad(context),
      ],
    );
  }

  Widget _buildNumberPad(BuildContext context) {
    final rows = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', '⌫'],
    ];

    return Column(
      children: rows.map((row) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: row.map((key) {
              if (key.isEmpty) return const SizedBox(width: 80, height: 64);
              return GestureDetector(
                onTap: () {
                  if (key == '⌫') {
                    onDelete();
                  } else {
                    onKeyTap(key);
                  }
                },
                child: Container(
                  width: 80,
                  height: 64,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: key == '⌫' ? Colors.transparent : const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      key,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: key == '⌫' ? 22 : 26,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }
}