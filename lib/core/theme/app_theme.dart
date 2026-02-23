import 'package:flutter/material.dart';

// Our Color Palette
const Color kPrimaryColor = Color(0xFF0A2540);
const Color kPrimaryVariant = Color(0xFF4A90E2);
const Color kBackgroundColor = Color(0xFFFFFFFF);
const Color kSurfaceColor = Color(0xFFF4F7F9);
const Color kTextPrimary = Color(0xFF121212);
const Color kTextSecondary = Color(0xFF6C757D);

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: kPrimaryColor,
      scaffoldBackgroundColor: kBackgroundColor,
      colorScheme: const ColorScheme.light(
        primary: kPrimaryColor,
        secondary: kPrimaryVariant,
        surface: kSurfaceColor,
        background: kBackgroundColor,
      ),
      fontFamily: 'Poppins',
      textTheme: const TextTheme(
        headlineSmall: TextStyle(color: kTextPrimary, fontSize: 28, fontWeight: FontWeight.w500),
        headlineMedium: TextStyle(color: kTextPrimary, fontSize: 22, fontWeight: FontWeight.w400),
        bodyMedium: TextStyle(color: kTextSecondary, fontSize: 16, fontWeight: FontWeight.w400),
        labelLarge: TextStyle(color: kBackgroundColor, fontSize: 18, fontWeight: FontWeight.w600),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: kPrimaryColor,
          foregroundColor: kBackgroundColor,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: kSurfaceColor,
        labelStyle: const TextStyle(color: kTextSecondary),
        hintStyle: const TextStyle(color: kTextSecondary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: kPrimaryVariant, width: 2)),
      ),
    );
  }
}