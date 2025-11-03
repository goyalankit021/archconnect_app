import 'package:flutter/material.dart';

// Our Color Palette
const Color kPrimaryColor = Color(0xFF0A2540); // Midnight Blue
const Color kPrimaryVariant = Color(0xFF4A90E2); // Architect Blue
const Color kBackgroundColor = Color(0xFFFFFFFF); // White
const Color kSurfaceColor = Color(0xFFF4F7F9); // Light Grey
const Color kTextPrimary = Color(0xFF121212);
const Color kTextSecondary = Color(0xFF6C757D);

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      // 1. Set main colors
      primaryColor: kPrimaryColor,
      scaffoldBackgroundColor: kBackgroundColor,
      colorScheme: const ColorScheme.light(
        primary: kPrimaryColor,
        secondary: kPrimaryVariant,
        surface: kSurfaceColor,
        background: kBackgroundColor,
      ),

      // 2. Set Font Family (Make sure to add Poppins to pubspec.yaml later)
      fontFamily: 'Poppins',

      // 3. Set Text Themes
      textTheme: const TextTheme(
        headlineSmall: TextStyle(
          color: kTextPrimary,
          fontSize: 28,
          fontWeight: FontWeight.w500, // Medium
        ),
        headlineMedium: TextStyle(
          color: kTextPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w400, // Regular
        ),
        bodyMedium: TextStyle(
          color: kTextSecondary,
          fontSize: 16,
          fontWeight: FontWeight.w400, // Regular
        ),
        labelLarge: TextStyle( // For Button Text
          color: kBackgroundColor,
          fontSize: 18,
          fontWeight: FontWeight.w600, // SemiBold
        ),
      ),

      // 4. Set Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: kPrimaryColor,
          foregroundColor: kBackgroundColor, // Text color
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // 5. Set Input Field Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: kSurfaceColor,
        labelStyle: const TextStyle(color: kTextSecondary),
        hintStyle: const TextStyle(color: kTextSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: kPrimaryVariant, width: 2),
        ),
      ),
    );
  }
}