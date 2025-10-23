import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryBlue = Color(0xFF007BFF);

  static final ThemeData lightTheme = ThemeData(
    primaryColor: primaryBlue,
    colorScheme: ColorScheme.fromSeed(seedColor: primaryBlue),
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryBlue,
      foregroundColor: Colors.white,
      centerTitle: true,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: primaryBlue,
    ),
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
    ),
  );
}
