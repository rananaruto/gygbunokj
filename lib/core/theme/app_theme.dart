import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// SnapTube Design System — Dark Hacker Neon aesthetic
/// Black background + neon cyan / purple / green accents
class AppTheme {
  AppTheme._();

  // ── Palette ───────────────────────────────────────────
  static const Color bgColor       = Color(0xFF080B14);
  static const Color surfaceColor  = Color(0xFF0E1422);
  static const Color cardColor     = Color(0xFF141928);
  static const Color neonCyan      = Color(0xFF00F5FF);
  static const Color neonGreen     = Color(0xFF39FF14);
  static const Color neonPurple    = Color(0xFFBF5AF2);
  static const Color neonRed       = Color(0xFFFF2D55);
  static const Color neonOrange    = Color(0xFFFF9F0A);
  static const Color textPrimary   = Color(0xFFEEF2FF);
  static const Color textSecondary = Color(0xFF6B7DB3);
  static const Color borderColor   = Color(0xFF1E2A45);
  static const Color progressBg    = Color(0xFF1A2040);

  // ── Gradients ─────────────────────────────────────────
  static const LinearGradient neonGradient = LinearGradient(
    colors: [neonCyan, neonPurple],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF141928), Color(0xFF0E1422)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Glow shadows ──────────────────────────────────────
  static List<BoxShadow> get neonGlow => [
    BoxShadow(color: neonCyan.withOpacity(0.3), blurRadius: 20, spreadRadius: 2),
  ];

  static List<BoxShadow> get cardShadow => [
    BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 12, offset: const Offset(0, 4)),
  ];

  // ── Theme ─────────────────────────────────────────────
  static ThemeData darkTheme() {
    final base = GoogleFonts.outfitTextTheme().apply(
      bodyColor: textPrimary,
      displayColor: textPrimary,
    );

    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgColor,
      primaryColor: neonCyan,
      colorScheme: const ColorScheme.dark(
        primary: neonCyan,
        secondary: neonPurple,
        surface: surfaceColor,
        background: bgColor,
        error: neonRed,
      ),
      textTheme: base,
      appBarTheme: AppBarTheme(
        backgroundColor: bgColor,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.outfit(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
        iconTheme: const IconThemeData(color: neonCyan),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surfaceColor,
        selectedItemColor: neonCyan,
        unselectedItemColor: textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
      ),
      cardTheme: CardTheme(
        color: cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: borderColor, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: neonCyan, width: 1.5),
        ),
        hintStyle: const TextStyle(color: textSecondary, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      dividerColor: borderColor,
      useMaterial3: true,
    );
  }
}
