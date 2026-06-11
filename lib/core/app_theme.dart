import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryColor = Colors.black; // Black for buttons
  static const Color secondaryColor = Color(0xFF6B7280); // Gray
  static const Color backgroundColor = Colors.white; // White background
  static const Color surfaceColor = Colors.white;
  static const Color textPrimaryColor = Colors.black;
  static const Color textSecondaryColor = Color(0xFF6B7280);

  static ThemeData get lightTheme {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: secondaryColor,
        surface: surfaceColor,
      ),
      scaffoldBackgroundColor: backgroundColor,
      textTheme: GoogleFonts.lexendTextTheme().copyWith(
        displayLarge: GoogleFonts.lexend(
          color: textPrimaryColor,
          fontWeight: FontWeight.bold,
        ),
        displayMedium: GoogleFonts.lexend(
          color: textPrimaryColor,
          fontWeight: FontWeight.bold,
        ),
        headlineLarge: GoogleFonts.lexend(
          color: textPrimaryColor,
          fontWeight: FontWeight.w700,
        ),
        headlineMedium: GoogleFonts.lexend(
          color: textPrimaryColor,
          fontWeight: FontWeight.bold,
        ),
        headlineSmall: GoogleFonts.lexend(
          color: textPrimaryColor,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: GoogleFonts.lexend(color: textPrimaryColor),
        bodyMedium: GoogleFonts.lexend(color: textSecondaryColor),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: textPrimaryColor),
        titleTextStyle: GoogleFonts.lexend(
          color: textPrimaryColor,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          elevation: 0,
        ),
      ),
    );
  }
}
