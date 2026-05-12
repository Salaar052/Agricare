import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Earthy agricultural palette
  static const Color primary = Color(0xFF2D6A4F); // Deep forest green
  static const Color primaryLight = Color(0xFF52B788); // Medium green
  static const Color accent = Color(0xFFD4A017); // Golden wheat
  static const Color accentLight = Color(0xFFF4D03F); // Light gold
  static const Color background = Color(0xFFF8F5F0); // Warm off-white
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1A2E1A); // Very dark green-black
  static const Color textSecondary = Color(0xFF5C6B5C); // Muted green-grey
  static const Color error = Color(0xFFB5432A);
  static const Color fertilizerColor = Color(
    0xFF1565C0,
  ); // Blue for fertilizers
  static const Color pesticideColor = Color(
    0xFF6A1B9A,
  ); // Purple for pesticides
  static const Color harvestColor = Color(0xFFE65100); // Orange for harvest

  static ThemeData get theme => ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      primary: primary,
      secondary: accent,
      background: background,
      surface: surface,
      error: error,
    ),
    scaffoldBackgroundColor: background,
    textTheme: GoogleFonts.plusJakartaSansTextTheme().copyWith(
      displayLarge: GoogleFonts.playfairDisplay(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: textPrimary,
      ),
      titleLarge: GoogleFonts.plusJakartaSans(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: textPrimary,
      ),
      titleMedium: GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      bodyLarge: GoogleFonts.plusJakartaSans(fontSize: 15, color: textPrimary),
      bodyMedium: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        color: textSecondary,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      margin: EdgeInsets.zero,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: error),
      ),
      labelStyle: GoogleFonts.plusJakartaSans(color: textSecondary),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.plusJakartaSans(
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    useMaterial3: true,
  );
}
