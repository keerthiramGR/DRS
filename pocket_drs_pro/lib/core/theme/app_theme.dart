import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Theme Color Palette
  static const Color darkBg = Color(0xFF0C0E1A);
  static const Color surfaceCard = Color(0xFF161A30);
  static const Color accentPurple = Color(0xFF7A1CAC);
  static const Color neonCyan = Color(0xFF00F0FF);
  static const Color iplGold = Color(0xFFFFCC00);
  static const Color neonGreen = Color(0xFF39FF14);
  static const Color neonRed = Color(0xFFFF3131);
  static const Color textPrimary = Color(0xFFF3F4F6);
  static const Color textSecondary = Color(0xFF9CA3AF);

  // Gradient definitions
  static const LinearGradient purpleCyanGradient = LinearGradient(
    colors: [accentPurple, neonCyan],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFFFB300), iplGold],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkCardGradient = LinearGradient(
    colors: [Color(0xFF1E2240), surfaceCard],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBg,
      primaryColor: accentPurple,
      colorScheme: const ColorScheme.dark(
        primary: accentPurple,
        secondary: neonCyan,
        surface: surfaceCard,
        error: neonRed,
      ),
      textTheme: GoogleFonts.outfitTextTheme(
        ThemeData.dark().textTheme.copyWith(
              displayLarge: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: textPrimary),
              displayMedium: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textPrimary),
              bodyLarge: const TextStyle(fontSize: 16, color: textPrimary),
              bodyMedium: const TextStyle(fontSize: 14, color: textSecondary),
            ),
      ),
      cardTheme: CardThemeData(
        color: surfaceCard,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF262D4A), width: 1.5),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: textPrimary,
          letterSpacing: 1.2,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentPurple,
          foregroundColor: textPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    );
  }

  // Common glassmorphic decoration
  static BoxDecoration glassBox({Color border = const Color(0xFF2E375E), double radius = 16}) {
    return BoxDecoration(
      color: surfaceCard.withOpacity(0.85),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: border, width: 1.5),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.3),
          blurRadius: 10,
          offset: const Offset(0, 5),
        )
      ],
    );
  }
}
