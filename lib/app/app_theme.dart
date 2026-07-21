import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color background = Color(0xFF15181C);
  static const Color surface = Color(0xFF1B2026);
  static const Color surfaceElevated = Color(0xFF222A31);
  static const Color emerald = Color(0xFF4CB58B);
  static const Color emeraldSoft = Color(0xFF8BD4B7);
  static const Color sand = Color(0xFFCEC6B2);
  static const Color copper = Color(0xFFB07A56);

  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: emerald,
      brightness: Brightness.dark,
      surface: surface,
      background: background,
    ).copyWith(
      primary: emerald,
      secondary: copper,
      tertiary: emeraldSoft,
    );

    return ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      textTheme: GoogleFonts.playfairDisplayTextTheme().copyWith(
        bodyMedium: GoogleFonts.inter(color: Colors.white70),
        bodySmall: GoogleFonts.inter(color: Colors.white60),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      cardColor: surface,
      dividerColor: Colors.white10,
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface.withValues(alpha: 0.96),
        indicatorColor: emerald.withValues(alpha: 0.2),
        labelTextStyle: WidgetStateProperty.all(
          GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}