import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class EpaColors {
  static const sidebarBg    = Color(0xFF0D1B2A);
  static const sidebarActive = Color(0xFF1B2E42);
  static const pageBg       = Color(0xFFF0F4F8);
  static const cardBg       = Color(0xFFFFFFFF);
  static const topBarBg     = Color(0xFFFFFFFF);
  static const primary      = Color(0xFF1565C0);
  static const primaryLight = Color(0xFF42A5F5);
  static const accent       = Color(0xFF00897B);
  static const warning      = Color(0xFFF57C00);
  static const danger       = Color(0xFFC62828);
  static const success      = Color(0xFF2E7D32);
  static const info         = Color(0xFF0277BD);
  static const purple       = Color(0xFF6A1B9A);
  static const amber        = Color(0xFFFF8F00);
  static const textPrimary  = Color(0xFF0D1B2A);
  static const textSecondary= Color(0xFF546E7A);
  static const textMuted    = Color(0xFF90A4AE);
  static const divider      = Color(0xFFE0E7EF);
  static const sidebarText  = Color(0xFF90A4AE);

  static const gradientBlue = LinearGradient(
    colors: [Color(0xFF0D47A1), Color(0xFF1565C0)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );
  static const gradientTeal = LinearGradient(
    colors: [Color(0xFF00695C), Color(0xFF00897B)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );
  static const gradientRed = LinearGradient(
    colors: [Color(0xFFB71C1C), Color(0xFFC62828)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );
  static const gradientAmber = LinearGradient(
    colors: [Color(0xFFE65100), Color(0xFFF57C00)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );
  static const gradientPurple = LinearGradient(
    colors: [Color(0xFF4A148C), Color(0xFF6A1B9A)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );
  static const gradientGreen = LinearGradient(
    colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );
  static const gradientNavy = LinearGradient(
    colors: [Color(0xFF0D1B2A), Color(0xFF1B2E42)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );
}

class EpaTheme {
  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: EpaColors.primary,
      primary: EpaColors.primary,
      surface: EpaColors.cardBg,
    ),
    scaffoldBackgroundColor: EpaColors.pageBg,
    textTheme: GoogleFonts.interTextTheme().copyWith(
      displayLarge: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w700, color: EpaColors.textPrimary),
      headlineMedium: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600, color: EpaColors.textPrimary),
      titleLarge: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: EpaColors.textPrimary),
      bodyLarge: GoogleFonts.inter(fontSize: 14, color: EpaColors.textPrimary),
      bodyMedium: GoogleFonts.inter(fontSize: 13, color: EpaColors.textSecondary),
    ),
    cardTheme: CardThemeData(
      color: EpaColors.cardBg, elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: EpaColors.divider),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true, fillColor: EpaColors.cardBg,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: EpaColors.divider)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: EpaColors.divider)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: EpaColors.primary, width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: EpaColors.primary, foregroundColor: Colors.white, elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
      ),
    ),
  );
}
