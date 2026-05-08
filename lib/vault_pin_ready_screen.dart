import 'package:flutter/material.dart';

import 'vault_home_screen.dart';

class VaultPinReadyScreen extends StatelessWidget {
  const VaultPinReadyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 70, 28, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your new\nPIN is\nready',
                style: TextStyle(
                  fontSize: 32,
                  height: 1.04,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1B1B1B),
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 46),
              const Center(
                child: SizedBox(
                  width: 130,
                  height: 100,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        left: 24,
                        top: 0,
                        child: Icon(Icons.circle_outlined, size: 34),
                      ),
                      Positioned(
                        left: 8,
                        top: 38,
                        child: Icon(Icons.person_outline, size: 70),
                      ),
                      Positioned(
                        right: 12,
                        top: 28,
                        child: Icon(Icons.check, size: 30),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),
              Center(
                child: GestureDetector(
                  onTap: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const VaultHomeScreen()),
                    );
                  },
                  child: Container(
                    height: 34,
                    padding: const EdgeInsets.symmetric(horizontal: 23),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Get Started',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(width: 10),
                        Icon(Icons.arrow_forward, color: Colors.white, size: 14),
                      ],
                    ),
                  ),
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}