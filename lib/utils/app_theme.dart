import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Cyberpunk / High-end Tactical Neon Aesthetic
  static const Color primaryColor = Color(0xFF00E5FF); // Neon Cyan
  static const Color backgroundColor = Color(0xFF08080C); // Deep Abyss Black
  static const Color accentColor = Color(0xFFFF007F); // Neon Pink Accent
  static const Color secondaryColor = Color(0xFF8A2BE2); // Deep Purple
  static const Color textPrimaryColor = Color(0xFFFFFFFF); // Pure White
  static const Color textSecondaryColor = Color(0xFFB0BEC5); // Metallic Grey
  
  static const Color dangerColor = Color(0xFFFF1744); // Neon Red
  static const Color successColor = Color(0xFF00E676); // Neon Green

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      textTheme: GoogleFonts.oswaldTextTheme().copyWith(
        displayLarge: GoogleFonts.oswald(color: textPrimaryColor, fontWeight: FontWeight.bold),
        titleLarge: GoogleFonts.oswald(color: textPrimaryColor, fontWeight: FontWeight.w600),
        bodyLarge: GoogleFonts.oswald(color: textSecondaryColor, fontWeight: FontWeight.w500, letterSpacing: 1.0),
        bodyMedium: GoogleFonts.oswald(color: textSecondaryColor, fontWeight: FontWeight.w400, letterSpacing: 1.0),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.oswald(color: textPrimaryColor, fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 3),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor.withOpacity(0.8),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: accentColor, width: 2),
          ),
          textStyle: GoogleFonts.oswald(fontSize: 24, letterSpacing: 2.0, fontWeight: FontWeight.bold),
          elevation: 15,
          shadowColor: primaryColor.withOpacity(0.8),
        ),
      ),
    );
  }
}
