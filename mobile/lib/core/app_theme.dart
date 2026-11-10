import 'package:flutter/material.dart';

abstract final class AppTheme {
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF176B5B)),
    scaffoldBackgroundColor: const Color(0xFFF5F7F8),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFF5F7F8),
      centerTitle: false,
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    ),
  );
}
