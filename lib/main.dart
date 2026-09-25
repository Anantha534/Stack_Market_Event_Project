import 'package:flutter/material.dart';
import 'screens/login.dart';

void main() => runApp(const TravelArchitectApp());

class TravelArchitectApp extends StatelessWidget {
  const TravelArchitectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Travel Architect',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0E7C7B)),
        scaffoldBackgroundColor: const Color(0xFFF6F8F8),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFE2E8E8)),
          ),
        ),
      ),
      home: const LoginScreen(),
    );
  }
}