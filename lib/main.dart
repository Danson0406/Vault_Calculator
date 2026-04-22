import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'calculator_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const VaultCalculatorApp());
}

class VaultCalculatorApp extends StatelessWidget {
  const VaultCalculatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calculator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.black),
        useMaterial3: true,
      ),
      home: const CalculatorScreen(),
    );
  }
}