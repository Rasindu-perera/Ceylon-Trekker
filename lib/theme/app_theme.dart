import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Colors based on the PDF design (emerald greens, dark background)
  static const Color darkBackground = Color(0xFF121413); // Very dark, almost black
  static const Color primaryEmerald = Color(0xFF327B5B); // Emerald green for buttons/chips
  static const Color cardBackground = Color(0xFF1E2120); // Dark gray for cards
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Colors.white70;
  static const Color accentEarth = Color(0xFFC49A6C); // Earthy tone for budget chart

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBackground,
      primaryColor: primaryEmerald,
      cardColor: cardBackground,
      useMaterial3: true,
      textTheme: GoogleFonts.interTextTheme().apply(
        bodyColor: textPrimary,
        displayColor: textPrimary,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: darkBackground,
        selectedItemColor: primaryEmerald,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      colorScheme: const ColorScheme.dark(
        primary: primaryEmerald,
        surface: cardBackground,
        background: darkBackground,
      ),
    );
  }
}
