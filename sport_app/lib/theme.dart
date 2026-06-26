import 'package:flutter/material.dart';

class AppTheme {
  static const Color darkBg = Color(0xff121214);
  static const Color darkSurface = Color(0xff1e1e24);
  static const Color darkBorder = Color(0xff2d2d34);
  static const Color athleticBlue = Color(0xff2563eb);
  
  static const Color darkGreenBg = Color(0xff142f23);
  static const Color greenCheck = Color(0xff10b981);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBg,
      cardColor: darkSurface,
      dividerColor: darkBorder,
      primaryColor: athleticBlue,
      colorScheme: const ColorScheme.dark(
        primary: athleticBlue,
        secondary: athleticBlue,
        surface: darkSurface,
        onPrimary: Colors.white,
        onSurface: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkBg,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: darkSurface,
        selectedItemColor: athleticBlue,
        unselectedItemColor: Colors.grey,
        elevation: 8,
      ),
      cardTheme: CardThemeData(
        color: darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: darkBorder, width: 1),
        ),
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: athleticBlue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }
}
