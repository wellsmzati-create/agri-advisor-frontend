import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const primary = Color(0xFF2E7D32);
  static const primaryLight = Color(0xFF4CAF50);
  static const primaryDark = Color(0xFF1B5E20);
  static const secondary = Color(0xFF8D6E63);
  static const accent = Color(0xFFFFA000);
  static const background = Color(0xFFF1F8E9);
  static const surface = Color(0xFFFFFFFF);
  static const cardBg = Color(0xFFFFFFFF);
  static const textPrimary = Color(0xFF1A1A1A);
  static const textSecondary = Color(0xFF6D6D6D);
  static const divider = Color(0xFFE0E0E0);
  static const success = Color(0xFF43A047);
  static const warning = Color(0xFFFB8C00);
  static const info = Color(0xFF1E88E5);
  static const earthBrown = Color(0xFF795548);
  static const skyBlue = Color(0xFF29B6F6);
  static const sunYellow = Color(0xFFFFCA28);

  static const gradientGreen = LinearGradient(
    colors: [Color(0xFF2E7D32), Color(0xFF66BB6A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const gradientEarth = LinearGradient(
    colors: [Color(0xFF5D4037), Color(0xFF8D6E63)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const gradientSky = LinearGradient(
    colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class AppTheme {
  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          secondary: AppColors.secondary,
          surface: AppColors.surface,
          background: AppColors.background,
        ),
        scaffoldBackgroundColor: AppColors.background,
        textTheme: GoogleFonts.poppinsTextTheme().copyWith(
          displayLarge: GoogleFonts.poppins(
              fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          headlineMedium: GoogleFonts.poppins(
              fontSize: 22, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          titleLarge: GoogleFonts.poppins(
              fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          titleMedium: GoogleFonts.poppins(
              fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
          bodyLarge: GoogleFonts.poppins(fontSize: 15, color: AppColors.textPrimary),
          bodyMedium: GoogleFonts.poppins(fontSize: 13, color: AppColors.textSecondary),
          labelLarge: GoogleFonts.poppins(
              fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          titleTextStyle: GoogleFonts.poppins(
              fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.divider),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.divider),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        cardTheme: CardThemeData(
          color: AppColors.cardBg,
          elevation: 2,
          shadowColor: Colors.black12,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textSecondary,
          type: BottomNavigationBarType.fixed,
          elevation: 12,
        ),
      );
}
