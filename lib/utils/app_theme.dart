import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFFD32F2F); // Blood red
  static const Color backgroundColor = Color(0xFF1A0B2E); // Deep purple/dark unique
  static const Color accentColor = Color(0xFFFFC107); // Gold for coins
  static const Color textPrimaryColor = Colors.white;
  static const Color textSecondaryColor = Colors.white70;

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      textTheme: GoogleFonts.oswaldTextTheme().copyWith(
        displayLarge: GoogleFonts.oswald(color: textPrimaryColor, fontWeight: FontWeight.bold),
        titleLarge: GoogleFonts.oswald(color: textPrimaryColor, fontWeight: FontWeight.w600),
        bodyLarge: GoogleFonts.roboto(color: textSecondaryColor),
        bodyMedium: GoogleFonts.roboto(color: textSecondaryColor),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.oswald(color: textPrimaryColor, fontSize: 24, fontWeight: FontWeight.bold),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: GoogleFonts.oswald(fontSize: 20, letterSpacing: 1.5, fontWeight: FontWeight.bold),
          elevation: 8,
          shadowColor: primaryColor.withOpacity(0.5),
        ),
      ),
    );
  }
}
