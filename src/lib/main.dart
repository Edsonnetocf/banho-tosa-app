import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(const BanhoTosaApp());
}

class BanhoTosaApp extends StatelessWidget {
  const BanhoTosaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Banho & Tosa App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF0B6374),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0B6374)),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}