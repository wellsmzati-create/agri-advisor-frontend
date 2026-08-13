import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class WebColors {
  static const sidebarBg = Color(0xFF0F1923);
  static const sidebarActive = Color(0xFF1E2D3D);
  static const sidebarAccent = Color(0xFF2E7D32);
  static const topBarBg = Color(0xFFFFFFFF);
  static const pageBg = Color(0xFFF4F6F9);
  static const cardBg = Color(0xFFFFFFFF);
  static const primary = Color(0xFF2E7D32);
  static const primaryLight = Color(0xFF4CAF50);
  static const accent = Color(0xFF00BFA5);
  static const warning = Color(0xFFFB8C00);
  static const danger = Color(0xFFE53935);
  static const info = Color(0xFF1E88E5);
  static const purple = Color(0xFF7B1FA2);
  static const textPrimary = Color(0xFF1A2332);
  static const textSecondary = Color(0xFF6B7A8D);
  static const textMuted = Color(0xFFADB5BD);
  static const divider = Color(0xFFE8ECF0);
  static const sidebarText = Color(0xFFB0BEC5);
  static const sidebarTextActive = Color(0xFFFFFFFF);

  static const gradientGreen = LinearGradient(
    colors: [Color(0xFF2E7D32), Color(0xFF43A047)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );
  static const gradientBlue = LinearGradient(
    colors: [Color(0xFF1565C0), Color(0xFF1E88E5)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );
  static const gradientOrange = LinearGradient(
    colors: [Color(0xFFE65100), Color(0xFFFB8C00)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );
  static const gradientPurple = LinearGradient(
    colors: [Color(0xFF6A1B9A), Color(0xFF9C27B0)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );
  static const gradientTeal = LinearGradient(
    colors: [Color(0xFF00695C), Color(0xFF00BFA5)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );
}

class WebTheme {
  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: WebColors.primary,
          primary: WebColors.primary,
          surface: WebColors.cardBg,
        ),
        scaffoldBackgroundColor: WebColors.pageBg,
        textTheme: GoogleFonts.interTextTheme().copyWith(
          displayLarge: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w700, color: WebColors.textPrimary),
          headlineMedium: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600, color: WebColors.textPrimary),
          titleLarge: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: WebColors.textPrimary),
          titleMedium: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: WebColors.textPrimary),
          bodyLarge: GoogleFonts.inter(fontSize: 14, color: WebColors.textPrimary),
          bodyMedium: GoogleFonts.inter(fontSize: 13, color: WebColors.textSecondary),
          labelLarge: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        cardTheme: CardThemeData(
          color: WebColors.cardBg,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: WebColors.divider),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: WebColors.cardBg,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: WebColors.divider),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: WebColors.divider),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: WebColors.primary, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          labelStyle: GoogleFonts.inter(fontSize: 13, color: WebColors.textSecondary),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: WebColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            textStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
      );
}
