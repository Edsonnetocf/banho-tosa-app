import 'data/app_repository.dart';
import 'data/app_scope.dart';

import 'package:flutter/material.dart';

import 'screens/splash_screen.dart';

void main() {
  runApp(const BanhoTosaApp());
}

class BanhoTosaApp extends StatelessWidget {
  const BanhoTosaApp({super.key, this.repository});

  final AppRepository? repository;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      repository: repository ?? AppRepository.instancia,
      child: MaterialApp(
        title: 'Banho & Tosa App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primaryColor: const Color(0xFF0B6374),
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0B6374)),
          useMaterial3: true,
          textTheme: const TextTheme(
            bodyMedium: TextStyle(fontSize: 16),
            titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          inputDecorationTheme: const InputDecorationTheme(
            border: OutlineInputBorder(),
            filled: true,
          ),
        ),
        home: const SplashScreen(),
      ),
    );
  }
}
